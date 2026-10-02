#!/usr/bin/env bash
# Runs the hook against fake permission requests. Touches nothing in ~/.claude.
set -u
hook="$(cd "$(dirname "$0")" && pwd)/hooks/plan-mode-no-prompts.sh"; fail=0
decide() { jq -n --arg m "$1" --arg t "$2" '{permission_mode:$m,tool_name:$t}' | "$hook" | jq -r '.hookSpecificOutput.decision.behavior // empty'; }
check() { got="$(decide "$1" "$2")"; [ -z "$got" ] && got=ask
  if [ "$got" = "$3" ]; then echo "ok   ${PLAN_MODE_READS_ONLY:+[reads-only] }$1 $2 -> $3"; else echo "FAIL ${PLAN_MODE_READS_ONLY:+[reads-only] }$1 $2 -> $got (want $3)"; fail=1; fi; }

# Default: everything is approved in plan mode, except plan review and questions
for t in mcp__gmail__search mcp__gmail__send_email mcp__github__delete_branch mcp__db__query \
         mcp__gmail__download_attachment Bash Edit Write WebFetch WebSearch \
         mcp__ccd_session_mgmt__set_session_title; do check plan "$t" allow; done
check plan ExitPlanMode    ask
check plan AskUserQuestion ask
check default mcp__gmail__send_email ask
check bypassPermissions Bash ask

# Opt-in PLAN_MODE_READS_ONLY=1: only read-only MCP tools, WebSearch and session rename
export PLAN_MODE_READS_ONLY=1
for t in mcp__gmail__search mcp__notion__get_page mcp__drive__list_files WebSearch \
         mcp__ccd_session_mgmt__set_session_title; do check plan "$t" allow; done
for t in mcp__gmail__send_email mcp__crm__get_or_create_user mcp__files__find_and_replace \
         mcp__db__query mcp__gmail__download_attachment mcp__audio__listen Bash Edit WebFetch; do check plan "$t" ask; done
exit $fail
