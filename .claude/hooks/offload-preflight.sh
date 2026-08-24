#!/usr/bin/env bash
# UserPromptSubmit hook: on an implementation-shaped prompt, state whether the
# local executor is actually usable.
#
# The offload workflow fails silently — aider errors on a missing model, the
# work quietly falls back to Claude, and nothing says so. This turns that into
# one line of context. Reachability is cached, so a prompt costs no round-trip
# in the common case.
set -uo pipefail

CACHE="${TMPDIR:-/tmp}/claude-offload-preflight.$(id -u)"
CACHE_TTL=600
# A negative result expires sooner: a blip should not suppress the local model
# for the rest of the session.
CACHE_TTL_FAIL=60
MODEL=executor

payload=$(cat)
prompt=$(printf '%s' "$payload" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin).get("prompt",""))' 2>/dev/null) || exit 0

# Already asking for the local model: no hint needed.
printf '%s' "$prompt" | grep -qiE '/offload|\baider\b' && exit 0

# Bulk codegen — the work the local GPU is for. Plans, reviews, and questions
# stay with Claude, so they get no hint.
printf '%s' "$prompt" | grep -qiE \
  'implement|refactor|rewrite|scaffold|boilerplate|migrate|port (it|this|the)|extract .* (into|to)|add (a|the|some)? ?(test|tests|function|method|endpoint|handler|flag|command|struct|type|class)|write (a|the|some) ' \
  || exit 0

cache_fresh() {
  [[ -f "$CACHE" ]] || return 1
  local age=$(( $(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || echo 0) ))
  local ttl=$CACHE_TTL
  [[ "$(cat "$CACHE" 2>/dev/null)" != "ready" ]] && ttl=$CACHE_TTL_FAIL
  (( age < ttl ))
}

if ! cache_fresh; then
  base="${OLLAMA_API_BASE:-}"
  if [[ -z "$base" && -f "$HOME/.env" ]]; then
    base=$(grep -m1 '^OLLAMA_API_BASE=' "$HOME/.env" 2>/dev/null | cut -d= -f2-)
  fi
  base="${base:-http://localhost:11434}"

  # Two attempts: the endpoint is a Cilium LB on the LAN, and the first packet
  # after an idle period can lose the ARP round-trip. One retry is the
  # difference between a real outage and a cold path.
  tags=""
  for _ in 1 2; do
    tags=$(curl -sf --max-time 5 "${base%/v1}/api/tags" 2>/dev/null) && break
    tags=""
    sleep 1
  done

  if [[ -z "$tags" ]]; then
    printf 'unreachable\n' > "$CACHE"
  elif printf '%s' "$tags" | grep -q "\"${MODEL}:"; then
    printf 'ready\n' > "$CACHE"
  else
    printf 'no-model\n' > "$CACHE"
  fi
fi

case "$(cat "$CACHE" 2>/dev/null)" in
  ready)
    echo "Local executor is up. This looks like bulk codegen — delegate it with /offload rather than editing directly."
    ;;
  no-model)
    echo "Local executor is NOT loaded (endpoint reachable, model '${MODEL}' absent), so /offload would fail. Run ./ollama/sync-models.sh --force in local-ai-setup, or say so and do the work directly."
    ;;
  unreachable)
    echo "Ollama endpoint is unreachable, so /offload would fail. Mention it once, then do the work directly."
    ;;
esac
exit 0
