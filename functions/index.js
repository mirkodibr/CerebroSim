/**
 * CerebroSim Firebase Functions
 * 
 * Deployment:
 * 1. firebase functions:config:set anthropic.key="YOUR_KEY_HERE"
 * 2. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const axios = require('axios');

exports.interpretExperiment = functions.https.onCall(async (data, context) => {
  // 1. Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'Interpretation requires a signed-in account.'
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
        max_tokens: 1024,
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

    return response.data.content[0].text;
  } catch (error) {
    console.error('Anthropic API Error:', error.response ? error.response.data : error.message);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate neuroscience interpretation.'
    );
  }
});
