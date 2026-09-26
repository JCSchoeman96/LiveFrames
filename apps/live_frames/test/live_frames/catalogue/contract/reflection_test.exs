defmodule LiveFrames.Catalogue.Contract.ReflectionTest.PhoenixFixture do
  use Phoenix.Component, global_prefixes: ["x-"]

  Module.register_attribute(__MODULE__, :liveframes_public_contract_metadata, persist: true)

  @liveframes_public_contract_metadata %{
    sample: %{
      capabilities: ["liveframes.test.fixture"],
      css_theme_contract: ["--lf-fixture-color"],
      global_prefixes: ["x-"]
    }
  }

  attr(:title, :string, required: true)
  attr(:level, :integer, default: 2, values: 1..6)
  attr(:rest, :global, include: ~w(id data-testid))

  slot :actions do
    attr(:label, :string, required: true)
  end

  def sample(assigns) do
    ~H"""
    <div {@rest}>
      <span>{@title} {@level}</span>
      <%= for action <- @actions do %>
        <button><%= action.label %></button>
      <% end %>
    </div>
    """
  end
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.ManualFixtures do
  @base_attr %{
    slot: nil,
    name: :title,
    type: :string,
    required: true,
    opts: [],
    doc: nil,
    line: 1
  }

  @slot_attr %{@base_attr | slot: :actions, name: :label}

  @base_slot %{
    name: :actions,
    required: false,
    opts: [],
    doc: nil,
    line: 2,
    attrs: [@slot_attr],
    validate_attrs: true
  }

  @base_component %{
    kind: :def,
    attrs: [@base_attr],
    slots: [@base_slot],
    line: 1
  }

  @component_functions [
    :valid,
    :valid_type_forms,
    :cardinality_unbounded,
    :component_missing,
    :component_extra_key,
    :attr_extra_key,
    :attr_has_slot,
    :attr_unknown_type,
    :attr_invalid_struct_type,
    :attr_invalid_fun_arity,
    :attr_unknown_option,
    :slot_extra_key,
    :slot_option,
    :slot_attr_wrong_slot,
    :slot_attr_global,
    :metadata_function_missing,
    :metadata_extra_key,
    :capability_invalid,
    :capability_unsorted,
    :capability_duplicate,
    :capability_invalid_utf8,
    :css_invalid,
    :css_invalid_utf8,
    :css_unsorted,
    :prefix_invalid,
    :prefix_unsorted,
    :prefix_duplicate,
    :cardinality_unknown_slot,
    :cardinality_invalid_tuple,
    :cardinality_negative_min,
    :cardinality_max_below_min
  ]

  @empty_metadata %{
    capabilities: [],
    css_theme_contract: [],
    global_prefixes: []
  }

  @metadata_functions @component_functions -- [:component_missing, :metadata_function_missing]

  @metadata_base (for function <- @metadata_functions, into: %{} do
                    {function, @empty_metadata}
                  end)

  @metadata Map.merge(@metadata_base, %{
              metadata_extra_key: Map.put(@empty_metadata, :unexpected, true),
              capability_invalid: %{@empty_metadata | capabilities: ["Not.Valid"]},
              capability_unsorted: %{@empty_metadata | capabilities: ["z.last", "a.first"]},
              capability_duplicate: %{@empty_metadata | capabilities: ["a.same", "a.same"]},
              capability_invalid_utf8: %{@empty_metadata | capabilities: [<<0xFF>>]},
              css_invalid: %{@empty_metadata | css_theme_contract: ["--lf-"]},
              css_invalid_utf8: %{@empty_metadata | css_theme_contract: [<<0xFF>>]},
              css_unsorted: %{@empty_metadata | css_theme_contract: ["--lf-z", "--lf-a"]},
              prefix_invalid: %{@empty_metadata | global_prefixes: ["data"]},
              prefix_unsorted: %{@empty_metadata | global_prefixes: ["z-", "a-"]},
              prefix_duplicate: %{@empty_metadata | global_prefixes: ["a-", "a-"]},
              cardinality_unknown_slot:
                Map.put(@empty_metadata, :slot_cardinality, %{"missing" => {0, 1}}),
              cardinality_unbounded:
                Map.put(@empty_metadata, :slot_cardinality, %{"actions" => {0, nil}}),
              cardinality_invalid_tuple:
                Map.put(@empty_metadata, :slot_cardinality, %{"actions" => [0, 1]}),
              cardinality_negative_min:
                Map.put(@empty_metadata, :slot_cardinality, %{"actions" => {-1, 1}}),
              cardinality_max_below_min:
                Map.put(@empty_metadata, :slot_cardinality, %{"actions" => {2, 1}})
            })

  @recognized_type_pairs [
    {:any_value, :any},
    {:boolean_value, :boolean},
    {:integer_value, :integer},
    {:float_value, :float},
    {:string_value, :string},
    {:atom_value, :atom},
    {:list_value, :list},
    {:map_value, :map},
    {:fun_value, :fun},
    {:global_value, :global},
    {:struct_value, {:struct, Date}},
    {:function_arity_value, {:fun, 2}}
  ]

  @recognized_type_attrs (for {name, type} <- @recognized_type_pairs do
                            %{@base_attr | name: name, type: type}
                          end)

  @components %{
    valid: @base_component,
    valid_type_forms: %{@base_component | attrs: @recognized_type_attrs},
    component_extra_key: Map.put(@base_component, :unexpected, true),
    attr_extra_key: %{
      @base_component
      | attrs: [Map.put(@base_attr, :unexpected, true)]
    },
    attr_has_slot: %{
      @base_component
      | attrs: [%{@base_attr | slot: :actions}]
    },
    attr_unknown_type: %{
      @base_component
      | attrs: [%{@base_attr | type: {:unknown, :type}}]
    },
    attr_invalid_struct_type: %{
      @base_component
      | attrs: [%{@base_attr | type: {:struct, :not_a_module}}]
    },
    attr_invalid_fun_arity: %{
      @base_component
      | attrs: [%{@base_attr | type: {:fun, :two}}]
    },
    attr_unknown_option: %{
      @base_component
      | attrs: [%{@base_attr | opts: [unknown: true]}]
    },
    slot_extra_key: %{
      @base_component
      | slots: [Map.put(@base_slot, :unexpected, true)]
    },
    slot_option: %{
      @base_component
      | slots: [%{@base_slot | opts: [unexpected: true]}]
    },
    slot_attr_wrong_slot: %{
      @base_component
      | slots: [%{@base_slot | attrs: [%{@slot_attr | slot: :other}]}]
    },
    slot_attr_global: %{
      @base_component
      | slots: [%{@base_slot | attrs: [%{@slot_attr | type: :global}]}]
    },
    metadata_function_missing: @base_component,
    metadata_extra_key: @base_component,
    capability_invalid: @base_component,
    capability_unsorted: @base_component,
    capability_duplicate: @base_component,
    capability_invalid_utf8: @base_component,
    css_invalid: @base_component,
    css_invalid_utf8: @base_component,
    css_unsorted: @base_component,
    prefix_invalid: @base_component,
    prefix_unsorted: @base_component,
    prefix_duplicate: @base_component,
    cardinality_unknown_slot: @base_component,
    cardinality_unbounded: @base_component,
    cardinality_invalid_tuple: @base_component,
    cardinality_negative_min: @base_component,
    cardinality_max_below_min: @base_component
  }

  Module.register_attribute(__MODULE__, :liveframes_public_contract_metadata, persist: true)
  @liveframes_public_contract_metadata @metadata

  for function <- @component_functions do
    def unquote(function)(_assigns), do: :ok
  end

  def __components__, do: @components
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.GlobalCandidateFixtures do
  @component %{kind: :def, attrs: [], slots: [], line: 1}

  @metadata %{
    rejected: %{capabilities: [], css_theme_contract: [], global_prefixes: ["reject-"]},
    raises: %{capabilities: [], css_theme_contract: [], global_prefixes: ["raise-"]}
  }

  Module.register_attribute(__MODULE__, :liveframes_public_contract_metadata, persist: true)
  @liveframes_public_contract_metadata @metadata

  def rejected(_assigns), do: :ok
  def raises(_assigns), do: :ok
  def __components__, do: %{rejected: @component, raises: @component}

  def __global__?(candidate) do
    if String.starts_with?(candidate, "raise-") do
      raise "fixture global prefix error"
    else
      false
    end
  end
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.MissingComponents do
  def sample(assigns), do: assigns
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.RaisedComponents do
  def sample(assigns), do: assigns
  def __components__, do: raise("fixture reflection error")
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.ThrownComponents do
  def sample(assigns), do: assigns
  def __components__, do: throw(:fixture_reflection_error)
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.NonMapComponents do
  def sample(assigns), do: assigns
  def __components__, do: [:not, :a, :map]
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.MissingMetadata do
  def sample(assigns), do: assigns

  def __components__ do
    %{
      sample: %{
        kind: :def,
        attrs: [],
        slots: [],
        line: 1
      }
    }
  end
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest.MultipleMetadata do
  Module.register_attribute(__MODULE__, :liveframes_public_contract_metadata,
    persist: true,
    accumulate: true
  )

  @liveframes_public_contract_metadata %{
    sample: %{capabilities: [], css_theme_contract: [], global_prefixes: []}
  }

  @liveframes_public_contract_metadata %{
    sample: %{capabilities: [], css_theme_contract: [], global_prefixes: []}
  }

  def sample(assigns), do: assigns

  def __components__ do
    %{
      sample: %{
        kind: :def,
        attrs: [],
        slots: [],
        line: 1
      }
    }
  end
end

defmodule LiveFrames.Catalogue.Contract.ReflectionTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Contract.Reflection
  alias LiveFrames.Catalogue.Contract.ReflectionTest.GlobalCandidateFixtures
  alias LiveFrames.Catalogue.Contract.ReflectionTest.ManualFixtures
  alias LiveFrames.Catalogue.Contract.ReflectionTest.MissingComponents
  alias LiveFrames.Catalogue.Contract.ReflectionTest.MissingMetadata
  alias LiveFrames.Catalogue.Contract.ReflectionTest.MultipleMetadata
  alias LiveFrames.Catalogue.Contract.ReflectionTest.NonMapComponents
  alias LiveFrames.Catalogue.Contract.ReflectionTest.PhoenixFixture
  alias LiveFrames.Catalogue.Contract.ReflectionTest.RaisedComponents
  alias LiveFrames.Catalogue.Contract.ReflectionTest.ThrownComponents
  alias LiveFrames.Components.Sections.Hero

  test "reads Hero's exact raw Phoenix reflection and persisted metadata" do
    assert Application.spec(:phoenix_live_view, :vsn) == ~c"1.2.11"

    assert {:ok, %{component: component, metadata: metadata}} = Reflection.read(Hero, :hero)

    assert Map.keys(component) |> MapSet.new() == MapSet.new([:kind, :attrs, :slots, :line])
    assert component.kind == :def

    assert component.attrs
           |> Enum.map(& &1.name)
           |> Enum.sort() ==
             [:class, :heading, :heading_level, :id, :image_alt, :image_src, :lede, :rest]

    assert Enum.all?(component.attrs, &(&1.slot == nil))

    assert component.slots
           |> Enum.map(& &1.name)
           |> Enum.sort() == [:primary_action, :secondary_action]

    assert [persisted_metadata] =
             Hero.__info__(:attributes)[:liveframes_public_contract_metadata]

    assert metadata == Map.fetch!(persisted_metadata, :hero)

    assert length(metadata.capabilities) == 5
    assert length(metadata.css_theme_contract) == 34
    assert metadata.global_prefixes == []

    assert metadata.slot_cardinality == %{
             "primary_action" => {0, 1},
             "secondary_action" => {0, 1}
           }

    heading_level = Enum.find(component.attrs, &(&1.name == :heading_level))
    assert Keyword.fetch!(heading_level.opts, :default) == 2
    assert Keyword.fetch!(heading_level.opts, :values) == 1..6
  end

  test "reads a real Phoenix component with raw attrs, a slot attr, and custom global metadata" do
    assert {:ok, %{component: component, metadata: metadata}} =
             Reflection.read(PhoenixFixture, :sample)

    assert component.kind == :def
    assert Enum.any?(component.attrs, &(&1.name == :title and &1.required))

    level = Enum.find(component.attrs, &(&1.name == :level))
    assert level.opts == [default: 2, values: 1..6]

    rest = Enum.find(component.attrs, &(&1.name == :rest))
    assert rest.type == :global
    assert rest.opts == [include: ["id", "data-testid"]]

    assert [%{name: :actions, attrs: [label_attr], opts: []}] = component.slots
    assert label_attr.slot == :actions
    assert label_attr.name == :label
    assert label_attr.required

    assert metadata == %{
             capabilities: ["liveframes.test.fixture"],
             css_theme_contract: ["--lf-fixture-color"],
             global_prefixes: ["x-"]
           }
  end

  test "accepts only the documented raw Phoenix attr type forms without normalization" do
    assert {:ok, %{component: component, metadata: metadata}} =
             Reflection.read(ManualFixtures, :valid_type_forms)

    assert Enum.map(component.attrs, & &1.type) == [
             :any,
             :boolean,
             :integer,
             :float,
             :string,
             :atom,
             :list,
             :map,
             :fun,
             :global,
             {:struct, Date},
             {:fun, 2}
           ]

    assert metadata == %{capabilities: [], css_theme_contract: [], global_prefixes: []}
  end

  test "accepts empty global prefixes without requiring a Phoenix prefix validator" do
    assert {:ok, %{metadata: %{global_prefixes: []}}} = Reflection.read(ManualFixtures, :valid)
  end

  test "rejects invalid targets and unavailable reflection functions" do
    assert_error(
      Reflection.read(nil, :sample),
      "catalogue.contract.reflection.target_invalid",
      "$"
    )

    assert_error(
      Reflection.read(ManualFixtures, "valid"),
      "catalogue.contract.reflection.target_invalid",
      "$"
    )

    assert_error(
      Reflection.read(ManualFixtures, :function_not_exported),
      "catalogue.contract.reflection.target_invalid",
      "$"
    )

    assert_error(
      Reflection.read(AbsentComponent, :sample),
      "catalogue.contract.reflection.target_invalid",
      "$"
    )

    assert_error(
      Reflection.read(MissingComponents, :sample),
      "catalogue.contract.reflection.component_invalid",
      "$.component"
    )
  end

  test "rejects missing component entries and malformed Phoenix component entries" do
    assert_error(
      Reflection.read(ManualFixtures, :component_missing),
      "catalogue.contract.reflection.component_invalid",
      "$.component"
    )

    for {function, code, path} <- [
          {:component_extra_key, "catalogue.contract.reflection.component_invalid",
           "$.component"},
          {:attr_extra_key, "catalogue.contract.reflection.attr_invalid", "$.component.attrs[0]"},
          {:attr_has_slot, "catalogue.contract.reflection.attr_invalid", "$.component.attrs[0]"},
          {:attr_unknown_type, "catalogue.contract.reflection.attr_invalid",
           "$.component.attrs[0].type"},
          {:attr_invalid_struct_type, "catalogue.contract.reflection.attr_invalid",
           "$.component.attrs[0].type"},
          {:attr_invalid_fun_arity, "catalogue.contract.reflection.attr_invalid",
           "$.component.attrs[0].type"},
          {:attr_unknown_option, "catalogue.contract.reflection.attr_invalid",
           "$.component.attrs[0].opts"},
          {:slot_extra_key, "catalogue.contract.reflection.slot_invalid", "$.component.slots[0]"},
          {:slot_option, "catalogue.contract.reflection.slot_invalid",
           "$.component.slots[0].opts"},
          {:slot_attr_wrong_slot, "catalogue.contract.reflection.attr_invalid",
           "$.component.slots[0].attrs[0]"},
          {:slot_attr_global, "catalogue.contract.reflection.attr_invalid",
           "$.component.slots[0].attrs[0].type"}
        ] do
      assert_error(Reflection.read(ManualFixtures, function), code, path)
    end
  end

  test "catches raised, thrown, and non-map reflection results" do
    for module <- [RaisedComponents, ThrownComponents, NonMapComponents] do
      assert_error(
        Reflection.read(module, :sample),
        "catalogue.contract.reflection.component_invalid",
        "$.component"
      )
    end
  end

  test "rejects absent, repeated, and missing-function persisted metadata" do
    assert_error(
      Reflection.read(MissingMetadata, :sample),
      "catalogue.contract.reflection.metadata_invalid",
      "$.metadata"
    )

    assert length(
             Keyword.get_values(
               MultipleMetadata.__info__(:attributes),
               :liveframes_public_contract_metadata
             )
           ) == 2

    assert_error(
      Reflection.read(MultipleMetadata, :sample),
      "catalogue.contract.reflection.metadata_invalid",
      "$.metadata"
    )

    assert_error(
      Reflection.read(ManualFixtures, :metadata_function_missing),
      "catalogue.contract.reflection.metadata_function_missing",
      "$.metadata"
    )

    assert_error(
      Reflection.read(ManualFixtures, :metadata_extra_key),
      "catalogue.contract.reflection.metadata_invalid",
      "$.metadata"
    )
  end

  test "requires sorted unique capability identifiers" do
    for {function, path} <- [
          {:capability_invalid, "$.metadata.capabilities[0]"},
          {:capability_unsorted, "$.metadata.capabilities"},
          {:capability_duplicate, "$.metadata.capabilities"},
          {:capability_invalid_utf8, "$.metadata.capabilities[0]"}
        ] do
      assert_error(
        Reflection.read(ManualFixtures, function),
        "catalogue.contract.reflection.metadata_invalid",
        path
      )
    end
  end

  test "requires exact sorted unique CSS identifiers and global prefixes" do
    for {function, path} <- [
          {:css_invalid, "$.metadata.css_theme_contract[0]"},
          {:css_invalid_utf8, "$.metadata.css_theme_contract[0]"},
          {:css_unsorted, "$.metadata.css_theme_contract"},
          {:prefix_invalid, "$.metadata.global_prefixes[0]"},
          {:prefix_unsorted, "$.metadata.global_prefixes"},
          {:prefix_duplicate, "$.metadata.global_prefixes"}
        ] do
      assert_error(
        Reflection.read(ManualFixtures, function),
        "catalogue.contract.reflection.metadata_invalid",
        path
      )
    end
  end

  test "fails when a declared global prefix candidate is rejected or raises" do
    for function <- [:rejected, :raises] do
      assert_error(
        Reflection.read(GlobalCandidateFixtures, function),
        "catalogue.contract.reflection.metadata_invalid",
        "$.metadata.global_prefixes[0]"
      )
    end
  end

  test "validates slot-cardinality slot names and bounds" do
    assert {:ok, %{metadata: %{slot_cardinality: %{"actions" => {0, nil}}}}} =
             Reflection.read(ManualFixtures, :cardinality_unbounded)

    for function <- [
          :cardinality_unknown_slot,
          :cardinality_invalid_tuple,
          :cardinality_negative_min,
          :cardinality_max_below_min
        ] do
      assert_error(
        Reflection.read(ManualFixtures, function),
        "catalogue.contract.reflection.metadata_invalid",
        if(function == :cardinality_unknown_slot,
          do: "$.metadata.slot_cardinality.missing",
          else: "$.metadata.slot_cardinality.actions"
        )
      )
    end
  end

  defp assert_error({:error, [diagnostic]}, code, path) do
    assert diagnostic.code == code
    assert diagnostic.path == path
    assert is_binary(diagnostic.message)
  end

  defp assert_error(other, code, path) do
    flunk("expected #{code} at #{path}, got: #{inspect(other)}")
  end
end
