# AGENTS.md

Guidelines for AI agents working on this repository.

## Workflow

1. Read and understand the current state before making changes.
2. Propose the change — explain what you plan to do and why.
3. Wait for approval before committing or pushing.
4. After approval, implement, commit, and push.

## Commit Style

- Use conventional commit prefixes: `feat:`, `fix:`, `docs:`, `chore:`, etc.
- Prefer regular `git push` over `git push -f`. Only use force push for initial setup squashing.
- Avoid `--amend` on already-pushed commits in normal workflow.

## Code Style

- Lua files under `lua/codewhale/`.
- Follow the existing patterns for module structure (`M.*` functions, `defaults` tables).
- Document functions with EmmyLua annotations (`---@param`, `---@return`).
- Keep the README.md up to date with new features, options, and commands.

## Testing

- Before pushing, verify changes don't break the plugin by checking syntax is valid.
