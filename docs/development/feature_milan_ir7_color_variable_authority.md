# Feature Milan IR7 color variable authority

Status: proposed for owner review. This document freezes the R3 evidence dispositions and future implementation contract. It authorizes no production implementation, R4, R5, Behavior, Component, NativeGenerator work, or generation.

~~~text
TASK=FEATURE_MILAN_IR7_R3_COLOR_VARIABLE_AUTHORITY_FREEZE
BASE_SHA=5c4c307ef38c264dd0da41d23a907688df2f619e
BASE_TREE=e3c53f87d62a4c5b5cf34faf2112fe1658a73309
BASE_POST_MERGE_CI_RUN=41648772191
BASE_POST_MERGE_CI_RESULT=SUCCESS
R2_STATUS=ACCEPTED
R3A_STATUS=ACCEPTED
R3B_STATUS=ACCEPTED
R3C_STATUS=ACCEPTED_AS_EVIDENCE_INCOMPLETE

STATUS=PROPOSED_FOR_OWNER_REVIEW
IMPLEMENTATION_AUTHORIZED=NO
R4_AUTHORIZED=NO
R5_AUTHORIZED=NO
~~~

## 1. Governing authority and scope

The governing records are:

- [Feature Milan IR7 style remediation authority](feature_milan_ir7_style_remediation_authority.md)
- [Feature Milan IR7 R2 reconstruction record](feature_milan_ir7_design_document_reconstruction_record.md)
- [Automatic.css TokenSet adapter](../06_ACSS_TOKEN_ADAPTER.md)
- [Bricks adapter](../07_BRICKS_ADAPTER.md)

For an exact direct expression such as `var(--x)`, only these records establish direct ownership:

~~~text
DIRECT_OWNER_KINDS=source_output_alias,explicit_project_contract
source_reference=NOT_AN_OWNER
~~~

No direct owner is inferred from spelling, property, resolved-value equality, source occurrence, candidate order, or where a Milan occurrence appears. A source output alias is an Automatic.css output contract. A project contract must apply project-wide. No Milan-only project contract is proposed here.

This document freezes R3 only. The R2 reconstruction remains intermediate evidence, not a final IR7 DesignDocument identity. The existing R2 blocker table records all three color variables as unresolved.

## 2. Accepted evidence and provenance

Evidence paths under `danbricks/app/public/` are relative to the owner-controlled Local Site root. Paths under `private_reference/` are repository-relative. Hashes identify the inspected files; they do not grant redistribution rights. Only the narrow facts in this table are published.

| Evidence ID | Relative evidence path | SHA-256 | Fact used |
| --- | --- | --- | --- |
| ACSS_VERSION | `danbricks/app/public/wp-content/plugins/automatic-css/automatic-css.php` | `fbb07573733b46f941c49d69153d9c4797bb0bf686da4fbc2d6f8f32cdd14276` | Plugin metadata identifies Automatic.css 4.0.1. |
| CONTEXTUAL_GENERATOR | `danbricks/app/public/wp-content/plugins/automatic-css/assets/scss/modules/contextual-colors/_contextual-tokens.scss` | `6ef43c18e6ac854a3b96174a2786affe8da314ab33c026bfedcb4ff6b283c1ac` | Contextual outputs are guarded by `$option-contextual-color-variables == on`; the generator emits background and text variables from their respective contextual categories. |
| CONTEXTUAL_MAPS | `danbricks/app/public/wp-content/plugins/automatic-css/assets/scss/modules/contextual-colors/_contextual-maps.scss` | `312565b672a29142e226bb8c89c13a3c1a1bc7480ddedab9d7ded5142e8970c5` | `ultra-light` belongs to `background-colors`; `dark-muted` belongs to `text-colors`. |
| CONTEXTUAL_SOURCE_DEFAULTS | `danbricks/app/public/wp-content/plugins/automatic-css/assets/scss/modules/contextual-colors/_contextual-vars.scss` | `a851bf7c50e0bfe4b2f5700d6ca5379fef2faf6663db0848974ffb9574712d09` | Source variables are overrideable Sass defaults. The generator consumes the effective contextual settings. |
| CONTEXTUAL_UI_SETTINGS | `danbricks/app/public/wp-content/plugins/automatic-css/config/ui/backgrounds-text.json` | `de8b1fe9a668646d98bccd9aa0283efaadce671aee0e500d326b574924891e2b` | UI setting records include the background and text members and their defaults. The `text-dark-muted` setting is text-valued and overrideable. |
| FEATURE_GUARD_SETTING | `danbricks/app/public/wp-content/plugins/automatic-css/config/ui/options.json` | `a78f19ce976b12214767b21bab60a4e280cbd9674f47c8b5af90243c8105cd59` | The contextual-color variable feature is a toggle with default `on`. |
| STAGING_SETTINGS | `private_reference/frames/staging-2026-09/environment/acss-settings.json` | `3347240b2837dc28854020b0fa0f1d2100086d259123f8b964ac8f31114cad32` | The staging snapshot has the feature on, `bg-ultra-light=var(--neutral-ultra-light)`, and `text-dark-muted=color-mix(in srgb, var(--text-dark) 80%, transparent)`. |
| GENERATED_VARIABLES | `danbricks/app/public/wp-content/uploads/automatic-css/automatic-variables.css` | `34127351b41a2496c5be9a9f238aba2fcffd63dc8a790eefc8f03d6b3becd093` | Version header identifies 4.0.1. Lines 366 and 373 contain the exact generated declarations for `--bg-ultra-light` and `--text-dark-muted`, respectively. |
| GENERATED_OUTPUT_CONTROL_1 | `danbricks/app/public/wp-content/uploads/automatic-css/automatic.css` | `77823f526e62ae945c5e295ced9179aa75cfd6fb6dc797cfec1acbc50299b4b5` | Accepted 4.0.1 generated-output comparison; no conflicting declaration. |
| GENERATED_OUTPUT_CONTROL_2 | `danbricks/app/public/wp-content/uploads/automatic-css/automatic-core-for-block-editor.css` | `2c29b31bbaba284a29e35c9a8e37284dc4e3232e187532b8063f2ae47424f533` | Accepted 4.0.1 generated-output comparison; no conflicting declaration. |
| GENERATED_OUTPUT_CONTROL_3 | `danbricks/app/public/wp-content/uploads/automatic-css/automatic-core-for-iframe-editor.css` | `49d18b654600a861e6048fcfae14ed0c2a340a02a563ee953c81c737359e5ff1` | Accepted 4.0.1 generated-output comparison; no conflicting declaration. |
| MILAN_EXPORT | `private_reference/frames/staging-2026-09/feature-section-milan/bricks-component-ybsqrl-feature-section-milan.json` | `f906273e067b3f23f8cd9c2a675f18fcdba1e78e6f2fcb1a6480857487e65132` | Exact Feature Milan variable occurrences and their Bricks source records. |
| R2_RECONSTRUCTION | `docs/development/feature_milan_ir7_design_document_reconstruction_record.md` | `da4af1d91d9227235c655413b62bf0747e995142d13436e7c0be589b04a64a64` | R2 preserves all three source expressions as unresolved. |
| R3C_REFERENCE_SCOPE | `private_reference/REFERENCE_MANIFEST.md` | `d4679f25cc37f1a3441f8f9c3bbea7f53e9f7f308f591e5cb3b677a049f63314` | The accepted reference corpus does not provide the matching staging global-variable registry or custom-code/style export. |

The accepted ACSS 4.0.1 fixture is `fixtures/automatic_css/acss_settings.json`, SHA-256 `19279873614b172a409f008dd4ab3c4b620c551a4ac4c68bb3773f0209e33a05`. Repository architecture checks below refer to the base commit named above.

## 3. `--bg-ultra-light` authority

The ACSS 4.0.1 contextual generator maps source category `background-colors`, member `ultra-light`, and source key `bg-ultra-light` to the emitted output `--bg-ultra-light`. The exact output is guarded by `option-contextual-color-variables == on`. The accepted staging snapshot has that feature enabled and the effective setting/output value `var(--neutral-ultra-light)`.

~~~text
VARIABLE=--bg-ultra-light
SOURCE_VERSION=Automatic.css 4.0.1
SOURCE_KEY=bg-ultra-light
SOURCE_CATEGORY=background-colors
SOURCE_MEMBER=ultra-light
SOURCE_GENERATOR=contextual-color variable generator
FEATURE_GUARD=option-contextual-color-variables == on
OUTPUT_VALUE=var(--neutral-ultra-light)
SEMANTIC_OWNER_PROVEN=YES
CANONICAL_TOKEN_PATH=color.background.ultra_light
TOKEN_PATH_ALREADY_EXISTS=YES
DIRECT_OWNER_AUTHORITY_KIND=source_output_alias
DIRECT_OWNER_AUTHORIZED=YES
AUTHORITY_ID=automatic-css-4.0.1:contextual-color:bg:ultra-light
~~~

The chosen authority ID uses the repository convention of a versioned Automatic.css prefix and colon-delimited contract family. It identifies the contextual-color output family and the exact category/member. It is deterministic and distinct from setting-reference and calculated-variable-group IDs.

The source setting value references the neutral path. That value dependency remains:

~~~text
color.background.ultra_light
-> color.neutral.ultra_light
~~~

The emitted contextual-background variable remains owned by `color.background.ultra_light`. A value reference does not transfer direct ownership to `color.neutral.ultra_light`.

The native package boundary must map the canonical token:

~~~text
TOKEN_PATH=color.background.ultra_light
PACKAGE_VARIABLE=--lf-color-background-ultra-light
PACKAGE_MAPPING_REQUIRED=YES
PACKAGE_VARIABLE_COLLISION=NO
~~~

Before this authority was drafted, an exact fixed-string search of tracked files at `BASE_SHA` found no existing definition or use of `--lf-color-background-ultra-light`. This package mapping belongs to R3 because it is required by the R3 direct-variable owner result.

The existing TokenSet path is present. The direct-owner terminal still requires the token to exist, be resolved, and expose a supported CSS terminal. Missing or invalid source setting data remains unresolved through the existing fail-closed behavior.

## 4. `--text-dark-muted` authority

The ACSS 4.0.1 contextual generator maps source category `text-colors`, member `dark-muted`, and source key `text-dark-muted` to the emitted output `--text-dark-muted`, under the same contextual-color feature guard. The setting can be overridden. The inspected UI default and staging setting both contain the exact expression below. The only value form authorized by this R3 contract is that demonstrated form.

~~~text
VARIABLE=--text-dark-muted
SOURCE_VERSION=Automatic.css 4.0.1
SOURCE_KEY=text-dark-muted
SOURCE_CATEGORY=text-colors
SOURCE_MEMBER=dark-muted
SOURCE_GENERATOR=contextual-color variable generator
FEATURE_GUARD=option-contextual-color-variables == on
STAGING_SETTING_VALUE=color-mix(in srgb, var(--text-dark) 80%, transparent)
UI_SETTING_DEFAULT=color-mix(in srgb, var(--text-dark) 80%, transparent)
SETTING_OVERRIDEABLE=YES
SEMANTIC_OWNER_PROVEN=YES
DIRECT_OWNER_AUTHORITY_KIND=source_output_alias
DIRECT_OWNER_AUTHORIZED=YES
AUTHORITY_ID=automatic-css-4.0.1:contextual-color:text:dark-muted
~~~

The ACSS Sass fallback for an unset source value is not a second authorized R3 form. R3 authorizes the exact staging/UI expression above. Any differing effective setting, including a fallback that does not produce this expression, remains unresolved until separate authority accepts it. The authority does not permit arbitrary values merely because ACSS stores the setting as text.

### Canonical token and value contract

Freeze the new source-independent token path:

~~~text
NEW_CANONICAL_TOKEN_PATH=color.text.dark_muted
TOKEN_CATEGORY=color
PATH_NORMALIZATION=dark-muted -> dark_muted
~~~

This compound segment follows existing ACSS path normalization, including `ultra-light -> ultra_light` and `semi-dark -> semi_dark`. The existing repository naming authority does not establish `color.text.dark.muted`; that path is not used.

The exact semantic recipe is:

~~~text
TOKEN_PATH=color.text.dark_muted
SEMANTIC_RELATIONSHIP=bounded color mix of canonical color.text.dark with transparent
COLOR_SPACE=srgb
BASE_TOKEN_PATH=color.text.dark
BASE_WEIGHT_PERCENT=80
OTHER_COLOR=transparent
REFERENCES=color.text.dark
~~~

Use the existing TokenSet derived-value shape. The serialized value is conceptually:

~~~json
{
  "type": "derived",
  "recipe": "css.color_mix",
  "inputs": {
    "color_space": "srgb",
    "base_path": "color.text.dark",
    "base_weight_percent": 80,
    "other": "transparent"
  }
}
~~~

The token records `color.text.dark` in its canonical references. Its source expression preserves the exact ACSS expression as provenance. The canonical value does not copy `var(--text-dark)`.

~~~text
CANONICAL_VALUE_CONTAINS_ACSS_VARIABLE=NO
SOURCE_EXPRESSION_PRESERVED_FOR_PROVENANCE=YES
SUPPORTED_R3_TEXT_DARK_MUTED_FORM=EXACT_DEMONSTRATED_FORM_ONLY
UNSUPPORTED_OVERRIDE_RESULT=UNRESOLVED
TOKENSET_VERSION_BUMP=NO
DESIGN_IR_SCHEMA_CHANGE_REQUIRED=NO
~~~

### Terminal realization

A resolved `color.text.dark_muted` token must expose a source-independent CSS terminal. Build the base color from the canonical `color.text.dark` token terminal, then realize the bounded mix. Do not copy the ACSS expression into the terminal or resolve it through `--text-dark`.

The existing TokenSet schema accepts a derived recipe, JSON-object inputs, references, and metadata. The existing `CSSValue` candidate path accepts a generated `metadata.css_expression`. R3 implementation may use those conventions or a narrowly reviewed helper in the authorized Automatic.css normalizer/resolver surfaces to create the terminal from the canonical referenced token. The direct-owner terminal API must not fall back to `source_expression` for this recipe.

~~~text
TERMINAL_MUST_BE_SELF_CONTAINED=YES
TERMINAL_SOURCE_VARIABLE_REFERENCE_FORBIDDEN=--text-dark
TERMINAL_BASE_PATH=color.text.dark
~~~

If the implementation cannot generate and validate that terminal from `color.text.dark` using the existing TokenSet/CSSValue model or a narrowly bounded helper, stop before adding modules or widening the serializer:

~~~text
STOP=R3_TEXT_DARK_MUTED_TERMINAL_ARCHITECTURE_REQUIRED
~~~

Do not solve the terminal requirement by copying an ACSS source variable into native CSS.

### Direct owner and package mapping

~~~text
DIRECT_OWNER_AUTHORITY_KIND=source_output_alias
DIRECT_OWNER_TOKEN_PATH=color.text.dark_muted
DIRECT_OWNER_AUTHORIZED=YES
DIRECT_OWNER_TERMINAL_SUCCESS_REQUIRES=token present,resolved,terminal-available

TOKEN_PATH=color.text.dark_muted
PACKAGE_VARIABLE=--lf-color-text-dark-muted
PACKAGE_MAPPING_REQUIRED=YES
PACKAGE_VARIABLE_COLLISION=NO
~~~

The exact fixed-string search of tracked files at `BASE_SHA` found no existing definition or use of `--lf-color-text-dark-muted`. The path `color.text.dark_muted` also had no existing token definition at that base. The package mapping is part of R3.

Only when the token is present, resolved, and terminal-available may `resolve_direct_owner_terminal("--text-dark-muted")` succeed. A missing token, unresolved setting, unsupported override, or unavailable terminal preserves the existing fail-closed result.

## 5. `--black-trans-10` disposition

R3A and R3B found no Automatic.css 4.0.1 generated definition or custom-property output family for `--black-trans-10`. The ACSS class key `bg--black-trans-10` is separate evidence and does not define the property.

The accepted Feature Milan Bricks export contains the reference in global class `feature-card-milan`, at `settings._border.color.raw`, with value `var(--black-trans-10)`. R3C found no definition in the supplied matching Feature Milan export or sibling staging settings snapshot. The accepted evidence scope does not include a matching staging global-variable registry or custom-code/style export. Candidate Local Site CSS did not prove a binding to the staging component environment. The source system therefore remains unproven.

~~~text
VARIABLE=--black-trans-10
ACSS_4_0_1_OUTPUT_CONTRACT_PROVEN=NO
ACSS_GENERATED_DEFINITION_FOUND=NO
BRICKS_USAGE=global class feature-card-milan; border-color; var(--black-trans-10)
MATCHING_STAGING_GLOBAL_VARIABLE_REGISTRY_AVAILABLE=NO
MATCHING_STAGING_CUSTOM_CODE_EXPORT_AVAILABLE=NO
SOURCE_SYSTEM=UNPROVEN
DEFINITION_VALUE=UNPROVEN
SEMANTIC_OWNER=UNPROVEN
CANONICAL_TOKEN_PATH=NONE
DIRECT_OWNER_AUTHORITY_KIND=NONE
DIRECT_OWNER_AUTHORIZED=NO
BLACK_TRANS_10_DISPOSITION=UNRESOLVED_EVIDENCE_INCOMPLETE
~~~

Do not claim `MISSING_SOURCE_DEPENDENCY`. Do not infer black, 10% opacity, transparent black, or `color.black` from the variable spelling. Native generation remains blocked on this exact occurrence.

Only the following matching-environment evidence may reopen this disposition without broad ACSS research:

- Feature Milan staging Bricks/project global-variable registry.
- Matching staging custom-code/style export.
- Matching staging stylesheet containing the exact definition.

A narrowly scoped supplemental authority may supersede this unresolved disposition if one of these records proves the exact definition, scope, semantic owner, and canonical path. R3C does not establish a source-environment mismatch.

## 6. Independent lifecycle and terminal states

Each variable advances independently.

~~~text
--bg-ultra-light:
  UNRESOLVED
  -> OUTPUT_CONTRACT_PROVEN
  -> SEMANTIC_OWNER_PROVEN
  -> EXISTING_CANONICAL_PATH_PROVEN
  -> SOURCE_OUTPUT_ALIAS_AUTHORIZED
  -> IMPLEMENTATION_PENDING

--text-dark-muted:
  UNRESOLVED
  -> OUTPUT_CONTRACT_PROVEN
  -> SEMANTIC_OWNER_PROVEN
  -> NEW_CANONICAL_PATH_FROZEN
  -> SOURCE_INDEPENDENT_VALUE_CONTRACT_FROZEN
  -> SOURCE_OUTPUT_ALIAS_AUTHORIZED
  -> IMPLEMENTATION_PENDING

--black-trans-10:
  UNRESOLVED
  -> DEFINITION_SEARCHED
  -> MATCHING_ENVIRONMENT_EVIDENCE_INCOMPLETE
  -> UNRESOLVED_EVIDENCE_INCOMPLETE
~~~

R3 terminal states are:

~~~text
AUTHORIZED_PENDING_IMPLEMENTATION
UNRESOLVED_FINAL_GENERATION_BLOCKER
~~~

The first state applies to the proposed `--bg-ultra-light` and `--text-dark-muted` source-output aliases, subject to token presence, resolution, and terminal checks. `--black-trans-10` remains an unresolved final-generation blocker.

## 7. R3 implementation boundary

This document authorizes no implementation. After independent owner acceptance, a separate implementation authority may use only the minimal required surfaces from this allowlist:

~~~text
apps/live_frames/lib/live_frames/adapters/automatic_css/normalizer.ex
apps/live_frames/lib/live_frames/adapters/automatic_css/resolver.ex
apps/live_frames/priv/token_maps/native_shared_v3.json

apps/live_frames/test/live_frames/automatic_css_adapter_test.exs
apps/live_frames/test/live_frames/tokens/variable_authority_test.exs
apps/live_frames/test/live_frames/bricks_design_ir_test.exs
apps/live_frames/test/live_frames/styling/token_bridge_test.exs
apps/live_frames/test/live_frames/styling/assets_drift_test.exs

docs/06_ACSS_TOKEN_ADAPTER.md
docs/11_CSS_AND_TAILWIND_STRATEGY.md

generated theme/static CSS only through deterministic regeneration
~~~

If R3 needs another production module, a new serialized value kind, a TokenSet/Design IR schema change, or a broader realization architecture, stop and return for authority review:

~~~text
STOP=R3_IMPLEMENTATION_SURFACE_EXPANSION_REQUIRED
STOP=SERIALIZED_SCHEMA_CHANGE_DISCOVERED
~~~

The implementation must preserve these boundaries:

- No NativeGenerator variable lookup or color-mix special case.
- No raw ACSS variable passthrough or source CSS copy.
- No Milan-specific serializer or property branch.
- No guessing, approximation, or mapping for `--black-trans-10`.
- No dropping unresolved declarations to force generation.
- No generic arbitrary `color-mix()` parser, arbitrary percentages, base variables, or second colors.
- No TokenSet version bump for the bounded recipe.

## 8. R4 and R5 interaction

R4 remains responsible for `spacing.scale.s -> --lf-space-scale-s`. The two color package mappings in this R3 authority remain owned by R3 because direct-variable remediation requires them. Do not move either color mapping into R4 or otherwise change R4 scope.

After successful R3 implementation and R4, `--black-trans-10` remains unresolved unless supplemental accepted evidence resolves it. R5 must not claim `UNRESOLVED_STYLE_REMAINS_FOR_FINAL_GENERATION=NO` while that occurrence remains unresolved.

~~~text
R5_EXPECTED_INITIAL_BLOCKER=--black-trans-10
~~~

Do not weaken R5 success criteria.

## 9. Stops and approval boundary

Stop without workaround or scope expansion on any of:

~~~text
STOP=R3_AUTHORITY_BASE_MOVED
STOP=R3_BG_OWNER_CONFLICT
STOP=R3_BG_PACKAGE_VARIABLE_COLLISION
STOP=R3_TEXT_DARK_MUTED_PATH_CONFLICT
STOP=R3_TEXT_DARK_MUTED_PACKAGE_VARIABLE_COLLISION
STOP=R3_TEXT_DARK_MUTED_TERMINAL_ARCHITECTURE_REQUIRED
STOP=R3_BLACK_TRANS_AUTHORITY_INFERRED_WITHOUT_EVIDENCE
STOP=R3_IMPLEMENTATION_SURFACE_EXPANSION_REQUIRED
STOP=SERIALIZED_SCHEMA_CHANGE_DISCOVERED
STOP=AUTHORITY_CONFLICT
~~~

This proposed authority changes no production code, tests, token maps, or generated assets. Owner acceptance of this document and a separate implementation authorization are both required before R3 implementation. R4 and R5 remain unauthorized.
