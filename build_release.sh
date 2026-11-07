#!/usr/bin/env bash
# build_release.sh  —  FitGenie release bundle (.aab) banata hai
#
# Chalane ka tareeqa (project root se):
#   chmod +x build_release.sh
#   ./build_release.sh            # version jaisa hai waisa hi, .aab banao
#   ./build_release.sh --bump     # build number +1 (2.0.2+20 -> 2.0.2+21), phir .aab banao
#   ./build_release.sh --apk      # saath mein .apk bhi banao (phone par test ke liye)
#   ./build_release.sh --skip-checks   # analyze chhod do (sirf zaroorat par)
#
# Ye script key.properties / .jks / .env ka content kabhi nahi padhta, sirf check karta hai ke file maujood hai.
# Output: ~/fitgenie_releases/<version>/  (aab + sha256)

set -euo pipefail

BUMP=0; WANT_APK=0; SKIP_CHECKS=0
for a in "$@"; do
  case "$a" in
    --bump) BUMP=1 ;;
    --apk) WANT_APK=1 ;;
    --skip-checks) SKIP_CHECKS=1 ;;
    -h|--help) sed -n 2,13p "$0"; exit 0 ;;
    *) echo "❌ Nahi samjha: $a"; exit 1 ;;
  esac
done

fail() { echo "❌ $*"; exit 1; }
ok()   { echo "✅ $*"; }

[ -f pubspec.yaml ] || fail "Project root se chalao (pubspec.yaml nahi mili)."
command -v flutter >/dev/null || fail "flutter PATH me nahi hai."

# 1) git saaf hona chahiye, taake build kisi commit se ban kar wapas mil sake
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  git status --short
  fail "Uncommitted changes hain. Pehle commit karo (ya stash), phir build karo."
fi
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT=$(git rev-parse --short HEAD)
ok "Branch: $BRANCH  |  commit: $COMMIT"

# 2) signing files maujood hain? (content nahi padhte)
[ -f android/key.properties ] || fail "android/key.properties nahi mili: release signing ke baghair Play Store reject karega."
ok "key.properties maujood hai"

# 3) version
CUR=$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')
NAME=${CUR%%+*}; NUM=${CUR##*+}
if [ "$BUMP" = 1 ]; then
  NEW="$NAME+$((NUM + 1))"
  sed -i.bak -E "s/^version: .*/version: $NEW/" pubspec.yaml && rm -f pubspec.yaml.bak
  ok "Version: $CUR -> $NEW"
  CUR=$NEW; NUM=$((NUM + 1))
else
  ok "Version: $CUR (badla nahi; Play Store ko naya build number chahiye to --bump lagao)"
fi

# 4) dependencies + analyze
flutter pub get >/dev/null
ok "pub get"
if [ "$SKIP_CHECKS" = 0 ]; then
  echo "🔎 dart analyze (sirf errors par ruk'ta hai)..."
  flutter analyze --no-fatal-infos --no-fatal-warnings || fail "analyze me error hain: pehle fix karo."
  ok "analyze: koi error nahi"
fi

# 5) build
echo "🏗️  flutter build appbundle --release ..."
flutter build appbundle --release
AAB=build/app/outputs/bundle/release/app-release.aab
[ -f "$AAB" ] || fail "AAB nahi bana ($AAB)."

APK=""
if [ "$WANT_APK" = 1 ]; then
  echo "🏗️  flutter build apk --release ..."
  flutter build apk --release
  APK=build/app/outputs/flutter-apk/app-release.apk
fi

# 6) output copy + checksum
OUT="$HOME/fitgenie_releases/$CUR"
mkdir -p "$OUT"
cp "$AAB" "$OUT/fitgenie-$CUR.aab"
[ -n "$APK" ] && [ -f "$APK" ] && cp "$APK" "$OUT/fitgenie-$CUR.apk"
( cd "$OUT" && sha256sum fitgenie-* > SHA256SUMS.txt )

echo
ok "Release tayar ho gaya"
echo "   📦 $OUT/fitgenie-$CUR.aab  ($(du -h "$OUT/fitgenie-$CUR.aab" | cut -f1))"
[ -n "$APK" ] && echo "   📱 $OUT/fitgenie-$CUR.apk"
echo "   🔖 branch $BRANCH @ $COMMIT, version $CUR"
echo
if [ "$BUMP" = 1 ]; then
  echo "👉 Version bump commit karna na bhoolo:"
  echo "   git add pubspec.yaml && git commit -m \"Release $CUR\" && git tag v$CUR && git push && git push --tags"
fi
echo "👉 Play Console > Production (ya Internal testing) > Create release > ye .aab upload karo."
