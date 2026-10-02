defmodule LiveFrames.ComponentizationPlan.ValidationError do
  @moduledoc """
  Exception raised by strict ComponentizationPlan validation and encoding.
  """

  defexception diagnostics: []

  @impl true
  def message(%{diagnostics: diagnostics}) do
    codes = Enum.map_join(diagnostics, ", ", &to_string(&1.code))
    "invalid LiveFrames ComponentizationPlan" <> if(codes == "", do: "", else: ": " <> codes)
  end
end
