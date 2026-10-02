#!/usr/bin/env bash
# Runs the hook against fake permission requests. Touches nothing in ~/.claude.
set -u
hook="$(cd "$(dirname "$0")" && pwd)/hooks/plan-mode-allow-reads.sh"; fail=0
decide() { jq -n --arg m "$1" --arg t "$2" '{permission_mode:$m,tool_name:$t}' | "$hook" | jq -r '.hookSpecificOutput.decision.behavior // empty'; }
check() { got="$(decide "$1" "$2")"; [ -z "$got" ] && got=ask
  if [ "$got" = "$3" ]; then echo "ok   $1 $2 -> $3"; else echo "FAIL $1 $2 -> $got (want $3)"; fail=1; fi; }

check plan mcp__gmail__search                      allow
check plan mcp__notion__get_page                   allow
check plan mcp__github__list_issues                allow
check plan WebSearch                               allow
check plan WebFetch                                ask
check plan mcp__crm__get_or_create_user            ask
check plan mcp__files__find_and_replace            ask
check plan mcp__files__readwrite_file              ask
check plan mcp__audio__listen                      ask
check plan mcp__db__query                          ask
check plan mcp__gmail__download_attachment         ask
check plan mcp__composio__COMPOSIO_SEARCH_TOOLS    ask
check plan mcp__drive__list_files                  allow
check plan mcp__crm__GetContact                    ask
check plan mcp__ccd_session_mgmt__set_session_title allow
check plan mcp__gmail__send_email                  ask
check plan mcp__notion__update_page                ask
check plan mcp__github__delete_branch              ask
check plan Bash                                    ask
check plan Edit                                    ask
check default mcp__gmail__search                   ask
check bypassPermissions mcp__gmail__search         ask
exit $fail
