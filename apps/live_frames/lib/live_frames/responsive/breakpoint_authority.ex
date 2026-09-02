defmodule LiveFrames.Responsive.BreakpointAuthority.Entry do
  @moduledoc false

  @type t :: %__MODULE__{
          source_name: String.t(),
          source_width: number(),
          min_width: number() | nil,
          max_width: number() | nil,
          unit: String.t(),
          query_semantics: String.t(),
          media_condition: String.t(),
          enabled: boolean(),
          cascade_order: pos_integer(),
          authority_level: pos_integer(),
          authority_type: String.t(),
          status: String.t()
        }

  defstruct source_name: nil,
            source_width: nil,
            min_width: nil,
            max_width: nil,
            unit: nil,
            query_semantics: nil,
            media_condition: nil,
            enabled: false,
            cascade_order: nil,
            authority_level: nil,
            authority_type: nil,
            status: nil
end

defmodule LiveFrames.Responsive.BreakpointAuthority do
  @moduledoc "Validated, source-neutral numeric breakpoint authority."

  alias LiveFrames.Responsive.BreakpointAuthority.Entry

  @schema_version "1.0.0"
  @supported_ordering "descending_width"
  @supported_query_semantics ["max-width", "min-width"]

  @type t :: %__MODULE__{
          schema_version: String.t(),
          authority_hash: String.t(),
          authority_level: pos_integer(),
          authority_type: String.t(),
          breakpoints: %{String.t() => Entry.t()},
          cascade_ordering: String.t()
        }

  defstruct schema_version: @schema_version,
            authority_hash: nil,
            authority_level: nil,
            authority_type: nil,
            breakpoints: %{},
            cascade_ordering: @supported_ordering

  @spec from_file(String.t()) :: {:ok, t()} | {:error, atom()}
  def from_file(path) when is_binary(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, map} <- Jason.decode(contents),
         {:ok, authority} <- from_map(map) do
      {:ok, %{authority | authority_hash: sha(contents)}}
    else
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      {:error, reason} -> {:error, reason}
    end
  end

  def from_file(_path), do: {:error, :invalid_path}

  @spec from_map(map()) :: {:ok, t()} | {:error, atom()}
  def from_map(map) when is_map(map) and not is_struct(map) do
    with {:ok, schema_version} <- required_string(map, "schema_version"),
         :ok <- exact(schema_version, @schema_version, :unsupported_schema_version),
         {:ok, authority_status} <- required_string(map, "authority_status"),
         :ok <- exact(authority_status, "accepted", :authority_not_accepted),
         {:ok, authority_level} <- positive_integer(map, "authority_level"),
         {:ok, authority_type} <- required_string(map, "authority_type"),
         {:ok, breakpoints} <- breakpoint_entries(map["breakpoints"]),
         {:ok, cascade_ordering} <- cascade_ordering(map["cascade"]) do
      {:ok,
       %__MODULE__{
         schema_version: schema_version,
         authority_hash: sha(Jason.encode!(map)),
         authority_level: authority_level,
         authority_type: authority_type,
         breakpoints: breakpoints,
         cascade_ordering: cascade_ordering
       }}
    end
  rescue
    _error in [ArgumentError, Protocol.UndefinedError] -> {:error, :invalid_authority}
  end

  def from_map(_map), do: {:error, :invalid_authority}

  @spec coerce(t() | map() | nil) :: {:ok, t() | nil} | {:error, atom()}
  def coerce(nil), do: {:ok, nil}

  def coerce(%__MODULE__{} = authority) do
    with {:ok, map} <- authority_map(authority),
         {:ok, validated} <- from_map(map) do
      {:ok, %{validated | authority_hash: authority.authority_hash || validated.authority_hash}}
    end
  end

  def coerce(map) when is_map(map), do: from_map(map)
  def coerce(_authority), do: {:error, :invalid_authority}

  @spec lookup(t(), String.t(), String.t() | nil) ::
          {:ok, Entry.t()} | {:error, :authority_missing | :source_breakpoint_mismatch}
  def lookup(%__MODULE__{breakpoints: breakpoints}, breakpoint_id, source_name)
      when is_binary(breakpoint_id) do
    case Map.get(breakpoints, breakpoint_id) do
      nil -> {:error, :authority_missing}
      %Entry{source_name: ^source_name} = entry -> {:ok, entry}
      %Entry{} -> {:error, :source_breakpoint_mismatch}
    end
  end

  def lookup(_authority, _breakpoint_id, _source_name), do: {:error, :authority_missing}

  @spec ordered_entries(t()) :: [Entry.t()]
  def ordered_entries(%__MODULE__{} = authority),
    do: ordered_entries(authority, Map.values(authority.breakpoints))

  @spec ordered_entries(t(), [Entry.t()]) :: [Entry.t()]
  def ordered_entries(%__MODULE__{}, entries) when is_list(entries),
    do: Enum.sort_by(entries, &{&1.cascade_order, &1.source_name})

  defp breakpoint_entries(breakpoints) when is_map(breakpoints) and not is_struct(breakpoints) do
    entries =
      Enum.map(breakpoints, fn {key, value} ->
        with :ok <- non_empty_string(key),
             {:ok, entry} <- breakpoint_entry(key, value) do
          {:ok, entry}
        else
          {:error, reason} -> {:error, reason}
        end
      end)

    case Enum.find(entries, &match?({:error, _}, &1)) do
      nil -> {:ok, Map.new(entries, fn {:ok, entry} -> {entry.source_name, entry} end)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp breakpoint_entries(_breakpoints), do: {:error, :invalid_breakpoints}

  defp authority_map(%__MODULE__{breakpoints: breakpoints} = authority)
       when is_map(breakpoints) and not is_struct(breakpoints) do
    entries =
      Enum.map(breakpoints, fn {key, entry} ->
        case entry_map(key, entry) do
          {:ok, mapped} -> {:ok, mapped}
          {:error, reason} -> {:error, reason}
        end
      end)

    case Enum.find(entries, &match?({:error, _}, &1)) do
      nil ->
        {:ok,
         %{
           "schema_version" => authority.schema_version,
           "authority_status" => "accepted",
           "authority_level" => authority.authority_level,
           "authority_type" => authority.authority_type,
           "breakpoints" => Map.new(entries, fn {:ok, {key, mapped}} -> {key, mapped} end),
           "cascade" => %{"ordering" => authority.cascade_ordering}
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp authority_map(_authority), do: {:error, :invalid_authority}

  defp entry_map(key, %Entry{} = entry) when is_binary(key) do
    {:ok,
     {key,
      %{
        "source_name" => entry.source_name,
        "source_width" => entry.source_width,
        "min_width" => entry.min_width,
        "max_width" => entry.max_width,
        "unit" => entry.unit,
        "query_semantics" => entry.query_semantics,
        "media_condition" => entry.media_condition,
        "enabled" => entry.enabled,
        "cascade_order" => entry.cascade_order,
        "authority_level" => entry.authority_level,
        "authority_type" => entry.authority_type,
        "status" => entry.status
      }}}
  end

  defp entry_map(_key, _entry), do: {:error, :invalid_breakpoint_entry}

  defp breakpoint_entry(key, value) when is_map(value) and not is_struct(value) do
    with {:ok, source_name} <- required_string(value, "source_name"),
         :ok <- exact(source_name, key, :source_breakpoint_mismatch),
         {:ok, source_width} <- non_negative_number(value, "source_width"),
         {:ok, min_width} <- optional_number(value, "min_width"),
         {:ok, max_width} <- optional_number(value, "max_width"),
         {:ok, unit} <- required_string(value, "unit"),
         :ok <- exact(unit, "px", :unsupported_breakpoint_unit),
         {:ok, query_semantics} <- required_string(value, "query_semantics"),
         :ok <- supported_query_semantics(query_semantics),
         {:ok, media_condition} <- required_string(value, "media_condition"),
         :ok <- valid_media_semantics(query_semantics, min_width, max_width, media_condition),
         :ok <- exact(value["enabled"], true, :breakpoint_disabled),
         {:ok, cascade_order} <- positive_integer(value, "cascade_order"),
         {:ok, authority_level} <- positive_integer(value, "authority_level"),
         {:ok, authority_type} <- required_string(value, "authority_type"),
         {:ok, status} <- required_string(value, "status"),
         :ok <- exact(status, "accepted", :breakpoint_not_accepted) do
      {:ok,
       %Entry{
         source_name: source_name,
         source_width: source_width,
         min_width: min_width,
         max_width: max_width,
         unit: unit,
         query_semantics: query_semantics,
         media_condition: media_condition,
         enabled: true,
         cascade_order: cascade_order,
         authority_level: authority_level,
         authority_type: authority_type,
         status: status
       }}
    end
  end

  defp breakpoint_entry(_key, _value), do: {:error, :invalid_breakpoint_entry}

  defp cascade_ordering(cascade) when is_map(cascade) and not is_struct(cascade) do
    case cascade["ordering"] do
      @supported_ordering -> {:ok, @supported_ordering}
      _ -> {:error, :unsupported_cascade_ordering}
    end
  end

  defp cascade_ordering(_cascade), do: {:error, :invalid_cascade}

  defp valid_media_semantics("max-width", nil, max_width, media_condition)
       when not is_nil(max_width),
       do:
         exact(media_condition, media_condition("max-width", max_width), :invalid_media_condition)

  defp valid_media_semantics("min-width", min_width, nil, media_condition)
       when not is_nil(min_width),
       do:
         exact(media_condition, media_condition("min-width", min_width), :invalid_media_condition)

  defp valid_media_semantics(_semantics, _min_width, _max_width, _media_condition),
    do: {:error, :ambiguous_media_semantics}

  defp media_condition("max-width", width), do: "@media (max-width: #{width_string(width)}px)"
  defp media_condition("min-width", width), do: "@media (min-width: #{width_string(width)}px)"

  defp width_string(width) when is_integer(width), do: Integer.to_string(width)
  defp width_string(width), do: :erlang.float_to_binary(width, [:compact])

  defp supported_query_semantics(semantics) when semantics in @supported_query_semantics, do: :ok
  defp supported_query_semantics(_semantics), do: {:error, :unsupported_query_semantics}

  defp required_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :invalid_authority_field}
    end
  end

  defp non_empty_string(value) when is_binary(value) and value != "", do: :ok
  defp non_empty_string(_value), do: {:error, :invalid_breakpoint_name}

  defp positive_integer(map, key) do
    case map[key] do
      value when is_integer(value) and value > 0 -> {:ok, value}
      _ -> {:error, :invalid_authority_field}
    end
  end

  defp non_negative_number(map, key) do
    case map[key] do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      value when is_float(value) and value >= 0 and value == value -> {:ok, value}
      _ -> {:error, :invalid_authority_field}
    end
  end

  defp optional_number(map, key) do
    case Map.fetch(map, key) do
      :error -> {:ok, nil}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} when is_integer(value) and value >= 0 -> {:ok, value}
      {:ok, value} when is_float(value) and value >= 0 and value == value -> {:ok, value}
      _ -> {:error, :invalid_authority_field}
    end
  end

  defp exact(value, expected, _reason) when value == expected, do: :ok
  defp exact(_value, _expected, reason), do: {:error, reason}

  defp sha(value), do: Base.encode16(:crypto.hash(:sha256, value), case: :lower)
end
