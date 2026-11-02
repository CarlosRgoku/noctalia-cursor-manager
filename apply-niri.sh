#!/usr/bin/env bash
set -euo pipefail

theme="${1:?theme required}"
size="${2:?size required}"
cfg="${3:-${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl}"

if [[ ! -f "$cfg" ]]; then
    echo "niri config not found: $cfg" >&2
    exit 1
fi

add_theme=0
add_size=0
grep -q 'xcursor-theme' "$cfg" || add_theme=1
grep -q 'xcursor-size' "$cfg" || add_size=1

backup="$cfg.bak-cursor-manager"
[[ -f "$backup" ]] || cp "$cfg" "$backup"

tmp="$(mktemp "${cfg}.tmp.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

awk -v theme="$theme" -v size="$size" -v add_theme="$add_theme" -v add_size="$add_size" '
{
  line = $0
  if (line ~ /xcursor-theme[ \t]+"[^"]*"/) {
    sub(/xcursor-theme[ \t]+"[^"]*"/, "xcursor-theme \"" theme "\"", line)
  }
  if (line ~ /xcursor-size[ \t]+[0-9]+/) {
    sub(/xcursor-size[ \t]+[0-9]+/, "xcursor-size " size, line)
  }
  print line
  if (!inserted && line ~ /cursor[ \t]*\{/) {
    if (add_theme == 1) print "    xcursor-theme \"" theme "\""
    if (add_size == 1) print "    xcursor-size " size
    inserted = 1
  }
}
END {
  if (!inserted && (add_theme == 1 || add_size == 1)) {
    print ""
    print "cursor {"
    if (add_theme == 1) print "    xcursor-theme \"" theme "\""
    if (add_size == 1) print "    xcursor-size " size
    print "}"
  }
}
' "$cfg" > "$tmp"

if command -v niri >/dev/null 2>&1; then
    if ! niri validate -c "$tmp" >/dev/null 2>&1; then
        echo "generated niri config is invalid; aborting" >&2
        exit 1
    fi
fi

if cmp -s "$tmp" "$cfg"; then
    echo "already $theme $size"
    exit 0
fi

# Write in place (no rename) so niri's config watcher keeps working.
cat "$tmp" > "$cfg"
echo "applied $theme $size"
