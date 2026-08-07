---
description: Delegate implementation to the local model (aider → ollama). Planning/review stay with Claude; bulk codegen runs free on the homelab GPU.
argument-hint: <task, or path to plan.md> [-- file paths...]
allowed-tools: Bash(aider:*), Bash(git diff:*), Bash(git status:*), Bash(curl:*), Bash(test:*), Bash(. ./.env:*), Bash(mise:*), Bash(go:*), Bash(npm:*), Bash(cargo:*), Write
---

Delegate the following implementation to the local model, then show me the diff to review.

**Task:** $ARGUMENTS

## 0. Split the arguments

Everything before `--` is the task. Everything after `--` is a list of file paths
and must be passed as `--file <path>` arguments, **never** interpolated into the
message. A path that leaks into the prompt text makes the model guess at files it
was already being handed.

If a file is needed as *context only* — a style reference, an interface the edit
must satisfy, a sibling exercise to imitate — pass it as `--read <path>` instead.
Read-only files cost the same context but the model cannot corrupt them.

## 1. Check reachability

```bash
set -a; [ -f .env ] && . ./.env; [ -f ~/.env ] && . ~/.env; set +a
curl -sf "${OLLAMA_API_BASE:-http://localhost:11434}/api/tags" >/dev/null \
  && echo "ollama reachable" \
  || echo "ollama NOT reachable — start: kubectl -n ollama port-forward svc/ollama 11434:11434"
```

If unreachable, stop and tell me how to fix it.

## 2. Write the prompt to a file

Long structured prompts break under shell quoting. Write the message to
`<scratchpad>/offload-msg.md` and pass `--message-file`. This also means I can
read back exactly what the model was told when a run goes wrong.

**Prompt contract** — the executor is a Q3 quant with a 16K window. It follows
concrete instructions and drifts on abstract ones. Every message must have:

- **Numbered, atomic changes.** One change per number. Not "fix the flaky test."
- **Literal target text.** Quote the exact line being replaced, not a description
  of it. Search/replace matching fails on paraphrase.
- **The exact code to write** where you already know it. You are the one who can
  reason; do not make a Q3 model re-derive a type signature you already worked out.
- **Explicit non-goals.** "Do not modify any other file." Plus a `Do NOT` line for
  anything adjacent it might helpfully wreck — see the guardrails below.
- **Reasons, briefly.** "…because `got` is int64 and this is int" survives a
  retry; a bare imperative does not.

**Guardrails — encode these when they apply.** Each cost a real re-prompt:

| Failure seen | Line to include |
|---|---|
| Solved a deliberately-broken fixture | "This file is an intentionally broken exercise. Keep the `FIXME` and the stub return. Do NOT solve it." |
| Pasted the instructions in as a code comment | "Do not repeat these instructions in the file. Write only the code and its own explanatory comments." |
| Added unrequested docstrings / `.gitignore` entries | "Change only the lines described above. Add nothing else." |
| Untyped `:=` constants against a typed variable | Give the literal `const (...)` block, typed. |
| Wrote a value into a `uint64`/unsigned path | State the type of every quantity in the arithmetic. |

## 3. Run aider with the local test loop closed

The point: aider runs the test command itself, feeds failures back to the model,
and lets it self-correct on the GPU — **for free, without a Claude round-trip.**
A compile error should never reach me.

Pick `--test-cmd` from the repo (`mise run test`, `go test ./...`, `npm test`,
`cargo test`). Scope it to what the change touches so the loop stays fast.

```bash
aider --yes --no-auto-commit \
      --message-file <scratchpad>/offload-msg.md \
      --auto-test --test-cmd "<the repo's test command>" \
      --lint-cmd "<lang>:<formatter/linter>" \
      --file <each path after --> \
      --read <each context-only path>
```

Put the *compiler* in `--test-cmd`, not just the test runner — `go vet ./... &&
go test ./...` beats `go test ./...`, because a type error then comes back as a
fixable message instead of a failed run. For anything flaky, put the repetition
in the command itself (`go test -count=50 ./...`); the model cannot fix a race it
never sees.

`--lint-cmd` takes `language:command` and runs after the edit (e.g.
`go:gofmt -l -w .`). Measured: the test loop alone still left `gofmt` dirty.

**Do not use `--auto-test` on a deliberately-broken fixture.** On a learner
exercise, a teaching stub, or any file whose tests are *supposed* to fail, the
loop will dutifully "fix" it by implementing the answer. Drop `--auto-test` there
and verify by hand that the file still fails the way it should.

If the repo has no runnable test for the change, say so and drop `--auto-test` —
but then expect to review harder.

Config comes from `~/.aider.conf.yml` (model `ollama/executor`, diff edits, no
auto-commit); a repo-local `.aider.conf.yml` wins if present.

## 4. Show the result

`git diff --stat`, then the full `git diff`.

## 5. Review — behavior, not syntax

Check: correctness, obvious bugs, whether it satisfies the task, and whether it
stayed in scope. **Compile and run it.** Two observed failures passed `bash -n`
and then died at runtime; one passed `gofmt` and failed `go vet`. A diff that
merely parses has not been verified.

Also diff the *scope*: list every file touched and confirm each was asked for.
The model adds things — ignore entries, docstrings, "helpful" refactors.

For anything timing-, memory-, or GC-dependent, run it in a loop (`-count=200`)
before believing it. A single green run proves nothing about a flaky assertion.

## 6. Iterate, then take over

Re-run aider with a targeted follow-up `--message-file` for anything wrong. State
the correction the same way as the original: numbered, literal, with the exact fix.

**Stop delegating when the remaining work is smaller than the prompt describing
it.** A one-line revert is mine to make. If two prompts in a row miss, write it
yourself and tell me the model missed.

## 7. Do not commit

Leave the working tree for me to inspect.
