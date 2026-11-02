#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/noctalia/plugins/cursor-manager"

mkdir -p "$DEST"
cp "$SRC/plugin.toml" "$SRC/service.luau" "$DEST/"
cp -r "$SRC/translations" "$DEST/"

echo "Plugin instalado em: $DEST"

if command -v noctalia >/dev/null 2>&1; then
    echo "Habilitando my-tools/cursor-manager..."
    noctalia msg plugins enable my-tools/cursor-manager || {
        echo "Não foi possível habilitar automaticamente."
        echo "Abra Settings → Plugins ou rode: noctalia msg plugins enable my-tools/cursor-manager"
    }
else
    echo "Comando 'noctalia' não encontrado. Habilite o plugin pelo painel do Noctalia."
fi
