// Trusted reward logic. The reward values live here, on the server, and are
// never read from the client request or from the challenge document.
import { HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";

export const CHALLENGE_ID = "today";
export const REWARD_POINTS = 10;
export const REWARD_BADGE = "first-quest";

/**
 * Awards the fixed reward exactly once for the verified caller.
 *
 * @param db   Admin Firestore instance (bypasses rules, so we validate here).
 * @param auth request.auth from the callable (verified by Firebase).
 * @param data request.data from the client. Only `challengeId` is read;
 *             any uid, points or badge the client sends is ignored.
 */
export async function completeChallenge(db, auth, data) {
  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  if (data?.challengeId !== CHALLENGE_ID) {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }

  const uid = auth.uid; // from the verified token, never from `data`
  const challengeRef = db.doc(`challenges/${CHALLENGE_ID}`);
  const progressRef = db.doc(`users/${uid}/progress/${CHALLENGE_ID}`);

  return db.runTransaction(async (transaction) => {
    const [challenge, progress] = await Promise.all([
      transaction.get(challengeRef),
      transaction.get(progressRef),
    ]);
    if (!challenge.exists) {
      throw new HttpsError("not-found", "Today's challenge is not available.");
    }
    if (progress.exists) {
      // Retry or double tap: return what is already stored, write nothing.
      const saved = progress.data();
      return {
        completed: true,
        points: saved.points,
        badgeId: saved.badgeId,
        alreadyCompleted: true,
      };
    }
    transaction.set(progressRef, {
      completed: true,
      points: REWARD_POINTS,
      badgeId: REWARD_BADGE,
      completedAt: FieldValue.serverTimestamp(),
    });
    return {
      completed: true,
      points: REWARD_POINTS,
      badgeId: REWARD_BADGE,
      alreadyCompleted: false,
    };
  });
}
