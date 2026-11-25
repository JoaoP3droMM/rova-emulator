#!/usr/bin/env bash
# Empacota o Ryubing oficial para o Rova: baixa, confere o hash de versions.json e monta
#   rova-emulator-switch-linux-x64.tar.gz   (pasta rova-switch/, executável Ryujinx)
#   rova-emulator-switch-windows-x64.zip    (pasta rova-switch/, executável Ryujinx.exe)
# Uso: switch/package.sh [versão] [pasta de saída]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
version="${1:-$(jq -r .current "$here/versions.json")}"
out="${2:-$PWD/out}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$out"
# Caminho completo: o zip roda de dentro de outra pasta.
out="$(cd "$out" && pwd)"

fetch() {
  local asset="$1"
  local expected url file
  expected="$(jq -r --arg v "$version" --arg a "$asset" '.versions[$v][$a] // empty' "$here/versions.json")"
  [ -n "$expected" ] || { echo "versions.json não tem o hash de $version/$asset" >&2; exit 1; }
  url="$(jq -r .source "$here/versions.json" | sed "s/{version}/$version/g; s/{asset}/$asset/g")"
  file="$work/$asset"
  curl -fsSL --retry 3 -o "$file" "$url"
  echo "$expected  $file" | sha256sum -c - >&2
  echo "$file"
}

notice() {
  cat > "$1/ROVA-EMULATOR.txt" <<NOTE
Ryubing $version (continuação do Ryujinx), empacotado pelo Rova-Emulator para o Rova Games.
Original: https://git.ryujinx.app/projects/Ryubing/releases/tag/$version
Licença do emulador: LICENSE.txt (MIT) e THIRDPARTY.md.
Não inclui jogos, chaves nem firmware.
NOTE
}

# Linux
linux="$(fetch linux_x64.tar.gz)"
mkdir -p "$work/linux" && tar -xzf "$linux" -C "$work/linux"
mv "$work/linux/publish" "$work/linux/rova-switch"
test -x "$work/linux/rova-switch/Ryujinx"
notice "$work/linux/rova-switch"
tar -czf "$out/rova-emulator-switch-linux-x64.tar.gz" -C "$work/linux" rova-switch

# Windows
win="$(fetch win_x64.zip)"
mkdir -p "$work/win" && (cd "$work/win" && unzip -q "$win")
mv "$work/win/publish" "$work/win/rova-switch"
test -f "$work/win/rova-switch/Ryujinx.exe"
notice "$work/win/rova-switch"
(cd "$work/win" && zip -qr "$out/rova-emulator-switch-windows-x64.zip" rova-switch)

echo "$version" > "$out/version.txt"
ls -la "$out"
