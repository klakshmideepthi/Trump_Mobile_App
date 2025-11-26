# Firebase Functions - Port-In Reminder Notifications

This directory contains Firebase Cloud Functions that send reminder notifications to users who have skipped port-in and have incomplete orders.

## Function Overview

### `sendPortInReminderNotifications`
- **Type**: Scheduled Function (Cron Job)
- **Schedule**: Daily at 10:00 AM UTC
- **Purpose**: Sends FCM notifications to users who:
  - Have FCM tokens (notification permission granted)
  - Have orders with `portInSkipped: true`
  - Have incomplete orders (billing not completed)
- **Rate Limiting**: Prevents sending duplicate notifications within 24 hours

### `manualPortInReminder`
- **Type**: HTTP Function
- **Purpose**: Manual trigger for testing
- **Method**: POST
- **Usage**: Call via HTTP POST request for testing

## Prerequisites

⚠️ **Important**: Your Firebase project must be on the **Blaze (pay-as-you-go) plan** to deploy Cloud Functions. The free Spark plan does not support Cloud Functions.

- Upgrade your project: https://console.firebase.google.com/project/linkmobile-494b0/usage/details
- Don't worry - there's a generous free tier, and you only pay for what you use

## Setup Instructions

1. **Ensure Node.js 20+ is installed and active**:
   ```bash
   # If using nvm
   nvm install 20
   nvm use 20
   nvm alias default 20
   
   # Verify version
   node --version  # Should show v20.x.x or higher
   ```

2. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

3. **Login to Firebase**:
   ```bash
   firebase login
   ```

4. **Install dependencies**:
   ```bash
   cd functions
   npm install
   ```

5. **Deploy the function**:
   
   **Option A: Use the deployment script** (recommended):
   ```bash
   # From the linkmobile directory
   ./deploy-functions.sh
   ```
   
   **Option B: Deploy manually**:
   ```bash
   # From the linkmobile directory
   source ~/.nvm/nvm.sh  # Load nvm if needed
   nvm use 20
   firebase deploy --only functions
   ```

   Or deploy a specific function:
   ```bash
   firebase deploy --only functions:sendPortInReminderNotifications
   ```

## Testing

### Local Testing (requires Firebase Emulator)
```bash
firebase emulators:start --only functions
```

### Manual Trigger (after deployment)
```bash
curl -X POST https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/manualPortInReminder
```

### View Logs
```bash
firebase functions:log
```

Or view logs for a specific function:
```bash
firebase functions:log --only sendPortInReminderNotifications
```

## Customization

### Change Schedule
Edit the cron expression in `index.js`:
- `'0 10 * * *'` = Daily at 10:00 AM UTC
- `'0 */6 * * *'` = Every 6 hours
- `'0 9 * * 1'` = Every Monday at 9:00 AM UTC

### Change Notification Message
Edit the `title` and `body` in the notification object in `index.js`.

### Adjust Notification Frequency
Modify the 24-hour check logic (currently prevents sending more than once per day).

## Firestore Structure

The function expects the following Firestore structure:

```
users/
  {userId}/
    - fcmTokens: [string]  // Array of FCM tokens
    - lastPortInReminderSent: Timestamp  // Last notification sent time
    orders/
      {orderId}/
        - status: "pending" | "draft" | "completed"
        - portInSkipped: boolean
        - billingCompleted: boolean
        - updatedAt: Timestamp
```

## Notes

- The function automatically cleans up invalid FCM tokens
- Notifications are sent to all devices registered for a user
- The function processes all users but only sends notifications to those matching the criteria
- For better performance with many users, consider adding a `hasFcmTokens` boolean field to users collection

