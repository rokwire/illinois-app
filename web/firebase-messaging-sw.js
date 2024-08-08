// Please see this file for the latest firebase-js-sdk version:
// https://github.com/firebase/flutterfire/blob/master/packages/firebase_core/firebase_core_web/lib/src/firebase_sdk_version.dart
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyA2jtU96o8YBeTCOnseW_CX3uocozE8UVU",
    authDomain: "neom-u.firebaseapp.com",
    projectId: "neom-u",
    storageBucket: "neom-u.appspot.com",
    messagingSenderId: "776164375754",
    appId: "1:776164375754:web:b37caf68c1255ba6b04833"
});

const messaging = firebase.messaging();

// Optional:
//messaging.onBackgroundMessage((message) => {
//  console.log("onBackgroundMessage", message);
//});