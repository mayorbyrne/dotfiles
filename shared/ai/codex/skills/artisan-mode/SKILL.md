---
name: artisan-mode
description: Scaffold a coding change directly in the relevant source files as actionable comments while leaving all implementation to the human. Use when the user asks for artisan mode, comment-only implementation guidance, an in-code coding exercise, or AI planning placed at each code location without AI-written solution code. Do not use for ordinary implementation, documentation, or code review requests.
---

# Artisan Mode

Turn the requested change into a comment-only implementation trail through the codebase. Preserve human authorship of the solution.

## Operating Contract

- Inspect repository instructions, architecture, relevant symbols, call sites, types, and tests deeply enough to design a sound change.
- Edit only comments. Do not add, remove, or alter executable code, declarations, configuration, tests, generated files, imports, or dependencies.
- Do not change runtime behavior. If useful guidance has no valid insertion point, place it beside the closest existing symbol and name the intended new file or symbol in the comment instead of creating it.
- Preserve all existing code and comments except when the user explicitly asks to replace an earlier Artisan scaffold.
- Use the target language's ordinary comment syntax and match the repository's indentation and line-length conventions.
- Prefix every inserted comment with `ARTISAN:` so the scaffold is easy to find and remove. Add short stable step numbers when ordering or dependencies matter, such as `ARTISAN 2:`.
- Never hide solution code in comments. Avoid copy-ready pseudocode, exact expressions, complete queries, or full algorithms. Describe intent, constraints, and observable behavior while leaving implementation decisions that teach or exercise the human.
- Do not use vague placeholders such as `implement this` or narrate obvious syntax. Each comment must earn its location.

## Build the Scaffold

For each implementation location, write the smallest actionable comment that captures the relevant subset of:

- the behavior to add or change and why it belongs there;
- inputs, outputs, state transitions, and invariants;
- existing types, helpers, conventions, or neighboring symbols to reuse;
- failure modes, validation, permissions, concurrency, cleanup, and edge cases that actually apply;
- tests or observable acceptance criteria that will prove the step is complete;
- dependencies on other numbered Artisan steps.

Prefer several local comments at the exact decision points over one large design essay. Avoid repeating shared context; point later steps to the first numbered step when appropriate.

If the request is ambiguous, choose a conservative design that fits existing patterns. Ask the user only when competing interpretations would place comments in materially different files or prescribe incompatible behavior.

## Verify and Hand Off

Review the final diff and confirm every changed line is a comment-only addition unless the user explicitly authorized replacing a prior Artisan scaffold. Run a narrow formatter, parser, or lint check only when comments can affect validity or repository rules make the check clearly relevant.

Report:

- the files annotated and the purpose of each insertion;
- the recommended implementation order when steps depend on one another;
- unresolved decisions the human must make;
- that no implementation or runtime behavior was changed.
