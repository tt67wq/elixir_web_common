defmodule Common.Xml do
  @moduledoc """
  Module to recursively traverse the output of erlsom.simple_form
  and produce a map.
  erlsom uses character lists so this library converts them to 
  Elixir binary string.
  """

  def parse([value]) do
    case is_tuple(value) do
      true -> parse(value)
      false -> to_string(value) |> String.trim()
    end
  end

  def parse({name, attr, content}) do
    parsed_content = parse(content)

    case is_map(parsed_content) do
      true ->
        %{to_string(name) => parsed_content |> Map.merge(attr_map(attr))}

      false ->
        %{to_string(name) => parsed_content}
    end
  end

  def parse(list) when is_list(list) do
    parsed_list = Enum.map(list, &{to_string(elem(&1, 0)), parse(&1)})

    Enum.reduce(parsed_list, %{}, fn {k, v}, acc ->
      case Map.get(acc, k) do
        nil -> Map.put_new(acc, k, v[k])
        [h | t] -> Map.put(acc, k, [h | t] ++ [v[k]])
        prev -> Map.put(acc, k, [prev] ++ [v[k]])
      end
    end)
  end

  defp attr_map(list) do
    list |> Enum.map(fn {k, v} -> {to_string(k), to_string(v)} end) |> Map.new()
  end

  @doc """
  naive_map(xml) utility is inspired by Rails Hash.from_xml()
  but is "naive" in that it is convenient (requires no setup)
  but carries the same drawbacks. Use with caution.
  XML and Maps are non-isomorphic.
  Attributes on some nodes don't carry over if the node has just
  one text value (like a leaf). Naive map has no validation over
  what should be a collection.  If and only if nodes are repeated
  at the same level will they beome a list.


  ## Examples

  iex> xml = "<xml><return_code><![CDATA[SUCCESS]]></return_code><return_msg><![CDATA[OK]]></return_msg></xml>"
  iex> Common.Xml.naive_map(xml)
  %{"xml" => %{"return_code" => "SUCCESS", "return_msg" => "OK"}}
  """

  def naive_map(xml) do
    # can't handle xmlns
    xml = String.replace(xml, ~r/(\sxmlns="\S+")|(xmlns:ns2="\S+")/, "")
    {:ok, tuples, _} = :erlsom.simple_form(xml)
    parse(tuples)
  end
end
