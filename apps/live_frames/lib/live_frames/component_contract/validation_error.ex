defmodule LiveFrames.ComponentContract.ValidationError do
  @moduledoc """
  Exception raised when strict ComponentContract validation fails.
  """

  defexception diagnostics: []

  @impl true
  def message(%{diagnostics: diagnostics}) do
    codes = Enum.map_join(diagnostics, ", ", &to_string(&1.code))
    "invalid LiveFrames ComponentContract" <> if(codes == "", do: "", else: ": " <> codes)
  end
end
