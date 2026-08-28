# LiveFrames Phase 1 preview and Storybook implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** Add the PhoenixStorybook, Tailwind v4, architecture-proof component and empty conversion-lab foundation required by LiveFrames Phase 1.

**Architecture:** Keep live_frames_preview -> live_frames. The reusable package owns one non-production Phoenix function component and has no dependency on preview code, source fixtures or Storybook. The preview app owns Storybook, browser assets, the conversion-lab LiveView and development watchers.

**Tech Stack:** Elixir 1.19.3, OTP 28, Phoenix 1.8.13, Phoenix LiveView 1.2.11, PhoenixStorybook 1.3.0, Tailwind wrapper 0.5.1 with Tailwind CSS 4.1.12, esbuild wrapper 0.10.0 with esbuild 0.25.0, Phoenix Live Reload 1.7.0, ExUnit and Phoenix LiveViewTest.

---

## File map

Modify:

- mix.exs: root asset setup/build aliases.
- .formatter.exs: Storybook script inputs.
- .gitignore: generated preview assets.
- config/config.exs: Tailwind and esbuild profiles.
- config/dev.exs: asset watchers and reload patterns.
- docs/COMPATIBILITY.md: Phase 1 dependency baseline.
- README.md: Phase 1 commands and routes.
- apps/live_frames/mix.exs: LiveView dependency for the proof component.
- apps/live_frames_preview/mix.exs: Storybook, asset and reload dependencies.
- apps/live_frames_preview/lib/live_frames_preview_web.ex: controller/layout/live-view macros.
- apps/live_frames_preview/lib/live_frames_preview_web/endpoint.ex: generated assets, sessions and reload.
- apps/live_frames_preview/lib/live_frames_preview_web/page_controller.ex: links to Phase 1 routes.
- apps/live_frames_preview/lib/live_frames_preview_web/router.ex: Storybook and lab routes.
- apps/live_frames_preview/test/test_helper.exs: endpoint support loading.

Create:

- apps/live_frames/lib/live_frames/proof_component.ex
- apps/live_frames/test/live_frames/proof_component_test.exs
- apps/live_frames_preview/lib/live_frames_preview_web/storybook.ex
- apps/live_frames_preview/lib/live_frames_preview_web/layouts.ex
- apps/live_frames_preview/lib/live_frames_preview_web/layouts/root.html.heex
- apps/live_frames_preview/lib/live_frames_preview_web/live/conversion_lab_live.ex
- apps/live_frames_preview/lib/live_frames_preview_web/live/conversion_lab_live.html.heex
- apps/live_frames_preview/storybook/components/proof_component.story.exs
- apps/live_frames_preview/assets/css/storybook.css
- apps/live_frames_preview/assets/js/app.js
- apps/live_frames_preview/assets/js/storybook.js
- apps/live_frames_preview/priv/static/assets/.gitkeep
- apps/live_frames_preview/test/support/conn_case.ex
- apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

Generated files under apps/live_frames_preview/priv/static/assets/ stay ignored.

### Task 1: Add the Phase 1 dependencies and asset profiles

**Files:**

- Modify: apps/live_frames/mix.exs
- Modify: apps/live_frames_preview/mix.exs
- Modify: mix.exs
- Modify: config/config.exs
- Modify: .gitignore
- Modify: .formatter.exs
- Create: apps/live_frames_preview/priv/static/assets/.gitkeep

- [ ] Step 1: Update dependency declarations and root aliases.

Use current compatible versions and keep preview-only tooling out of the reusable package:

~~~elixir
# apps/live_frames/mix.exs
defp deps do
  [{:phoenix_live_view, "~> 1.2.11"}]
end
~~~

~~~elixir
# apps/live_frames_preview/mix.exs
defp deps do
  [
    {:live_frames, in_umbrella: true},
    {:phoenix, "~> 1.8.13"},
    {:phoenix_live_view, "~> 1.2.11"},
    {:phoenix_storybook, "~> 1.3.0"},
    {:tailwind, "~> 0.5.1"},
    {:esbuild, "~> 0.10.0"},
    {:phoenix_live_reload, "~> 1.7", only: :dev},
    {:bandit, "~> 1.12"},
    {:jason, "~> 1.4"}
  ]
end
~~~

Add the root aliases to mix.exs:

~~~elixir
"assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
"assets.build": ["assets.setup", "tailwind storybook", "esbuild app", "esbuild storybook"]
~~~

Add the generated asset ignore:

~~~gitignore
/apps/live_frames_preview/priv/static/assets/*
!/apps/live_frames_preview/priv/static/assets/.gitkeep
~~~

Add apps/*/storybook/**/*.exs to the formatter inputs.

- [ ] Step 2: Configure CSS-first Tailwind and esbuild profiles.

Append these profiles to config/config.exs:

~~~elixir
config :tailwind,
  version: "4.1.12",
  storybook: [
    args: ~w(--input=assets/css/storybook.css --output=priv/static/assets/css/storybook.css),
    cd: Path.expand("apps/live_frames_preview", __DIR__)
  ]

config :esbuild,
  version: "0.25.0",
  app: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js),
    cd: Path.expand("apps/live_frames_preview/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("deps", __DIR__)}
  ],
  storybook: [
    args: ~w(js/storybook.js --bundle --target=es2022 --outdir=../priv/static/assets/js),
    cd: Path.expand("apps/live_frames_preview/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("deps", __DIR__)}
  ]
~~~

- [ ] Step 3: Fetch and inspect the resolved dependency graph.

Run:

~~~sh
mix deps.get
mix deps.tree --only runtime
~~~

Expected direct additions are phoenix_storybook, tailwind, esbuild and phoenix_live_reload. No database, Redis, Oban or ACSS runtime package may appear.

- [ ] Step 4: Commit the dependency boundary.

~~~sh
git add mix.exs mix.lock .formatter.exs .gitignore config/config.exs \
  apps/live_frames/mix.exs apps/live_frames_preview/mix.exs \
  apps/live_frames_preview/priv/static/assets/.gitkeep
git commit -m "build: add Phase 1 preview dependencies"
~~~

### Task 2: Add the library architecture-proof component

**Files:**

- Create: apps/live_frames/lib/live_frames/proof_component.ex
- Create: apps/live_frames/test/live_frames/proof_component_test.exs

- [ ] Step 1: Write the failing component test.

~~~elixir
defmodule LiveFrames.ProofComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "renders a labelled library-owned proof badge" do
    html =
      render_component(&LiveFrames.ProofComponent.proof_badge/1,
        label: "Library component"
      )

    assert html =~ ~s(data-liveframes-proof="true")
    assert html =~ "Library component"
    assert html =~ "lf-proof-badge"
  end
end
~~~

- [ ] Step 2: Run the focused test and confirm the expected missing-module failure.

Run: mix test apps/live_frames/test/live_frames/proof_component_test.exs

Expected: failure because LiveFrames.ProofComponent does not exist yet.

- [ ] Step 3: Implement the smallest function component.

~~~elixir
defmodule LiveFrames.ProofComponent do
  use Phoenix.Component

  attr :label, :string, default: "LiveFrames library"
  attr :class, :string, default: nil

  @doc "Renders the internal Phase 1 library-to-preview proof marker."
  def proof_badge(assigns) do
    ~H"""
    <span class={[@class, "lf-proof-badge"]} data-liveframes-proof="true">
      <span class="lf-proof-badge__mark" aria-hidden="true">+</span>
      <span><%= @label %></span>
    </span>
    """
  end
end
~~~

- [ ] Step 4: Run the focused and complete core tests.

Run: mix test apps/live_frames/test/live_frames/proof_component_test.exs

Expected: 1 test, 0 failures.

Run: mix test apps/live_frames

Expected: all core tests pass without warnings.

- [ ] Step 5: Commit the proof component.

~~~sh
git add apps/live_frames/lib/live_frames/proof_component.ex \
  apps/live_frames/test/live_frames/proof_component_test.exs
git commit -m "feat: add library-owned Phase 1 proof component"
~~~

### Task 3: Mount PhoenixStorybook and add the single proof story

**Files:**

- Modify: apps/live_frames_preview/lib/live_frames_preview_web.ex
- Modify: apps/live_frames_preview/lib/live_frames_preview_web/endpoint.ex
- Modify: apps/live_frames_preview/lib/live_frames_preview_web/router.ex
- Create: apps/live_frames_preview/lib/live_frames_preview_web/storybook.ex
- Create: apps/live_frames_preview/storybook/components/proof_component.story.exs
- Create: apps/live_frames_preview/test/support/conn_case.ex
- Modify: apps/live_frames_preview/test/test_helper.exs
- Create: apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

- [ ] Step 1: Write the failing Storybook route and story-contract tests.

Create test/support/conn_case.ex and load it from the test helper:

~~~elixir
defmodule LiveFramesPreviewWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint LiveFramesPreviewWeb.Endpoint
      use Phoenix.ConnTest
      import Phoenix.LiveViewTest
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
~~~

Add the failing assertions:

~~~elixir
defmodule LiveFramesPreviewWeb.Phase1Test do
  use LiveFramesPreviewWeb.ConnCase, async: true

  test "storybook route is mounted", %{conn: conn} do
    conn = get(conn, "/storybook/components/proof_component")

    assert conn.status == 200
    assert conn.resp_body =~ "LiveFrames Storybook"
  end

  test "storybook has exactly one Phase 1 story", _context do
    stories =
      Path.wildcard(
        Path.expand("../../storybook/**/*.story.exs", __DIR__)
      )

    assert stories == [
             Path.expand(
               "../../storybook/components/proof_component.story.exs",
               __DIR__
             )
           ]
  end
end
~~~

- [ ] Step 2: Run the preview tests and verify the expected route failure.

Run: mix test apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

Expected: the Storybook test fails because the dependency, backend and route are not mounted yet. The story-count test fails until the story file exists.

- [ ] Step 3: Add the backend, session support and routes.

Create the backend:

~~~elixir
defmodule LiveFramesPreviewWeb.Storybook do
  use PhoenixStorybook,
    otp_app: :live_frames_preview,
    content_path: Path.expand("../../storybook", __DIR__),
    css_path: "/assets/css/storybook.css",
    js_path: "/assets/js/storybook.js",
    sandbox_class: "live-frames",
    title: "LiveFrames Storybook"
end
~~~

Add Plug.Session to the endpoint before the router:

~~~elixir
plug Plug.Session,
  store: :cookie,
  key: "_live_frames_key",
  signing_salt: "liveframes-session"
~~~

Extend the browser pipeline with the standard LiveView plugs:

~~~elixir
plug :accepts, ["html"]
plug :fetch_session
plug :fetch_live_flash
plug :put_root_layout, html: {LiveFramesPreviewWeb.Layouts, :root}
plug :protect_from_forgery
plug :put_secure_browser_headers
~~~

Mount Storybook assets without the browser pipeline and the Storybook LiveView inside it:

~~~elixir
import PhoenixStorybook.Router

scope "/" do
  storybook_assets()
end

scope "/", LiveFramesPreviewWeb do
  pipe_through :browser
  live_storybook "/storybook", backend_module: LiveFramesPreviewWeb.Storybook
end
~~~

- [ ] Step 4: Add the proof story.

~~~elixir
defmodule LiveFramesPreviewWeb.Storybook.Components.ProofComponent do
  use PhoenixStorybook.Story, :component

  alias PhoenixStorybook.Stories.Variation

  def function, do: &LiveFrames.ProofComponent.proof_badge/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Library component"}
      }
    ]
  end

  def layout, do: :one_column
  def render_source, do: :function
end
~~~

- [ ] Step 5: Run the focused Storybook tests and compile with warnings as errors.

Run: mix test apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

Expected: the route returns 200 and the story-count assertion passes.

Run: mix compile --warnings-as-errors

Expected: compilation succeeds with no warnings.

- [ ] Step 6: Commit the Storybook integration.

~~~sh
git add apps/live_frames_preview/lib apps/live_frames_preview/storybook \
  apps/live_frames_preview/test
git commit -m "feat: mount Phase 1 PhoenixStorybook"
~~~

### Task 4: Add Tailwind v4 and browser bundles

**Files:**

- Modify: config/dev.exs
- Create: apps/live_frames_preview/assets/css/storybook.css
- Create: apps/live_frames_preview/assets/js/app.js
- Create: apps/live_frames_preview/assets/js/storybook.js
- Modify: apps/live_frames_preview/lib/live_frames_preview_web/endpoint.ex
- Create: apps/live_frames_preview/priv/static/assets/.gitkeep

- [ ] Step 1: Add an asset-build check that fails before inputs exist.

Run:

~~~sh
mix tailwind storybook
~~~

Expected: failure because assets/css/storybook.css has not been created.

- [ ] Step 2: Add the CSS-first Tailwind input.

~~~css
@import "tailwindcss" source(none);

@source "../../lib/live_frames_preview_web";
@source "../../storybook";

@layer components {
  .live-frames .lf-proof-badge {
    align-items: center;
    background: #172033;
    border: 1px solid #5eead4;
    border-radius: 999px;
    color: #ccfbf1;
    display: inline-flex;
    gap: 0.5rem;
    padding: 0.5rem 0.75rem;
  }

  .live-frames .lf-proof-badge__mark {
    align-items: center;
    background: #5eead4;
    border-radius: 999px;
    color: #172033;
    display: inline-flex;
    font-weight: 700;
    height: 1.25rem;
    justify-content: center;
    width: 1.25rem;
  }
}
~~~

- [ ] Step 3: Add the LiveView and Storybook JavaScript entry points.

assets/js/app.js:

~~~javascript
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document.querySelector("meta[name='csrf-token']");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken?.getAttribute("content") }
});

liveSocket.connect();
window.liveSocket = liveSocket;
~~~

assets/js/storybook.js:

~~~javascript
window.storybook = {
  Hooks: {},
  Params: {},
  Uploaders: {}
};
~~~

Update Plug.Static to serve assets as well as robots.txt:

~~~elixir
only: ~w(assets robots.txt)
~~~

- [ ] Step 4: Configure development watchers and reload patterns.

Add watchers and live_reload to the endpoint config in config/dev.exs:

~~~elixir
watchers: [
  tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]},
  esbuild_app: {Esbuild, :install_and_run, [:app, ~w(--watch --sourcemap=inline)]},
  esbuild_storybook: {Esbuild, :install_and_run, [:storybook, ~w(--watch --sourcemap=inline)]}
],
live_reload: [
  patterns: [
    ~r"priv/static/.*(js|css)$",
    ~r"lib/live_frames_preview_web/.*(ex|heex)$",
    ~r"storybook/.*\.exs$"
  ]
]
~~~

In the endpoint, add the development-only plug:

~~~elixir
if code_reloading? do
  plug Phoenix.LiveReloader
end
~~~

- [ ] Step 5: Build both bundles and check their contents.

Run:

~~~sh
mix assets.build
test -s apps/live_frames_preview/priv/static/assets/css/storybook.css
test -s apps/live_frames_preview/priv/static/assets/js/app.js
test -s apps/live_frames_preview/priv/static/assets/js/storybook.js
rg -q "lf-proof-badge" apps/live_frames_preview/priv/static/assets/css/storybook.css
rg -q "liveSocket" apps/live_frames_preview/priv/static/assets/js/app.js
rg -q "window.storybook" apps/live_frames_preview/priv/static/assets/js/storybook.js
~~~

Expected: all commands succeed and generated files remain ignored.

- [ ] Step 6: Commit the asset pipeline.

~~~sh
git add config/dev.exs apps/live_frames_preview/assets \
  apps/live_frames_preview/lib/live_frames_preview_web/endpoint.ex \
  apps/live_frames_preview/priv/static/assets/.gitkeep
git commit -m "feat: add Tailwind and preview asset builds"
~~~

### Task 5: Add the conversion-lab shell and shared layout

**Files:**

- Modify: apps/live_frames_preview/lib/live_frames_preview_web.ex
- Create: apps/live_frames_preview/lib/live_frames_preview_web/layouts.ex
- Create: apps/live_frames_preview/lib/live_frames_preview_web/layouts/root.html.heex
- Create: apps/live_frames_preview/lib/live_frames_preview_web/live/conversion_lab_live.ex
- Create: apps/live_frames_preview/lib/live_frames_preview_web/live/conversion_lab_live.html.heex
- Modify: apps/live_frames_preview/lib/live_frames_preview_web/router.ex
- Modify: apps/live_frames_preview/lib/live_frames_preview_web/page_controller.ex
- Modify: apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

- [ ] Step 1: Write the failing conversion-lab test.

Add to phase_1_test.exs:

~~~elixir
test "conversion lab renders the static inspection regions", %{conn: conn} do
  {:ok, _view, html} = live(conn, "/liveframes/lab")

  assert html =~ "LiveFrames Conversion Lab"
  assert html =~ "Source metadata"
  assert html =~ "Normalized tokens"
  assert html =~ "Design IR"
  assert html =~ "Diagnostics"
  assert html =~ "Phase 1 shell"
end
~~~

- [ ] Step 2: Run the focused test and confirm the route is missing.

Run: mix test apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

Expected: the new test fails because /liveframes/lab is not routed.

- [ ] Step 3: Add the shared root layout.

Update the LiveView macro:

~~~elixir
def live_view do
  quote do
    use Phoenix.LiveView, layout: {LiveFramesPreviewWeb.Layouts, :root}
    import Phoenix.Component
    alias Phoenix.LiveView.JS
  end
end
~~~

Create layouts.ex:

~~~elixir
defmodule LiveFramesPreviewWeb.Layouts do
  use LiveFramesPreviewWeb, :html

  embed_templates "layouts"
end
~~~

Create layouts/root.html.heex:

~~~heex
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
    <title><%= assigns[:page_title] || "LiveFrames Preview" %></title>
    <link rel="stylesheet" href="/assets/css/storybook.css" phx-track-static />
  </head>
  <body class="live-frames bg-slate-950 text-slate-100">
    <%= @inner_content %>
    <script defer type="text/javascript" src="/assets/js/app.js" phx-track-static></script>
  </body>
</html>
~~~

- [ ] Step 4: Add the static conversion-lab LiveView and route.

conversion_lab_live.ex:

~~~elixir
defmodule LiveFramesPreviewWeb.ConversionLabLive do
  use LiveFramesPreviewWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Conversion Lab")}
  end
end
~~~

conversion_lab_live.html.heex:

~~~heex
<main class="mx-auto max-w-6xl space-y-8 px-6 py-12">
  <header class="max-w-3xl space-y-3">
    <p class="text-sm font-semibold uppercase tracking-[0.2em] text-teal-300">Phase 1 shell</p>
    <h1 class="text-4xl font-semibold tracking-tight">LiveFrames Conversion Lab</h1>
    <p class="text-slate-300">
      The inspection surface is ready. Conversion data will arrive in a later phase.
    </p>
  </header>

  <section class="grid gap-4 md:grid-cols-2" aria-label="Future inspection regions">
    <article class="rounded-2xl border border-slate-700 bg-slate-900 p-6">
      <h2 class="text-xl font-medium">Source metadata</h2>
      <p class="mt-2 text-slate-400">No source selected.</p>
    </article>
    <article class="rounded-2xl border border-slate-700 bg-slate-900 p-6">
      <h2 class="text-xl font-medium">Normalized tokens</h2>
      <p class="mt-2 text-slate-400">No token set selected.</p>
    </article>
    <article class="rounded-2xl border border-slate-700 bg-slate-900 p-6">
      <h2 class="text-xl font-medium">Design IR</h2>
      <p class="mt-2 text-slate-400">No Design IR document selected.</p>
    </article>
    <article class="rounded-2xl border border-slate-700 bg-slate-900 p-6">
      <h2 class="text-xl font-medium">Diagnostics</h2>
      <p class="mt-2 text-slate-400">No conversion diagnostics.</p>
    </article>
  </section>
</main>
~~~

Add this route inside the browser scope:

~~~elixir
live "/liveframes/lab", ConversionLabLive, :index
~~~

- [ ] Step 5: Link the routes from the home page.

Add these links to the existing home HTML:

~~~html
<nav aria-label="Preview tools">
  <a href="/storybook">Open Storybook</a>
  <a href="/liveframes/lab">Open Conversion Lab</a>
</nav>
~~~

- [ ] Step 6: Run the lab tests and commit.

Run: mix test apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

Expected: Storybook and conversion-lab tests pass.

~~~sh
git add apps/live_frames_preview/lib apps/live_frames_preview/test
git commit -m "feat: add the Phase 1 conversion lab shell"
~~~

### Task 6: Update documentation and run the Phase 1 gate

**Files:**

- Modify: README.md
- Modify: docs/COMPATIBILITY.md
- Modify: apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs

- [ ] Step 1: Document the Phase 1 commands and routes.

Add to README.md:

~~~markdown
## Phase 1 preview tools

Build the browser assets with mix assets.build. Start development with
PORT=4400 mix phx.server when port 4000 is already occupied.

- /storybook contains the single architecture-proof story.
- /liveframes/lab is the empty conversion-lab shell.

Storybook and the lab use the CSS-first Tailwind v4 bundle. ACSS settings,
Bricks JSON, Design IR and real catalogue content remain deferred.
~~~

Record Phoenix 1.8.13, Phoenix LiveView 1.2.11, PhoenixStorybook 1.3.0,
Tailwind wrapper 0.5.1, Tailwind CLI 4.1.12, esbuild wrapper 0.10.0,
esbuild 0.25.0 and Phoenix Live Reload 1.7.0 in docs/COMPATIBILITY.md.

- [ ] Step 2: Add the development configuration assertion.

Add a test that reads config/dev.exs and asserts it contains the three watcher
profiles and the Storybook story reload pattern. This keeps the hot-reload gate
visible in the tests without loading development configuration into the test
environment.

- [ ] Step 3: Run the complete Phase 1 verification.

Run:

~~~sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix assets.build
mix test
mix deps.unlock --check-unused
git diff --check
~~~

Expected: all commands exit successfully; no unused locked dependencies are
reported; generated assets are ignored.

- [ ] Step 4: Smoke-test the running preview.

Start the server in a PTY:

~~~sh
PORT=4400 mix phx.server
~~~

From another shell, run:

~~~sh
curl --fail --silent http://127.0.0.1:4400/health
curl --fail --silent --location http://127.0.0.1:4400/storybook
curl --fail --silent http://127.0.0.1:4400/liveframes/lab
~~~

Confirm the Storybook response includes LiveFrames Storybook, the lab response
includes LiveFrames Conversion Lab, and the server output reports the
development endpoint with the configured watchers. Touching the Storybook story
file must trigger its configured reload path. Do not add conversion logic while
testing this behavior.

- [ ] Step 5: Commit documentation and final Phase 1 changes.

~~~sh
git add README.md docs/COMPATIBILITY.md \
  apps/live_frames_preview/test/live_frames_preview_web/phase_1_test.exs
git commit -m "docs: record the Phase 1 preview gate"
~~~

- [ ] Step 6: Stop at the Phase 1 gate.

Do not begin Hero India, Bricks parsing, ACSS normalization, Design IR, real
catalogue content or generator work in this plan.
