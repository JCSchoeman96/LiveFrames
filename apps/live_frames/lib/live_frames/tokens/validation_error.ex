defmodule LiveFrames.Tokens.ValidationError do
  @moduledoc """
  Exception raised when strict TokenSet validation fails.
  """

  defexception diagnostics: []

  @impl true
  def message(%{diagnostics: diagnostics}) do
    codes = Enum.map_join(diagnostics, ", ", &to_string(&1.code))
    "invalid LiveFrames TokenSet" <> if(codes == "", do: "", else: ": " <> codes)
  end
end
