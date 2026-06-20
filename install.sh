#!/usr/bin/env bash
# Claude Modules installer — github.com/ateett12ue/claude-agent-harnes
#
# Installs / updates the harness (agents, commands, skills, CLAUDE.md, settings)
# into a target project. Idempotent: re-running updates files and re-merges
# settings without creating duplicates.
#
#   # install into the current directory
#   curl -fsSL https://raw.githubusercontent.com/ateett12ue/claude-agent-harnes/main/install.sh | bash
#
#   # install into a specific project
#   curl -fsSL https://raw.githubusercontent.com/ateett12ue/claude-agent-harnes/main/install.sh | bash -s -- /path/to/project

set -euo pipefail

REPO="ateett12ue/claude-agent-harnes"
BRANCH="main"
TARGET="${1:-$PWD}"

# --- resolve & validate target -----------------------------------------------
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  echo "✗ Target directory not found: ${1:-$PWD}" >&2; exit 1
}
CLAUDE_DIR="$TARGET/.claude"
echo "▶ Installing Claude Modules into: $TARGET"

# --- download the latest modules from GitHub ---------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "▶ Downloading latest from github.com/$REPO ($BRANCH)…"
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" | tar -xz -C "$TMP"
SRC="$(find "$TMP" -maxdepth 1 -type d -name 'claude-agent-harnes-*' | head -n1)"
[ -n "$SRC" ] && [ -d "$SRC" ] || { echo "✗ Download/extract failed" >&2; exit 1; }

# --- copy module folders into .claude/ ---------------------------------------
mkdir -p "$CLAUDE_DIR"
for d in agents commands skills; do
  if [ -d "$SRC/$d" ]; then
    mkdir -p "$CLAUDE_DIR/$d"
    cp -R "$SRC/$d/." "$CLAUDE_DIR/$d/"
    echo "  ✓ .claude/$d/"
  fi
done

# --- CLAUDE.md: back up the user's original once, then write the managed file -
if [ -f "$TARGET/CLAUDE.md" ]; then
  if grep -q 'claude-modules:managed' "$TARGET/CLAUDE.md" 2>/dev/null; then
    echo "  ✓ CLAUDE.md (updating managed file)"
  elif [ ! -f "$TARGET/CLAUDE.md.orig" ]; then
    cp "$TARGET/CLAUDE.md" "$TARGET/CLAUDE.md.orig"
    echo "  ✓ CLAUDE.md (existing file backed up → CLAUDE.md.orig)"
  fi
fi
cp "$SRC/CLAUDE.md" "$TARGET/CLAUDE.md"

# --- deep-merge settings.json & settings.local.json (additive, deduped) ------
merge_json() {
  local src="$1" dst="$2" name="$3"
  [ -f "$src" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    local base="$TMP/base.json"
    if [ -f "$dst" ]; then cp "$dst" "$base"; else echo '{}' > "$base"; fi
    jq -s '
      def deepmerge(a; b):
        a as $a | b as $b
        | if   ($a|type)=="object" and ($b|type)=="object"
          then reduce ($b|keys_unsorted[]) as $k ($a; .[$k] = deepmerge($a[$k]; $b[$k]))
          elif ($a|type)=="array"  and ($b|type)=="array"
          then ($a + $b) | unique
          else (if $b==null then $a else $b end)
          end;
      deepmerge(.[0]; .[1])
    ' "$base" "$src" > "$dst.tmp" && mv "$dst.tmp" "$dst"
    echo "  ✓ .claude/$name (merged)"
  else
    if [ -f "$dst" ]; then
      echo "  ! jq not found — left existing .claude/$name unchanged (merge it manually)"
    else
      cp "$src" "$dst"
      echo "  ✓ .claude/$name (copied — install jq to enable merging on re-run)"
    fi
  fi
}
merge_json "$SRC/settings.json"       "$CLAUDE_DIR/settings.json"       "settings.json"
merge_json "$SRC/settings.local.json" "$CLAUDE_DIR/settings.local.json" "settings.local.json"

# --- keep the SessionStart hook's backup file out of git ---------------------
GI="$TARGET/.gitignore"
if [ -f "$GI" ] && ! grep -qx '.claude-md.bak' "$GI" 2>/dev/null; then
  printf '\n# Claude Modules: SessionStart hook backup\n.claude-md.bak\n' >> "$GI"
fi

echo ""
echo "✅ Claude Modules installed."
echo "   • CLAUDE.md at the project root (managed)"
echo "   • .claude/{agents,commands,skills} ready"
echo "   • settings.json + settings.local.json merged (permissions + hooks)"
echo "   Restart Claude Code in this project so the SessionStart hook runs."
