defmodule LiveFrames do
  @moduledoc """
  Reusable, source-independent contracts for the LiveFrames compiler.

  Phase 2 owns the source-independent Design IR contract, frozen at 1.0.0.
  Phase 3 adds the source-independent TokenSet contract and the initial
  Automatic.css settings adapter under the reusable package. The TokenSet
  contract has no dependency on that adapter. There is still no Bricks parser,
  component catalogue, or generated UI; those boundaries belong to later
  phases of docs/00_LIVEFRAMES_MASTER_SPEC.md.
  """
end
