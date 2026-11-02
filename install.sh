#!/usr/bin/env bash
set -euo pipefail

THEME="macOS"
INSTALL_THEME=1

for arg in "$@"; do
    case "$arg" in
        --white) THEME="macOS-White" ;;
        --no-theme) INSTALL_THEME=0 ;;
        *)
            echo "Uso: $0 [--white] [--no-theme]"
            exit 1
            ;;
    esac
done

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/noctalia/plugins/cursor-manager"
ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
THEME_VERSION="v2.0.1"

mkdir -p "$DEST"
cp "$SRC/plugin.toml" "$SRC/service.luau" "$SRC/apply-niri.sh" "$DEST/"
cp -r "$SRC/translations" "$DEST/"
echo "Plugin instalado em: $DEST"

if [[ "$INSTALL_THEME" -eq 1 ]]; then
    if [[ -d "$ICONS/$THEME" ]]; then
        echo "Tema $THEME já instalado em $ICONS/$THEME"
    else
        if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
            echo "curl e tar são necessários para baixar o tema $THEME."
        else
            echo "Baixando tema $THEME ($THEME_VERSION) de ful1e5/apple_cursor..."
            TMP="$(mktemp -d)"
            trap 'rm -rf "$TMP"' EXIT
            curl -fL --retry 3 -o "$TMP/theme.tar.xz" \
                "https://github.com/ful1e5/apple_cursor/releases/download/${THEME_VERSION}/${THEME}.tar.xz"
            mkdir -p "$ICONS"
            tar -xJf "$TMP/theme.tar.xz" -C "$ICONS"
            echo "Tema instalado em $ICONS/$THEME"
        fi
    fi
fi

if command -v noctalia >/dev/null 2>&1; then
    echo "Habilitando my-tools/cursor-manager..."
    noctalia msg plugins enable my-tools/cursor-manager || {
        echo "Não foi possível habilitar automaticamente."
        echo "Abra Settings → Plugins ou rode: noctalia msg plugins enable my-tools/cursor-manager"
    }
else
    echo "Comando 'noctalia' não encontrado. Habilite o plugin pelo painel do Noctalia."
fi
