# Compatibility baseline

Verified locally on 2026-08-28:

| Tool or package | Version |
| --- | --- |
| Erlang/OTP | 28 (erts 16.1.1) |
| Elixir | 1.19.3 |
| Mix | 1.19.3 |
| Phoenix installer | 1.8.7 |
| Phoenix dependency lock | 1.8.9 |
| Phoenix LiveView dependency lock | 1.1.33 |
| Bandit dependency lock | 1.12.5 |
| Jason dependency lock | 1.4.5 |
| Phoenix PubSub dependency lock | 2.2.0 |

The lock file is the reproducible dependency record for this Phase 0
foundation. Major framework upgrades require a compatibility review because
later LiveFrames compiler contracts depend on Phoenix and LiveView behavior.
Tailwind v4 and PhoenixStorybook are intentionally deferred to Phase 1.
