const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {initializeApp} = require("firebase-admin/app");

initializeApp();

// This function triggers whenever a new document is added to 'device_tokens'
exports.sendWelcomeNotification = onDocumentCreated("device_tokens/{tokenId}",
    async (event) => {
      const newValue = event.data.data();
      const token = newValue.token;

      const message = {
        notification: {
          title: "Welcome to Fertilityshare!",
          body: "Thank you for joining our community. We are glad to have you here!",
        },
        token: token,
      };

      try {
        const response = await getMessaging().send(message);
        console.log("Successfully sent message:", response);
      } catch (error) {
        console.log("Error sending message:", error);
      }
    });
