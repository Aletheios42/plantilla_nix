When performing a code review, respond in Spanish.

When performing a code review, focus on:
- Readability and simplicity — avoid nested ternaries, prefer early returns.
- Conventional Commits compliance — feat, fix, refactor, docs, test, chore.
- No secrets, credentials, or hardcoded tokens in code.
- CI/pipeline workflows must use `nix develop .#ci` or `make ci` entrypoints.
- Commit messages must follow `type(scope): description` format.
