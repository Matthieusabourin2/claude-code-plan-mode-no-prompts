#!/usr/bin/env bash
# PermissionRequest hook: in plan mode, auto-approve read-only MCP tools
# (search_*, get_*, list_*...) and WebSearch. Everything else keeps asking:
# writes, Bash, Edit, WebFetch.
# Matching is by tool name only: see the README before installing.

input="$(cat)"
mode="$(printf '%s' "$input" | jq -r '.permission_mode // empty' 2>/dev/null)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
[ "$mode" = "plan" ] || exit 0

# Name after the last "__", lowercased: mcp__gmail__search_threads -> search_threads
name="$(printf '%s' "${tool##*__}" | tr '[:upper:]' '[:lower:]')"
read_verbs="${PLAN_MODE_READ_PATTERN:-^(search|list|get|read|find|fetch|lookup|describe|show|view|count)(_|$)}"
write_words='(^|_)(add|apply|approve|archive|cancel|create|decline|delete|download|edit|execute|forward|import|insert|mark|modify|move|patch|post|purge|put|remove|replace|reply|run|send|set|share|submit|sync|trash|update|upload|write)(_|$)'

allow=
case "$tool" in
  mcp__ccd_session_mgmt__set_session_title) allow=1 ;;  # session rename (Claude Desktop)
  WebSearch) allow=1 ;;
  mcp__*)
    if ! printf '%s' "$name" | grep -Eq -e "$write_words" \
       && printf '%s' "$name" | grep -Eq -e "$read_verbs"; then allow=1; fi ;;
esac

if [ -n "$allow" ]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PermissionRequest",decision:{behavior:"allow"}}}'
fi
[ -n "${PLAN_MODE_ALLOW_LOG:-}" ] && echo "$(date '+%F %T') $tool $([ -n "$allow" ] && echo allow || echo ask)" >> "$PLAN_MODE_ALLOW_LOG"
exit 0
