defmodule LiveFrames.Catalogue.ContractTest.PhoenixFixture do
  use Phoenix.Component, global_prefixes: ["x-"]

  Module.register_attribute(__MODULE__, :liveframes_public_contract_metadata, persist: true)

  @liveframes_public_contract_metadata %{
    sample: %{
      capabilities: ["liveframes.test.fixture"],
      css_theme_contract: ["--lf-fixture-color"],
      global_prefixes: ["x-"],
      slot_cardinality: %{"optional_action" => {0, 1}}
    }
  }

  attr(:title, :string, required: true)
  attr(:count, :integer, default: 2)
  attr(:explicit_nil, :string, default: nil)
  attr(:choice, :integer, values: 1..3)
  attr(:rest, :global, include: ["data-z", "id", "data-z", "aria-label"])

  slot :required_action, required: true do
    attr(:label, :string, required: true)
  end

  slot :optional_action do
    attr(:label, :string)
  end

  def sample(assigns) do
    ~H"""
    <div {@rest}>
      <p>{@title} {@count} {@explicit_nil} {@choice}</p>
      <%= for action <- @required_action do %><span>{action.label}</span><% end %>
      <%= for action <- @optional_action do %><span>{action.label}</span><% end %>
    </div>
    """
  end
end

defmodule LiveFrames.Catalogue.ContractTest.RaisingEnumerable do
  defstruct []
end

defimpl Enumerable, for: LiveFrames.Catalogue.ContractTest.RaisingEnumerable do
  def reduce(_value, _accumulator, _function), do: raise("Enumerable.reduce/3 was invoked")
  def count(_value), do: raise("Enumerable.count/1 was invoked")
  def member?(_value, _member), do: raise("Enumerable.member?/2 was invoked")
  def slice(_value), do: raise("Enumerable.slice/1 was invoked")
end

defmodule LiveFrames.Catalogue.ContractTest.ManualFixtures do
  alias LiveFrames.Catalogue.ContractTest.RaisingEnumerable

  @base_component %{kind: :def, attrs: [], slots: [], line: 1}

  @base_attr %{
    slot: nil,
    name: :sample,
    type: :string,
    required: false,
    opts: [],
    doc: nil,
    line: 1
  }

  @base_slot %{
    name: :sample_slot,
    required: false,
    opts: [],
    doc: nil,
    line: 2,
    attrs: [],
    validate_attrs: true
  }

  @empty_metadata %{capabilities: [], css_theme_contract: [], global_prefixes: []}

  @builtin_pairs [
    {:any, :any},
    {:boolean, :boolean},
    {:integer, :integer},
    {:float, :float},
    {:string, :string},
    {:atom, :atom},
    {:list, :list},
    {:map, :map},
    {:fun, :fun},
    {:global, :global}
  ]

  @builtin_attrs (for {name, type} <- @builtin_pairs do
                    %{@base_attr | name: name, type: type}
                  end)

  @struct_attr %{@base_attr | name: :struct, type: {:struct, Date}}

  @z_attr %{@base_attr | name: :zebra}
  @a_attr %{@base_attr | name: :alpha}

  @slot_attr %{
    @base_attr
    | slot: :alpha_slot,
      name: :label,
      required: true
  }

  @a_slot %{@base_slot | name: :alpha_slot, attrs: [@slot_attr]}
  @z_slot %{@base_slot | name: :zeta_slot}

  @components %{
    type_mapping: %{@base_component | attrs: @builtin_attrs ++ [@struct_attr]},
    function_arity: %{
      @base_component
      | attrs: [%{@base_attr | name: :callback, type: {:fun, 2}}]
    },
    negative_function_arity: %{
      @base_component
      | attrs: [%{@base_attr | name: :callback, type: {:fun, -1}}]
    },
    range_values: %{
      @base_component
      | attrs: [%{@base_attr | name: :choice, type: :integer, opts: [values: 1..6]}]
    },
    list_values: %{
      @base_component
      | attrs: [
          %{
            @base_attr
            | name: :choice,
              type: :integer,
              opts: [values: [6, 1, 4, 3, 2, 5]]
          }
        ]
    },
    descending_values: %{
      @base_component
      | attrs: [
          %{
            @base_attr
            | name: :choice,
              type: :integer,
              opts: [values: Range.new(5, 1, -2)]
          }
        ]
    },
    duplicate_values: %{
      @base_component
      | attrs: [%{@base_attr | name: :choice, opts: [values: [2, 1, 1]]}]
    },
    duplicate_values_reordered: %{
      @base_component
      | attrs: [%{@base_attr | name: :choice, opts: [values: [1, 2, 1]]}]
    },
    empty_values: %{
      @base_component
      | attrs: [%{@base_attr | name: :choice, opts: [values: []]}]
    },
    custom_values: %{
      @base_component
      | attrs: [%{@base_attr | name: :choice, opts: [values: %RaisingEnumerable{}]}]
    },
    improper_values: %{
      @base_component
      | attrs: [%{@base_attr | name: :choice, opts: [values: [1, 2 | 3]]}]
    },
    malformed_range: %{
      @base_component
      | attrs: [
          %{
            @base_attr
            | name: :choice,
              opts: [values: struct(Range, first: 1, last: 3, step: 0)]
          }
        ]
    },
    invalid_allowed_member: %{
      @base_component
      | attrs: [
          %{
            @base_attr
            | name: :choice,
              opts: [values: [[1, Date.new!(2020, 1, 1)]]]
          }
        ]
    },
    default_absent: %{
      @base_component
      | attrs: [%{@base_attr | name: :value}]
    },
    default_nil: %{
      @base_component
      | attrs: [%{@base_attr | name: :value, opts: [default: nil]}]
    },
    default_integer: %{
      @base_component
      | attrs: [%{@base_attr | name: :value, type: :integer, opts: [default: 2]}]
    },
    invalid_default: %{
      @base_component
      | attrs: [%{@base_attr | name: :value, opts: [default: [1, Date.new!(2020, 1, 1)]]}]
    },
    global_include: %{
      @base_component
      | attrs: [
          %{
            @base_attr
            | name: :rest,
              type: :global,
              opts: [include: ["data-z", "id", "data-z", "aria-label"]]
          }
        ]
    },
    global_include_nil: %{
      @base_component
      | attrs: [%{@base_attr | name: :rest, type: :global, opts: [include: nil]}]
    },
    global_invalid_include: %{
      @base_component
      | attrs: [%{@base_attr | name: :rest, type: :global, opts: [include: ["id", :invalid]]}]
    },
    global_prefix_bound: %{
      @base_component
      | attrs: [%{@base_attr | name: :rest, type: :global}]
    },
    global_prefix_unbound: %{
      @base_component
      | attrs: [%{@base_attr | name: :label}]
    },
    global_no_include: %{
      @base_component
      | attrs: [%{@base_attr | name: :rest, type: :global}]
    },
    unordered: %{
      @base_component
      | attrs: [@z_attr, @a_attr],
        slots: [@z_slot, @a_slot]
    },
    deterministic_failures: %{
      @base_component
      | attrs: [
          %{@base_attr | name: :z_bad, opts: [values: %RaisingEnumerable{}]},
          %{@base_attr | name: :a_bad, opts: [default: Date.new!(2020, 1, 1)]}
        ]
    },
    reflection_invalid: %{
      @base_component
      | attrs: [%{@base_attr | name: :bad, type: {:unapproved, :type}}]
    }
  }

  @metadata Map.new(Map.keys(@components), fn function -> {function, @empty_metadata} end)

  @metadata Map.merge(@metadata, %{
              global_prefix_bound: %{@empty_metadata | global_prefixes: ["x-"]},
              global_prefix_unbound: %{@empty_metadata | global_prefixes: ["x-"]}
            })

  Module.register_attribute(__MODULE__, :liveframes_public_contract_metadata, persist: true)
  @liveframes_public_contract_metadata @metadata

  for function <- Map.keys(@components) do
    def unquote(function)(assigns), do: assigns
  end

  def __components__, do: @components
  def __global__?(candidate), do: String.starts_with?(candidate, "x-")
end

defmodule LiveFrames.Catalogue.ContractTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Contract
  alias LiveFrames.Catalogue.Contract.Reflection
  alias LiveFrames.Catalogue.ContractTest.ManualFixtures
  alias LiveFrames.Catalogue.ContractTest.PhoenixFixture
  alias LiveFrames.Components.Sections.Hero

  test "normalizes the production Hero into the complete six-key v1 document" do
    assert normalize_success!(Hero, :hero) == hero_document()
  end

  test "normalizes real Phoenix reflection and persisted metadata end to end" do
    assert normalize_success!(PhoenixFixture, :sample) == phoenix_fixture_document()
  end

  test "sorts manually reflected attrs and slots by their UTF-8 names" do
    document = normalize_success!(ManualFixtures, :unordered)

    assert Enum.map(document["attrs"], & &1["name"]) == ["alpha", "zebra"]
    assert Enum.map(document["slots"], & &1["name"]) == ["alpha_slot", "zeta_slot"]

    slots = Map.new(document["slots"], &{&1["name"], &1})
    assert slots["alpha_slot"]["required"] == false
    assert slots["alpha_slot"]["min_entries"] == 0
    assert slots["alpha_slot"]["max_entries"] == nil

    assert Map.keys(hd(document["slots"])) |> Enum.sort() == [
             "max_entries",
             "min_entries",
             "name",
             "required"
           ]
  end

  test "distinguishes an absent default from an explicit nil and normalizes integer defaults" do
    absent = normalize_success!(ManualFixtures, :default_absent)["attrs"] |> hd()
    explicit_nil = normalize_success!(ManualFixtures, :default_nil)["attrs"] |> hd()
    integer = normalize_success!(ManualFixtures, :default_integer)["attrs"] |> hd()

    assert absent["default"] == %{"present" => false}
    assert explicit_nil["default"] == %{"present" => true, "value" => nil}

    assert integer["default"] == %{
             "present" => true,
             "value" => %{"$type" => "integer", "value" => "2"}
           }
  end

  test "rebases nested Value diagnostics for defaults and allowed-value members" do
    assert {:error, [default_diagnostic]} = Contract.normalize(ManualFixtures, :invalid_default)

    assert default_diagnostic.code == "catalogue.contract.value.unsupported"
    assert default_diagnostic.path == "$.attrs[0].default.value.items[1]"

    assert {:error, [allowed_diagnostic]} =
             Contract.normalize(ManualFixtures, :invalid_allowed_member)

    assert allowed_diagnostic.code == "catalogue.contract.value.unsupported"
    assert allowed_diagnostic.path == "$.attrs[0].constraints.allowed_values[0].items[1]"
  end

  test "maps all ten builtin types and normal Elixir struct types" do
    document = normalize_success!(ManualFixtures, :type_mapping)

    actual = Map.new(document["attrs"], fn attr -> {attr["name"], attr["type"]} end)

    assert actual == %{
             "any" => builtin("any"),
             "boolean" => builtin("boolean"),
             "integer" => builtin("integer"),
             "float" => builtin("float"),
             "string" => builtin("string"),
             "atom" => builtin("atom"),
             "list" => builtin("list"),
             "map" => builtin("map"),
             "fun" => builtin("fun"),
             "global" => builtin("global"),
             "struct" => %{"kind" => "struct", "module" => "Date"}
           }
  end

  test "rejects arity-specific function types even when Reflection accepts them" do
    for function <- [:function_arity, :negative_function_arity] do
      assert {:ok, _reflection} = Reflection.read(ManualFixtures, function)
      assert {:error, [diagnostic]} = Contract.normalize(ManualFixtures, function)
      assert diagnostic.code == "catalogue.contract.normalization.unsupported_type"
      assert diagnostic.path == "$.attrs[0].type"
    end
  end

  test "normalizes Range and list declarations to the same sorted semantic set" do
    range_document = normalize_success!(ManualFixtures, :range_values)
    list_document = normalize_success!(ManualFixtures, :list_values)

    assert attr(range_document, "choice")["constraints"]["allowed_values"] ==
             attr(list_document, "choice")["constraints"]["allowed_values"]

    assert attr(range_document, "choice")["constraints"]["allowed_values"] ==
             Enum.map(1..6, &tagged_integer(&1))
  end

  test "supports descending stepped ranges" do
    document = normalize_success!(ManualFixtures, :descending_values)

    assert attr(document, "choice")["constraints"]["allowed_values"] ==
             Enum.map([1, 3, 5], &tagged_integer(&1))
  end

  test "rejects duplicate canonical allowed members independent of declaration order" do
    first = Contract.normalize(ManualFixtures, :duplicate_values)
    second = Contract.normalize(ManualFixtures, :duplicate_values_reordered)

    assert {:error, [diagnostic]} = first
    assert second == first
    assert diagnostic.code == "catalogue.contract.normalization.allowed_values_duplicate"
    assert diagnostic.path == "$.attrs[0].constraints.allowed_values"
  end

  test "keeps an empty allowed-values set distinct from an absent declaration" do
    empty = normalize_success!(ManualFixtures, :empty_values)
    absent = normalize_success!(ManualFixtures, :default_absent)

    assert attr(empty, "choice")["constraints"]["allowed_values"] == []
    assert attr(absent, "value")["constraints"]["allowed_values"] == nil
  end

  test "rejects custom Enumerable values without invoking their callbacks" do
    assert {:error, [diagnostic]} = Contract.normalize(ManualFixtures, :custom_values)
    assert diagnostic.code == "catalogue.contract.normalization.allowed_values_invalid"
    assert diagnostic.path == "$.attrs[0].constraints.allowed_values"
  end

  test "rejects improper lists and malformed Range values" do
    for function <- [:improper_values, :malformed_range] do
      assert {:error, [diagnostic]} = Contract.normalize(ManualFixtures, function)
      assert diagnostic.code == "catalogue.contract.normalization.allowed_values_invalid"
      assert diagnostic.path == "$.attrs[0].constraints.allowed_values"
    end
  end

  test "sorts and deduplicates global include names without changing their spelling" do
    document = normalize_success!(ManualFixtures, :global_include)

    assert attr(document, "rest")["constraints"]["global_names"] == [
             "aria-label",
             "data-z",
             "id"
           ]
  end

  test "uses empty global names for absent and nil include declarations" do
    absent = normalize_success!(ManualFixtures, :global_no_include)
    explicit_nil = normalize_success!(ManualFixtures, :global_include_nil)

    assert attr(absent, "rest")["constraints"]["global_names"] == []
    assert attr(explicit_nil, "rest")["constraints"]["global_names"] == []
  end

  test "rejects non-string global include members" do
    assert {:error, [diagnostic]} = Contract.normalize(ManualFixtures, :global_invalid_include)
    assert diagnostic.code == "catalogue.contract.normalization.global_names_invalid"
    assert diagnostic.path == "$.attrs[0].constraints.global_names"
  end

  test "binds supplemental global prefixes only to global attrs" do
    document = normalize_success!(ManualFixtures, :global_prefix_bound)
    global_constraints = attr(document, "rest")["constraints"]

    assert global_constraints["global_prefixes"] == ["x-"]

    phoenix_document = normalize_success!(PhoenixFixture, :sample)
    refute attr(phoenix_document, "title")["constraints"]["global_prefixes"] == ["x-"]
    assert attr(phoenix_document, "title")["constraints"]["global_prefixes"] == []
  end

  test "rejects supplemental prefixes when no global attr can bind them" do
    assert {:error, [diagnostic]} = Contract.normalize(ManualFixtures, :global_prefix_unbound)
    assert diagnostic.code == "catalogue.contract.normalization.unbound_global_prefixes"
  end

  test "uses required-slot defaults and exact supplemental cardinality overrides" do
    document = normalize_success!(PhoenixFixture, :sample)
    slots = Map.new(document["slots"], &{&1["name"], &1})

    assert slots["required_action"]["required"] == true
    assert slots["required_action"]["min_entries"] == 1
    assert slots["required_action"]["max_entries"] == nil

    assert slots["optional_action"]["required"] == false
    assert slots["optional_action"]["min_entries"] == 0
    assert slots["optional_action"]["max_entries"] == 1
  end

  test "propagates Reflection diagnostics unchanged and rejects string targets" do
    assert Contract.normalize("LiveFrames.Components.Sections.Hero", :hero) ==
             Reflection.read("LiveFrames.Components.Sections.Hero", :hero)

    assert Contract.normalize(PhoenixFixture, "sample") ==
             Reflection.read(PhoenixFixture, "sample")

    assert Contract.normalize(ManualFixtures, :reflection_invalid) ==
             Reflection.read(ManualFixtures, :reflection_invalid)
  end

  test "processes malformed attrs in canonical name order" do
    assert {:error, [diagnostic]} = Contract.normalize(ManualFixtures, :deterministic_failures)
    assert diagnostic.code == "catalogue.contract.value.unsupported"
    assert diagnostic.path == "$.attrs[0].default.value"
  end

  defp normalize_success!(module, function) do
    assert {:ok, document} = Contract.normalize(module, function)
    assert {:ok, _canonical_bytes} = CanonicalJSON.encode(document)
    document
  end

  defp attr(document, name) do
    Enum.find(document["attrs"], &(&1["name"] == name))
  end

  defp builtin(name), do: %{"kind" => "builtin", "name" => name}

  defp tagged_integer(value) do
    %{"$type" => "integer", "value" => Integer.to_string(value)}
  end

  defp hero_document do
    %{
      "format" => "lf-contract-v1",
      "component" => %{
        "module" => "LiveFrames.Components.Sections.Hero",
        "function" => "hero"
      },
      "attrs" => [
        attr_record("class", builtin("string"), false, %{"present" => true, "value" => nil}),
        attr_record("heading", builtin("string"), true, %{"present" => false}),
        attr_record(
          "heading_level",
          builtin("integer"),
          false,
          %{
            "present" => true,
            "value" => tagged_integer(2)
          },
          Enum.map(1..6, &tagged_integer(&1))
        ),
        attr_record("id", builtin("string"), false, %{"present" => true, "value" => nil}),
        attr_record(
          "image_alt",
          builtin("string"),
          false,
          %{"present" => true, "value" => nil}
        ),
        attr_record(
          "image_src",
          builtin("string"),
          false,
          %{"present" => true, "value" => nil}
        ),
        attr_record("lede", builtin("string"), false, %{"present" => true, "value" => nil}),
        attr_record("rest", builtin("global"), false, %{"present" => false})
      ],
      "slots" => [
        slot_record("primary_action", false, 0, 1),
        slot_record("secondary_action", false, 0, 1)
      ],
      "capabilities" => [
        "liveframes.consumer.owns_action_navigation_and_events",
        "liveframes.consumer.owns_global_root_attributes",
        "liveframes.content.plain_text_heading_and_lede",
        "liveframes.integration.requires_liveframes_css",
        "liveframes.validation.argument_error_on_contract_violation"
      ],
      "css_theme_contract" => [
        "--lf-action-primary-background",
        "--lf-action-primary-background-hover",
        "--lf-action-primary-border",
        "--lf-action-primary-border-style",
        "--lf-action-primary-border-width",
        "--lf-action-primary-focus",
        "--lf-action-primary-font-size",
        "--lf-action-primary-font-weight",
        "--lf-action-primary-line-height",
        "--lf-action-primary-min-width",
        "--lf-action-primary-padding-block",
        "--lf-action-primary-padding-inline",
        "--lf-action-primary-radius",
        "--lf-action-primary-text",
        "--lf-action-secondary-background",
        "--lf-action-secondary-background-hover",
        "--lf-action-secondary-border",
        "--lf-action-secondary-border-hover",
        "--lf-action-secondary-focus",
        "--lf-action-secondary-text",
        "--lf-action-secondary-text-hover",
        "--lf-color-background-ultra-dark",
        "--lf-color-heading-on-dark",
        "--lf-color-text-on-dark",
        "--lf-layout-container-max-width",
        "--lf-space-container-gap",
        "--lf-space-content-gap",
        "--lf-space-gutter",
        "--lf-space-section-padding-block",
        "--lf-typography-body-line-height",
        "--lf-typography-body-size",
        "--lf-typography-display-line-height",
        "--lf-typography-display-size",
        "--lf-typography-display-weight"
      ]
    }
  end

  defp phoenix_fixture_document do
    %{
      "format" => "lf-contract-v1",
      "component" => %{
        "module" => "LiveFrames.Catalogue.ContractTest.PhoenixFixture",
        "function" => "sample"
      },
      "attrs" => [
        attr_record(
          "choice",
          builtin("integer"),
          false,
          %{"present" => false},
          Enum.map(1..3, &tagged_integer(&1))
        ),
        attr_record(
          "count",
          builtin("integer"),
          false,
          %{"present" => true, "value" => tagged_integer(2)}
        ),
        attr_record(
          "explicit_nil",
          builtin("string"),
          false,
          %{"present" => true, "value" => nil}
        ),
        attr_record(
          "rest",
          builtin("global"),
          false,
          %{"present" => false},
          nil,
          ["aria-label", "data-z", "id"],
          ["x-"]
        ),
        attr_record("title", builtin("string"), true, %{"present" => false})
      ],
      "slots" => [
        slot_record("optional_action", false, 0, 1),
        slot_record("required_action", true, 1, nil)
      ],
      "capabilities" => ["liveframes.test.fixture"],
      "css_theme_contract" => ["--lf-fixture-color"]
    }
  end

  defp attr_record(
         name,
         type,
         required,
         default,
         allowed_values \\ nil,
         global_names \\ [],
         global_prefixes \\ []
       ) do
    %{
      "name" => name,
      "type" => type,
      "required" => required,
      "default" => default,
      "constraints" => %{
        "allowed_values" => allowed_values,
        "global_names" => global_names,
        "global_prefixes" => global_prefixes
      }
    }
  end

  defp slot_record(name, required, min_entries, max_entries) do
    %{
      "name" => name,
      "required" => required,
      "min_entries" => min_entries,
      "max_entries" => max_entries
    }
  end
end
