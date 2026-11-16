#!/usr/bin/env bash
# Starts the Auth, Firestore and Functions emulators for the local
# "demo-cloud-quest" project and seeds challenges/today. Leave it running.
# Emulator UI: http://127.0.0.1:4000
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/env.sh
need firebase "Run: npm install -g firebase-tools"
need java "The Firestore emulator needs Java. Install a JDK (brew install openjdk@21)."

[ -d functions/node_modules ] || (cd functions && npm install)

firebase emulators:start --only auth,firestore,functions --project demo-cloud-quest &
EMULATORS=$!
trap 'kill $EMULATORS 2>/dev/null || true' EXIT INT TERM

echo "Waiting for the Firestore emulator on port 8080..."
for _ in $(seq 1 90); do
  if curl -s -o /dev/null http://127.0.0.1:8080; then break; fi
  if ! kill -0 $EMULATORS 2>/dev/null; then echo "Emulators failed to start."; exit 1; fi
  sleep 1
done

(cd functions && npm run seed)
echo "Ready. Run the app with: flutter run"
wait $EMULATORS
