import {onCall, HttpsError} from "firebase-functions/v2/https";
import {GoogleGenAI} from "@google/genai";

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Import Google Cloud clients
import {SpeechClient} from "@google-cloud/speech";
import {LanguageServiceClient} from "@google-cloud/language";
import {google} from "@google-cloud/speech/build/protos/protos";

// Initialize Firebase Admin SDK and Google Cloud clients
admin.initializeApp();
const speechClient = new SpeechClient();
const languageClient = new LanguageServiceClient();

/**
 * Triggered when a new vibe document is created in Firestore (v2 Syntax).
 * This function will orchestrate the analysis of the audio file.
 */
export const analyzeVibe = onDocumentCreated(
  "vibes/{vibeId}",
  async (event) => {
    // 1. Get the data from the newly created vibe document
    const snapshot = event.data;
    if (!snapshot) {
      logger.log("No data associated with the event, exiting.");
      return;
    }

    const vibeData = snapshot.data();
    if (!vibeData) {
      logger.log("Vibe document has no data, exiting.");
      return;
    }

    const storagePath = vibeData.audioPath;
    if (!storagePath) {
      logger.error("Audio path is missing from the vibe document.");
      return;
    }

    logger.log(
      `New vibe: ${event.params.vibeId}. Analyzing: ${storagePath}`
    );

    const bucketName = admin.storage().bucket().name;
    const gcsUri = `gs://${bucketName}/${storagePath}`;

    // --- Step 2: Speech-to-Text ---
    let transcription = "";
    try {
      logger.log(`Transcribing audio from: ${gcsUri}`);

      const audio = {uri: gcsUri};
      const config: google.cloud.speech.v1.IRecognitionConfig = {
        languageCode: "en-US",
        encoding: "FLAC",
        audioChannelCount: 1,
      };
      const request: google.cloud.speech.v1.ILongRunningRecognizeRequest = {
        audio: audio,
        config: config,
      };

      const [operation] = await speechClient.longRunningRecognize(request);
      const [response] = await operation.promise();

      transcription =
        response.results
          ?.map((result) => result.alternatives?.[0].transcript)
          .join("\n") ?? "";

      logger.log(`Transcription successful: "${transcription}"`);

      await snapshot.ref.update({transcription: transcription});
    } catch (error) {
      logger.error("Speech-to-Text failed:", error);
      await snapshot.ref.update({
        transcription: "Transcription failed.",
        mood: "unknown",
      });
      return;
    }

    if (transcription.trim().length === 0) {
      logger.log("Transcription is empty. No sentiment to analyze.");
      await snapshot.ref.update({mood: "neutral"});
      return;
    }

    // --- Step 3: Sentiment Analysis ---
    try {
      logger.log("Analyzing sentiment for transcription...");
      const [result] = await languageClient.analyzeSentiment({
        document: {
          content: transcription,
          type: "PLAIN_TEXT",
        },
      });

      const sentiment = result.documentSentiment;
      if (!sentiment) {
        throw new Error("Sentiment analysis returned no result.");
      }
      const score = sentiment.score ?? 0;
      const magnitude = sentiment.magnitude ?? 0;

      logger.log(
        `Sentiment successful: Score=${score}, Magnitude=${magnitude}`
      );

      // --- Step 4: Categorize and Save Mood ---
      let mood = "neutral";
      if (score > 0.25) {
        mood = "positive";
      } else if (score < -0.25) {
        mood = "negative";
      }

      await snapshot.ref.update({
        mood: mood,
        sentimentScore: score,
        sentimentMagnitude: magnitude,
      });
      logger.log(`Vibe analysis complete. Mood set to: ${mood}`);
    } catch (error) {
      logger.error("Sentiment analysis failed:", error);
      await snapshot.ref.update({
        mood: "unknown",
      });
    }
  }
);

/**
 * A callable function that acts as
 * a journaling assistant, powered by Gemini.
 * It can generate journaling prompts or
 * provide reflective feedback on an entry.
 */
export const aiAssistant = onCall(async (request) => {
  // 1. Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to use the AI Assistant."
    );
  }

  const {text, action} = request.data;
  if (!action) {
    throw new HttpsError("invalid-argument", "An action must be provided.");
  }

  logger.log(`AI Assistant called with action: ${action}`);

  // 2. Initialize the client using the @google/genai SDK for Vertex AI
  const genAI = new GoogleGenAI({
    vertexai: true, // Use the Vertex AI backend
    project: process.env.GCLOUD_PROJECT,
    location: "us-central1",
  });

  // 3. Construct the master prompt for the AI based on the requested action
  let prompt = "";
  if (action === "get_prompt") {
    prompt = `
      You are VibeJournal's supportive and empathetic AI assistant.
      Your goal is to help users reflect on their day.
      Please provide one, and only one, unique and thoughtful journaling prompt.
      Make it open-ended and related to self-reflection, gratitude, or daily
      experiences. Do not ask a question back to me. Just provide the prompt.
    `;
  } else if (action === "get_feedback" && text) {
    prompt = `
      You are VibeJournal's supportive and empathetic AI assistant.
      A user has shared the following journal entry with you. Your goal is to
      help them reflect. Your response must follow these rules strictly:
      1.  Do not give medical, financial, or legal advice. Do not act as a
          therapist.
      2.  Start with a one-sentence summary that validates the primary
          emotion or theme in their entry.
      3.  Then, ask one single, gentle, open-ended question to encourage
          deeper reflection.
      4.  End with the exact disclaimer: "(Disclaimer: I am an AI assistant
          and not a substitute for professional help.)"
      
      Here is the user's journal entry:
      ---
      ${text}
      ---
    `;
  } else {
    throw new HttpsError("invalid-argument", "Invalid action or missing text.");
  }

  // 4. Call the Gemini API and return the response
  try {
    // This combines model selection and content generation in one call
    const result = await genAI.models.generateContent({
      model: "gemini-2.0-flash",
      contents: [{role: "user", parts: [{text: prompt}]}],
    });

    const responseText = result.text;

    logger.log("AI Assistant response generated successfully.");
    return {responseText};
  } catch (error) {
    logger.error("Error calling generative model:", error);
    throw new HttpsError("internal", "Failed to get a response from the AI.");
  }
});
