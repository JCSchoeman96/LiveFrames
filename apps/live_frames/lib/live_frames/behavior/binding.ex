defmodule LiveFrames.Behavior.Binding.PrimitiveRef do
  @moduledoc false
  @type t :: %__MODULE__{kind: String.t(), definition_version: String.t()}
  defstruct [:kind, :definition_version]
end

defmodule LiveFrames.Behavior.Binding.Trigger do
  @moduledoc false
  @type t :: %__MODULE__{kind: String.t(), origin_node_id: String.t() | nil}
  defstruct [:kind, :origin_node_id]
end

defmodule LiveFrames.Behavior.Binding.ControlledTarget do
  @moduledoc false
  @type t :: %__MODULE__{role: String.t(), node_id: String.t()}
  defstruct [:role, :node_id]
end

defmodule LiveFrames.Behavior.Binding.FocusPolicy do
  @moduledoc false
  @type t :: %__MODULE__{
          initial_strategy: String.t() | nil,
          initial_target_node_id: String.t() | nil,
          containment_strategy: String.t() | nil,
          movement_strategy: String.t() | nil,
          scope_node_id: String.t() | nil,
          restoration_strategy: String.t() | nil,
          restoration_target_node_id: String.t() | nil,
          restoration_fallback_node_id: String.t() | nil
        }
  defstruct initial_strategy: nil,
            initial_target_node_id: nil,
            containment_strategy: nil,
            movement_strategy: nil,
            scope_node_id: nil,
            restoration_strategy: nil,
            restoration_target_node_id: nil,
            restoration_fallback_node_id: nil
end

defmodule LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride do
  @moduledoc false
  @type canonical_value ::
          nil
          | boolean()
          | integer()
          | String.t()
          | [canonical_value()]
          | %{optional(String.t()) => canonical_value()}
  @type t :: %__MODULE__{
          mode: String.t(),
          authority_ref: String.t() | nil,
          state_mapping: %{optional(String.t()) => canonical_value()}
        }
  defstruct [:mode, :authority_ref, :state_mapping]
end

defmodule LiveFrames.Behavior.Binding do
  @moduledoc """
  Source-neutral structural representation of one behavior occurrence.
  """

  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.IR.SourceTrace

  @safe_integer 9_007_199_254_740_991
  @binding_fields [
    :binding_id,
    :ordinal,
    :primitive_ref,
    :owner_node_id,
    :binding_role,
    :initial_state,
    :primitive_policy_values,
    :triggers,
    :controlled_targets,
    :timer_policy,
    :focus_policy,
    :keyboard_policy,
    :motion_policy,
    :responsive_overrides,
    :diagnostics,
    :provenance,
    :source_trace
  ]
  @focus_fields [
    :initial_strategy,
    :initial_target_node_id,
    :containment_strategy,
    :movement_strategy,
    :scope_node_id,
    :restoration_strategy,
    :restoration_target_node_id,
    :restoration_fallback_node_id
  ]
  @type canonical_value ::
          nil
          | boolean()
          | integer()
          | String.t()
          | [canonical_value()]
          | %{optional(String.t()) => canonical_value()}
  @type cross_cutting_policy_values :: %{optional(String.t()) => canonical_value()}
  @type t :: %__MODULE__{
          binding_id: nil,
          ordinal: nil,
          primitive_ref: PrimitiveRef.t() | nil,
          owner_node_id: String.t() | nil,
          binding_role: String.t() | nil,
          initial_state: cross_cutting_policy_values() | nil,
          primitive_policy_values: cross_cutting_policy_values(),
          triggers: [Trigger.t()],
          controlled_targets: [ControlledTarget.t()],
          timer_policy: cross_cutting_policy_values() | nil,
          focus_policy: FocusPolicy.t() | nil,
          keyboard_policy: cross_cutting_policy_values() | nil,
          motion_policy: cross_cutting_policy_values() | nil,
          responsive_overrides: [ResponsiveBehaviorOverride.t()],
          diagnostics: list(),
          provenance: map(),
          source_trace: SourceTrace.t() | nil
        }

  defstruct binding_id: nil,
            ordinal: nil,
            primitive_ref: nil,
            owner_node_id: nil,
            binding_role: nil,
            initial_state: nil,
            primitive_policy_values: %{},
            triggers: [],
            controlled_targets: [],
            timer_policy: nil,
            focus_policy: nil,
            keyboard_policy: nil,
            motion_policy: nil,
            responsive_overrides: [],
            diagnostics: [],
            provenance: %{},
            source_trace: nil

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)

  @spec validate(term()) :: :ok | {:error, {:invalid_structure, String.t()}}
  def validate(%__MODULE__{} = binding) do
    with :ok <- exact_fields(binding, __MODULE__, @binding_fields, "binding"),
         :ok <- check(binding.binding_id == nil, "binding_id"),
         :ok <- check(binding.ordinal == nil, "ordinal"),
         :ok <- validate_primitive_ref(binding.primitive_ref),
         :ok <- validate_string(binding.owner_node_id, "owner_node_id"),
         :ok <- validate_string(binding.binding_role, "binding_role"),
         :ok <- validate_optional_object(binding.initial_state, "initial_state"),
         :ok <- validate_object(binding.primitive_policy_values, "primitive_policy_values"),
         :ok <- validate_triggers(binding.triggers),
         :ok <- validate_targets(binding.controlled_targets),
         :ok <- validate_optional_object(binding.timer_policy, "timer_policy"),
         :ok <- validate_focus_policy(binding.focus_policy, binding.owner_node_id),
         :ok <- validate_optional_object(binding.keyboard_policy, "keyboard_policy"),
         :ok <- validate_optional_object(binding.motion_policy, "motion_policy"),
         :ok <- validate_overrides(binding.responsive_overrides),
         :ok <- check(is_list(binding.diagnostics), "diagnostics"),
         :ok <-
           check(is_map(binding.provenance) and not is_struct(binding.provenance), "provenance"),
         :ok <-
           check(
             is_nil(binding.source_trace) or match?(%SourceTrace{}, binding.source_trace),
             "source_trace"
           ) do
      :ok
    end
  end

  def validate(_binding), do: invalid("binding")

  defp validate_primitive_ref(%PrimitiveRef{} = ref) do
    with :ok <- exact_fields(ref, PrimitiveRef, [:kind, :definition_version], "primitive_ref"),
         :ok <- validate_string(ref.kind, "primitive_ref.kind"),
         :ok <- validate_string(ref.definition_version, "primitive_ref.definition_version") do
      :ok
    end
  end

  defp validate_primitive_ref(_ref), do: invalid("primitive_ref")

  defp validate_triggers(triggers) when is_list(triggers) do
    triggers
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {trigger, index}, :ok ->
      path = "triggers[#{index}]"

      result =
        case trigger do
          %Trigger{} ->
            with :ok <- exact_fields(trigger, Trigger, [:kind, :origin_node_id], path),
                 :ok <- validate_string(trigger.kind, "#{path}.kind"),
                 :ok <- validate_optional_string(trigger.origin_node_id, "#{path}.origin_node_id") do
              :ok
            end

          _ ->
            invalid(path)
        end

      case result do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_triggers(_triggers), do: invalid("triggers")

  defp validate_targets(targets) when is_list(targets) do
    targets
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {target, index}, :ok ->
      path = "controlled_targets[#{index}]"

      result =
        case target do
          %ControlledTarget{} ->
            with :ok <- exact_fields(target, ControlledTarget, [:role, :node_id], path),
                 :ok <- validate_string(target.role, "#{path}.role"),
                 :ok <- validate_string(target.node_id, "#{path}.node_id") do
              :ok
            end

          _ ->
            invalid(path)
        end

      case result do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_targets(_targets), do: invalid("controlled_targets")

  defp validate_focus_policy(nil, _owner_node_id), do: :ok

  defp validate_focus_policy(%FocusPolicy{} = focus, owner_node_id) do
    with :ok <- exact_fields(focus, FocusPolicy, @focus_fields, "focus_policy"),
         :ok <- validate_optional_string(focus.initial_strategy, "focus_policy.initial_strategy"),
         :ok <-
           validate_optional_string(
             focus.containment_strategy,
             "focus_policy.containment_strategy"
           ),
         :ok <-
           validate_optional_string(focus.movement_strategy, "focus_policy.movement_strategy"),
         :ok <-
           validate_optional_string(
             focus.restoration_strategy,
             "focus_policy.restoration_strategy"
           ),
         :ok <-
           validate_optional_string(
             focus.initial_target_node_id,
             "focus_policy.initial_target_node_id"
           ),
         :ok <- validate_optional_string(focus.scope_node_id, "focus_policy.scope_node_id"),
         :ok <-
           validate_optional_string(
             focus.restoration_target_node_id,
             "focus_policy.restoration_target_node_id"
           ),
         :ok <-
           validate_optional_string(
             focus.restoration_fallback_node_id,
             "focus_policy.restoration_fallback_node_id"
           ),
         :ok <-
           check(
             is_nil(focus.scope_node_id) or focus.scope_node_id != owner_node_id,
             "focus_policy.scope_node_id"
           ) do
      :ok
    end
  end

  defp validate_focus_policy(_focus, _owner_node_id), do: invalid("focus_policy")

  defp validate_overrides(overrides) when is_list(overrides) do
    overrides
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, MapSet.new()}, fn {override, index}, {:ok, seen_modes} ->
      path = "responsive_overrides[#{index}]"

      result =
        case override do
          %ResponsiveBehaviorOverride{} ->
            with :ok <-
                   exact_fields(
                     override,
                     ResponsiveBehaviorOverride,
                     [:mode, :authority_ref, :state_mapping],
                     path
                   ),
                 :ok <- validate_string(override.mode, "#{path}.mode"),
                 :ok <- validate_optional_string(override.authority_ref, "#{path}.authority_ref"),
                 :ok <- validate_object(override.state_mapping, "#{path}.state_mapping"),
                 :ok <- check(not MapSet.member?(seen_modes, override.mode), "#{path}.mode") do
              {:ok, MapSet.put(seen_modes, override.mode)}
            end

          _ ->
            invalid(path)
        end

      case result do
        {:ok, next_modes} -> {:cont, {:ok, next_modes}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, _seen_modes} -> :ok
      error -> error
    end
  end

  defp validate_overrides(_overrides), do: invalid("responsive_overrides")

  defp validate_optional_object(nil, _path), do: :ok
  defp validate_optional_object(value, path), do: validate_object(value, path)

  defp validate_object(value, path) when is_map(value) and not is_struct(value) do
    if Enum.all?(Map.keys(value), &valid_string?/1) do
      validate_object_values(Map.to_list(value), path)
    else
      invalid(path)
    end
  end

  defp validate_object(_value, path), do: invalid(path)

  defp validate_value(nil, _path), do: :ok
  defp validate_value(value, _path) when is_boolean(value), do: :ok

  defp validate_value(value, _path)
       when is_integer(value) and value >= -@safe_integer and value <= @safe_integer,
       do: :ok

  defp validate_value(value, path) when is_binary(value) do
    check(valid_string?(value), path)
  end

  defp validate_value(value, path) when is_list(value), do: validate_list(value, path, 0)

  defp validate_value(value, path) when is_map(value) and not is_struct(value) do
    validate_object(value, path)
  end

  defp validate_value(_value, path), do: invalid(path)

  defp validate_object_values([], _path), do: :ok

  defp validate_object_values([{key, value} | rest], path) do
    with :ok <- validate_value(value, "#{path}.#{key}") do
      validate_object_values(rest, path)
    end
  end

  defp validate_list([], _path, _index), do: :ok

  defp validate_list([value | rest], path, index) do
    with :ok <- validate_value(value, "#{path}[#{index}]") do
      validate_list(rest, path, index + 1)
    end
  end

  defp validate_list(_improper_tail, path, index), do: invalid("#{path}[#{index}]")

  defp validate_string(value, path), do: check(is_binary(value) and valid_string?(value), path)
  defp validate_optional_string(nil, _path), do: :ok
  defp validate_optional_string(value, path), do: validate_string(value, path)

  defp valid_string?(value) when is_binary(value) do
    String.valid?(value) and
      Enum.all?(String.to_charlist(value), fn codepoint ->
        not (codepoint in 0xFDD0..0xFDEF or rem(codepoint, 65_536) in 65_534..65_535)
      end)
  end

  defp valid_string?(_value), do: false

  defp exact_fields(value, module, fields, path) do
    check(
      Map.get(value, :__struct__) == module and
        Enum.sort(Map.keys(value)) == Enum.sort([:__struct__ | fields]),
      path
    )
  end

  defp check(true, _path), do: :ok
  defp check(false, path), do: invalid(path)
  defp invalid(path), do: {:error, {:invalid_structure, path}}
end
