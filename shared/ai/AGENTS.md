# Global instructions

## Text output rules

- Never use em dashes. Not in any generated text, ever.
- Semicolons: max 2 per piece of generated text. Prefer periods or commas.
- No special ASCII characters or character combos. Only what a human types normally on a regular laptop keyboard.
- No en dashes, curly quotes, ellipsis characters, arrows, box-drawing characters, or decorative symbols. Use plain hyphens, straight quotes, and three periods if needed.
- No emojis. Not in chat text, not in code, not in comments, not in commit messages, not in PR bodies, not in documentation.


## Honesty rules

- No appeasement. Never soften, reverse, or hedge a technical claim because the user pushed back. Pushback is not evidence. Re-check the facts, then either hold the position with the reason, or correct it and say plainly what was wrong.
- If a capability, API, or approach exists, say so, even when the user seems to prefer the other answer. Never claim something is impossible without verifying it.
- No unsolicited compliments, no praise for the question, no "great catch". State findings flat.
- When wrong, one sentence of correction and move on. No apology spirals, no self-flagellation.
- Truth over comfort, every time.

## Asana task workflow (git)

When starting work on an Asana task (from an Asana task link, task ID, the asana skill/plugin, or any Asana-driven request), do this before writing code:

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

## Code comments

Applies in every language and file type.

- Comment sparingly, if at all. The team is experienced developers who review
  diffs by hand, and walls of comment text slow that review down.
- Write a comment only when the code cannot say it: a non-obvious why, a
  workaround for an external bug, a constraint that is not visible locally.
- One line is the default. A multi-line comment needs a real reason. Never write
  paragraphs.
- Never narrate what the code does, restate a name, or describe the change
  being made ("added X", "now uses Y"). That belongs in the commit message.
- No doc-comment blocks on functions whose name and signature already say
  everything.

## Commit messages

- Keep the body sparse. Many commits need only the subject line.
- When a body is needed, use short bullet points, not paragraphs.
- Each bullet says what changed or why, in one line. Skip anything the diff
  already makes obvious.

## Code duplication

If a block of code appears more than once, extract it. This holds in every
language and every file type, not just components: a repeated markup block
becomes a component or a loop, a repeated function body becomes a helper, a
repeated object shape becomes a type, a repeated style block becomes a class or
a custom property.

Extract on the second occurrence, not the third. Copy-paste plus a small edit is
the same duplication as copy-paste, and it is worse, because the difference is
the part that will be forgotten when one copy changes.

Say what the extracted thing is for in its name. If a good name does not exist,
that usually means the two blocks were not the same thing after all, and they
should stay separate.

## Vue SFC layout (script setup, lang=ts)

Applies to every .vue file I write or edit, in any project.

### Block order

`<template>`, then `<script setup lang="ts">`, then `<style scoped>`. Always scoped.

### Script section order

Never interleave kinds. Imports, then every declaration, then lifecycle, then
functions, then the trailing macros. No banner comments marking the sections:
the order is the rule, and comments stay reserved for explaining why something
non-obvious is there.

1. imports
2. local `type` / `interface` declarations
3. all `const` and `let` declarations, in the sub-order below
4. `watch` / `watchEffect`, then `onMounted` / `onUnmounted`
5. all other functions
6. `defineOptions`
7. `defineExpose`

This works because `function` declarations hoist, so a declaration at the top can
call a function defined at the bottom. It is another reason functions are never
written as arrow consts. The one trap: a hoisted function called during
initialization must not read a `const` declared below that call, which throws at
runtime rather than failing the typecheck.

### The declarations block

One unbroken run of `const` and `let`, blank line between bands, in this order:

1. `defineProps`
2. `defineEmits`
3. stores and composables (`const proxy = useProxy()`)
4. constants (lookup tables, sizing values)
5. reactive state (`ref`, `reactive`)
6. template refs (DOM elements and component instances)
7. non-reactive bookkeeping (`let` counters and handles, `const` Maps that
   nothing renders from)
8. `computed`

Band seven is decided by reactivity, not by keyword: a `const` Map that only
functions touch belongs there.

Use a `ref` only when the template or a computed reads the value. Anything else
stays a plain `let` or `const`, so nothing pays for dependency tracking it does
not use.

### Naming

- Booleans controlling whether UI is shown: `<thing>Open` (`helpOpen`,
  `reportsOpen`, `iconLegendOpen`). Every other boolean: `is<Adjective>`
  (`isNewRow`, `isFetching`).
- Template refs take no suffix, element or component alike: `gridScroll`,
  `helpBtn`, `popupBox`, `helpMenu`.
- Constants are camelCase everywhere, including a dedicated constants module:
  `nameColMinW`, `statusColor`, `dayEditIcon`. Enums and const objects acting as
  enums keep PascalCase (`RowType`, `NameMode`), because they are types.
- Arrays are plural: `students`, `dates`, `silRows`.
- Maps and Records are named for their contents and their key: `eipByDay`,
  `studentEditsByDay`, `assignedMinsByRowId`. The type alone does not say what
  the key means.

### Derived values

- No argument: `computed`.
- Varies per row or cell: a function.
- A function called inside a `v-for` over a large list reads from a precomputed
  `computed` lookup (a Set or Map) rather than scanning on every cell.

### Functions, ordering

Helpers and data shaping first, `handle*` entry points last, so everything a
handler calls is already defined above it.

### Promises

- `.then` chains are the style for component-level async work, closed with
  `.catch` and `.finally`. This holds in lifecycle hooks too.
- A function whose chain a caller must sequence against has to `return` the
  chain. Losing that return silently breaks ordering, for example a save that
  must land before a week change.

### Imports

- Always the `@/` alias for anything inside src, including sibling components.
  Never `../` or `./` for intra-src imports.
- Grouped by origin, blank line between groups, no sort inside a group:
  vue, then third-party npm, then `@quaver/*`, then `@/*`.
- `import type` for type-only imports.

### Props and emits

- `const props = defineProps<{ ... }>()`, type-argument form.
- `const emit = defineEmits<{ ... }>()`, always the typed generic with named tuple
  payloads. Never the string-array form: it gives up payload checking at the emit
  call and types the parent's handler params as any. One line when it fits, broken
  only when prettier forces it.
- Templates reference props bare (`{{ studentName }}`). Script references them
  through `props.` (`props.classId`).

### Functions

- `function` declarations, not arrow consts.
- Explicit return type on every declared function, including `: void`. Inline
  callbacks and arrow expressions are left to inference: annotating
  `window.onresize = (): void => close()` is noise, not a contract.
- Event handlers, whether bound in this file's template or receiving a child's
  emit, are named `handle*`. Everything else is named for what it does
  (`saveAttendance`, `measureNameCol`, `hasLogEdit`).

### Template

- Events use longhand `v-on:click`. Bindings use shorthand `:class`. Never `@click`.
- Attribute order: structural (`v-if`, `v-for`), then identity (`ref`, `key`),
  then static attributes, then bound attributes, then all `v-on:` handlers last.
- Anything clickable is a `<button type="button">` unless the layout genuinely
  forbids it; only then use `role="button"` plus `tabindex="0"`.
- Every interactive element carries all five: `v-on:click`,
  `v-on:keydown.enter.prevent`, `v-on:keydown.space.prevent`, `v-on:keyup.enter`,
  `v-on:keyup.space`. The keydown preventers are mandatory whenever the keyup
  handlers are present, because a native button activates itself on Enter keydown
  and Space keyup; preventing those makes the keyup handlers the single activation
  path and stops double firing.
- Interactive elements need an `aria-label` when their text alone is not the label.

### Types

- A type that crosses a component boundary (prop, emit payload, API response)
  lives in `@/types`. A type used only inside one file is declared in that file,
  after the imports and before `defineProps`.

### Style

- Colors come from CSS custom properties defined once on `:root` in the project's
  global stylesheet, used as `var(--q-blue)`. Prefix custom properties, since a
  library's stylesheet lands in the host page's global scope.
- Keep a value in TS constants only when script genuinely needs it (inline `:style`
  bindings, export code). Those mirror the CSS variable names.

### Comments and text in source

- Plain ASCII in code comments: hyphens not em dashes, `->` not arrows, three
  periods not an ellipsis character.
- Glyphs are fine in user-facing markup, where they are content rather than prose.
- Comments explain why, not what.
