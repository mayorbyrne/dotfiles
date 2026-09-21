# Global instructions

## Asana task workflow (git)

When starting work on an Asana task (from an Asana task link, task ID, or any Asana-driven request), do this before writing code:

1. `git stash -u` if the working tree is dirty. Tell the user what was stashed.
2. `git checkout main` then `git pull` (fresh main, not dev, not the current branch).
3. Create a working branch named from the task type plus a short human-readable slug
   derived from the task title. Never use the numeric Asana task ID.
   - `fix/[shortSlug]` for bugs
   - `feat/[shortSlug]` for features
   - `chore/[shortSlug]` for maintenance, refactors, docs, deps
   The slug is camelCase, 1 to 3 words, describing the problem or feature, for example
   `fix/moveFolderIssue`, `feat/jumpToGuid`, `chore/cleanupDocs`. Tell the user the branch
   name when you create it.
4. Only then start the work.

If the branch already exists, check it out and rebase on fresh main instead of creating a duplicate.
