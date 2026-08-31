import { createContext, useContext, useEffect, useRef, useState } from 'react';
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
} from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { auth, db } from './firebase.js';

const DEMO_ADMIN_EMAIL = 'admin@mazonn.app';
const DEMO_ADMIN_PASSWORD = 'admin123';

const AuthContext = createContext(null);

function isDemoAdmin(email, password) {
  return email.trim().toLowerCase() === DEMO_ADMIN_EMAIL && password === DEMO_ADMIN_PASSWORD;
}

async function ensureAdminProfile(uid) {
  const profile = {
    id: uid,
    fullName: 'Maya Chen',
    email: DEMO_ADMIN_EMAIL,
    phone: '+1 415 555 0100',
    avatarLabel: 'MA',
    city: 'San Francisco',
    role: 'admin',
  };
  await setDoc(doc(db, 'users', uid), profile, { merge: true });
  return profile;
}

async function readAdminProfile(uid) {
  const snap = await getDoc(doc(db, 'users', uid));
  return snap.exists() ? { id: uid, ...snap.data() } : null;
}

async function signInOrCreateDemo(email, password) {
  try {
    return (await signInWithEmailAndPassword(auth, email.trim(), password)).user;
  } catch (error) {
    const retryable = error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential' || error.code === 'auth/wrong-password';
    if (!retryable || !isDemoAdmin(email, password)) throw error;
  }
  try {
    const created = await createUserWithEmailAndPassword(auth, DEMO_ADMIN_EMAIL, DEMO_ADMIN_PASSWORD);
    await updateProfile(created.user, { displayName: 'Maya Chen' });
    return created.user;
  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
      throw new Error(
        'admin@mazonn.app already exists in Firebase with a different password. In Firebase Console → Authentication, set that user’s password to admin123, then try again.',
      );
    }
    throw error;
  }
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const bootstrapping = useRef(false);

  useEffect(() => {
    return onAuthStateChanged(auth, async (firebaseUser) => {
      if (bootstrapping.current) return;
      setError('');
      if (!firebaseUser) {
        setUser(null);
        setProfile(null);
        setLoading(false);
        return;
      }
      try {
        const data = await readAdminProfile(firebaseUser.uid);
        if (data?.role !== 'admin') {
          await signOut(auth);
          setUser(null);
          setProfile(null);
          setError('This account is not a Super Admin.');
          setLoading(false);
          return;
        }
        setUser(firebaseUser);
        setProfile(data);
      } catch (e) {
        setError(e.message || 'Unable to verify Super Admin access.');
        await signOut(auth);
        setUser(null);
        setProfile(null);
      } finally {
        setLoading(false);
      }
    });
  }, []);

  const login = async (email, password) => {
    setError('');
    bootstrapping.current = true;
    try {
      const firebaseUser = await signInOrCreateDemo(email, password);
      let data = await readAdminProfile(firebaseUser.uid);
      if (isDemoAdmin(email, password) && data?.role !== 'admin') {
        data = await ensureAdminProfile(firebaseUser.uid);
      }
      if (data?.role !== 'admin') {
        await signOut(auth);
        throw new Error('This account is not a Super Admin.');
      }
      setUser(firebaseUser);
      setProfile(data);
      setLoading(false);
    } finally {
      bootstrapping.current = false;
    }
  };

  const logout = () => signOut(auth);

  return (
    <AuthContext.Provider value={{ user, profile, loading, error, setError, login, logout, isAdmin: profile?.role === 'admin' }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error('useAuth must be used within AuthProvider');
  return value;
}
