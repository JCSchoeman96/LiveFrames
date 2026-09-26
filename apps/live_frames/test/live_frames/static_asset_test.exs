defmodule LiveFrames.StaticAssetTest do
  use ExUnit.Case, async: true

  @accepted_uris [
    "http://images.example.test:8443/assets/team.webp",
    "https://images.example.test/assets/team.webp",
    "/wp-content/uploads/team.webp"
  ]

  test "accepts only the validated URI unchanged" do
    for uri <- @accepted_uris do
      assert validate(uri) == {:ok, uri}
    end
  end

  test "classifies missing and non-string URI evidence" do
    for uri <- [nil, false, ""] do
      assert validate(uri) == {:error, :missing}
    end

    assert validate(880) == {:error, :malformed}
  end

  test "classifies dynamic and query-backed image URIs" do
    for uri <- [
          "{featured_image}",
          "{{ post.image }}",
          "http://images.example.test/assets/team.webp?size=large",
          "http://images.example.test/assets/team.webp#preview"
        ] do
      assert validate(uri) == {:error, :dynamic}
    end
  end

  test "rejects unsafe schemes and URI forms" do
    for uri <- [
          "javascript:alert(1)",
          "data:image/png;base64,abc",
          "vbscript:msgbox(1)",
          "file:///tmp/image.png",
          "blob:https://images.example.test/id",
          "ftp://images.example.test/assets/team.webp",
          "//images.example.test/assets/team.webp",
          "http://images.example.test/assets\\team.webp",
          " http://images.example.test/assets/team.webp",
          "\u00A0http://images.example.test/assets/team.webp",
          "http://images.example.test/assets/team.webp ",
          "http://images.example.test/assets/\nteam.webp",
          "http://images.example.test/assets/\u0085team.webp"
        ] do
      assert validate(uri) == {:error, :unsafe}
    end
  end

  test "rejects malformed static image URIs" do
    for uri <- [
          "assets/team.webp",
          "http://-invalid.example.test/assets/team.webp",
          "http://images.example.test:70000/assets/team.webp",
          "http://images..example.test/assets/team.webp",
          "http://images.example.test/assets/%zz.webp"
        ] do
      assert validate(uri) == {:error, :malformed}
    end
  end

  defp validate(uri) do
    assert Code.ensure_loaded?(LiveFrames.StaticAsset)
    apply(LiveFrames.StaticAsset, :validate, [uri])
  end
end
