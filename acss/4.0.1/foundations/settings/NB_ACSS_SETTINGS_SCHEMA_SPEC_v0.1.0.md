# NB-000 F01 — ACSS 4.0.1 Settings Schema Spec

**Document:** `NB_ACSS_SETTINGS_SCHEMA_SPEC_v0.1.0.md`  
**Version:** 0.1.0  
**Status:** Research (ready for review)  
**Task:** F01 — Settings Schema  
**Source product:** Automatic.css 4.0.1  
**Reference root:** `reference/acss/4.0.1/plugin/`  
**Machine map:** `acss-settings-map.json`  
**Source map:** `NB_ACSS_SETTINGS_SCHEMA_SOURCE_MAP_v0.1.0.md`  
**Authority:** Evidence about ACSS behaviour only. Not NovaBase design law.

---

## 1. Scope

This specification describes how Automatic.css 4.0.1 **declares, stores, conditions, transforms, and relates** dashboard settings.

In scope:

- layered config schemas under `config/`;
- UI screen/input model;
- runtime flattening and color expansion;
- defaults, units, conditions, dependencies;
- feature flags vs settings;
- setting ID → SCSS variable / CSS custom property relationships where traceable;
- transformers that touch setting values before SCSS injection;
- legacy migration aliases;
- export/version identification;
- handoffs to F02–F04 and later domains.

Out of scope (handoffs):

- full formula mathematics (F02);
- complete compilation/pipeline ordering and caching (F03);
- full token/naming taxonomy across utilities/components (F04);
- domain-specific value semantics (D01–D19).

---

## 2. Summary

**CONFIRMED:** ACSS settings are not a single flat schema file. They are a **layered configuration system**:

1. **Dashboard shell** — `config/ui.json` lists screens and carries globals (color shades, calculated variable groups).
2. **Screen declarations** — `config/ui/{screen}.json` nested trees of containers + inputs (validated by `screen.schema.json`).
3. **Runtime flattening** — `Automatic_CSS\Model\Config\UI::get_all_settings()` walks the tree into a flat `setting_id => metadata` map used for save validation and CSS generation.
4. **Persistence** — WordPress option `automatic_css_settings` via `Database_Settings`.
5. **Generation path** — `Core::get_framework_variables()` applies transformers, then injects values as SCSS variables keyed primarily by setting ID.
6. **Adjacent inventories** — `framework.json` (class/var cheat-sheet conditioned on settings), `flags.json` (feature flags), utility expansions.

**CONFIRMED count (UI-declared inputs):** 1599 unique input IDs across 18 screens listed in `ui.json` (see `acss-settings-map.json` meta.counts). Color UI controls additionally expand into many runtime settings (OKLCH/HSL shades + option toggles) that are **not** written as separate JSON inputs.

---

## 3. Relevant inputs / settings

### 3.1 Canonical declaration locus

| Layer | Path | Role |
| --- | --- | --- |
| Screen index | `config/ui.json` | `screens[]`, `globals` |
| Screen bodies | `config/ui/*.json` | Nested containers + inputs |
| Screen schema | `config/ui/screen.schema.json` | Input/container contracts |
| UI shell schema | `config/ui.schema.json` | Screens + globals shape |
| Framework inventory | `config/framework.json` + `framework.schema.json` | Classes/vars gated by setting conditions |
| Feature flags | `config/flags.json` | Behaviour gates (not design settings) |
| Features marketing | `config/features.json` | Feature blurbs; **not** setting declarations |

**CONFIRMED:** Loader chain is `UI` → `UI_Screen` (`ui/{name}.json`) via `Base::load()` reading `ACSS_CONFIG_DIR`.

### 3.2 Control types (screen schema)

Schema enum: `text`, `textarea`, `px`, `percent`, `number`, `rem`, `color`, `select`, `toggle`, `clone`, `codebox`.

Observed UI-declared distribution (4.0.1): heavily `text` (1141), then `toggle` (180), `select` (136), `textarea` (72), `px` (41), `number` (12), `color` (10), `clone` (5), `codebox` (1), `percent` (1). **No `rem` typed inputs** appear in the shipped UI JSON (schema still allows them).

**CONFIRMED:** `UI::is_setting()` treats as persisted settings: `text`, `textarea`, `select`, `toggle`, `color`, `number`, `px`, `rem`, `percent`, `codebox`. **`clone` is excluded** — UI-only construct for cloning another component by `target`.

Runtime-only types produced by color expansion include `color-oklch` and expanded `number` shade components (not in screen schema enum).

### 3.3 Screens

Order from `ui.json`: palette, backgrounds-text, color-scheme, typography, layout, spacing, buttons-links, surfaces-overlays, borders-dividers, shadows, cards, icons, additional-styling, animations, form-styling, custom-css, options, cheat-sheet.

Each screen file is a `screen-container` with `id`, `title`, nested `content`.

---

## 4. Structures / functions

### 4.1 Container hierarchy

Containers (schema): `section-container`, `accordion-container`, `tabs-container`, `tab`, `two-columns-container`, `select-container`, `hover-container`, `double-input`, `cheat-sheet-container`.

**CONFIRMED:** Hierarchy encodes UI grouping only. Persistence keys are **input `id`s**, not container IDs.

### 4.2 Key PHP structures

| Symbol | Path | Role |
| --- | --- | --- |
| `UI` | `classes/Model/Config/UI.php` | Load screens; flatten; defaults; color expansion |
| `UI_Screen` | `classes/Model/Config/UI_Screen.php` | Load one `ui/{screen}.json` |
| `Base` | `classes/Model/Config/Base.php` | JSON file load + `acss/config/{filename}` filter |
| `Database_Settings` | `classes/Model/Database_Settings.php` | Persist/validate/save; trigger generation |
| `Core` | `classes/Framework/Core/Core.php` | Settings → framework SCSS variables |
| `GenerationOrchestrator` | `classes/CSS_Engine/GenerationOrchestrator.php` | Generation entry (F03 owns depth) |
| `Flag` | `classes/Helpers/Flag.php` | Feature-flag store |
| `Import_Export` | `classes/UI/Settings_Page/Import_Export.php` | Raw settings JSON import/export UI |
| `UpdateManager` | `classes/Lifecycle/UpdateManager.php` | `automatic_css_db_version` |
| Migrations | `classes/Migrations/Versions/*` | Legacy renames / value migrations |

### 4.3 Dashboard frontend

Compiled dashboard bundle (`classes/Framework/Dashboard/js/assets/Main-*.js`) resolves preview CSS variables as `cssVariable ?? \`--${id}\``.

---

## 5. Transformations

Pipeline **CONFIRMED** in `Core::process_main_variables()` (non-dependent vars):

```text
UI metadata + DB values
  → skip if skip-css-var / dependent reserved / missing non-empty default
  → value = DB[id] ?? default
  → filter automaticcss_input_value_{id}
  → skip if skip-if-empty and value === ''
  → rename key if options.variable set (unused in shipped UI JSON)
  → if type===color: ColorTransformer → component vars; continue
  → ScaleFallbackTransformer (scale ids only)
  → UnitTransformer.get_unit + transform
  → CssVarTransformer.maybe_transform
  → UnitTransformer.append_unit
  → maybe_wrap_in_quotes (output: quotes)
  → filter automaticcss_output_value_{id}
```

Second pass: `DependentColorTransformer` for `f-focus-color`, `f-input-placeholder-color`.

### 5.1 UnitTransformer (summary)

| Rule | Behaviour |
| --- | --- |
| Unit source | `options.unit` else type `px`/`rem`/`percent`→`%` |
| `px` | `floatval(value) / 10` (unless `skip-unit-conversion`) |
| `%` | append `%` if missing |
| `percentage-convert` | scale by `62.5 / root-font-size` (`DEFAULT_ROOT_FONT_SIZE`) |
| `appendunit` | concatenate after CSS-var wrap |

**HANDOFF F01→F02/F03:** Exact rem semantics, root-font coupling, and SCSS consumption of transformed values belong to F02/F03.

### 5.2 Color expansion (before generation)

`UI::handle_color()` replaces a palette color control with:

- `color-{name}`, `color-{name}-alt` (+ OKLCH channel settings);
- shade HSL and OKLCH component settings for `ultra-light`…`hover`;
- `option-{name}-*` toggles (clr / clr-alt / trans variants) with coded defaults.

Shade lightness comes from `ui.json` `globals.color.shades`, with custom maps for `shade`/`neutral` and status colors.

**HANDOFF F01→D10 / F02:** OKLCH/HSL shade maths and palette generation belong to color domain + formulas.

---

## 6. Formulas / behaviour

### 6.1 Defaults

- Declared on inputs via `default` (schema: string | boolean | number; toggles use `"on"`/`"off"`).
- `UI::get_default_settings()` returns only keys that have a `default` key after flattening/expansion.
- Save path: if flag `ADD_DEFAULTS_TO_SAVE_PROCESS` is on, missing submitted values fall back to defaults (`Database_Settings::get_validated_setting`).
- Backend validation gated by `ENABLE_BACKEND_VALIDATION` (default **off** in `flags.json`).

### 6.2 Units

Units are expressed by:

1. control type (`px`, `rem`, `percent`);
2. explicit `unit` (rare; e.g. some typography bases);
3. `appendunit` (e.g. `rem` after px transform for breakpoints);
4. runtime shade `appendunit: '%'` for HSL s/l.

Most `text` settings carry unitless or already-suffixed string defaults (e.g. `var(--text-dark)`, `1.5rem`).

### 6.3 Conditions

| Mechanism | Where | Logic |
| --- | --- | --- |
| `displayWhen` | UI inputs/containers | AND of `[settingId, value]` pairs |
| `displayWhenOr` | UI inputs/containers | OR of pairs |
| `condition` | `framework.json` | `{type: "="|"!=", setting, value}` for inventory items |
| `environment.include/exclude` | UI containers | Environment gating (builder contexts) |

**INFERRED:** `displayWhen*` primarily affects dashboard visibility; generation skip logic uses `skip-css-var`, emptiness, and defaults — not a direct re-evaluation of `displayWhen` in `Core`. Domain agents should not assume hidden settings are omitted from CSS unless other skip flags apply.

### 6.4 Dependencies

Dependency kinds observed:

1. **Conditional display** — `displayWhen` / `displayWhenOr` reference other setting IDs.
2. **Toggle `control`** — schema supports forcing other settings’ values (no instances observed in 4.0.1 UI JSON).
3. **Calculated groups** — `ui.json` `globals.calculatedVariableGroups` map calculation recipes to setting IDs (`baseValueSetting`, `mobileBaseValueSetting`, etc.).
4. **Scale fallbacks** — `ScaleFallbackTransformer` couples `*-scale` → `*-scale-custom`.
5. **Dependent colors** — form focus/placeholder colors derive HSL from referenced palette components.
6. **Framework inventory conditions** — 59 distinct setting IDs gate class/var entries in `framework.json`.

### 6.5 Feature flags

`flags.json` defaults include logging, dashboard script loading, `ADD_DEFAULTS_TO_SAVE_PROCESS=on`, `ENABLE_BACKEND_VALIDATION=off`, etc.

Loaded by `Flag::init()` with override layers: prod → optional `flags.dev.json` → optional uploads `flags.user.json` (unknown keys ignored).

**CONFIRMED:** Flags are **not** stored inside `automatic_css_settings`.

---

## 7. Outputs

| Output | Mechanism |
| --- | --- |
| Persisted settings bag | WP option `automatic_css_settings` |
| SCSS framework variables | Setting ID (or `options.variable`) → transformed value map from `Core::get_framework_variables()` |
| Dashboard live CSS vars | `cssVariable` or `--{id}` applied to `target` (default `body` per schema) |
| Toggle CSS classes | `cssClasses` on `target` |
| Custom SCSS file | `custom-global-css` / related custom path via Core hooks |
| Cheat-sheet / inventory | `framework.json` conditioned lists |
| Import/export textarea | Raw JSON of settings values (no embedded schema version) |

### 7.1 Setting ID vs CSS variable

**CONFIRMED distinction:**

- **SCSS injection key** ≈ setting `id` (unless unused `variable` override).
- **Dashboard `cssVariable`** ≈ preview custom property; often `--something-else`, and sometimes a **bare CSS property name** (e.g. `font-family`) for contextual preview — not always a `--*` token.

Of UI-declared inputs with `cssVariable` set: majority differ from `--{id}`.

**HANDOFF F01→F04:** Canonical token naming across generated CSS custom properties vs setting IDs needs F04 tracing through SCSS templates.

---

## 8. Dependencies

F01 itself depends on no other foundation tasks.

Downstream consumers that **must inherit** F01 facts rather than rediscover them:

| Consumer | Inherit |
| --- | --- |
| F02 | Which settings feed scales/clamps; unit/`percentage-convert` flags; color expansion inputs |
| F03 | Transformer chain; skip flags; `Core`/`GenerationOrchestrator` boundary; save→generate hook |
| F04 | ID vs `cssVariable` vs SCSS key; framework inventory naming |
| D01–D19 | Screen/setting IDs, defaults, conditions, group membership from `acss-settings-map.json` |

---

## 9. Consumers

- Dashboard (`Dashboard.php` loads full UI tree + plugin version separately).
- Save/validation (`Database_Settings::save_settings`).
- CSS generation (`GenerationOrchestrator` → `Core`).
- CLI settings/status/doctor commands.
- Migrations on upgrade (`automaticcss_upgrade_database`).
- Integrations implementing `InjectsScssVariableInterface` (F03/F04 for depth).

---

## 10. Edge cases

1. **Color UI id ≠ persisted id** — palette JSON uses `id: "primary"`; persisted keys become `color-primary`, shade keys, `option-primary-*`.
2. **Hidden `timestamp`** — injected in `get_all_settings()`.
3. **Empty defaults** — variables without non-empty default may be skipped in generation if absent from DB.
4. **`skip-css-var: true`** — options/admin settings never enter SCSS var map (6 UI instances).
5. **`output: "quotes"`** — string values wrapped for SCSS.
6. **Export without version** — cannot reliably identify export source version from settings JSON alone.
7. **Schema vs runtime** — dashboard may create additional color-related settings client-side; PHP expansion is the save/generation authority for allowed keys.

---

## 11. Unknowns / contradictions

### UNRESOLVED

1. Exact client-side evaluation rules for every `displayWhen` variant in the minified dashboard bundle (pair shapes confirmed in schema; runtime evaluator not fully decompiled).
2. Whether any `options.variable` overrides exist via `acss/config/*` filters in production sites (none in shipped UI JSON).
3. Complete list of runtime-expanded color setting IDs for all palette colors × shades × channels (pattern **CONFIRMED**; exhaustive enumeration left as mechanical expansion of the documented pattern if a fixture requires it).
4. Full SCSS template mapping from each setting ID to emitted `--*` CSS custom properties (F04).

### CONTRADICTORY

None material between JSON schema and PHP loaders for core contracts. Minor tension:

- Screen schema documents `cssVariable` as “custom CSS variable name to use instead of the id”, while generation uses setting `id` (or `variable`) for SCSS keys — **dashboard preview vs generation** are different channels (**CONFIRMED** distinction, not a data conflict).

### INFERRED

- `features.json` is marketing/docs content, not an executable settings schema (structure and lack of loader coupling support this).

---

## 12. Test vectors

Deterministic structural vectors (no CSS pixel output claimed):

| Case | Input | Expected |
| --- | --- | --- |
| Flatten uniqueness | All `config/ui/*.json` inputs | 1599 unique IDs; zero duplicate IDs |
| UnitTransformer px | value `30`, unit `px`, no skip | `3` (30/10) before append |
| UnitTransformer percentage-convert | value `30`, convert true, root 62.5 | `30` unchanged vs default root |
| Scale fallback | `space-scale=0`, custom present | uses `space-scale-custom` |
| CssVarTransformer | `"--primary"` | `"var(--primary)"` |
| Clone persistence | type `clone` | excluded from `UI::is_setting` |
| Export shape | Import_Export render | `json_encode(get_vars())` without version field |

Fixture file: the machine map `acss-settings-map.json` itself is the primary structural fixture. Formula numeric fixtures belong to F02.

---

## 13. Candidate cross-domain implications

### HANDOFF F01→F02

- Document `UnitTransformer`, color OKLCH/HSL expansion defaults, and `calculatedVariableGroups.calculationType` (`clamp`, `simple-clamp`, `simple-scale`) as shared primitives.
- Scale/music-scale UI (`musicScale`) is input affordance only; ratio maths elsewhere.

### HANDOFF F01→F03

- Own full generate lifecycle, SCSS file writers, caching, hooks `automaticcss_generate_css`, `automaticcss_settings_after_save`.
- F01 records transformer existence and skip flags only.

### HANDOFF F01→F04

- Map setting IDs ↔ emitted CSS custom properties ↔ utility/class names.
- Reconcile `cssVariable` preview names with generated token names.

### HANDOFF F01→D01–D19

- Use `acss-settings-map.json` for IDs, defaults, screens, conditions, and `calculatedVariableGroups` membership.
- Do not re-parse UI JSON for existence questions already answered here.

---

## 14. Answers to required F01 questions

| Question | Answer (confidence) |
| --- | --- |
| Where canonically declared? | `config/ui/{screen}.json` (+ `ui.json` index); flattened by `UI` (**CONFIRMED**) |
| One schema or layered? | Layered: ui / screen / framework / expansions / flags (**CONFIRMED**) |
| Screens/groups/sections? | Nested container types under `screen-container` (**CONFIRMED**) |
| Defaults? | Input `default`; runtime color defaults; `get_default_settings()` (**CONFIRMED**) |
| Units? | Type + `unit`/`appendunit` + UnitTransformer (**CONFIRMED**) |
| Conditions? | `displayWhen`/`displayWhenOr`; framework `condition` (**CONFIRMED**) |
| Dependencies? | Display conditions, calculated groups, scale fallbacks, dependent colors (**CONFIRMED**) |
| Feature flags? | Separate `flags.json` store (**CONFIRMED**) |
| ID → internal vars? | Setting ID is SCSS key by default (**CONFIRMED**) |
| ID → CSS custom properties? | Preview via `cssVariable`; generated tokens need F04 (**CONFIRMED** / **UNRESOLVED** depth) |
| Transformers? | Unit, CssVar, Color, ScaleFallback, DependentColor (**CONFIRMED**) |
| Legacy aliases? | Migration rename maps (100+ pairs extracted) (**CONFIRMED**) |
| UI metadata vs generation-critical? | titles/tooltips/docs vs type/default/unit/skip*/output/cssVariable (**CONFIRMED**) |
| Export identify version? | **No** in settings JSON; separate `automatic_css_db_version` (**CONFIRMED**) |
| Inherit for F02–F04 / D01–D19? | Map + this spec’s architecture/transformer/alias sections (**CONFIRMED**) |

---

## 15. Completion notes

- Research only; no NovaBase implementation; `reference/` untouched.
- Manifest status not modified on this branch.
- Machine-readable inventory: `acss-settings-map.json`.
