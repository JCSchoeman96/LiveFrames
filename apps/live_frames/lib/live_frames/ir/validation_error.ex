defmodule LiveFrames.IR.ValidationError do
  @moduledoc """
  Exception raised when strict IR validation fails.
  """

  defexception diagnostics: []

  @impl true
  def message(%{diagnostics: diagnostics}) do
    codes = Enum.map_join(diagnostics, ", ", &to_string(&1.code))
    "invalid LiveFrames Design IR" <> if(codes == "", do: "", else: ": " <> codes)
  end
end
