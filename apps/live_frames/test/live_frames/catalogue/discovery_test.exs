defmodule LiveFrames.Catalogue.DiscoveryTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue
  alias LiveFrames.Catalogue.Discovery
  alias LiveFrames.Catalogue.Manifest

  @states [
    "DRAFT",
    "VALIDATED",
    "REVIEWED",
    "APPROVED",
    "RELEASED",
    "DEPRECATED",
    "WITHDRAWN",
    "RETIRED"
  ]

  test "filter exposes only released or released and deprecated manifests" do
    manifests = Enum.map(@states, &manifest(String.downcase(&1), &1))
    released = manifest("released", "RELEASED")
    deprecated = manifest("deprecated", "DEPRECATED")

    assert Discovery.filter(manifests, :released) == [released]

    assert Discovery.filter(manifests, :released_and_deprecated) == [
             released,
             deprecated
           ]
  end

  test "filter preserves the supplied order" do
    released_z = manifest("released-z", "RELEASED")
    deprecated_m = manifest("deprecated-m", "DEPRECATED")
    released_b = manifest("released-b", "RELEASED")

    manifests = [
      released_z,
      manifest("draft-a", "DRAFT"),
      deprecated_m,
      released_b,
      manifest("retired-c", "RETIRED")
    ]

    assert Enum.map(Discovery.filter(manifests, :released), & &1.id) == [
             "released-z",
             "released-b"
           ]

    assert Enum.map(Discovery.filter(manifests, :released_and_deprecated), & &1.id) == [
             "released-z",
             "deprecated-m",
             "released-b"
           ]
  end

  test "visible_fetch returns the original manifest only for released and deprecated states" do
    Enum.each(@states, fn state ->
      value = manifest("synthetic.#{String.downcase(state)}", state)

      case state do
        state when state in ["RELEASED", "DEPRECATED"] ->
          assert Discovery.visible_fetch({:ok, value}) == {:ok, value}

        _hidden_state ->
          assert Discovery.visible_fetch({:ok, value}) == :error
      end
    end)
  end

  test "a hidden manifest has the same result as an absent Registry entry" do
    hidden = manifest("synthetic.draft", "DRAFT")

    assert Discovery.visible_fetch({:ok, hidden}) == :error
    assert Discovery.visible_fetch(:error) == :error
  end

  test "filter rejects unsupported modes" do
    invalid_modes = [:deprecated, :all, "released", nil, [], %{}, include_deprecated: true]

    Enum.each(invalid_modes, fn mode ->
      assert_raise ArgumentError, fn ->
        Discovery.filter([], mode)
      end
    end)
  end

  test "the public list rejects unsupported modes" do
    invalid_modes = [:deprecated, :all, "released", nil, [], %{}, include_deprecated: true]

    Enum.each(invalid_modes, fn mode ->
      assert_raise ArgumentError, fn ->
        Catalogue.list(mode)
      end
    end)
  end

  test "the production Registry is empty and Hero fetch is unavailable" do
    assert Catalogue.list() == []
    assert Catalogue.list() == Catalogue.list(:released)
    assert Catalogue.list(:released) == []
    assert Catalogue.list(:released_and_deprecated) == []
    assert Catalogue.fetch("live_frames.section.hero") == :error
  end

  test "fetch returns errors for unknown IDs and non-binary input" do
    assert Catalogue.fetch("live_frames.section.unknown") == :error
    assert Catalogue.fetch(" live_frames.section.hero") == :error
    assert Catalogue.fetch("LIVE_FRAMES.SECTION.HERO") == :error
    assert Catalogue.fetch(nil) == :error
    assert Catalogue.fetch(:hero) == :error
    assert Catalogue.fetch(%{}) == :error
  end

  test "the public facade exposes only list and fetch functions" do
    assert Catalogue.__info__(:functions) == Enum.sort([{:list, 0}, {:list, 1}, {:fetch, 1}])
  end

  test "Discovery exposes only its two internal operations" do
    assert Discovery.__info__(:functions) == Enum.sort([{:filter, 2}, {:visible_fetch, 1}])
  end

  defp manifest(id, state) do
    %Manifest{id: id, state: state, display_name: "Synthetic #{id}"}
  end
end
