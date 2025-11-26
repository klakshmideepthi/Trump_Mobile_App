#!/bin/bash

# Script to deploy Firebase Functions
# Make sure you're on the Blaze plan before running this

echo "🔍 Checking Node.js version..."

# Source nvm if it exists
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  source "$HOME/.nvm/nvm.sh"
elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
  source "/usr/local/opt/nvm/nvm.sh"
fi

# Ensure Node 20 is used
nvm use 20 2>/dev/null || {
  echo "⚠️  nvm use 20 failed, trying to install/use Node 20..."
  nvm install 20
  nvm use 20
}

NODE_VERSION=$(node --version)
echo "✅ Using Node.js $NODE_VERSION"

if [[ ! "$NODE_VERSION" =~ ^v(20|22|24) ]]; then
  echo "❌ Error: Node.js version must be 20, 22, or 24"
  echo "   Current version: $NODE_VERSION"
  echo "   Run: nvm install 20 && nvm use 20"
  exit 1
fi

# Verify Firebase CLI compatibility
FIREBASE_VERSION=$(firebase --version 2>/dev/null || echo "unknown")
echo "📦 Firebase CLI version: $FIREBASE_VERSION"

echo ""
echo "🚀 Deploying Firebase Functions..."
echo ""

cd "$(dirname "$0")"
firebase deploy --only functions

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Functions deployed successfully!"
  echo ""
  echo "📋 Function details:"
  echo "   - sendPortInReminderNotifications: Runs daily at 10:00 AM UTC"
  echo "   - manualPortInReminder: HTTP endpoint for manual testing"
  echo ""
  echo "📊 View logs: firebase functions:log"
else
  echo ""
  echo "❌ Deployment failed. Common issues:"
  echo "   1. Project not on Blaze plan - upgrade at:"
  echo "      https://console.firebase.google.com/project/linkmobile-494b0/usage/details"
  echo "   2. Missing permissions - check IAM settings"
  echo "   3. API not enabled - wait a few minutes and try again"
fi

