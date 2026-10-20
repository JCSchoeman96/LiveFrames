# Page A v0 browser proof

```text
PAGE_ID=frames_page_a_v0
ROUTE=/liveframes/pages/frames-a-v0
CONSUMER_TARGET=LIVEFRAMES_PREVIEW
BROWSER=Collaborative T3 preview browser
BROWSER_RESULT=PASSED
STRUCTURAL_FIDELITY=PASS
FUNCTIONAL_FIDELITY=PARTIAL
VISUAL_FIDELITY=PARTIAL

CSS_COMPONENT_COLLISION=NONE
DOM_ID_COLLISION=NONE
BEHAVIOR_INSTANCE_COLLISION=NOT_REQUIRED
ASSET_COLLISION=NONE

LIVEFRAMES_STYLESHEET_LINKS_PER_VIEWPORT=1
LIVEFRAMES_STYLESHEET_LOADED_PER_VIEWPORT=YES
BEHAVIOR_RUNTIME_CHECKS=NOT_REQUIRED
```

The page was opened in the real collaborative browser at the preview application route. The preview server ran from the implementation worktree on port 4011 because port 4000 was occupied by an unrelated Local process. The page route returned HTTP 200. Browser network records show HTTP 200 for the LiveFrames stylesheet and all seven image URLs. The seven URLs use query variants of the existing synthetic preview asset; they intentionally resolve to the same asset bytes.

## Viewport results

| Viewport class | CSS viewport | Document width | Section boxes in order | Horizontal overflow | Overlap | Images loaded | Focus and link semantics |
| --- | ---: | ---: | --- | --- | --- | --- | --- |
| Desktop | 1440 × 900 | 1440 / 1440 px | Hero 760 px; CTA A 675 px; CTA B 675 px | None | None | 7 of 7 | Tab reaches all three links with visible 2 px focus outlines; expected `href` values are present; target pages out of scope |
| Tablet | 768 × 1024 | 768 / 768 px | Hero 689 px; CTA A 878 px; CTA B 878 px | None | None | 7 of 7 | Tab reaches all three links with visible 2 px focus outlines; expected `href` values are present; target pages out of scope |
| Mobile | 390 × 844 | 390 / 390 px | Hero 705 px; CTA A 896 px; CTA B 896 px | None | None | 7 of 7 | Tab reaches all three links with visible 2 px focus outlines; expected `href` values are present; target pages out of scope |

The section boxes are ordered Hero, CTA A, CTA B at each viewport, and their boxes do not overlap. The Hero and both CTA sections coexist in the same page. The two CTA roots retain their independent `page-a-cta-a` and `page-a-cta-b` classes and distinct caller-owned text and destinations. At desktop the CTA content uses its two-column composition; at tablet and mobile it stacks into a single content column. The repeated CTA image mosaic remains within the viewport at all three sizes.

## Isolation and collision checks

- The page has exactly one link to `/liveframes/library/live_frames/css/live_frames.css`; that stylesheet is loaded at each viewport. The preview host also loads its separate `storybook.css` stylesheet.
- The loaded LiveFrames rules were inspected against the Hero and CTA subtrees at desktop, tablet, and mobile. Hero selectors did not match CTA nodes, and CTA selectors did not match Hero nodes. No mixed Hero/CTA selector was found.
- No duplicate DOM IDs were found.
- No `phx-click` or `phx-hook` attributes occur inside the three component roots. Page A v0 has no component-specific behavior runtime, so behavior-instance collision checks are `NOT_REQUIRED`.
- All seven image elements completed with a nonzero natural width. The query variants are separate requests for one existing synthetic preview asset; there is no conflicting asset identity or private/source asset.

## Fidelity assessment

`STRUCTURAL_FIDELITY=PASS`: one Hero followed by two independent CTAs rendered at all three viewport classes, with no horizontal overflow or overlapping section boxes.

`FUNCTIONAL_FIDELITY=PARTIAL`: the three primary links preserve their caller-owned `href` values, are keyboard reachable, and show visible focus. Their destination pages are outside this one-page tracer and were not opened. No other behavior runtime applies to these sections in this proof.

`VISUAL_FIDELITY=PARTIAL`: the responsive section arrangement and stacking are visible at all three viewport classes, and the component styles load once. The CTA image mosaic repeats the same synthetic preview image through distinct query variants. No source screenshot or pixel-level visual target is included in this proof, so source-level visual similarity is not claimed.

## Browser console deviation

The browser console repeatedly records a failed handshake with HTTP 404 for `/phoenix/live_reload/socket/websocket?vsn=2.0.0`. The route itself, LiveView mount, stylesheets, JavaScript bundle, and images load successfully. This is recorded as a development LiveReload tooling deviation; it did not prevent inspection of the rendered page or any required browser check. It is not evidence for component behavior.

```text
BLOCKED_BROWSER_ENVIRONMENT=NO
STOP=NONE
```
