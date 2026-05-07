// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyD9I6_RGsJDUue65XdIKH2bEUQz8rNwbT4",
  authDomain: "wateny.firebaseapp.com",
  projectId: "wateny",
  storageBucket: "wateny.firebasestorage.app",
  messagingSenderId: "896592650203",
  appId: "1:896592650203:web:5815f58fd95038347491fe",
  measurementId: "G-CQLH65GRM1"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
