const { getAuth, getFirestore, admin } = require('../config/firebase');

exports.register = async (req, res) => {
  try {
    const { email, password, name = '', gender = null } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const auth = getAuth();
    const db = getFirestore();

    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name,
    });

    await db.collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: userRecord.email,
      name,
      gender,
      provider: 'password',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      role: 'member',
    });

    res.status(201).json({
      message: 'User registered successfully',
      uid: userRecord.uid,
      email: userRecord.email,
      name,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.verifyGoogleToken = async (req, res) => {
  try {
    const { idToken, name = '', gender = null } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'Google ID token is required' });
    }

    const auth = getAuth();
    const db = getFirestore();
    const decodedToken = await auth.verifyIdToken(idToken);
    const { uid, email, picture } = decodedToken;

    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    const payload = {
      uid,
      email: email || null,
      name: name || decodedToken.name || '',
      gender,
      profilePic: picture || null,
      provider: 'google',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!userDoc.exists) {
      payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
      payload.role = 'member';
    }

    await userRef.set(payload, { merge: true });

    res.status(200).json({
      message: 'Google token verified',
      uid,
      email,
      name: payload.name,
    });
  } catch (error) {
    res.status(401).json({ error: 'Invalid Google token', details: error.message });
  }
};
