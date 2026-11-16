// Cloud Quest backend: two callables.
//   completeToday  - the only code that writes points and the badge
//   askQuestCoach  - AI coach with one read-only tool (see questCoach.js)
import { onCall } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { completeChallenge } from "./reward.js";

initializeApp();
const db = getFirestore();
const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

export const completeToday = onCall((request) =>
  completeChallenge(db, request.auth, request.data),
);

// Genkit is loaded on first use, so the reward function and the emulator's
// function discovery stay fast.
let coach;
async function getCoach() {
  if (coach) return coach;
  const { createQuestCoach } = await import("./questCoach.js");
  // In the emulator (or with no key) the built-in mock model is used, so no
  // account, key or paid call is needed. For a deployed backend, set
  // GEMINI_API_KEY as a function secret/env var and add @genkit-ai/google-genai.
  if (!isEmulator && process.env.GEMINI_API_KEY) {
    const { googleAI } = await import("@genkit-ai/google-genai");
    coach = createQuestCoach({
      db,
      plugins: [googleAI()],
      model: process.env.COACH_MODEL ?? "googleai/gemini-2.5-flash",
    });
  } else {
    coach = createQuestCoach({ db, isEmulator });
  }
  return coach;
}

export const askQuestCoach = onCall(async (request) => {
  const ask = await getCoach();
  return ask(request.auth, request.data);
});
