defmodule LiveFrames.Adapters.Bricks.Document do
  @moduledoc """
  Recognized Bricks copied-elements envelope.
  """

  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.ContentProxy
  alias LiveFrames.Adapters.Bricks.GlobalClass

  @adapter_version "1.0.0"

  @type t :: %__MODULE__{
          source: String.t() | nil,
          source_url: String.t() | nil,
          payload_version: String.t() | nil,
          adapter_version: String.t(),
          source_label: String.t() | nil,
          source_hash: String.t() | nil,
          content_proxies: %{optional(String.t()) => ContentProxy.t()},
          content_proxy_order: [String.t()],
          components: %{optional(String.t()) => Component.t()},
          component_order: [String.t()],
          global_classes: %{optional(String.t()) => GlobalClass.t()},
          global_class_order: [String.t()],
          raw: map()
        }

  defstruct source: nil,
            source_url: nil,
            payload_version: nil,
            adapter_version: @adapter_version,
            source_label: nil,
            source_hash: nil,
            content_proxies: %{},
            content_proxy_order: [],
            components: %{},
            component_order: [],
            global_classes: %{},
            global_class_order: [],
            raw: %{}

  @spec adapter_version() :: String.t()
  def adapter_version, do: @adapter_version

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)

  @spec component_count(t()) :: non_neg_integer()
  def component_count(%__MODULE__{components: components}), do: map_size(components)

  @spec global_class_count(t()) :: non_neg_integer()
  def global_class_count(%__MODULE__{global_classes: global_classes}),
    do: map_size(global_classes)

  @spec proxy_count(t()) :: non_neg_integer()
  def proxy_count(%__MODULE__{content_proxies: proxies}), do: map_size(proxies)
end
