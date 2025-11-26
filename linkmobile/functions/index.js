const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onRequest} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Core function to send port-in reminder notifications
 * This is called by both the scheduled function and the manual trigger
 * @param {boolean} skip24HourCheck - If true, ignores the 24-hour cooldown period
 */
async function sendPortInReminderNotifications(skip24HourCheck = false) {
  console.log('🔄 Starting port-in reminder notification job...');
  if (skip24HourCheck) {
    console.log('⚠️ Manual trigger: 24-hour cooldown check is disabled');
  }
  
  const db = admin.firestore();
  const messaging = admin.messaging();
  
  try {
    // Get all users who have FCM tokens (notification permission granted)
    // Note: Firestore doesn't support querying for array existence directly
    // So we'll need to fetch all users and filter in code, or use a different approach
    // For better performance with many users, consider adding a hasFcmTokens boolean field
    const usersSnapshot = await db.collection('users').get();
    
    console.log(`📊 Found ${usersSnapshot.size} total users`);
    
    let notificationsSent = 0;
    let errors = 0;
    let usersProcessed = 0;
    
    // Process each user
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      const fcmTokens = userData.fcmTokens || [];
      
      // Log FCM token status for all users
      if (Array.isArray(fcmTokens) && fcmTokens.length > 0) {
        console.log(`✅ User ${userId} has ${fcmTokens.length} FCM token(s)`);
      } else {
        console.log(`❌ User ${userId} has no FCM tokens`);
      }
      
      // Skip if no FCM tokens (no notification permission)
      if (!Array.isArray(fcmTokens) || fcmTokens.length === 0) {
        continue;
      }
      
      usersProcessed++;
      
      try {
        // Get user's pending/incomplete orders (including pending_port_in)
        const ordersSnapshot = await db.collection('users')
          .doc(userId)
          .collection('orders')
          .where('status', 'in', ['pending', 'draft', 'pending_port_in'])
          .get();
        
        if (ordersSnapshot.empty) {
          continue;
        }
        
        // Check each order for pending port-in (skipped or needs completion)
        let hasPendingPortIn = false;
        let latestOrderId = null;
        let latestOrderUpdated = null;
        
        for (const orderDoc of ordersSnapshot.docs) {
          const orderData = orderDoc.data();
          const orderStatus = orderData.status;
          const portInSkipped = orderData.portInSkipped === true;
          const billingCompleted = orderData.billingCompleted === true;
          
          // Check if order needs port-in completion:
          // 1. Order has pending_port_in status (billing completed but port-in pending)
          // 2. Port-in was skipped and billing not completed
          const needsPortIn = orderStatus === 'pending_port_in' || 
                             (portInSkipped && billingCompleted);
          
          if (needsPortIn) {
            hasPendingPortIn = true;
            
            // Track the most recent order
            const orderUpdated = orderData.updatedAt?.toMillis() || 0;
            if (!latestOrderUpdated || orderUpdated > latestOrderUpdated) {
              latestOrderUpdated = orderUpdated;
              latestOrderId = orderDoc.id;
            }
          }
        }
        
        // Send notification if user has pending port-in
        if (hasPendingPortIn && latestOrderId) {
          // Check if we've already sent a notification recently (within last 24 hours)
          // Skip this check if called manually
          if (!skip24HourCheck) {
            const lastNotificationSent = userData.lastPortInReminderSent;
            const now = admin.firestore.Timestamp.now();
            const oneDayAgo = now.toMillis() - (24 * 60 * 60 * 1000);
            
            if (lastNotificationSent && lastNotificationSent.toMillis() > oneDayAgo) {
              console.log(`⏭️ Skipping user ${userId} - notification sent recently`);
              continue;
            }
          } else {
            console.log(`🔓 Manual trigger: Skipping 24-hour check for user ${userId}`);
          }
          
          // Validate FCM tokens before sending
          const validTokens = fcmTokens.filter(token => 
            token && typeof token === 'string' && token.length > 0
          );
          
          if (validTokens.length === 0) {
            console.log(`⚠️ User ${userId} has no valid FCM tokens`);
            continue;
          }
          
          // Log token info for debugging (first 20 chars only for security)
          console.log(`📱 User ${userId} has ${validTokens.length} valid token(s). First token preview: ${validTokens[0].substring(0, 20)}...`);
          
          // Prepare notification message
          const message = {
            notification: {
              title: 'Complete Your Order Details',
              body: 'You have an incomplete order. Please complete your port-in details to finish your order.',
            },
            data: {
              type: 'port_in_reminder',
              orderId: latestOrderId,
              userId: userId,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            tokens: validTokens,
          };
          
          console.log(`📤 Attempting to send notification to user ${userId} with ${validTokens.length} token(s)`);
          
          try {
            // Try batch send first
            const response = await messaging.sendMulticast(message);
            
            if (response.successCount > 0) {
              console.log(`✅ Sent notification to user ${userId} (${response.successCount} devices)`);
              
              // Update last notification sent timestamp
              await db.collection('users').doc(userId).update({
                lastPortInReminderSent: admin.firestore.FieldValue.serverTimestamp(),
              });
              
              notificationsSent += response.successCount;
            }
            
            if (response.failureCount > 0) {
              console.warn(`⚠️ Failed to send to ${response.failureCount} devices for user ${userId}`);
              errors += response.failureCount;
              
              // Remove invalid tokens
              const invalidTokens = [];
              response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                  const errorCode = resp.error?.code;
                  console.warn(`  Device ${idx} error: ${errorCode} - ${resp.error?.message}`);
                  
                  if (errorCode === 'messaging/invalid-registration-token' ||
                      errorCode === 'messaging/registration-token-not-registered' ||
                      errorCode === 'messaging/unknown-error') {
                    invalidTokens.push(validTokens[idx]);
                  }
                }
              });
              
              if (invalidTokens.length > 0) {
                const updatedTokens = fcmTokens.filter(token => !invalidTokens.includes(token));
                await db.collection('users').doc(userId).update({
                  fcmTokens: updatedTokens,
                });
                console.log(`🧹 Removed ${invalidTokens.length} invalid tokens for user ${userId}`);
              }
            }
          } catch (fcmError) {
            console.error(`❌ FCM batch error for user ${userId}:`, fcmError.code || fcmError.message);
            console.error(`  Error type: ${fcmError.constructor.name}`);
            
            // Log detailed error info for debugging
            if (fcmError.code === 'messaging/unknown-error' || fcmError.code === 'messaging/invalid-argument') {
              console.error(`  This might indicate FCM API is not properly configured or tokens are invalid`);
              if (fcmError.errorInfo) {
                console.error(`  Error details:`, JSON.stringify(fcmError.errorInfo, null, 2));
              }
            }
            
            // If batch fails, try sending to individual tokens
            if (fcmError.code === 'messaging/unknown-error' && validTokens.length > 0) {
              console.log(`🔄 Batch failed, trying individual token sends for user ${userId}...`);
              let individualSuccess = 0;
              const tokensToRemove = [];
              
              for (let i = 0; i < validTokens.length; i++) {
                try {
                  const singleResponse = await messaging.send({
                    notification: message.notification,
                    data: message.data,
                    token: validTokens[i],
                  });
                  console.log(`✅ Successfully sent to token ${i} for user ${userId}`);
                  individualSuccess++;
                } catch (singleError) {
                  console.error(`❌ Failed to send to token ${i} for user ${userId}:`, singleError.code || singleError.message);
                  if (singleError.code === 'messaging/invalid-registration-token' ||
                      singleError.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(validTokens[i]);
                  }
                }
              }
              
              if (individualSuccess > 0) {
                notificationsSent += individualSuccess;
                await db.collection('users').doc(userId).update({
                  lastPortInReminderSent: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log(`✅ Individual sends succeeded: ${individualSuccess}/${validTokens.length} for user ${userId}`);
              }
              
              if (tokensToRemove.length > 0) {
                const updatedTokens = fcmTokens.filter(token => !tokensToRemove.includes(token));
                await db.collection('users').doc(userId).update({
                  fcmTokens: updatedTokens,
                });
                console.log(`🧹 Removed ${tokensToRemove.length} invalid tokens for user ${userId}`);
              }
              
              if (individualSuccess === 0) {
                errors++;
              }
            } else {
              // Continue to next user instead of throwing
              errors++;
            }
            continue;
          }
        }
      } catch (error) {
        console.error(`❌ Error processing user ${userId}:`, error);
        errors++;
      }
    }
    
    console.log(`✅ Job completed. Users processed: ${usersProcessed}, Notifications sent: ${notificationsSent}, Errors: ${errors}`);
    return null;
  } catch (error) {
    console.error('❌ Fatal error in port-in reminder job:', error);
    throw error;
  }
}

/**
 * Scheduled function (cron job) that runs daily to send notifications
 * to users who have FCM tokens and have skipped port-in
 * 
 * Runs every day at 10:00 AM UTC (adjust timezone as needed)
 * To change schedule, modify the cron expression:
 * - "0 10 * * *" = daily at 10:00 AM UTC
 * - "0 10 * * 1" = every Monday at 10:00 AM UTC
 * - "0 0,6,12,18 * * *" = every 6 hours (at 0, 6, 12, 18)
 */
exports.sendPortInReminderNotifications = onSchedule(
  {
    schedule: '0 10 * * *', // Daily at 10:00 AM UTC
    timeZone: 'UTC',
  },
  async (event) => {
    await sendPortInReminderNotifications();
  }
);

/**
 * Optional: Manual trigger function for testing
 * You can call this from Firebase Console or via HTTP
 */
exports.manualPortInReminder = onRequest(async (req, res) => {
  // Only allow POST requests
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  
  // Optional: Add authentication/authorization check here
  // For example, check for an admin token
  
  try {
    // Trigger the scheduled function logic
    await sendPortInReminderNotifications(true); // Pass true to skip 24-hour check
    res.status(200).json({ success: true, message: 'Reminder notifications sent' });
  } catch (error) {
    console.error('Error in manual trigger:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

