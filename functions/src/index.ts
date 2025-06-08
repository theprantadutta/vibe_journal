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
