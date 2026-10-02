#!/usr/bin/env bash
# Copies the hook to ~/.claude/hooks/ and registers it in ~/.claude/settings.json.
# Backs up settings.json first. Safe to run twice.
set -euo pipefail
command -v jq >/dev/null || { echo "jq is required (brew install jq)"; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)/hooks/plan-mode-no-prompts.sh"
settings="$HOME/.claude/settings.json"
cmd='"$HOME/.claude/hooks/plan-mode-no-prompts.sh"'

mkdir -p "$HOME/.claude/hooks"
[ -f "$settings" ] || echo '{}' > "$settings"
jq -e . "$settings" >/dev/null 2>&1 || { echo "$settings is not valid JSON: fix it first. Nothing changed."; exit 1; }
cp "$settings" "$settings.bak-$(date +%Y%m%d-%H%M%S)"

tmp="$(mktemp)"
jq --arg cmd "$cmd" '
  if [.hooks.PermissionRequest[]?.hooks[]?.command] | index($cmd) then .
  else .hooks.PermissionRequest = ((.hooks.PermissionRequest // []) + [{hooks:[{type:"command",command:$cmd}]}])
  end' "$settings" > "$tmp"
cat "$tmp" > "$settings"   # keeps symlinks and file permissions
rm "$tmp"
cp "$src" "$HOME/.claude/hooks/plan-mode-no-prompts.sh" && chmod +x "$HOME/.claude/hooks/plan-mode-no-prompts.sh"

echo "Installed. Restart Claude Desktop, then open a new session in plan mode."
