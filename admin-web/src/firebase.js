import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: 'AIzaSyABj4yVGvG1bp5vo8H6h1CE2ze8F6dTpP4',
  authDomain: 'mazonn-ecommerce-and-pos.firebaseapp.com',
  projectId: 'mazonn-ecommerce-and-pos',
  storageBucket: 'mazonn-ecommerce-and-pos.firebasestorage.app',
  messagingSenderId: '1034972929409',
  appId: '1:1034972929409:web:3e9207384039c3f7fa1c80',
  measurementId: 'G-8T9YLJQ03H',
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
