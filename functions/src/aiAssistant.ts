import {onCall, HttpsError} from "firebase-functions/v2/https";
import {GoogleGenAI} from "@google/genai";

import * as logger from "firebase-functions/logger";

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
