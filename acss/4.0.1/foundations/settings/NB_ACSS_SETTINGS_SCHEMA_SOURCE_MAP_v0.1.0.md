# NB-000 F01 — ACSS 4.0.1 Settings Schema Source Map

**Document:** `NB_ACSS_SETTINGS_SCHEMA_SOURCE_MAP_v0.1.0.md`  
**Version:** 0.1.0  
**Status:** Research (ready for review)  
**Paired spec:** `NB_ACSS_SETTINGS_SCHEMA_SPEC_v0.1.0.md`  
**Machine map:** `acss-settings-map.json`  
**Reference root:** `reference/acss/4.0.1/plugin/`

Every material finding below is independently verifiable from the cited path/symbol.

Confidence: `CONFIRMED` | `INFERRED` | `UNRESOLVED` | `CONTRADICTORY`

---

## Finding index

| ID | Finding | Evidence path | Symbol / setting | Supporting evidence | Confidence | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| F01-001 | Settings are declared in per-screen UI JSON files indexed by `ui.json` | `config/ui.json`, `config/ui/*.json` | `screens[]` | `Model/Config/UI.php` loads each screen via `UI_Screen` | CONFIRMED | Canonical declaration locus |
| F01-002 | Screen JSON validated by draft-07 screen schema | `config/ui/screen.schema.json` | `$id` `.../screen.json` | Input/container definitions; `displayWhen`; `cssVariable` | CONFIRMED | |
| F01-003 | UI shell schema requires screens + globals | `config/ui.schema.json` | `screens`, `globals` | `UI::load()` throws if missing/empty | CONFIRMED | |
| F01-004 | Framework inventory is a separate schema/layer | `config/framework.schema.json`, `config/framework.json` | `categories`, `condition` | Conditions reference setting IDs | CONFIRMED | Not the settings declaration store |
| F01-005 | Feature flags are a separate JSON store | `config/flags.json` | e.g. `ADD_DEFAULTS_TO_SAVE_PROCESS` | `Helpers/Flag.php` | CONFIRMED | Not inside settings option |
| F01-006 | `features.json` lists product features for docs/marketing | `config/features.json` | feature objects | No settings-id schema coupling found | INFERRED | No loader treats it as settings schema |
| F01-007 | Config files load through `Base::load()` | `classes/Model/Config/Base.php` | `load()` | Filter `acss/config/{filename}` | CONFIRMED | Allows programmatic injection |
| F01-008 | `UI_Screen` maps name → `ui/{name}.json` | `classes/Model/Config/UI_Screen.php` | `__construct($screen)` | Used by `UI::load()` | CONFIRMED | |
| F01-009 | `UI::get_all_settings()` flattens nested tree | `classes/Model/Config/UI.php` | `get_all_settings`, `parse_data` | Containers recurse; settings keyed by `id` | CONFIRMED | Injects hidden `timestamp` |
| F01-010 | Persisted setting types exclude `clone` | `classes/Model/Config/UI.php` | `is_setting()` | Enum omits `clone` | CONFIRMED | Schema still allows clone UI nodes |
| F01-011 | Color controls expand into many settings at flatten time | `classes/Model/Config/UI.php` | `handle_color`, `add_color_settings`, `handle_color_shades` | OKLCH + HSL shades + `option-*` toggles | CONFIRMED | Pattern in map `runtime_color_expansion` |
| F01-012 | Shade lightness defaults come from `ui.json` globals | `config/ui.json` | `globals.color.shades` | Custom maps in `get_shades_map()` for shade/neutral/status | CONFIRMED | |
| F01-013 | Calculated variable groups declare setting→token recipes | `config/ui.json` | `globals.calculatedVariableGroups` | Types: `clamp`, `simple-clamp`, `simple-scale` | CONFIRMED | Formula depth → F02/F03 |
| F01-014 | Settings persist in WP option `automatic_css_settings` | `classes/Model/Database_Settings.php` | `ACSS_SETTINGS_OPTION` | `get_vars` / `save_settings` | CONFIRMED | |
| F01-015 | Save allows only keys from `UI::get_all_settings()` | `classes/Model/Database_Settings.php` | `save_settings` | Unknown form keys ignored | CONFIRMED | |
| F01-016 | Defaults applied on save when flag on | `classes/Model/Database_Settings.php`, `config/flags.json` | `ADD_DEFAULTS_TO_SAVE_PROCESS` | `get_validated_setting` | CONFIRMED | Flag default `on` |
| F01-017 | Backend validation optional / off by default | `classes/Model/Database_Settings.php`, `config/flags.json` | `ENABLE_BACKEND_VALIDATION` | Type/range checks when on | CONFIRMED | |
| F01-018 | Generation uses setting metadata + DB values | `classes/Framework/Core/Core.php` | `get_framework_variables` | Calls transformers | CONFIRMED | |
| F01-019 | SCSS variable key defaults to setting ID | `classes/Framework/Core/Core.php` | `process_main_variables` | `$options['variable']` override supported | CONFIRMED | No `variable` keys in shipped UI JSON |
| F01-020 | `UnitTransformer` implements px/10, %, percentage-convert, appendunit | `classes/Framework/Generation/Transformers/UnitTransformer.php` | `transform`, `append_unit`, `get_unit` | `DEFAULT_ROOT_FONT_SIZE=62.5` | CONFIRMED | Handoff F02/F03 |
| F01-021 | `CssVarTransformer` wraps `--*` strings in `var()` | `classes/Framework/Generation/Transformers/CssVarTransformer.php` | `maybe_transform` | | CONFIRMED | |
| F01-022 | `ColorTransformer` expands hex colors to HSL/RGB/hex components | `classes/Framework/Generation/Transformers/ColorTransformer.php` | `transform` | Strips `color-` prefix | CONFIRMED | |
| F01-023 | `ScaleFallbackTransformer` maps zero scales to `*-custom` | `classes/Framework/Generation/Transformers/ScaleFallbackTransformer.php` | `SCALE_FALLBACKS` | text/heading/space × mob/desk | CONFIRMED | |
| F01-024 | `DependentColorTransformer` second-pass for form colors | `classes/Framework/Generation/Transformers/DependentColorTransformer.php` | `f-focus-color`, `f-input-placeholder-color` | | CONFIRMED | |
| F01-025 | `skip-css-var` skips generation entirely | `classes/Framework/Core/Core.php` | `should_skip_variable` | 6 UI settings use the flag | CONFIRMED | Admin/options style settings |
| F01-026 | `displayWhen` / `displayWhenOr` defined in screen schema | `config/ui/screen.schema.json` | `elements.displayWhen*` | AND vs OR descriptions | CONFIRMED | Pair = `[id, value]` or list of pairs |
| F01-027 | Framework conditions reference setting IDs | `config/framework.json` | `condition.setting` | 59 unique setting refs in map | CONFIRMED | Inventory gating |
| F01-028 | Dashboard preview CSS var = `cssVariable ?? --{id}` | `classes/Framework/Dashboard/js/assets/Main-CrhxTgP-.js` | `cssVariable` | Minified setting constructor | CONFIRMED | Often ≠ `--{id}` |
| F01-029 | Many `cssVariable` values are remaps or bare property names | `config/ui/typography.json` et al. | e.g. `heading-font-family` → `font-family` | Map stats: 777 differ, 27 match `--id` | CONFIRMED | Preview channel ≠ SCSS key |
| F01-030 | Import/export dumps settings JSON without version field | `classes/UI/Settings_Page/Import_Export.php` | `json_encode($settings)` | Defaults in hidden textarea | CONFIRMED | |
| F01-031 | Plugin DB version stored separately | `classes/Lifecycle/UpdateManager.php` | `automatic_css_db_version` | Compared to `Plugin::get_plugin_version()` | CONFIRMED | Export cannot self-identify version |
| F01-032 | Dashboard receives version separately from settings | `classes/Framework/Dashboard/Dashboard.php` | `'version' => Plugin::get_plugin_version()` | Alongside `ui_settings` | CONFIRMED | |
| F01-033 | Legacy renames in migrations | `classes/Migrations/Versions/Migration_*.php` | e.g. `migrate_renamed_settings` | 113 rename-like pairs extracted into map | CONFIRMED | Historical aliases |
| F01-034 | Migrations registered on `Database_Settings` | `classes/Model/Database_Settings.php` | `create_migration_runner` | 2.0.0 → 4.0.1-beta.1 | CONFIRMED | |
| F01-035 | Generation orchestrator is CSS entrypoint | `classes/CSS_Engine/GenerationOrchestrator.php` | `generate` | Filter `automaticcss_generate_css` | CONFIRMED | Depth → F03 |
| F01-036 | Utility expansions have own schema | `config/utility-expansions/expansions.schema.json` | expansions JSON | Adjacent to settings, not declarations | CONFIRMED | Handoff F04/D19 |
| F01-037 | Toggle `control` array can force other settings | `config/ui/screen.schema.json` | `control[].target/value` | No instances in 4.0.1 UI JSON | CONFIRMED | Capability unused in ship |
| F01-038 | `percentage-convert` present on fluid base sizes | e.g. `config/ui/spacing.json` `base-space` | `percentage-convert: true` | Consumed by UnitTransformer | CONFIRMED | |
| F01-039 | Explicit `unit: "px"` rare; type often encodes unit | `config/ui/typography.json` | `base-heading-desk` | UnitTransformer `get_unit` | CONFIRMED | |
| F01-040 | `appendunit: "rem"` used for some breakpoints | `config/ui/options.json` / buttons | e.g. `auto-staggered-grid-breakpoint` | After CSS-var wrap | CONFIRMED | |
| F01-041 | Message nodes are UI copy, not settings | `config/ui/screen.schema.json` | `type: message` | Excluded by `is_setting` | CONFIRMED | |
| F01-042 | Container IDs are not persistence keys | UI JSON trees | accordion/section ids | Only input ids flattened | CONFIRMED | |
| F01-043 | Color UI ids in palette lack `color-` prefix | `config/ui/palette.json` | `id: "primary"` | PHP builds `color-primary` | CONFIRMED | |
| F01-044 | `get_default_settings` omits keys without `default` | `classes/Model/Config/UI.php` | `get_default_settings` | | CONFIRMED | |
| F01-045 | Flag override layers documented in Flag + CLI | `classes/Helpers/Flag.php`, `CLI/Flags_Command.php` | prod/dev/user | Unknown override keys ignored | CONFIRMED | |
| F01-046 | Client-side displayWhen evaluator details | dashboard minified JS | — | Schema shapes confirmed; full evaluator not fully mapped | UNRESOLVED | Does not block schema map |
| F01-047 | Exhaustive expanded color setting ID list | `UI.php` expansion | all shades × channels | Pattern confirmed; full cartesian not dumped | UNRESOLVED | Expand mechanically if needed |
| F01-048 | Emitted CSS custom property per setting in compiled CSS | SCSS templates under `assets/scss` | — | Requires F04 token pass | UNRESOLVED | F01 maps declaration + transformers only |
| F01-049 | `cssVariable` vs SCSS key dual-channel | schema text vs `Core.php` | `cssVariable` / setting id | Preview vs generation | CONFIRMED | Documented as distinction, not contradiction |
| F01-050 | Site-level `acss/config/*` filters may add settings | `Base::load` filter | `acss/config/{filename}` | None in reference tree | UNRESOLVED | Runtime extensibility |

---

## Evidence clusters

### A. Declaration & schema

- `config/ui.json`
- `config/ui.schema.json`
- `config/ui/screen.schema.json`
- `config/ui/*.json` (18 screens)
- `config/framework.schema.json`
- `config/flags.json`

### B. Runtime model

- `classes/Model/Config/{Base,UI,UI_Screen}.php`
- `classes/Model/Database_Settings.php`
- `classes/Model/SettingsRepositoryInterface.php`

### C. Generation boundary

- `classes/Framework/Core/Core.php`
- `classes/Framework/Generation/Transformers/*.php`
- `classes/CSS_Engine/GenerationOrchestrator.php`

### D. Versioning & aliases

- `classes/UI/Settings_Page/Import_Export.php`
- `classes/Lifecycle/UpdateManager.php`
- `classes/Migrations/Versions/*.php`

### E. Dashboard preview

- `classes/Framework/Dashboard/Dashboard.php`
- `classes/Framework/Dashboard/js/assets/Main-*.js`

---

## How to verify the machine map

1. Parse `acss-settings-map.json` (JSON).
2. Confirm `meta.counts.ui_declared_inputs` equals unique input IDs walked from `config/ui/*.json`.
3. Spot-check records (e.g. `base-space`, `color` palette entries, `skip-css-var` options).
4. Confirm `legacy_aliases` entries cite migration files that still contain the `from` → `to` pairs.
5. Confirm transformer paths exist under `classes/Framework/Generation/Transformers/`.

---

## Provenance for bulk settings

Each element of `acss-settings-map.json` → `settings[]` carries:

```text
source_evidence.path = reference/acss/4.0.1/plugin/config/ui/{screen}.json
source_evidence.setting_id
source_evidence.ancestry_ids
confidence
```

Bulk extraction is mechanical from the reference JSON; confidence for field presence is **CONFIRMED** when the field exists in the source object. Runtime-only color expansions are described under `runtime_color_expansion` rather than fabricated per-shade rows.
