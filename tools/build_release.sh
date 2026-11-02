#!/usr/bin/env bash
# Builds the signed release APKs for the version in project.godot.
# Used by .github/workflows/release.yml and runnable locally:
#   GODOT=godot_console \
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH=... \
#   GODOT_ANDROID_KEYSTORE_RELEASE_USER=... \
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=... \
#   tools/build_release.sh
#
# Outputs (in release-assets/):
#   aftermind-arm64-v8a-vX.Y.Z.apk   most modern phones
#   aftermind-universal-vX.Y.Z.apk   any device (all ABIs; largest)
set -euo pipefail

GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

VERSION="$(sed -nE 's/^config\/version="([0-9]+\.[0-9]+\.[0-9]+)"$/\1/p' project.godot)"
if [[ -z "$VERSION" ]]; then
	echo "Could not read config/version (X.Y.Z) from project.godot" >&2
	exit 1
fi
IFS=. read -r MAJOR MINOR PATCH <<<"$VERSION"
# Monotonic Android versionCode: 1.2.3 -> 10203.
CODE=$((MAJOR * 10000 + MINOR * 100 + PATCH))

for var in GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD; do
	if [[ -z "${!var:-}" ]]; then
		echo "Missing $var (release signing)" >&2
		exit 1
	fi
done

echo "Building AFTERMIND v$VERSION (versionCode $CODE)"

# Stamp the version into the presets for this build only.
cp export_presets.cfg export_presets.cfg.bak
trap 'mv -f export_presets.cfg.bak export_presets.cfg' EXIT
sed -i -E "s/^version\/code=.*/version\/code=$CODE/; s/^version\/name=.*/version\/name=\"$VERSION\"/" export_presets.cfg

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/smoke_test.gd

rm -rf release-assets
mkdir -p release-assets
"$GODOT" --headless --path . --export-release "Android arm64-v8a" "release-assets/aftermind-arm64-v8a-v$VERSION.apk"
"$GODOT" --headless --path . --export-release "Android Universal" "release-assets/aftermind-universal-v$VERSION.apk"
rm -f release-assets/*.idsig

for apk in "release-assets/aftermind-arm64-v8a-v$VERSION.apk" "release-assets/aftermind-universal-v$VERSION.apk"; do
	if [[ ! -s "$apk" ]]; then
		echo "Export failed: $apk missing" >&2
		exit 1
	fi
done
ls -l release-assets
