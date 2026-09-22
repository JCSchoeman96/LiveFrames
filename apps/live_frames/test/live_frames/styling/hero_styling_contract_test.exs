defmodule LiveFrames.Styling.HeroStylingContractTest do
  use ExUnit.Case, async: true

  @hero_css Path.expand("../../../assets/css/components/sections/hero.css", __DIR__)

  defp css, do: File.read!(@hero_css)

  test "pins accepted native Hero styling contract in authored CSS" do
    source = css()

    assert source =~ "margin-top: 400px"

    assert source =~ "--lf-hero-overlay-gradient-vertical"
    assert source =~ "--lf-hero-overlay-gradient-desktop"
    assert source =~ "background-image: var(--lf-hero-overlay-gradient-vertical)"
    assert source =~ "object-position: 50% 50%"

    assert source =~ "@media (min-width: 479px)"
    assert source =~ "@media (min-width: 992px)"
    assert source =~ "background-image: var(--lf-hero-overlay-gradient-desktop)"
    assert source =~ "object-position: 70% 50%"

    refute source =~ "@media (max-width"
    refute source =~ "1280px"

    assert source =~ ".lf-hero__heading"
    assert source =~ "margin: 0"
    assert source =~ ".lf-hero__lede"

    assert source =~ ".lf-hero__action--primary > :where(a, button)"
    assert source =~ ".lf-hero__action--secondary > :where(a, button)"
    assert source =~ "box-sizing: border-box"
    assert source =~ "font-family: inherit"
    assert source =~ "text-decoration: none"

    assert source =~ ":hover"
    assert source =~ ":focus-visible"
    assert source =~ "outline-style: solid"
    assert source =~ "outline-width: 2px"

    refute source =~ "fr-"
    refute source =~ "acss-"
    refute source =~ "lf-fidelity-node-"
    refute source =~ ".live-frames"
  end

  test "base layout stacks full-width action wrappers and roots" do
    source = css()

    assert source =~ "flex-direction: column"
    assert source =~ ".lf-hero__actions > .lf-hero__action"
    assert source =~ "width: 100%"
  end
end
