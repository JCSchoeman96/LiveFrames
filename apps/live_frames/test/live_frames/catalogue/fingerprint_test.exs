defmodule LiveFrames.Catalogue.FingerprintTest.EmptyFixture do
  @sample_component %{kind: :def, attrs: [], slots: [], line: 1}

  @required_attr %{
    slot: nil,
    name: :label,
    type: :string,
    required: true,
    opts: [],
    doc: nil,
    line: 1
  }

  @unsupported_attr %{
    slot: nil,
    name: :callback,
    type: {:fun, 2},
    required: false,
    opts: [],
    doc: nil,
    line: 1
  }

  Module.register_attribute(__MODULE__, :liveframes_public_contract_metadata, persist: true)

  @liveframes_public_contract_metadata %{
    sample: %{capabilities: [], css_theme_contract: [], global_prefixes: []},
    different: %{capabilities: [], css_theme_contract: [], global_prefixes: []},
    unsupported: %{capabilities: [], css_theme_contract: [], global_prefixes: []}
  }

  def sample(assigns), do: assigns
  def different(assigns), do: assigns
  def unsupported(assigns), do: assigns

  def __components__ do
    %{
      sample: @sample_component,
      different: %{@sample_component | attrs: [@required_attr]},
      unsupported: %{@sample_component | attrs: [@unsupported_attr]}
    }
  end
end

defmodule LiveFrames.Catalogue.FingerprintTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.CanonicalJSON
  alias LiveFrames.Catalogue.Contract
  alias LiveFrames.Catalogue.Fingerprint
  alias LiveFrames.Catalogue.FingerprintTest.EmptyFixture
  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Components.Sections.Hero

  @algorithm "lf-contract-v1-jcs-sha256"
  @hero_digest "18e3ad5ed26e49bd85a529629154d33aa105134e13df52d1da9385b3f6923ac9"
  @hero_component %{
    "module" => "LiveFrames.Components.Sections.Hero",
    "function" => "hero"
  }

  @hero_contract %{
    "fingerprint_algorithm" => @algorithm,
    "fingerprint" => @hero_digest
  }

  @fixture_document %{
    "format" => "lf-contract-v1",
    "component" => %{
      "module" => "LiveFrames.Catalogue.FingerprintTest.EmptyFixture",
      "function" => "sample"
    },
    "attrs" => [],
    "slots" => [],
    "capabilities" => [],
    "css_theme_contract" => []
  }

  @fixture_jcs "{\"attrs\":[],\"capabilities\":[],\"component\":{\"function\":\"sample\",\"module\":\"LiveFrames.Catalogue.FingerprintTest.EmptyFixture\"},\"css_theme_contract\":[],\"format\":\"lf-contract-v1\",\"slots\":[]}"

  @fixture_digest "6066360be7fe83418176cbe3cc6660a46ecd3d965916c190e9a78c113487a740"

  test "returns the single approved algorithm identifier" do
    assert Fingerprint.algorithm() == @algorithm
  end

  test "normalizes and fingerprints the exact synthetic JCS vector" do
    assert Contract.normalize(EmptyFixture, :sample) == {:ok, @fixture_document}
    assert {:ok, canonical_bytes} = CanonicalJSON.encode(@fixture_document)
    assert canonical_bytes == @fixture_jcs

    assert Fingerprint.compute(EmptyFixture, :sample) ==
             {:ok,
              %{
                "fingerprint_algorithm" => @algorithm,
                "fingerprint" => @fixture_digest
              }}
  end

  test "matches the production Hero golden fingerprint on repeated calls" do
    expected =
      {:ok,
       %{
         "fingerprint_algorithm" => @algorithm,
         "fingerprint" => @hero_digest
       }}

    assert Fingerprint.compute(Hero, :hero) == expected

    assert Enum.map(1..3, fn _ -> Fingerprint.compute(Hero, :hero) end) ==
             List.duplicate(expected, 3)
  end

  test "returns exactly the two manifest contract fields with a lowercase SHA-256 digest" do
    assert {:ok, result} = Fingerprint.compute(EmptyFixture, :sample)

    assert Map.keys(result) |> Enum.sort() == ["fingerprint", "fingerprint_algorithm"]
    assert result["fingerprint_algorithm"] == Fingerprint.algorithm()
    assert byte_size(result["fingerprint"]) == 64
    assert String.match?(result["fingerprint"], ~r/\A[0-9a-f]{64}\z/)
  end

  test "changes the fingerprint when the public component contract changes" do
    assert {:ok, empty_result} = Fingerprint.compute(EmptyFixture, :sample)
    assert {:ok, changed_result} = Fingerprint.compute(EmptyFixture, :different)

    refute empty_result["fingerprint"] == changed_result["fingerprint"]
  end

  test "passes Contract diagnostics through unchanged" do
    expected = Contract.normalize(EmptyFixture, :unsupported)

    assert {:error, [_diagnostic]} = expected
    assert Fingerprint.compute(EmptyFixture, :unsupported) == expected
  end

  test "passes invalid target and function diagnostics through unchanged" do
    for {module, function} <- [{nil, :sample}, {EmptyFixture, :missing}, {EmptyFixture, "sample"}] do
      assert Fingerprint.compute(module, function) == Contract.normalize(module, function)
    end
  end

  test "verifies the persisted Hero manifest fingerprint" do
    assert {:ok, manifest} = decode_hero_manifest()
    assert Fingerprint.verify(manifest, Hero, :hero) == :ok
  end

  test "allows a DRAFT manifest without a contract but rejects requested verification" do
    assert {:ok, manifest} = decode_hero_manifest(:missing)
    assert manifest.state == "DRAFT"
    assert manifest.contract == nil

    assert_error(
      Fingerprint.verify(manifest, Hero, :hero),
      "catalogue.fingerprint.contract_missing",
      "contract"
    )

    assert_error(
      Fingerprint.verify(%Manifest{contract: "unusable"}, Hero, :hero),
      "catalogue.fingerprint.contract_missing",
      "contract"
    )
  end

  test "rejects values that are not decoded manifests" do
    assert_error(
      Fingerprint.verify(%{}, Hero, :hero),
      "catalogue.fingerprint.manifest_invalid",
      "$"
    )
  end

  test "distinguishes malformed and unsupported algorithm identifiers" do
    for contract <- [
          Map.delete(@hero_contract, "fingerprint_algorithm"),
          Map.put(@hero_contract, "fingerprint_algorithm", nil),
          Map.put(@hero_contract, "fingerprint_algorithm", 7),
          Map.put(@hero_contract, "fingerprint_algorithm", [])
        ] do
      assert {:ok, manifest} = decode_hero_manifest(contract)

      assert_error(
        Fingerprint.verify(manifest, Hero, :hero),
        "catalogue.fingerprint.algorithm_invalid",
        "contract.fingerprint_algorithm"
      )
    end

    unsupported_contract = %{
      "fingerprint_algorithm" => "lf-contract-v2-jcs-sha256",
      "fingerprint" => nil
    }

    component = %{
      "module" => "LiveFrames.Catalogue.FingerprintTest.EmptyFixture",
      "function" => "unsupported"
    }

    assert {:ok, manifest} = decode_hero_manifest(unsupported_contract, component)

    assert_error(
      Fingerprint.verify(manifest, EmptyFixture, :unsupported),
      "catalogue.fingerprint.algorithm_unsupported",
      "contract.fingerprint_algorithm"
    )
  end

  test "requires the stored digest to be 64 lowercase hexadecimal characters" do
    invalid_contracts = [
      Map.delete(@hero_contract, "fingerprint"),
      Map.put(@hero_contract, "fingerprint", nil),
      Map.put(@hero_contract, "fingerprint", 7),
      Map.put(@hero_contract, "fingerprint", String.duplicate("A", 64)),
      Map.put(@hero_contract, "fingerprint", String.duplicate("a", 63)),
      Map.put(@hero_contract, "fingerprint", String.duplicate("a", 65)),
      Map.put(@hero_contract, "fingerprint", String.duplicate("a", 63) <> "g"),
      Map.put(@hero_contract, "fingerprint", " " <> String.duplicate("a", 64)),
      Map.put(@hero_contract, "fingerprint", String.duplicate("a", 64) <> " "),
      Map.put(@hero_contract, "fingerprint", String.duplicate("a", 64) <> "\n")
    ]

    for contract <- invalid_contracts do
      assert {:ok, manifest} = decode_hero_manifest(contract)

      assert_error(
        Fingerprint.verify(manifest, Hero, :hero),
        "catalogue.fingerprint.value_invalid",
        "contract.fingerprint"
      )
    end

    failing_component = %{
      "module" => "LiveFrames.Catalogue.FingerprintTest.EmptyFixture",
      "function" => "unsupported"
    }

    assert {:ok, malformed_manifest} =
             decode_hero_manifest(Map.put(@hero_contract, "fingerprint", nil), failing_component)

    assert_error(
      Fingerprint.verify(malformed_manifest, EmptyFixture, :unsupported),
      "catalogue.fingerprint.value_invalid",
      "contract.fingerprint"
    )
  end

  test "accepts unrelated contract keys" do
    contract = Map.put(@hero_contract, "opaque_metadata", %{"enabled" => true})
    assert {:ok, manifest} = decode_hero_manifest(contract)

    assert Fingerprint.verify(manifest, Hero, :hero) == :ok
  end

  test "checks the manifest module reference before the function reference" do
    {:ok, wrong_module} =
      decode_hero_manifest(@hero_contract, Map.put(@hero_component, "module", "Other.Component"))

    assert_error(
      Fingerprint.verify(wrong_module, Hero, :hero),
      "catalogue.fingerprint.target_mismatch",
      "component.module"
    )

    {:ok, wrong_function} =
      decode_hero_manifest(@hero_contract, Map.put(@hero_component, "function", "other"))

    assert_error(
      Fingerprint.verify(wrong_function, Hero, :hero),
      "catalogue.fingerprint.target_mismatch",
      "component.function"
    )
  end

  test "reports a well-formed but stale fingerprint" do
    stale_contract =
      Map.put(@hero_contract, "fingerprint", "28" <> binary_part(@hero_digest, 2, 62))

    assert {:ok, manifest} = decode_hero_manifest(stale_contract)

    assert_error(
      Fingerprint.verify(manifest, Hero, :hero),
      "catalogue.fingerprint.stale",
      "contract.fingerprint"
    )
  end

  test "passes current contract computation diagnostics through unchanged" do
    component = %{
      "module" => "LiveFrames.Catalogue.FingerprintTest.EmptyFixture",
      "function" => "unsupported"
    }

    assert {:ok, manifest} = decode_hero_manifest(@hero_contract, component)
    expected = Fingerprint.compute(EmptyFixture, :unsupported)

    assert {:error, [_]} = expected
    assert Fingerprint.verify(manifest, EmptyFixture, :unsupported) == expected
  end

  test "does not create atoms from manifest component references" do
    marker = "untrusted_component_ref_#{System.unique_integer([:positive, :monotonic])}"

    component = %{"module" => marker, "function" => marker}
    assert {:ok, manifest} = decode_hero_manifest(fixture_metadata(), component)

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end

    assert {:error, [_]} = Fingerprint.verify(manifest, EmptyFixture, :sample)

    assert_raise ArgumentError, fn ->
      String.to_existing_atom(marker)
    end
  end

  defp decode_hero_manifest(contract \\ @hero_contract, component \\ @hero_component) do
    data = %{
      "schema_version" => 1,
      "id" => "live_frames.component.hero_test",
      "kind" => "component",
      "display_name" => "Hero verification fixture",
      "state" => "DRAFT",
      "component" => component,
      "storybook" => %{"module" => "LiveFrames.Stories.Sections.Hero"},
      "docs" => %{},
      "provenance" => %{}
    }

    data = if contract == :missing, do: data, else: Map.put(data, "contract", contract)
    Manifest.decode(Jason.encode!(data))
  end

  defp assert_error(result, expected_code, expected_path) do
    assert {:error, [%{code: ^expected_code, path: ^expected_path}]} = result
  end

  defp fixture_metadata do
    %{
      "fingerprint_algorithm" => @algorithm,
      "fingerprint" => @fixture_digest
    }
  end
end
