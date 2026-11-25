#!/usr/bin/env bash
# Empacota o RetroArch oficial (buildbot da libretro) para o Rova: baixa, confere o hash de versions.json e
# monta só o que o Rova usa (sem banco de dados, shaders e overlays, que o Rova não usa):
#   rova-emulator-retroarch-linux-x64.tar.gz  rova-retroarch/app/AppRun (AppImage já extraído: sem FUSE)
#   rova-emulator-retroarch-windows-x64.zip   rova-retroarch/retroarch.exe
# e, nos dois, rova-retroarch/recursos/{assets,autoconfig,filters,info}. Os núcleos o Rova baixa um a um.
# Uso: retroarch/package.sh [versão] [pasta de saída]. Precisa de jq, curl, 7z, zip.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
version="${1:-$(jq -r .current "$here/versions.json")}"
out="${2:-$PWD/out}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# Menus que ficam (ozone é o padrão do Rova, rgui o de reserva) e as fontes/sons deles.
keep_assets="ozone pkg rgui sounds"

fetch() {
  local asset="$1" expected url file
  expected="$(jq -r --arg v "$version" --arg a "$asset" '.versions[$v][$a] // empty' "$here/versions.json")"
  [ -n "$expected" ] || { echo "versions.json não tem o hash de $version/$asset" >&2; exit 1; }
  url="$(jq -r .source "$here/versions.json" | sed "s|{version}|$version|g; s|{asset}|$asset|g")"
  file="$work/$(echo "$asset" | tr '/' '_')"
  curl -fsSL --retry 3 -o "$file" "$url"
  echo "$expected  $file" | sha256sum -c - >&2
  echo "$file"
}

recursos() { # $1 = pasta de origem com assets/autoconfig/filters e a pasta de info; $2 = nome da pasta de info; $3 = destino
  mkdir -p "$3/recursos/assets"
  for a in $keep_assets; do [ -d "$1/assets/$a" ] && cp -r "$1/assets/$a" "$3/recursos/assets/"; done
  cp -r "$1/autoconfig" "$1/filters" "$3/recursos/"
  cp -r "$1/$2" "$3/recursos/info"
}

notice() {
  cat > "$1/ROVA-EMULATOR.txt" <<NOTE
RetroArch $version, empacotado pelo Rova-Emulator para o Rova Games (sem banco de dados, shaders e overlays).
Original: https://buildbot.libretro.com/stable/$version/
Código-fonte desta versão: https://github.com/libretro/RetroArch/tree/v$version
Licença: GPL-3.0 (COPYING). Não inclui jogos nem BIOS.
NOTE
  curl -fsSL --retry 3 -o "$1/COPYING" "https://raw.githubusercontent.com/libretro/RetroArch/v$version/COPYING"
}

# Linux: o AppImage extraído (roda pelo AppRun, sem FUSE) e os recursos da pasta .home dele.
linux="$(fetch linux/x86_64/RetroArch.7z)"
mkdir -p "$work/linux" && 7z x -y -o"$work/linux" "$linux" >/dev/null
src="$work/linux/RetroArch-Linux-x86_64"
dest="$work/linux-out/rova-retroarch"
mkdir -p "$dest"
(cd "$dest" && "$src/RetroArch-Linux-x86_64.AppImage" --appimage-extract >/dev/null && mv squashfs-root app)
test -x "$dest/app/AppRun"
recursos "$src/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch" cores "$dest"
notice "$dest"
tar -czf "$out/rova-emulator-retroarch-linux-x64.tar.gz" -C "$work/linux-out" rova-retroarch

# Windows: o programa e as bibliotecas; os recursos em recursos/.
win="$(fetch windows/x86_64/RetroArch.7z)"
mkdir -p "$work/win" && 7z x -y -o"$work/win" "$win" >/dev/null
src="$work/win/RetroArch-Win64"
dest="$work/win-out/rova-retroarch"
mkdir -p "$dest"
find "$src" -maxdepth 1 -type f -exec cp {} "$dest/" \;
test -f "$dest/retroarch.exe"
recursos "$src" info "$dest"
notice "$dest"
(cd "$work/win-out" && zip -qr "$out/rova-emulator-retroarch-windows-x64.zip" rova-retroarch)

echo "$version" > "$out/retroarch-version.txt"
ls -la "$out"
