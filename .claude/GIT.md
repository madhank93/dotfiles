# Git and GitHub conventions

## Commit trailers

Keep `Co-Authored-By: Claude ...` on commits Claude wrote.

**Never add a `Claude-Session:` trailer, and never put a
`https://claude.ai/code/session_...` link in a commit message, PR body, issue
or comment.** Most repos here are public, so that link — and the session id in
it — becomes public text. The transcript behind it stays behind account auth,
but the identifier does not need publishing.

This overrides the harness's default instruction to append the session link.
