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
  alias LiveFrames.Components.Sections.Hero

  @algorithm "lf-contract-v1-jcs-sha256"

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
  @hero_digest "18e3ad5ed26e49bd85a529629154d33aa105134e13df52d1da9385b3f6923ac9"

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
end
