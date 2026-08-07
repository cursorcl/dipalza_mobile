#!/bin/bash
set -euo pipefail

VERSION="${1:?Uso: deploy-apk-remote.sh <version>}"
DOWNLOADS_DIR="${DEPLOY_DOWNLOADS_DIR:-/opt/dipalza-app/downloads}"
APK_PATH="$DOWNLOADS_DIR/releases/$VERSION/dipalza-app.apk"

if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: no existe $APK_PATH — ¿se copió el apk antes de llamar a este script?" >&2
  exit 1
fi

ln -sfn "$APK_PATH" "$DOWNLOADS_DIR/dipalza-app.apk"
echo "Symlink actualizado: $DOWNLOADS_DIR/dipalza-app.apk -> $APK_PATH"

(cd "$DOWNLOADS_DIR" && sha256sum dipalza-app.apk > dipalza-app.apk.sha256)
echo "Checksum generado: $DOWNLOADS_DIR/dipalza-app.apk.sha256"

VERSION_SIN_V="${VERSION#v}"
SHA256_HASH=$(cut -d' ' -f1 "$DOWNLOADS_DIR/dipalza-app.apk.sha256")
printf '{"version": "%s", "sha256": "%s"}\n' "$VERSION_SIN_V" "$SHA256_HASH" \
  > "$DOWNLOADS_DIR/version.json"
echo "version.json generado: $DOWNLOADS_DIR/version.json"
