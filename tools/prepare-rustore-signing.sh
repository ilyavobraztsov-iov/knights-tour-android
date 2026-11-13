#!/usr/bin/env bash
# Produces the two files RuStore's "Подпись приложения" form asks for.
#
#   pepk_out.zip    the app signing key (alias sign_v1), encrypted so that
#                   only RuStore can open it
#   uploadcert.pem  the certificate of the upload key (alias upload)
#
# Before running this, open the app signing section in the RuStore console:
# it shows an encryption key token and a download link for pepk.jar. Both
# are per-app — the token from someone else's app will not work.
#
# Usage:
#   bash tools/prepare-rustore-signing.sh <keystore> <token> <pepk.jar>

set -euo pipefail

KS="${1:-}"
TOKEN="${2:-}"
PEPK="${3:-pepk.jar}"

usage() {
  echo "usage: bash tools/prepare-rustore-signing.sh <keystore> <encryption-token> <path/to/pepk.jar>" >&2
  exit 1
}

[ -n "$KS" ] && [ -n "$TOKEN" ] || usage
[ -f "$KS" ]   || { echo "keystore not found: $KS" >&2; exit 1; }
[ -f "$PEPK" ] || { echo "pepk.jar not found: $PEPK — download it from the RuStore console" >&2; exit 1; }
command -v keytool >/dev/null || { echo "keytool not found: install a JDK" >&2; exit 1; }
command -v java    >/dev/null || { echo "java not found: install a JDK" >&2; exit 1; }

for f in pepk_out.zip uploadcert.pem; do
  [ -e "$f" ] && { echo "refusing to overwrite the existing $f" >&2; exit 1; }
done

# Check both aliases are really there before asking for a password.
for a in sign_v1 upload; do
  keytool -list -keystore "$KS" -alias "$a" -storepass:env KSPW >/dev/null 2>&1 || true
done

read -r -s -p "Keystore password: " KSPW; echo
export KSPW

keytool -list -keystore "$KS" -storepass:env KSPW >/dev/null \
  || { echo "wrong password, or $KS is not a keystore" >&2; exit 1; }

for a in sign_v1 upload; do
  keytool -list -keystore "$KS" -alias "$a" -storepass:env KSPW >/dev/null 2>&1 \
    || { echo "alias '$a' is missing from $KS — was it made by tools/make-keystore.sh?" >&2; exit 1; }
done

echo
echo "1/2  encrypting the app signing key (sign_v1) for RuStore..."
java -jar "$PEPK" \
  --keystore "$KS" \
  --alias sign_v1 \
  --output pepk_out.zip \
  --encryptionkey="$TOKEN" \
  --include-cert

echo
echo "2/2  exporting the upload key certificate (upload)..."
keytool -exportcert \
  -keystore "$KS" \
  -alias upload \
  -storepass:env KSPW \
  -rfc -file uploadcert.pem

unset KSPW

echo
echo "Done:"
ls -lh pepk_out.zip uploadcert.pem
echo
echo "Upload pepk_out.zip   where the console asks for the app signing key."
echo "Upload uploadcert.pem where it asks for the upload key certificate."
echo "AAB upload unlocks once RuStore has checked them."
