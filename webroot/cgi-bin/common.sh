#!/system/bin/sh
urldecode() {
  # stdin -> stdout
  sed 's/+/ /g;s/%/\\x/g' | xargs -0 printf '%b' 2>/dev/null || \
  python3 -c 'import sys,urllib.parse; print(urllib.parse.unquote_plus(sys.stdin.read()), end="")' 2>/dev/null
}

# Busybox-friendly decode of one value
udecode_val() {
  printf '%s' "$1" | sed 's/+/ /g' | sed -e 's/%0[Aa]/\n/g' | \
    sed 's/%20/ /g; s/%21/!/g; s/%22/"/g; s/%23/#/g; s/%24/$/g; s/%25/%/g; s/%26/\&/g; s/%27/'"'"'/g; s/%28/(/g; s/%29/)/g; s/%2[Bb]/+/g; s/%2[Cc]/,/g; s/%2[Ff]/\//g; s/%3[Aa]/:/g; s/%3[Bd]/;/g; s/%3[Cd]/</g; s/%3[Dd]/=/g; s/%3[Ee]/>/g; s/%3[Ff]/?/g; s/%40/@/g; s/%5[Bb]/[/g; s/%5[Cd]/\\/g; s/%5[Dd]/]/g; s/%7[Bb]/{/g; s/%7[Cd]/|/g; s/%7[Dd]/}/g'
}
