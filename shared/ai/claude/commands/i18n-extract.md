# i18n String Extraction — Vue 3 + vue-i18n

Extract all hardcoded UI strings from a Vue 3 app into `vue-i18n` locale files, wire locale from backend, and set up Spanish as a placeholder locale.

Target app: $ARGUMENTS (default: current working directory)

---

## Phase 0 — Audit

1. Confirm `vue-i18n` in `package.json`.
2. Find i18n instance file (`src/utils/i18n.ts` or `src/plugins/i18n.ts`).
   - Confirm `legacy: false`.
   - Confirm `i18n.global.locale` is a writable ref.
   - Note any sibling-package message merges — note their top-level key namespaces to avoid collision.
3. Find `src/lang/en.json` and `src/lang/es.json`. If empty `{}`, full extraction needed.
4. List all `.vue` files under `src/ui/` (or equivalent).
5. Grep for hardcoded strings not yet extracted:
   ```
   grep -r ">[A-Z]" src/ui --include="*.vue" -l
   ```

---

## Phase 1 — Wire Locale to Backend

### 1a. App data type
Add optional `language` field to the app data type class:
```ts
export type QAppData = {
  // existing fields...
  language?: string;
};
// Getter with fallback:
get language(): string { return this.appData.language ?? "en"; }
```

### 1b. Apply locale in init
In the main `continueInit()` / app boot function, after app data loads:
```ts
import i18n from "@/utils/i18n";
const lang = proxy.appData.language;
if (lang === "en" || lang === "es") {
  i18n.global.locale.value = lang;
}
```

### 1c. Dev mock fixture
Add `language: "en"` as the first key of the MirageJS/mock fixture object.

---

## Phase 2 — Build en.json

Use a single top-level namespace matching the app abbreviation (e.g. `rm`, `mc`, `qb`) to avoid collision with sibling package keys.

```json
{
  "<ns>": {
    "common": { "cancel": "Cancel", "ok": "Ok", "save": "Save" },
    "alert": { "oops": "Oops!", "error": "Error" },
    "<feature>": { "<key>": "<value>" }
  }
}
```

**Grouping rules:**
- Shared strings across components → `<ns>.common.*`
- Alert/modal strings → `<ns>.alert.*`
- Per-feature/component strings → `<ns>.<feature>.*`
- Named interpolation for dynamic values: `"deleteItem": "Delete \"{name}\"?"`
- Plural form: `"items": "{count} item | {count} items"`

**String patterns:**

| Type | en.json value | Template | Script |
|------|--------------|----------|--------|
| Static | `"Save"` | `{{ $t('ns.x.key') }}` | `t('ns.x.key')` |
| Interpolated | `"Hello {name}"` | `$t('ns.x.key', { name })` | `t('ns.x.key', { name })` |
| Plural | `"{n} item \| {n} items"` | `$t('ns.x.key', { n }, count)` | `t('ns.x.key', { n }, count)` |
| Attribute | `"Search..."` | `:placeholder="$t('ns.x.key')"` | — |

---

## Phase 3 — Extract Per Component

Work through each `.vue` file one at a time.

### Template
```html
<!-- Before -->
<span>Cancel</span>
<input placeholder="Search..." />

<!-- After -->
<span>{{ $t('ns.common.cancel') }}</span>
<input :placeholder="$t('ns.search.placeholder')" />
```

### Script
```ts
import { useI18n } from "vue-i18n";
const { t } = useI18n();
```

**Arrays that call `t()` must be `computed`:**
```ts
// Wrong — t() called outside composition context
const tabs = [{ label: t('ns.tabs.all') }];

// Correct
const tabs = computed(() => [{ label: t('ns.tabs.all') }]);
```

**Type cast when `t()` feeds a literal union parameter:**
```ts
const type = isAssignment
  ? t('ns.x.assignment') as "Assignment"
  : t('ns.x.lesson') as "Lesson";
```

**Do NOT translate:**
- Strings passed as API/backend parameters (e.g. `"Assignment"` in a REST call)
- Strings embedded in data format values (e.g. `"0-0min"` parsed server-side)
- `console.log` / debug strings
- `switch` case keys that match backend enum values

---

## Phase 4 — Build es.json

Copy `en.json` verbatim to `es.json`. Values stay English (placeholder pass — real translation is a separate pass).

Verify key parity:
```bash
node -e "
  const en = JSON.stringify(require('./src/lang/en.json'));
  const es = JSON.stringify(require('./src/lang/es.json'));
  const count = s => (s.match(/\":/g)||[]).length;
  console.log('en:', count(en), '| es:', count(es), '| match:', count(en) === count(es));
"
```

---

## Phase 5 — Verify

1. `npm run typecheck` — zero errors.
2. `npm run build` — clean build.
3. Dev server with `language: "en"` in mock — UI looks identical to before extraction.
4. Change mock to `language: "es"`, reload — UI must look **identical** to English. Any raw `ns.x.key` path visible means a key is missing from es.json.
5. Grep sweep for remaining hardcoded strings:
   ```bash
   grep -rn ">[A-Z][a-z]" src/ui --include="*.vue"
   grep -rn "= \"[A-Z]" src/ui --include="*.vue"
   ```
6. Revert mock back to `language: "en"` before committing.

---

## Phase 6 — Commit

Stage all modified `.vue` files, `en.json`, `es.json`, the app data type file, and the mock fixture. Commit with message:
```
feat: introduce i18n infrastructure with full string extraction
```

---

## Common Gotchas

| Problem | Fix |
|---------|-----|
| Static array uses `t()` → blank or stale values | Wrap in `computed(() => [...])` |
| `t()` assigned to literal union param → TS error | Add `as "TypeA" \| "TypeB"` cast |
| HTML in translation string | Use `v-html="$t('key')"` — sanitize if user-controlled |
| Sibling package key collision | Namespace all keys under app abbreviation |
| Missing key in es.json shows raw key path | Add missing key to es.json, re-run parity check |
| `i18n.global.locale` appears read-only | Confirm `legacy: false` in i18n instance creation |
