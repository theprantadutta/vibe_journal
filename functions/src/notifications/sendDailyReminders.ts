import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {getMessaging} from "firebase-admin/messaging";

/**
 * A scheduled function that runs every day at 9:00 AM (UTC).
 * Finds users with reminders enabled, sends a random notification,
 * and cleans up invalid device tokens.
 */
export const sendDailyReminders = onSchedule("every day 09:00", async (event) => {
  logger.info("🚀 Executing sendDailyReminders function...");

  // 1. Fetch a random, active daily reminder template
  const templatesSnapshot = await admin.firestore().collection("notification_templates")
    .where("type", "==", "daily_reminder")
    .where("isActive", "==", true)
    .get();

  if (templatesSnapshot.empty) {
    logger.error("No active daily reminder templates found. Exiting.");
    return;
  }
  const templates = templatesSnapshot.docs.map((doc) => doc.data());
  const randomTemplate = templates[Math.floor(Math.random() * templates.length)];
  const {title, body} = randomTemplate;

  if (!title || !body) {
    logger.error("Chosen template is missing title or body.", randomTemplate);
    return;
  }
  logger.info(`Selected random notification: "${title}"`);

  // 2. Find all users who have daily reminders enabled
  const usersSnapshot = await admin.firestore().collection("users")
    .where("notificationPreferences.dailyReminderEnabled", "==", true)
    .get();

  if (usersSnapshot.empty) {
    logger.info("No users with daily reminders enabled. Exiting.");
    return;
  }

  // 3. Collect all tokens and create a map to track which user owns which token
  const tokenToUserMap = new Map<string, string>();
  usersSnapshot.forEach((doc) => {
    const user = doc.data();
    const userId = doc.id;
    if (user.fcmTokens && Array.isArray(user.fcmTokens)) {
      user.fcmTokens.forEach((token: string) => {
        tokenToUserMap.set(token, userId);
      });
    }
  });

  const allTokens = Array.from(tokenToUserMap.keys());
  if (allTokens.length === 0) {
    logger.info("Users found, but no valid FCM tokens. Exiting.");
    return;
  }

  // 4. Batch notifications and send using sendEachForMulticast
  logger.info(`Total tokens to send to: ${allTokens.length}. Preparing batches...`);

  const messaging = getMessaging();
  const batchSize = 500;
  const cleanupPromises: Promise<any>[] = [];

  for (let i = 0; i < allTokens.length; i += batchSize) {
    const chunk = allTokens.slice(i, i + batchSize);

    const message = {
      notification: {title, body},
      tokens: chunk,
    };

    logger.log(`Sending batch starting at index ${i} with ${chunk.length} tokens.`);
    
    // Using sendEachForMulticast gives us detailed results for each token
    const response = await messaging.sendEachForMulticast(message);
    
    logger.info(`${response.successCount} messages from this batch sent successfully.`);

    // 5. Handle errors and identify invalid tokens for cleanup
    if (response.failureCount > 0) {
      logger.warn(`${response.failureCount} messages from this batch failed.`);
      
      response.responses.forEach((result, index) => {
        const error = result.error;
        if (error) {
          const failedToken = chunk[index];
          logger.error(`Failure sending to token: ${failedToken}`, error);

          // If the error indicates the token is no longer valid, schedule it for deletion
          if (
            error.code === "messaging/registration-token-not-registered" ||
            error.code === "messaging/invalid-registration-token"
          ) {
            const userId = tokenToUserMap.get(failedToken);
            if (userId) {
              logger.log(`Queueing removal of invalid token for user: ${userId}`);
              const userRef = admin.firestore().collection("users").doc(userId);
              const cleanupPromise = userRef.update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(failedToken),
              });
              cleanupPromises.push(cleanupPromise);
            }
          }
        }
      });
    }
  }

  // 6. Wait for all cleanup operations to complete
  await Promise.all(cleanupPromises);
  logger.info("Finished processing all batches and cleaning up invalid tokens.");
});
