import {onCall, HttpsError} from "firebase-functions/v2/https";
import {google} from "googleapis";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

import * as logger from "firebase-functions/logger";

export const verifyPlayPurchase = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const {purchaseToken, subscriptionId} = request.data;
  const packageName = "com.pranta.vibejournal"; // <-- IMPORTANT: Replace with your actual package name

  if (!purchaseToken || !subscriptionId) {
    throw new HttpsError("invalid-argument", "Missing purchase token or subscription ID.");
  }

  logger.log(`Verifying purchase for user ${request.auth.uid}...`);

  try {
    // Initialize the Google Play API client
    const auth = new google.auth.GoogleAuth({
      // The key is loaded from the function's environment config we set earlier
      credentials: JSON.parse(functions.config().play_api.key),
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });

    const publisher = google.androidpublisher({version: "v3", auth: auth});

    // Call the Google Play Developer API to verify the subscription
    const result = await publisher.purchases.subscriptions.get({
      packageName: packageName,
      subscriptionId: subscriptionId,
      token: purchaseToken,
    });
    
    // Check if the purchase is valid and active
    // expiryTimeMillis is a string, so we parse it to a number
    const expiryTime = parseInt(result.data.expiryTimeMillis ?? "0", 10);
    const isAcknowledged = result.data.acknowledgementState === 1;

    if (expiryTime > Date.now() && isAcknowledged) {
      // Purchase is valid and active. Grant premium.
      logger.log(`Purchase validated for user ${request.auth.uid}. Granting premium.`);
      
      const userRef = admin.firestore().collection("users").doc(request.auth.uid);
      
      // Update the user's document in Firestore
      await userRef.update({
        plan: "premium",
        // You might want to update their limits here as well
        maxCloudVibes: 100000, // Effectively unlimited
        maxRecordingDurationMinutes: 60, // Premium limit
        // Optionally store subscription details
        // 'subscription.id': subscriptionId,
        // 'subscription.expiry': admin.firestore.Timestamp.fromMillis(expiryTime),
      });

      return {success: true, message: "Premium access granted!"};
    } else {
      // Purchase is invalid, expired, or not acknowledged
      logger.warn(`Invalid purchase for user ${request.auth.uid}.`);
      throw new HttpsError("permission-denied", "Purchase is not valid or has expired.");
    }
  } catch (error) {
    logger.error("Error verifying Google Play purchase:", error);
    throw new HttpsError("internal", "An error occurred while verifying the purchase.");
  }
});