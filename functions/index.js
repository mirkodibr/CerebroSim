/**
 * CerebroSim Firebase Functions (v2)
 * 
 * Deployment:
 * 1. firebase functions:secrets:set ANTHROPIC_KEY
 * 2. firebase deploy --only functions
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// Define Secrets
const anthropicKey = defineSecret('ANTHROPIC_KEY');

// Constants for limits
const MAX_CALLS_PER_USER_PER_DAY = 20;
const MAX_TOKENS_PER_CALL = 1024;
const GLOBAL_DAILY_TOKEN_CAP = 1000000; // 1M tokens total safety cap

exports.interpretExperiment = onCall({ 
  secrets: [anthropicKey],
  enforceAppCheck: true 
}, async (request) => {
  // 1. Verify App Check token
  // Note: enforceAppCheck: true handles the rejection if missing/invalid.
  // In local emulator/test, we might skip this if configured.
  if (request.app === undefined && process.env.NODE_ENV !== 'test') {
    throw new HttpsError(
      'failed-precondition',
      'The function must be called from an App Check verified app.'
    );
  }

  // 2. Verify authentication
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated', 
      'Interpretation requires a signed-in account.'
    );
  }

  const uid = request.auth.uid;
  const today = new Date().toISOString().split('T')[0];
  const userUsageRef = db.collection('users').doc(uid).collection('usage').doc(today);
  const globalUsageRef = db.collection('system').doc('limits').collection('usage').doc(today);

  // 3. Check limits
  const [userUsageDoc, globalUsageDoc] = await Promise.all([
    userUsageRef.get(),
    globalUsageRef.get()
  ]);

  const userUsage = userUsageDoc.data() || { aiCalls: 0, tokensIn: 0, tokensOut: 0 };
  const globalUsage = globalUsageDoc.data() || { totalTokens: 0 };

  // 3.1 Fetch user tier for tiered limits
  const userDoc = await db.collection('users').doc(uid).get();
  const userTier = userDoc.data()?.tier || 'free';
  const callsLimit = userTier === 'free' ? MAX_CALLS_PER_USER_PER_DAY : 100;

  if (userUsage.aiCalls >= callsLimit) {
    throw new HttpsError(
      'resource-exhausted', 
      'Daily AI interpretation limit reached. Resets at midnight UTC.'
    );
  }

  if (globalUsage.totalTokens >= GLOBAL_DAILY_TOKEN_CAP) {
    throw new HttpsError(
      'resource-exhausted',
      'The service is currently at capacity. Please try again tomorrow.'
    );
  }

  const { taskName, episodeCount, finalErrorRate, learningProgress } = request.data;
  const apiKey = anthropicKey.value();

  if (!apiKey) {
    throw new HttpsError(
      'failed-precondition', 
      'Interpretation service not configured on server.'
    );
  }

  const structuredSummary = `
Experiment Summary:
- Task: ${taskName}
- Total Episodes: ${episodeCount}
- Final Error Rate: ${(finalErrorRate * 100).toFixed(2)}%
- Learning Progress (mean punishments): ${learningProgress || 'N/A'}
`;

  try {
    const response = await axios.post(
      'https://api.anthropic.com/v1/messages',
      {
        model: 'claude-3-haiku-20240307',
        max_tokens: MAX_TOKENS_PER_CALL,
        system: 'You are a neuroscience educator explaining cerebellar learning results to a graduate student. Be specific, cite Marr-Albus-Ito theory, reference LTD at PF-PC synapses, climbing fiber error signals, and DCN output. Maximum 3 short paragraphs. Be encouraging.',
        messages: [
          { role: 'user', content: structuredSummary }
        ],
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        }
      }
    );

    const usage = response.data.usage;
    const tokensIn = usage.input_tokens;
    const tokensOut = usage.output_tokens;
    const totalTokens = tokensIn + tokensOut;

    // 4. Update counters atomically
    await Promise.all([
      userUsageRef.set({
        aiCalls: admin.firestore.FieldValue.increment(1),
        tokensIn: admin.firestore.FieldValue.increment(tokensIn),
        tokensOut: admin.firestore.FieldValue.increment(tokensOut),
      }, { merge: true }),
      globalUsageRef.set({
        totalTokens: admin.firestore.FieldValue.increment(totalTokens),
      }, { merge: true })
    ]);

    return response.data.content[0].text;
  } catch (error) {
    console.error('Anthropic API Error:', error.response ? error.response.data : error.message);
    throw new HttpsError(
      'internal',
      'Failed to generate neuroscience interpretation.'
    );
  }
});
