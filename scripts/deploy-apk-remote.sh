#!/bin/bash
set -euo pipefail

VERSION="${1:?Uso: deploy-apk-remote.sh <version>}"
DOWNLOADS_DIR="${DEPLOY_DOWNLOADS_DIR:-/opt/dipalza-app/downloads}"
APK_PATH="$DOWNLOADS_DIR/releases/$VERSION/dipalza.apk"

if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: no existe $APK_PATH — ¿se copió el apk antes de llamar a este script?" >&2
  exit 1
fi

ln -sfn "$APK_PATH" "$DOWNLOADS_DIR/dipalza.apk"
echo "Symlink actualizado: $DOWNLOADS_DIR/dipalza.apk -> $APK_PATH"

(cd "$DOWNLOADS_DIR" && sha256sum dipalza.apk > dipalza.apk.sha256)
echo "Checksum generado: $DOWNLOADS_DIR/dipalza.apk.sha256"
