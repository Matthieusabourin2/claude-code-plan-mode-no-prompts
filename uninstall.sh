#!/usr/bin/env bash
# Removes the hook from ~/.claude/settings.json (backup first) and deletes the script.
set -euo pipefail
settings="$HOME/.claude/settings.json"
cmd='"$HOME/.claude/hooks/plan-mode-no-prompts.sh"'

if [ -f "$settings" ]; then
  jq -e . "$settings" >/dev/null 2>&1 || { echo "$settings is not valid JSON: fix it first. Nothing changed."; exit 1; }
  cp "$settings" "$settings.bak-$(date +%Y%m%d-%H%M%S)"
  tmp="$(mktemp)"
  jq --arg cmd "$cmd" '
    if .hooks.PermissionRequest then .hooks.PermissionRequest |= map(.hooks |= map(select(.command != $cmd)) | select(.hooks | length > 0)) else . end
    | if .hooks.PermissionRequest == [] then del(.hooks.PermissionRequest) else . end' "$settings" > "$tmp"
  cat "$tmp" > "$settings"
  rm "$tmp"
fi
rm -f "$HOME/.claude/hooks/plan-mode-no-prompts.sh"
echo "Uninstalled."
