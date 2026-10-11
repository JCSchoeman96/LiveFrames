defmodule LiveFrames.Behavior.PrimitiveRegistry do
  @moduledoc false

  alias LiveFrames.Behavior.Binding.PrimitiveRef

  @spec resolve(term()) :: {:ok, {:selection_v1, non_neg_integer()}} | :error
  def resolve(%PrimitiveRef{} = reference) do
    if Map.keys(reference) |> Enum.sort() == [:__struct__, :definition_version, :kind] and
         reference.kind == "selection" and reference.definition_version == "1.0.0" do
      {:ok, {:selection_v1, 0}}
    else
      :error
    end
  end

  def resolve(_reference), do: :error
end
