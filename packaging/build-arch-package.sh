#!/usr/bin/env bash
# Monta o pacote .pkg.tar.zst do Arch a partir do repositorio.
#
# POR QUE ISSO EXISTE
# O jeito normal e "makepkg -si" numa maquina Arch, e o PKGBUILD ao lado serve
# exatamente para isso. Este script e' o caminho alternativo: permite gerar o
# pacote a partir de uma maquina que NAO e' Arch (aqui, um Fedora), para poder
# anexar o binario na release junto com o .rpm.
#
# Um pacote do pacman e' so um tar comprimido com uma ordem especifica:
#   .PKGINFO   primeiro, com os metadados
#   .MTREE     depois, com hashes e permissoes de cada arquivo
#   os arquivos em seguida
# Fora dessa ordem o pacman recusa o arquivo.
#
# Uso:  ./packaging/build-arch-package.sh [versao]
set -euo pipefail

VERSION="${1:-1.5.0}"
PKGREL=1
PKGNAME=update-notifier-tray
ROOT=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
OUT="$ROOT/dist"
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT

for tool in bsdtar zstd; do
    command -v "$tool" >/dev/null || { echo "falta $tool"; exit 1; }
done

# ------------------------------------------------------------------ arquivos
install -Dm755 "$ROOT/src/update-fedora-rawhide" \
    "$BUILD/usr/bin/update-fedora-rawhide"

for f in "$ROOT"/icons/update-*.svg; do
    install -Dm644 "$f" \
        "$BUILD/usr/share/icons/hicolor/scalable/apps/$(basename "$f")"
done
install -Dm644 "$ROOT/icons/fedora-update-notifier.svg" \
    "$BUILD/usr/share/icons/hicolor/scalable/apps/fedora-update-notifier.svg"

install -Dm644 "$ROOT/desktop/update-fedora-rawhide.desktop" \
    "$BUILD/usr/share/applications/update-fedora-rawhide.desktop"
install -Dm644 "$ROOT/README.md" "$BUILD/usr/share/doc/$PKGNAME/README.md"
install -Dm644 "$ROOT/LICENSE" "$BUILD/usr/share/licenses/$PKGNAME/LICENSE"

SIZE=$(du -sb "$BUILD" | cut -f1)

# ------------------------------------------------------------------ .PKGINFO
cat > "$BUILD/.PKGINFO" <<EOF
pkgname = $PKGNAME
pkgbase = $PKGNAME
pkgver = $VERSION-$PKGREL
pkgdesc = Tray icon that watches for system updates, for Fedora and Arch based systems
url = https://github.com/gabrielmf1998/UpdateNotify-Fedora
builddate = $(date +%s)
packager = Gabriel <empresagabriel24@gmail.com>
size = $SIZE
arch = any
license = MIT
depend = python
depend = python-gobject
depend = gtk3
depend = libappindicator-gtk3
depend = libnotify
depend = polkit
optdepend = pacman-contrib: check for updates without root
optdepend = konsole: terminal used by "Install updates"
optdepend = alacritty: alternative terminal
optdepend = kitty: alternative terminal
EOF

# -------------------------------------------------------------------- .MTREE
# O pacman usa isso para conferir permissoes e hashes na instalacao.
# --uid/--gid 0: os arquivos de um pacote pertencem ao root. Empacotar com o
# dono de quem construiu faria o pacman instalar arquivos de sistema com dono
# de usuario comum.
( cd "$BUILD" && bsdtar -czf .MTREE --format=mtree \
    --uid 0 --gid 0 --uname root --gname root \
    --options='!all,use-set,type,uid,gid,mode,time,size,md5,sha256,link' \
    .PKGINFO usr )

# ------------------------------------------------------------------- empacota
mkdir -p "$OUT"
PKG="$OUT/$PKGNAME-$VERSION-$PKGREL-any.pkg.tar.zst"
( cd "$BUILD" && bsdtar -cf - --uid 0 --gid 0 --uname root --gname root \
    .PKGINFO .MTREE usr | zstd -19 -q -f -o "$PKG" )

echo "gerado: $PKG"
bsdtar -tf "$PKG" | head -4
