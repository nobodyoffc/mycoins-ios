#!/bin/sh
# Check that the C Argon2 the iOS app runs (ios/MyCoins/Argon2) and the
# JavaScript one Android runs (src/crypto/vendor/noble-argon2.js) derive the
# same key from a phrase, at the production cost and with the empty salt.
# A difference here would mean a phrase opens a different wallet on iOS.
#
#   tools/check-argon2.sh ["a phrase"]
set -eu
cd "$(dirname "$0")/.."
PHRASE="${1:-correct horse battery staple 天地玄黄}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
A=ios/MyCoins/Argon2
cat > "$TMP/main.c" <<'C'
#include <stdio.h>
#include <string.h>
#include "argon2.h"
int main(int argc, char **argv) {
  unsigned char out[32];
  int rc = argon2id_hash_raw(3, 65536, 1, argv[1], strlen(argv[1]), "", 0, out, sizeof out);
  if (rc != ARGON2_OK) { fprintf(stderr, "%s\n", argon2_error_message(rc)); return 1; }
  for (int i = 0; i < 32; i++) printf("%02x", out[i]);
  printf("\n");
  return 0;
}
C
cc -O2 -I "$A" -I "$A/include" "$TMP/main.c" "$A/argon2.c" "$A/core.c" "$A/encoding.c" \
   "$A/ref.c" "$A/thread.c" "$A/blake2/blake2b.c" -o "$TMP/argon2"
C_KEY="$("$TMP/argon2" "$PHRASE")"
cat > "$TMP/main.mjs" <<JS
import {argon2id} from '$(pwd)/src/crypto/vendor/noble-argon2.js';
const key = argon2id(new TextEncoder().encode(process.argv[2]), new Uint8Array(0), {t: 3, m: 65536, p: 1, dkLen: 32});
console.log(Buffer.from(key).toString('hex'));
JS
JS_KEY="$(NODE_NO_WARNINGS=1 node "$TMP/main.mjs" "$PHRASE")"
echo "C : $C_KEY"
echo "JS: $JS_KEY"
[ "$C_KEY" = "$JS_KEY" ] && echo "same key" || { echo "DIFFERENT KEYS"; exit 1; }
