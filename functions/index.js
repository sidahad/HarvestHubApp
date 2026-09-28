const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const crypto = require('crypto');

initializeApp();

const PEPPER = 'harvesthub_otp_v1';

function emailKey(email) {
  return String(email || '').trim().toLowerCase();
}

function hashOtp(email, otp) {
  return crypto.createHash('sha256').update(`${emailKey(email)}|${otp}|${PEPPER}`).digest('hex');
}

function randomOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

exports.sendEmailOtp = onCall(async (request) => {
  const email = emailKey(request.data.email);
  const purpose = request.data.purpose || 'verifyEmail';
  if (!email.includes('@')) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }

  const otp = randomOtp();
  const db = getFirestore();
  await db.collection('email_otps').doc(email).set({
    hash: hashOtp(email, otp),
    purpose,
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000)),
    attempts: 0,
    consumed: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  await db.collection('mail').add({
    to: email,
    message: {
      subject: 'Your HarvestHub verification code',
      text: `Your HarvestHub OTP is ${otp}. It expires in 10 minutes.`,
      html: `<p>Your HarvestHub OTP is <strong>${otp}</strong>.</p><p>It expires in 10 minutes.</p>`,
    },
  });

  return {ok: true};
});

async function assertOtp(email, otp, purpose) {
  const db = getFirestore();
  const ref = db.collection('email_otps').doc(email);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'No OTP found. Please request a new code.');
  }
  const data = snap.data();
  if (data.consumed) {
    throw new HttpsError('failed-precondition', 'This OTP was already used.');
  }
  if (purpose && data.purpose && data.purpose !== purpose) {
    throw new HttpsError('failed-precondition', 'OTP does not match this action.');
  }
  const expiry = data.expiresAt && data.expiresAt.toDate ? data.expiresAt.toDate() : null;
  if (expiry && Date.now() > expiry.getTime()) {
    throw new HttpsError('deadline-exceeded', 'OTP expired. Request a new code.');
  }
  const attempts = data.attempts || 0;
  if (attempts >= 5) {
    throw new HttpsError('resource-exhausted', 'Too many attempts. Request a new OTP.');
  }
  if (data.hash !== hashOtp(email, otp)) {
    await ref.update({attempts: attempts + 1});
    throw new HttpsError('permission-denied', 'Incorrect OTP.');
  }
  return ref;
}

exports.verifyEmailOtp = onCall(async (request) => {
  const email = emailKey(request.data.email);
  const otp = String(request.data.otp || '').trim();
  const purpose = request.data.purpose || 'verifyEmail';
  const ref = await assertOtp(email, otp, purpose);
  await ref.update({
    consumed: purpose !== 'resetPassword',
    attempts: FieldValue.increment(1),
    verifiedAt: FieldValue.serverTimestamp(),
  });

  if (purpose === 'verifyEmail') {
    const users = await getFirestore().collection('users').where('email', '==', email).limit(1).get();
    if (!users.empty) {
      await users.docs[0].ref.set({emailVerified: true}, {merge: true});
    }
  }
  return {ok: true};
});

exports.resetPasswordWithOtp = onCall(async (request) => {
  const email = emailKey(request.data.email);
  const otp = String(request.data.otp || '').trim();
  const newPassword = String(request.data.newPassword || '');
  if (newPassword.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }
  const ref = await assertOtp(email, otp, 'resetPassword');
  try {
    const user = await getAuth().getUserByEmail(email);
    await getAuth().updateUser(user.uid, {password: newPassword, emailVerified: true});
    await getFirestore().collection('users').doc(user.uid).set({emailVerified: true}, {merge: true});
  } catch (e) {
    throw new HttpsError('not-found', 'No account found for this email.');
  }
  await ref.update({consumed: true, attempts: FieldValue.increment(1)});
  return {ok: true};
});

