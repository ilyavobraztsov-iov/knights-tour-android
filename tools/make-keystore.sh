#!/usr/bin/env bash
# Creates the TWO keys RuStore's app signing needs.
#
# RuStore works like Google Play: it signs the APKs that reach users itself,
# with a key you hand over once, and you sign the .aab you upload with a
# separate key it only ever sees the certificate of.
#
#   sign_v1  — the app signing key. Goes to RuStore, encrypted, via the
#              PEPK tool (tools/prepare-rustore-signing.sh). Never used by
#              the build, never leaves this keystore in the clear.
#   upload   — the upload key. Signs every .aab the build produces. Its
#              certificate goes to RuStore; the key itself stays yours.
#
# Keep release.keystore and the password. Losing the upload key is
# recoverable through RuStore support; losing both before RuStore holds the
# app signing key is not.

set -euo pipefail

OUT="${1:-release.keystore}"

if [ -e "$OUT" ]; then
  echo "refusing to overwrite the existing $OUT" >&2
  exit 1
fi

read -r -s -p "Password for the new keystore (remember it): " PW; echo
read -r -s -p "Repeat the password: " PW2; echo
[ "$PW" = "$PW2" ] || { echo "passwords differ" >&2; exit 1; }
[ "${#PW}" -ge 6 ] || { echo "keytool requires at least 6 characters" >&2; exit 1; }

DN="CN=Knights Tour, OU=Game, O=Knights Tour, L=Moscow, C=RU"

# the app signing key — handed to RuStore, long validity on purpose
keytool -genkeypair -v \
  -keystore "$OUT" -alias sign_v1 \
  -keyalg RSA -keysize 2048 -validity 36500 \
  -storepass "$PW" -keypass "$PW" -dname "$DN"

# the upload key — signs the .aab the build produces
keytool -genkeypair -v \
  -keystore "$OUT" -alias upload \
  -keyalg RSA -keysize 2048 -validity 36500 \
  -storepass "$PW" -keypass "$PW" -dname "$DN"

echo
echo "Created $OUT with two keys:"
keytool -list -keystore "$OUT" -storepass "$PW" | grep -E 'sign_v1|upload' || true

echo
echo "=============================================================="
echo "1. GitHub repository secrets"
echo "   (Settings -> Secrets and variables -> Actions)"
echo "=============================================================="
echo
echo "  KEY_ALIAS          = upload"
echo "  KEYSTORE_PASSWORD  = the password you just typed"
echo "  KEY_PASSWORD       = the same password"
echo "  KEYSTORE_BASE64    = the line below"
echo
echo "----- KEYSTORE_BASE64 -----"
base64 -w0 "$OUT" 2>/dev/null || base64 "$OUT" | tr -d '\n'
echo
echo "---------------------------"
echo
echo "=============================================================="
echo "2. Files for RuStore's signing form"
echo "=============================================================="
echo
echo "  Open the app signing section in the RuStore console, copy the"
echo "  encryption key token it shows, download its pepk.jar, then run:"
echo
echo "      bash tools/prepare-rustore-signing.sh $OUT <token> <path/to/pepk.jar>"
echo
echo "  It produces pepk_out.zip and uploadcert.pem for the two upload fields."
echo
echo "Back up $OUT somewhere safe before you go on."
