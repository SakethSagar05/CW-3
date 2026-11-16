// Seeds the one shared challenge into the Firestore EMULATOR.
//   cd functions && npm run seed      (emulators must be running)
// It refuses to run against a real project unless you pass --production.
import { pathToFileURL } from "node:url";
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

export const TODAY_CHALLENGE = {
  title: "Spot the Trusted Writer",
  prompt:
    "Which part of Cloud Quest is allowed to write your points and badge? " +
    "Explain in one sentence why the app on your phone is not allowed to do it itself, " +
    "then tap Complete challenge.",
};

export async function seedChallenge(db) {
  await db.doc("challenges/today").set(TODAY_CHALLENGE);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const production = process.argv.includes("--production");
  if (!production) {
    process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
    process.env.GCLOUD_PROJECT ??= "demo-cloud-quest";
  }
  if (!getApps().length) initializeApp({ projectId: process.env.GCLOUD_PROJECT });
  await seedChallenge(getFirestore());
  console.log(
    `Seeded challenges/today in ${production ? "the configured project" : "the emulator (" + process.env.FIRESTORE_EMULATOR_HOST + ")"}.`,
  );
}
