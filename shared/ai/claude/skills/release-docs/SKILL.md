---
name: release-docs
description: Update CHANGELOG.md and README.md for a new release. Use this skill whenever the user wants to add a changelog entry, bump a version number, document changes for a release, or update their README to reflect new features, props, or behavior. Trigger on phrases like "update my changelog", "add a changelog entry", "document this release", "update the README", "bump version and update docs", "I just shipped X", "create release notes", "new version is ready", or any mention of version numbers alongside changes.
---

# Release Docs Updater

This skill updates `CHANGELOG.md` and `README.md` when you're releasing a new version. It handles the formatting so you just need to describe what changed.

## Workflow

### Step 1: Find the files

Look for `CHANGELOG.md` and `README.md` in the current working directory. If they aren't there, ask the user for the paths. Read both files before proceeding.

### Step 2: Gather release info

**Pull recent commits from git:**

Run this to get commits since the last changelog version tag (or last 20 if no tag exists):

```
git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD 2>/dev/null || git log --oneline -20
```

Present the commits as a numbered list and ask the user which ones to include. Example:

> Here are the recent commits — which ones should go in the changelog? (pick numbers, or say "all")
>
> 1. `a1b2c3d` fix scrollbar issue on mobile
> 2. `e4f5g6h` add dark mode support
> 3. `i7j8k9l` bump deps

If git is not available or the repo has no commits, skip this and ask the user to describe what changed manually.

Once the user selects commits, use those as the basis for changelog bullets. Lightly clean up the commit messages (normalize capitalization, drop trailing periods, expand obvious abbreviations) but don't rewrite intent. The user can add, remove, or edit before you write anything.

Then ask three things — keep it conversational, not a form:

1. **New version number.** Show the current latest from the CHANGELOG as a reference (e.g. "Latest in the changelog is 3.8.2 — what's the new version?")
2. **Any additional changes** not in the selected commits worth noting? (optional)
3. **README updates.** Ask whether anything in the README needs updating (new props, changed behavior, new features, updated examples). If yes, ask what specifically. If no, skip it.

Don't ask all three in a single wall of text. A natural two-exchange conversation is fine.

### Step 3: Update CHANGELOG.md

Prepend the new version entry directly after the `# Changelog` header line. Follow the exact style of the existing entries:

```
## X.Y.Z

- change one
- change two
```

Leave one blank line between the `##` header and the first bullet. Leave one blank line between the last bullet of the new entry and the `##` header of the previous entry. Do not touch any existing entries — preserve them exactly.

**Version number format:** match whatever the existing file uses (no `v` prefix unless the file already uses one).

**Bullet style:** start with `- ` (dash + space). Keep entries short and direct — same register as the other entries. If the user gives you a rough note like "fixed that weird scrollbar bug on mobile", write `- fix scrollbar issue on mobile`. Don't over-formalize, but do normalize capitalization and drop trailing periods to match the file's style.

If the new version number already exists in the file, warn the user before writing.

### Step 4: Update README.md (only if needed)

If the user identified changes, update only the affected sections. Common patterns:

- **New or changed props:** add/update rows in the props table, matching the existing column format
- **New feature section:** add a section using the existing heading style
- **Updated code examples:** update the relevant snippet only
- **Description paragraph:** update if the project's core purpose or audience changed significantly

Don't add sections that aren't there unless explicitly requested. Preserve all formatting — heading levels, table alignment, code block language tags, spacing.

### Step 5: Confirm

Summarize briefly what was done:
- "Added CHANGELOG entry for X.Y.Z with N changes ✓"
- "README updated: [brief description of what changed] ✓" — or "README unchanged ✓"

Don't print the full file contents unless the user asks.

## Format reference

Based on observed file patterns:

**CHANGELOG entry:**
```
## 3.8.3

- fix scrollbar issue on mobile
- improve initial load time

## 3.8.2   ← previous entry starts here
```

**README props table row:**
```
| `propName` | `TypeName` (Object) | Yes/No | default | Description |
```

Match column widths and spacing to the existing table.
