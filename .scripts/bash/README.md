# Local Scripts

The zip-based `apply-issue` workflow has been replaced by a conversational
workflow using the GitHub MCP server. Claude now pushes code directly to
GitHub, opens PRs, and performs code reviews from the conversation.

## Remaining local scripts

Only two scripts remain — both require the local Node.js runtime and cannot
be replaced by the MCP workflow.

| Command | Script | Purpose |
|---|---|---|
| `npm run install-deps` | `install-deps.sh` | Runs `npm install` only when `node_modules` is stale |
| `npm run run-tests` | `run-tests.sh` | Runs Vitest and exits non-zero on failure |

## Workflow

```
You : "Implement issue #N"
Me  : reads issue → generates code → pushes to branch → opens PR → code review

You : npm run install-deps
You : fix any CR issues locally
You : npm run run-tests
You : merge PR on GitHub → issue closes
```

## Removed scripts

The following scripts have been removed as they are now handled by Claude
via the GitHub MCP server:

- `apply-issue.sh` — orchestrator
- `handle-zip.sh` — zip extraction
- `handle-branch.sh` — branch management
- `commit-push.sh` — commit and push
- `pull-request.sh` — PR creation
- `code-review.sh` — AI code review
- `create-gh-issues.sh` — issue creation
- `steps/_lib.sh` — moved to `.scripts/bash/_lib.sh`
