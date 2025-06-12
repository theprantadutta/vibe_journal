import {onSchedule} from "firebase-functions/v2/scheduler";

import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
/**
 * A scheduled function that runs every day at 9:00 AM (UTC).
 * It finds users who have daily reminders enabled and sends them
 * a push notification.
 */
export const sendDailyReminders = onSchedule("every day 09:00", async (event) => {
  logger.log("Executing sendDailyReminders function...");

  // 1. Fetch all active, daily reminder notification templates
  const templatesSnapshot = await admin.firestore().collection("notification_templates")
    .where("type", "==", "daily_reminder")
    .where("isActive", "==", true)
    .get();

  if (templatesSnapshot.empty) {
    logger.error("No active daily reminder templates found in Firestore. Exiting.");
    return;
  }

  // 2. Pick one template at random from the list
  const templates = templatesSnapshot.docs.map((doc) => doc.data());
  const randomTemplate = templates[Math.floor(Math.random() * templates.length)];

  const { title, body } = randomTemplate;

  if (!title || !body) {
    logger.error("Chosen template is missing a title or body. Exiting.", randomTemplate);
    return;
  }

  logger.log(`Selected random notification: "${title}"`);

  // 3. Construct the dynamic notification payload
  const payload: admin.messaging.MessagingPayload = {
    notification: {
      title: title,
      body: body,
    },
  };

  // 4. Find all users who have daily reminders enabled (this part is the same)
  const usersSnapshot = await admin.firestore().collection("users")
    .where("dailyReminderEnabled", "==", true)
    .get();

  if (usersSnapshot.empty) {
    logger.log("No users with daily reminders enabled. Exiting.");
    return;
  }

  const tokens: string[] = [];
  usersSnapshot.forEach((doc) => {
    const user = doc.data();
    if (user.fcmTokens && Array.isArray(user.fcmTokens)) {
      tokens.push(...user.fcmTokens);
    }
  });

  if (tokens.length === 0) {
    logger.log("Users found, but no valid FCM tokens. Exiting.");
    return;
  }

  // 5. Send the dynamically fetched notification
  logger.log(`Sending notification to ${tokens.length} token(s)...`);
  try {
    const response = await admin.messaging().sendToDevice(tokens, payload);
    logger.log("Successfully sent messages:", response.successCount);
    // You can add logic here to handle and remove invalid tokens
  } catch (error) {
    logger.error("Error sending notifications:", error);
  }
});