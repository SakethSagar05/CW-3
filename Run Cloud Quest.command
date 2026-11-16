#!/bin/bash
# Double-click this file in Finder. It does everything that has to happen on
# this Mac, in order:
#   1. one-time setup (android/ folder, packages, functions dependencies)
#   2. runs all automated tests and saves their output to docs/evidence/
#   3. starts the Firebase emulators and seeds today's challenge
#   4. boots an Android emulator if none is running, then runs the app
# Close this window (or press q, then Ctrl+C) to stop everything.
cd "$(dirname "$0")" || exit 1
source tools/env.sh
set -uo pipefail
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m%s\033[0m\n' "$*"; read -r -p "Press Return to close." _; exit 1; }
mkdir -p docs/evidence

step "1/4 Setup"
bash tools/setup.sh || fail "Setup failed. Copy the lines above and send them to Claude."

step "2/4 Automated tests (output saved in docs/evidence/)"
if grep -q "pass 7" docs/evidence/emulator_test_output.txt 2>/dev/null; then
  echo "Tests already passed earlier (results kept in docs/evidence/). Skipping."
else
  { flutter --version; firebase --version; node --version; } > docs/evidence/env.txt 2>&1
  flutter analyze 2>&1 | tee docs/evidence/flutter_analyze_output.txt
  flutter test 2>&1 | tee docs/evidence/flutter_test_output.txt
  (cd functions && npm test 2>&1) | tee docs/evidence/logic_test_output.txt
  (cd functions && npm run test:emulator 2>&1) | tee docs/evidence/emulator_test_output.txt
  echo "Test output saved. Problems above do not stop the app from starting."
fi

step "3/4 Firebase emulators"
bash tools/start_emulators.sh > docs/evidence/emulators.log 2>&1 &
EMULATORS=$!
trap 'kill $EMULATORS 2>/dev/null; pkill -f "firebase emulators:start" 2>/dev/null' EXIT
for _ in $(seq 1 120); do
  grep -q "^Ready\." docs/evidence/emulators.log 2>/dev/null && break
  kill -0 $EMULATORS 2>/dev/null || { cat docs/evidence/emulators.log; fail "The emulators stopped. See the log above."; }
  sleep 1
done
grep -q "^Ready\." docs/evidence/emulators.log || fail "The emulators did not become ready in 2 minutes. See docs/evidence/emulators.log."
echo "Emulators are up. Emulator UI: http://127.0.0.1:4000"

step "4/4 Android emulator and app"
if ! adb devices 2>/dev/null | grep -qw device; then
  AVD="$(flutter emulators 2>/dev/null | awk -F ' • ' 'NF>=4 && $1 != "Id" {print $1; exit}')"
  [ -n "$AVD" ] || fail "No Android emulator found. Create one in Android Studio (Device Manager), then run this again."
  echo "Starting Android emulator: $AVD"
  flutter emulators --launch "$AVD"
  adb wait-for-device
  until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
fi
flutter run || fail "flutter run failed. Copy the error above and send it to Claude."
