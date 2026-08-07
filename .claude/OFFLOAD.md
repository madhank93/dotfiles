# Local-model offload — global working agreement

Available in any repo on this machine. **I plan and review; the local model
implements.** Bulk codegen runs free on the homelab GPU (RTX 5070 Ti, 16GB,
Ollama behind a Cilium LoadBalancer).

| Piece | Where | Role |
|---|---|---|
| endpoint | `~/.env` → `OLLAMA_API_BASE` | aider auto-loads it in every repo |
| model config | `~/.aider.conf.yml` | `ollama/executor`, diff edits, no auto-commit |
| command | `/offload <task> [-- files]` | delegate + show diff + review |
| model definition | `local-ai-setup` repo | Modelfile + sync script |

## When to delegate

| Work | Who |
|---|---|
| One-line edits, renames, typo fixes | me, directly |
| Anything larger — new functions, refactors, boilerplate, tests | `/offload` |
| Planning, architecture, review, debugging a failed offload | me |

## Loop

1. I write a short plan
2. `/offload` — aider drives the local model
3. I review `git diff`
4. Re-run aider with a targeted `--message`, or fix small things myself
5. No commit unless asked

## Limits worth remembering

The executor is a **Q3 quant on a 16GB card, 16K context**. It is not a frontier
model. It drifts out of scope, and it can emit code that parses but does not run
(it once shipped an uninitialized variable that died under `set -u`). Always
check behavior, not just syntax. If two prompts fail, write it myself.

Full architecture, hardware envelope, and the model bake-off:
`/Volumes/work/git-repos/local-ai-setup/README.md`
