# Canonical Feature Romeo no-ACSS normalization and blocker inventory

## Scope and authority

This record reports two fresh normalizations of the accepted canonical Romeo
artifact under the authorized conservative no-ACSS context. It ends at the
validated Design IR returned by the public Bricks adapter. It does not create a
component contract or plan, run NativeGenerator, or authorize implementation.

The accepted authority files remain the source and style authorities. Their
historical ACSS-use claims remain unproven. The current repository base and
CI were checked before normalization:

~~~text
BASE_SHA=59e81aaf431e7b4031c25366e86614e81322f8c1
BASE_TREE=cf3d9a050900bf042c48720224068cf5aa884fdc
BASE_CI=39053281280 SUCCESS
CURRENT_MAIN_AT_NORMALIZATION=59e81aaf431e7b4031c25366e86614e81322f8c1
CURRENT_MAIN_TREE_AT_NORMALIZATION=cf3d9a050900bf042c48720224068cf5aa884fdc
CURRENT_MAIN_MOVEMENT=NONE
~~~

## Canonical source identity and context

The corpus digest and Romeo artifact identity were recomputed before the
adapter runs. The component identity was checked through the returned document
provenance. No source bytes changed during either run.

~~~text
CORPUS_RECORDS=34
CORPUS_DIGEST=074b60cf0ca2db30babe956a657d4838963bcb3a9c69a1eef70d888d93f31d1e
CORPUS_DIGEST_MATCH=YES
ROMEO_SHA256=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
ROMEO_SHA256_MATCH=YES
ROMEO_BYTES=24944
ROMEO_BYTES_MATCH=YES
COMPONENT_ID_MATCH=YES

CANONICAL_CONTEXT=public Bricks.to_ir/2; component_id=eiwwbh; fresh empty TokenSet per run
ACSS_FIXTURE_LOADED=NO
ACSS_PROFILE_SELECTED=NO
ACSS_SOURCE_VERSION_ASSIGNED=NO
STRUCTURAL_VARIABLE_AUTHORITY_SUPPLIED=NO
NAMED_BREAKPOINT_AUTHORITY_SUPPLIED=NO
ROMEO_CANONICAL_EXTERNAL_TOKEN_AUTHORITY=NONE
ROMEO_CANONICAL_ACSS_AUTHORITY=NONE
ROMEO_CANONICAL_STRUCTURAL_VARIABLE_AUTHORITY=NONE
ROMEO_CANONICAL_NAMED_BREAKPOINT_AUTHORITY=NONE
HISTORICAL_ROMEO_USED_ACSS=UNPROVEN
HISTORICAL_ROMEO_DID_NOT_USE_ACSS=UNPROVEN
CANONICAL_ROMEO_NORMALIZATION_AUTHORIZED=YES
~~~

## Independent canonical runs

Each run read the source path again, created a new TokenSet, called only the
public Bricks adapter, received a DesignDocument, and serialized it with
LiveFrames.IR.encode!/1.

~~~text
CANONICAL_RUN_1=SUCCESS
CANONICAL_RUN_2=SUCCESS
IR_SHA256_RUN_1=352f355a798f74562dd475068e2829c017a6bee4040ee4a54ae8d8cecfb2acf3
IR_SHA256_RUN_2=352f355a798f74562dd475068e2829c017a6bee4040ee4a54ae8d8cecfb2acf3
IR_BYTES_IDENTICAL=YES
SOURCE_SHA256_AFTER_RUNS=0cf29929a25bc2485ece90375d8c0f90fa1710eac0439bc5decc13af11f03f63
SOURCE_BYTES_UNCHANGED=YES
~~~

## Owners, state, and scope proof

The four card owners were located by source_trace.source_id. These are the
fresh node IDs returned by the adapter:

~~~text
CARD_OWNER_COUNT=4
CARD_OWNER_NODES_DISTINCT=YES
CARD_OWNER_NODE_IDS=node_000001_000001_000002_000001,node_000001_000001_000002_000002,node_000001_000001_000002_000003,node_000001_000001_000002_000004
EFFECTIVE_LAYER_PROVENANCE_MATCH=YES
HOVER_ALIAS_PROVEN=YES
FOCUS_WITHIN_RULES_PRESENT=YES
SOURCE_ACTION_IN_EXECUTABLE_RULES=NO
SOURCE_TRANSIENT_TOKEN_AS_STATE_CONDITION=NO
CROSS_CARD_TARGETS=0
SIBLING_TARGETS=0
ESCAPED_BOUNDARY_TARGETS=0
FOUR_OWNER_SCOPE_ISOLATION=PASS
~~~

For each owner, the custom-CSS trace points to its effective class-reference
settings layer, and the normalized rules contain the hover condition proved by
the exact reversible interaction pair on that layer. Executable rules contain
only closed conditions and normalized declarations. Source event/action names
and the transient class do not become executable authority.

The four state-rule maps pass LiveFrames.IR.StateRuleSet.validate/1. Every
target resolves within the owner subtree. The adapter stores each state_rules
value in its owner node's base style map; no state_rules subtype is stored
under a responsive override. The component has one root, so every
resolved target also remains inside the component boundary.

## Responsive and focus safety

The direct custom-CSS media bounds remain distinct. No named breakpoint was
inferred from them or from a responsive setting.

~~~text
DIRECT_MIN_767_PRESENT=YES
DIRECT_MAX_767_PRESENT=YES
BOUNDARY_REWRITTEN_TO_766=NO
BOUNDARY_REWRITTEN_TO_768=NO
NAMED_BREAKPOINT_MAPPING_APPLIED=NO

COMPLEX_CSS_COUNT=8
STATE_RULE_OWNER_COUNT=4
STATE_RULE_RULE_COUNT=48
STATE_RULE_SET_VALID_COUNT=4
CUSTOM_CSS_RESIDUAL_COUNT=4
STATE_RULE_RESIDUAL_COUNT=44
STATE_RULE_VIEWPORT_TUPLES=viewport none:32; min_width 767, max_width none:16
COMPLEX_CSS_SUBTYPE_COUNTS=custom_css:4; state_rules:4
UNKNOWN_COMPLEX_CSS_SUBTYPE=NO
SOURCE_FOCUS_SUPPRESSION_IN_GENERATABLE_IR=NO
~~~

Each card owner has 12 state rules and 11 state residuals. Per owner, the
rules have eight unscoped entries and four entries at min-width 767. The IR
residual schema does not retain a viewport field, so residual viewport
categories below are marked NOT_RETAINED rather than inferred.

~~~text
STATE_RULE_OWNER_INVENTORY
28c2a3 | node_000001_000001_000002_000001 | rules=12 | residuals=11 | conditions=focus_within,hover | viewports=none:8,min=767/max=none:4
640a40 | node_000001_000001_000002_000002 | rules=12 | residuals=11 | conditions=focus_within,hover | viewports=none:8,min=767/max=none:4
07d0e9 | node_000001_000001_000002_000003 | rules=12 | residuals=11 | conditions=focus_within,hover | viewports=none:8,min=767/max=none:4
336877 | node_000001_000001_000002_000004 | rules=12 | residuals=11 | conditions=focus_within,hover | viewports=none:8,min=767/max=none:4
~~~

## Fresh diagnostics and independent gaps

These counts come from the canonical DesignDocument. The diagnostic inventory
is separate from residual counts. The 48 custom-CSS diagnostics correspond to
the 48 fresh residual records and are not added again to the blocker-family
counts.

~~~text
DIAGNOSTIC_COUNTS=bricks.asset.unresolved:4; bricks.breakpoint.unresolved:3; bricks.custom_css.unresolved_value:32; bricks.custom_css.unsupported_selector:16; bricks.navigation.unsupported_carrier:4; bricks.setting.unsupported:13; bricks.variable.unresolved:25
DIAGNOSTIC_GROUP_COUNTS=asset:4; navigation:4; unsupported_source_setting:13; named_breakpoint:3; custom_css:48; variable_value:25; other:0

NAVIGATION_CARRIER_BLOCKERS=4
FRESH_NAVIGATION_LINK_SOURCE_EVIDENCE_COUNT=4
ASSET_RESOLUTION_BLOCKERS=4
SOURCE_SETTING_BLOCKERS=13
NAMED_BREAKPOINT_BLOCKERS=3
ACCESSIBILITY_BLOCKERS=0
~~~

All four fresh navigation diagnostics are unsupported heading-link carriers.
The corresponding source traces retain a link setting, while normalized nodes
have no href or navigation attribute. Asset findings remain unresolved; no
asset identity or URL was inferred. All 13 unsupported source-setting findings
remain UNKNOWN_REQUIREMENT because the accepted Romeo authorities do not
classify their individual meaning. Their values and source paths are omitted.

The named-breakpoint diagnostics are independent from the literal 767px CSS
queries. Their mapping remains absent. No accessibility diagnostic was
emitted. Source focus suppression remains an inert residual under the accepted
focus policy; visible target focus remains a later browser-acceptance check.

### Unsupported source-setting findings

The following per-finding hashes identify the 13 diagnostics without exposing
setting names, values, or source paths. Each is SHA-256 of source_trace.source_id
concatenated with diagnostic.code and source_trace.source_path. Each finding has requirement
UNKNOWN_REQUIREMENT, family SOURCE_SETTING, and subtype UNSUPPORTED_SETTING.

| Fingerprint | Requirement | Family | Subtype |
| --- | --- | --- | --- |
| 2b95f3e6ffd078b1886e30b3dc530e13aec38991930ec4ce76655f1e4600d0dd | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| 34160fc1baf552f46a0cff30b1b552365b65187cca66d12f1d953c5fea2b3d84 | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| 66f636f6de2f5c8ae9b27a63b8c4a62b2edc62e0411062355cb29dca6e2a98d4 | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| 695ad5b101baa309c17e5b34fcbe19be3c93b4473dd076169de652b08b849637 | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| 73b83ad27b2fa6e5f38a6fca19b7c21da2373de7bb48384e1b4beafbb1d293e0 | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| 92574be91dcf1465b63b717095ff7f60453f89307d1cd9424718fcc24e72c89e | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| 9731bdb779d640c8dc40eb383192eefc7e58a8bbfca21163785662bcca1a7f9c | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| a4a4490318ea5278d78a3cbe226147eac372fa9655fab877b0715b951a5db88f | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| b422271028822837280ef1e7308d52aa7e28e13120868e4f222c6d6a89f5fc0e | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| b9bbf1a6d871a0eab11c2041b1c3dfc9399bd159a0f9cc959b0e2b48c77ac65a | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| cf4126866bec71597a502df80a351de8b6943340021efae092aff6cde5a61d51 | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| fb901688858cc8b57a43f88005135668c5715089e31b1fe688a22cb59c7ee518 | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |
| fdea3da6cf6c93554d8d694392ac99aa6ae3cd95979326ed242bac72cf90b764 | UNKNOWN_REQUIREMENT | SOURCE_SETTING | UNSUPPORTED_SETTING |

## Fresh residual inventory

Each fingerprint is SHA-256 of owner_source_id concatenated with the exact
reason enum and raw source_text. The raw text, selectors, variable names, and
values are not included. The property names shown in the table are the only
property names emitted.

| Fingerprint | Owner source ID | Reason | State | Viewport | Selector shape | Whitelisted properties | Requirement | Gap family | Gap subtype | Value cause |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 03533098b670bc5ae529d33e3097ee6d645f4749e2f99432e9d50a0fdd453904 | 07d0e9 | unsupported_selector | focus_within | NOT_RETAINED | focus_within_selector | box-shadow,outline | SOURCE_FOCUS_SUPPRESSION | ACCESSIBILITY | SOURCE_FOCUS_SUPPRESSION | N/A |
| 0901cb3b415a2e9bbc1f573416894cad3fef9d7a3e883b50f491eb358b0ee068 | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | flex-basis,height,isolation,min-height,overflow,position,transition | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 1e1d6e7b9a560ceb2cdad4fdb8b5e1f0e617a708143e0298d02966110b3687c0 | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | - | UNKNOWN_REQUIREMENT | OTHER | EXTERNAL_VALUE_AUTHORITY_MISSING | EXTERNAL_VALUE_AUTHORITY_MISSING |
| 3f468e23c8bf3dcaa23bafd79c6f1f1946c966d941fca2e40d8201ab9aed5fdb | 07d0e9 | unsupported_selector | none | NOT_RETAINED | pseudo_element | content,margin-left,order | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |
| 65924823bba32261aa5e2224a6daec356626882c04ba5a0de589d673aab3d35d | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | inset-block-start,inset-inline-end,line-height,opacity,position,transition,translate | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 7151eb291426421e163e7cce37f962183ad05f6053cfdcd9fb66fac406440cd8 | 07d0e9 | unsupported_selector | none | NOT_RETAINED | class_compound | height,min-height,min-width,position,width,z-index | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_SELECTOR | N/A |
| 777e98dede7eb1fa849103d9e8c4f10f8ad212eec36fe12e7c06fedc18202491 | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | max-width,opacity,transition,translate,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 999f3ce30356ad3ff65bd9e4f66c5f89fbb1bf9e9f8f2a76d8a4f511a3e364b7 | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,background-image,display,flex-direction,gap,height,justify-content,padding,position,transition,width,z-index | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| b590ab7069cca8ab161207dd1e2d35812e80b66e431887eff24344bb59caefd1 | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | border-radius | UNKNOWN_REQUIREMENT | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| c5b322a1649bac2a2f6036700ed190df4a1427467953e492466a6bd83d78dd84 | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | opacity,transition | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| e8921b20135635c66775a69f43c51a763647cdd852bab2db78dc4b7c2abe58c1 | 07d0e9 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,display,max-width,opacity,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| bab209aa7fdd2b78409545ec17beb3ecc6b9435fcfd1065b550db6184b18f6d1 | 27edbc | unsupported_selector | none | NOT_RETAINED | pseudo_element | background-color,content,height,inset,position,width | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |
| 0a143f9a4b3cae0ade8bbfdcefd3ecb81b4fb6d247d9370147578a9a41c203b3 | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | flex-basis,height,isolation,min-height,overflow,position,transition | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 1e8aa992f3886b5fb691b37ac8780d7f3482ded51fe1fcc0e19fbd3fb16c9088 | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | opacity,transition | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| 34c665636e58fbbf8c46a5fba298f5319bbcc29279e0a0a1c47c185200970376 | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | border-radius | UNKNOWN_REQUIREMENT | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 36839f378bea4fc003aa28afdcf75dc4ec93221d221a6279f84372aa50ed3e1c | 28c2a3 | unsupported_selector | focus_within | NOT_RETAINED | focus_within_selector | box-shadow,outline | SOURCE_FOCUS_SUPPRESSION | ACCESSIBILITY | SOURCE_FOCUS_SUPPRESSION | N/A |
| 3e5d82e9994a51df18f4dfedcf5e6ee83ce86847f12154b558f67aff08fcd668 | 28c2a3 | unsupported_selector | none | NOT_RETAINED | class_compound | height,min-height,min-width,position,width,z-index | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_SELECTOR | N/A |
| 7fb98c60ed0674ea3722c2b88f395f31d49ca3d690b9551c62840bf8708433b9 | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | - | UNKNOWN_REQUIREMENT | OTHER | EXTERNAL_VALUE_AUTHORITY_MISSING | EXTERNAL_VALUE_AUTHORITY_MISSING |
| 87b4b639dcb6f8bfb601f43dd54eaaf13e0c1bd17008199f2901a7e5ccb78318 | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | max-width,opacity,transition,translate,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| a99f584aeb79fa43edf62b696e840a9be0e5d721db76c45bf50c455cf13096c5 | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,background-image,display,flex-direction,gap,height,justify-content,padding,position,transition,width,z-index | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| b86f194d506cc3be7f3c34e405cafa444fb86e6c729918a371afdb74ca473de3 | 28c2a3 | unsupported_selector | none | NOT_RETAINED | pseudo_element | content,margin-left,order | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |
| e40736eb3a7ba24791b285411a4f33ea6a57f4116427e5d8c7b5f35112fbe2a7 | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,display,max-width,opacity,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| e9adc28bb05687de8f61835107d992e0175a0494a92753b41de48c1c4f425dbe | 28c2a3 | unresolved_value | none | NOT_RETAINED | class_compound | inset-block-start,inset-inline-end,line-height,opacity,position,transition,translate | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 08ccfef7fcf3a815180db0ce062a55ca2bc89e26fb8aed832688585b4457a900 | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | - | UNKNOWN_REQUIREMENT | OTHER | EXTERNAL_VALUE_AUTHORITY_MISSING | EXTERNAL_VALUE_AUTHORITY_MISSING |
| 0e0fd4f508e840ba1312fc9027ac22b45e68ba2376f3b54318e73018afedac74 | 336877 | unsupported_selector | none | NOT_RETAINED | class_compound | height,min-height,min-width,position,width,z-index | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_SELECTOR | N/A |
| 0eb6e30c8be2df915df46743081ea9b3cbe5c0577a63d89b227074c87f72aec3 | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | border-radius | UNKNOWN_REQUIREMENT | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 11a5372763514c76564e4047b0857145d742dbe7a38029e53027c35b7197a30e | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | max-width,opacity,transition,translate,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 4c4295d25952df9923ebf63bd96eb34cc50f0b44b1512bbf3267025f72edd388 | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | flex-basis,height,isolation,min-height,overflow,position,transition | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 70f678f1f1c140cf9ed5bff56d319d49867a38e13bc9d619d1e01943ef4a515a | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | opacity,transition | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| 7c0e9d03b683dd2a4e66f0f0ced1c850fff76af09ff00ed6b047be21adcc8eb4 | 336877 | unsupported_selector | none | NOT_RETAINED | pseudo_element | content,margin-left,order | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |
| 9a0ea1e0606417aa1e9b21972a128f8b6250d6b1f1bbe9366d189f6c995f033b | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,background-image,display,flex-direction,gap,height,justify-content,padding,position,transition,width,z-index | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| df72c996e64f726c7924d377fa5d407656bd6386e05f254a82e9b5c10c2b620f | 336877 | unsupported_selector | focus_within | NOT_RETAINED | focus_within_selector | box-shadow,outline | SOURCE_FOCUS_SUPPRESSION | ACCESSIBILITY | SOURCE_FOCUS_SUPPRESSION | N/A |
| f7c6c544077d326584455d1541df7b0e96d2b5bd146cfa4f60eb92ad57d9563b | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,display,max-width,opacity,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| fa494ac736aeb63e246a5e9c0529181594975127289df907734e9f42363076be | 336877 | unresolved_value | none | NOT_RETAINED | class_compound | inset-block-start,inset-inline-end,line-height,opacity,position,transition,translate | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| bcdf06c9e630a6101615840ff68214ef5da88fc0bb6b26193bffe4702fe1acd0 | 35ade1 | unsupported_selector | none | NOT_RETAINED | pseudo_element | background-color,content,height,inset,position,width | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |
| 79b816e08e27098430919aabe83a518778dda9890de996ab19b2f587ae9e1e22 | 3a2656 | unsupported_selector | none | NOT_RETAINED | pseudo_element | background-color,content,height,inset,position,width | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |
| 05765c3e51f92ce4aaafe75d9705f5704a602a0b48423519f812bba21d207bc6 | 640a40 | unsupported_selector | none | NOT_RETAINED | pseudo_element | content,margin-left,order | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |
| 2c4c67fb4ca78eaadad1cbc02a1dad4650ae9ab58547955d379217f1ec40a53d | 640a40 | unsupported_selector | none | NOT_RETAINED | class_compound | height,min-height,min-width,position,width,z-index | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_SELECTOR | N/A |
| 4e38d541683ae1ebe9cea5b256fb18fba1ecf1e1210e6932696884db61cd0c56 | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,background-image,display,flex-direction,gap,height,justify-content,padding,position,transition,width,z-index | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| 4f3213b09bf886d16827795a698457d2703cd4967d301ffbcd3762ba3d710941 | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | max-width,opacity,transition,translate,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 544a9acb6aa8a07156bbf87494fed0d71a9570e84614e057aa0546a47246986c | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | border-radius | UNKNOWN_REQUIREMENT | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 5aea014b627ad3d857e65b49beab2e4e022251be857102f0382c8311286042dc | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | flex-basis,height,isolation,min-height,overflow,position,transition | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 718d9d8ab0f034749578e2a1643a9024ab35d557a15ed17791ca66717fb488e1 | 640a40 | unsupported_selector | focus_within | NOT_RETAINED | focus_within_selector | box-shadow,outline | SOURCE_FOCUS_SUPPRESSION | ACCESSIBILITY | SOURCE_FOCUS_SUPPRESSION | N/A |
| 864d4d9a990bdcd3ce6e41380254af7e44b171abb2dae1bc4d1f5b7968355814 | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | - | UNKNOWN_REQUIREMENT | OTHER | EXTERNAL_VALUE_AUTHORITY_MISSING | EXTERNAL_VALUE_AUTHORITY_MISSING |
| 871df53a6b0d81071afa5df722bf9865a17339afcac737f49958d07d363e38b2 | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | opacity,transition | VISUALLY_REQUIRED_UNSUPPORTED | TOKEN_OR_VALUE_GRAMMAR | UNSUPPORTED_COMPOUND_EXPRESSION | UNSUPPORTED_COMPOUND_EXPRESSION |
| 99893c69ecce677034b89d73f9dd1cbe046575734306c6835c9e32d0c4b0ad8c | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | inset-block-start,inset-inline-end,line-height,opacity,position,transition,translate | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 9c301f6e3bb52d7d1765c3ea5e8332e7361a9ee10a441d7ebf121763c94d0e93 | 640a40 | unresolved_value | none | NOT_RETAINED | class_compound | align-items,display,max-width,opacity,width | VISUALLY_REQUIRED_UNSUPPORTED | SOURCE_LOCAL_VARIABLE | SOURCE_LOCAL_CUSTOM_PROPERTY | SOURCE_LOCAL_CUSTOM_PROPERTY |
| 6a68364f46f1a7966347b16f16428415b3451a9bddbcd19c9e55144b255e0a4a | dd9991 | unsupported_selector | none | NOT_RETAINED | pseudo_element | background-color,content,height,inset,position,width | UNKNOWN_REQUIREMENT | SELECTOR_OR_PSEUDO_ELEMENT | UNSUPPORTED_PSEUDO_ELEMENT | N/A |

## Classification and blocker families

The requirement classes use only accepted Romeo source and style authority.
The 24 VISUALLY_REQUIRED_UNSUPPORTED residuals are six per card: card base
layout, collapsed heading, lede, inner-content base, overlay default, and
vertical-heading default. These meanings come from the accepted [source
semantics authority](feature_romeo_source_semantics_authority.md#8-observed-presentationstyle-evidence)
and [CSS style authority sections 4 and 6](feature_romeo_css_style_authority.md#6-generic-stateful-style-representation).
The 20 UNKNOWN_REQUIREMENT residuals are four border-radius value residuals,
four unresolved-value records with no whitelisted property name, and 12
unsupported-selector residuals. The 12 selector findings include
pseudo-element rules and geometry rules. The accepted authorities do not
establish whether these are required, so they remain blocking unknowns. No
residual was classified as a duplicate or proven non-required. Property overlap
alone was not treated as duplicate presentation; no residual had an accepted
proof of equivalent target, condition, viewport, and normalized value. The 24
confirmed visually required residuals and 20 unknown-requirement residuals
make 44 blocking residuals. The four source-focus-suppression residuals are
intentionally inert and excluded from that blocking count.

~~~text
CANONICAL_RESIDUAL_COUNT=48
CANONICAL_CONFIRMED_REQUIRED_RESIDUAL_COUNT=24
CANONICAL_BLOCKING_UNKNOWN_RESIDUAL_COUNT=20
CANONICAL_BLOCKING_RESIDUAL_COUNT=44
CANONICAL_UNRESOLVED_VALUE_COUNT=32

CANONICAL_VISUALLY_REQUIRED_UNSUPPORTED_RESIDUALS=24
CANONICAL_UNKNOWN_REQUIREMENT_RESIDUALS=20
CANONICAL_SOURCE_FOCUS_SUPPRESSION_RESIDUALS=4
CANONICAL_DUPLICATE_RESIDUALS=0
CANONICAL_NON_REQUIRED_RESIDUALS=0

BLOCKING_RESIDUAL_INVARIANT=PASS; 24+20=44
TOTAL_RESIDUAL_INVARIANT=PASS; 24+20+4=48

RESIDUAL_REASON_COUNTS=unresolved_value:32;unsupported_selector:16
UNRESOLVED_VALUE_CAUSE_COUNTS=SOURCE_LOCAL_CUSTOM_PROPERTY:20;EXTERNAL_VALUE_AUTHORITY_MISSING:4;UNSUPPORTED_COMPOUND_EXPRESSION:8;UNSUPPORTED_VALUE_GRAMMAR:0;TOKEN_LOOKUP_NOT_AUTHORIZED:0;OTHER_PROVEN_CAUSE:0;UNKNOWN_CAUSE:0
~~~

The 20 SOURCE_LOCAL_CUSTOM_PROPERTY causes have local definitions in the same
effective source expression. This establishes the dependency only. No computed
value was inferred. Four unresolved values require external semantic meaning;
they are family OTHER with subtype EXTERNAL_VALUE_AUTHORITY_MISSING. This does
not attribute them to ACSS. Eight values fail the supported compound-value
grammar. They remain a measured capability gap, not evidence of a production
defect.

Blocker-family counts combine blocking residual findings with independent
non-CSS gap findings. Custom-CSS diagnostics are excluded from this family
count because their residuals already appear above. Counts remain separated;
there is no combined total.

~~~text
BLOCKER_FAMILY_COUNTS=ASSET_RESOLUTION:4; NAMED_BREAKPOINT:3; NAVIGATION_CARRIER:4; OTHER:4; SELECTOR_OR_PSEUDO_ELEMENT:12; SOURCE_LOCAL_VARIABLE:20; SOURCE_SETTING:13; TOKEN_OR_VALUE_GRAMMAR:8; ACCESSIBILITY:0
INDEPENDENT_NON_CSS_GAP_COUNTS=navigation:4; asset:4; source_setting:13; named_breakpoint:3; accessibility:0
~~~

## Historical diagnostic comparison

The comparison below uses the fresh counts above. The previous numbers were
not used to create or adjust any canonical finding.

~~~text
OLD_DIAGNOSTIC_RESIDUAL_COUNT=48
OLD_DIAGNOSTIC_REQUIRED_CLASSIFICATION=44_PROVISIONAL
OLD_DIAGNOSTIC_UNRESOLVED_VALUE_COUNT=32

DELTA_RESIDUAL_COUNT=0
DELTA_UNRESOLVED_VALUE_COUNT=0

OLD_PROVISIONAL_BLOCKING_SET_COUNT=44
CANONICAL_BLOCKING_RESIDUAL_COUNT=44
DELTA_BLOCKING_SET_COUNT=0

OLD_PROVISIONAL_CONFIRMED_REQUIRED_COUNT=NOT_ESTABLISHED
CANONICAL_CONFIRMED_REQUIRED_RESIDUAL_COUNT=24
DELTA_CONFIRMED_REQUIRED_COUNT=NOT_COMPARABLE
~~~

The earlier diagnostic probe provisionally treated all 44 non-focus residuals
as required or blocking. The canonical authority refines that provisional set
into 24 confirmed visually required residuals and 20 unknown-requirement
residuals. The blocking-set cardinality is unchanged, but the requirement
certainty is more precise. A `DELTA_REQUIRED_COUNT=0` claim would be
misleading because the earlier probe did not establish how many residuals
were confirmed required.

## Privacy, runtime, and authorization boundary

Only requested card owner IDs, normalized DesignNode IDs, residual owner IDs,
and sanitized fingerprints appear. No private JSON, CSS body, raw residual
text, selector, custom-property name, variable value, URL, or domain was
printed or committed. No private identifier outside the IDs required for this
inventory was published.

~~~text
RAW_PRIVATE_SOURCE_PRINTED=NO
PRIVATE_PAYLOAD_COMMITTED=NO
PRIVATE_IDENTIFIER_PUBLISHED=NO

ROMEO_COMPONENT_CONTRACT_CREATED=NO
ROMEO_COMPONENTIZATION_PLAN_CREATED=NO
ROMEO_NATIVE_GENERATION_RUN=NO
BROWSER_ACCEPTANCE_RUN=NO

DATA_LAYER=COLD_BUILD_TIME
RUNTIME_DB_CALLS=0
RUNTIME_NETWORK_CALLS=0
REDIS=N/A
POSTGRES=N/A
CACHE=N/A
GENSERVER=N/A
PUBSUB=N/A
OBAN=N/A
UNBOUNDED_SCAN=NO

PRODUCTION_FILES_CHANGED=NO
TEST_FILES_CHANGED=NO
CONVERSION_MATRIX_CHANGED=NO
DEPENDENCY_FILES_CHANGED=NO
GENERATED_IR_COMMITTED=NO
PRIVATE_SOURCE_COMMITTED=NO
~~~

## Readiness verdict

Canonical IR has 44 blocking residuals: 24 confirmed visually required and 20
with unknown requirements. It also has gaps in navigation carriers, unresolved
assets, unsupported settings, and named breakpoints. The four focus-suppression
residuals remain inert by authority and do not count as target focus rules or
blocking residuals.

~~~text
ROMEO_COMPONENTIZATION_READINESS=BLOCKED
ROMEO_COMPONENTIZATION_AUTHORIZED=NO
ROMEO_IMPLEMENTATION_AUTHORIZED=NO
ROMEO_NATIVE_GENERATION_AUTHORIZED=NO
NEXT_GATE=ROMEO_CANONICAL_GAP_DECOMPOSITION
STOP=NONE
~~~
