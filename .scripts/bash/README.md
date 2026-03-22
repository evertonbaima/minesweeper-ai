# apply-issue workflow

Automates the full lifecycle of applying a pre-built issue zip into the repo,
running tests, committing, pushing, opening a PR, and posting a code review.

---

## Folder layout expected

```
.zip/
  issue-1-project-scaffolding.zip   ← drop zips here
  issue-2-type-definitions.zip
  done/                             ← successfully applied zips move here
.scripts/
  bash/
    apply-issue.sh
```

---

## Usage

```bash
npm run apply-issue -- <issue-number>
```

**Example:**
```bash
npm run apply-issue -- 1
```

---

## What the script does, step by step

| Step | Description |
|------|-------------|
| 1 | Finds `.zip/issue-{N}-*.zip` matching the given issue number |
| 2 | Derives the branch name `issue-{N}/{slug}` from the zip filename |
| 3 | Creates or checks out the branch (skips if already exists) |
| 4 | Skips unzip if a sentinel file `.zip/done/.applied-issue-{N}` already exists |
| 5 | Unzips into project root; moves zip to `.zip/done/`; writes sentinel |
| 6 | Runs `npm install` only if `node_modules` is missing or stale |
| 7 | Runs `vitest --run`; **aborts** if any test fails |
| 8 | Commits all changes with message `close #N — <slug>` |
| 9 | Pushes the branch to origin |
| 10 | Opens a Pull Request on the **first** push only |
| 11 | Posts an automated code review comment to the PR |

---

## Re-running after a test failure

Fix your code, then simply re-run the same command:

```bash
npm run apply-issue -- 1
```

The script will skip re-unzipping (sentinel present) and re-attempt
install check → test → commit → push.

---

## Prerequisites

| Tool | Required version | Check |
|------|-----------------|-------|
| Node.js | ≥ 18 | `node -v` |
| npm | ≥ 9 | `npm -v` |
| GitHub CLI | ≥ 2.40 | `gh --version` |
| gh auth | logged in | `gh auth status` |

The `gh` token needs the following scopes:
- `repo` (push, PR creation)
- `pull_requests: write` (review comments)

Run `gh auth login` if not already authenticated.

---

## Notes

- The script **never closes the issue**. Issues are closed when you merge the PR manually.
- The PR is opened only on the **first push** to a branch. Subsequent pushes to the same branch skip PR creation.
- The automated code review is a checklist comment, not a blocking review. You decide whether to merge.
- Zip filenames must follow the pattern `issue-{N}-{slug}.zip` (e.g. `issue-3-core-game-logic.zip`).
