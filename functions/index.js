/**
 * CerebroSim Firebase Functions
 * 
 * Deployment:
 * 1. firebase functions:config:set anthropic.key="YOUR_KEY_HERE"
 * 2. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// Constants for limits - could be externalized further via params/config
const MAX_CALLS_PER_USER_PER_DAY = 20;
const MAX_TOKENS_PER_CALL = 1024;
const GLOBAL_DAILY_TOKEN_CAP = 1000000; // 1M tokens total safety cap

exports.interpretExperiment = functions.https.onCall(async (data, context) => {
  // 1. Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'Interpretation requires a signed-in account.'
    );
  }

  const uid = context.auth.uid;
  const today = new Date().toISOString().split('T')[0];
  const userUsageRef = db.collection('users').doc(uid).collection('usage').doc(today);
  const globalUsageRef = db.collection('system').doc('limits').collection('usage').doc(today);

  // 2. Check limits
  const [userUsageDoc, globalUsageDoc] = await Promise.all([
    userUsageRef.get(),
    globalUsageRef.get()
  ]);

  const userUsage = userUsageDoc.data() || { aiCalls: 0, tokensIn: 0, tokensOut: 0 };
  const globalUsage = globalUsageDoc.data() || { totalTokens: 0 };

  // 2.1 Fetch user tier for tiered limits
  const userDoc = await db.collection('users').doc(uid).get();
  const userTier = userDoc.data()?.tier || 'free';
  const callsLimit = userTier === 'free' ? MAX_CALLS_PER_USER_PER_DAY : 100; // Future tiers

  if (userUsage.aiCalls >= callsLimit) {
    throw new functions.https.HttpsError(
      'resource-exhausted', 
      'Daily AI interpretation limit reached. Resets at midnight UTC.'
    );
  }

  if (globalUsage.totalTokens >= GLOBAL_DAILY_TOKEN_CAP) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'The service is currently at capacity. Please try again tomorrow.'
    );
  }

  const { taskName, episodeCount, finalErrorRate, learningProgress } = data;
  const apiKey = functions.config().anthropic.key;

  if (!apiKey) {
    throw new functions.https.HttpsError(
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

    // 3. Update counters atomically
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
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate neuroscience interpretation.'
    );
  }
});
