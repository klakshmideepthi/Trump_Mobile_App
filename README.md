# Link up
flutter clean

flutter pub get 

pod install

flutter build apk --release

nvm use 20 && ./deploy-functions.sh

curl -X POST https://us-central1-linkmobile-494b0.cloudfunctions.net/manualPortInReminder

firebase functions:log --only manualPortInReminder