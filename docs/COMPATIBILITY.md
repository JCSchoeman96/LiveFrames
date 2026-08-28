# Compatibility baseline

Verified locally on 2026-08-28:

| Tool or package | Version |
| --- | --- |
| Erlang/OTP | 28 (erts 16.1.1) |
| Elixir | 1.19.3 |
| Mix | 1.19.3 |
| Phoenix installer | 1.8.7 |
| Phoenix dependency lock | 1.8.13 |
| Phoenix LiveView dependency lock | 1.2.11 |
| PhoenixStorybook | 1.3.0 |
| Tailwind wrapper | 0.5.1 |
| Tailwind CLI | 4.1.12 |
| esbuild wrapper | 0.10.0 |
| esbuild binary | 0.25.0 |
| Phoenix Live Reload | 1.7.0 |
| Bandit dependency lock | 1.12.5 |
| Jason dependency lock | 1.4.5 |
| Phoenix PubSub dependency lock | 2.3.0 |
| lazy_html test dependency | 0.1.12 |

The lock file is the reproducible dependency record for this Phase 1
foundation. Major framework upgrades require a compatibility review because
later LiveFrames compiler contracts depend on Phoenix and LiveView behavior.
Tailwind and PhoenixStorybook are mounted only for the Phase 1 preview
surface; they do not introduce conversion or catalogue behavior.
