defmodule Common.Format do
  @moduledoc """
  format tools
  """

  @doc """
  map key转为驼峰风格
  """
  def camelize(map) when is_map(map) do
    map
    |> Enum.into(%{}, fn {key, value} -> {camelize_key(key), value} end)
  end

  defp camelize_key(key) when is_atom(key), do: key |> to_string |> camelize_key

  defp camelize_key(key) when is_bitstring(key) do
    key
    |> String.split("_")
    |> Enum.reduce([], &camel_case/2)
    |> Enum.join()
  end

  defp camel_case(item, []), do: [item]
  defp camel_case(item, list), do: list ++ [String.capitalize(item)]

  @doc """
  map key从str转为atom
  """
  def stringkey2atom(params),
    do:
      params
      |> Enum.into(%{}, fn
        {k, v} when is_map(v) -> {String.to_atom(k), stringkey2atom(v)}
        {k, v} -> {String.to_atom(k), v}
      end)

  @doc """
  map 转成 xml
  """
  def map2xml(params) do
    content =
      params
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> "<#{k}>#{v}</#{k}>" end)
      |> Enum.join()

    "<xml>" <> content <> "</xml>"
  end

  @doc """
  xml 转 map
  """
  def xml2map(xml) do
    re = ~r/<(?<k>.+)>(?<v>.+)<\/(.+)>/

    xml
    |> String.slice(5..-8)
    |> String.split("\n")
    |> Enum.map(fn x -> Regex.named_captures(re, x) end)
    |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, Map.get(x, "k"), cdata(Map.get(x, "v"))) end)
    |> stringkey2atom()
  end

  defp cdata(str) do
    if String.contains?(str, "CDATA") do
      ~r/\<\!\[CDATA\[(?<v>.*)\]\]\>/
      |> Regex.named_captures(str)
      |> Map.get("v")
    else
      str
    end
  end

  @doc """
  map按照字典序排列并链接
  """
  @spec sort_and_concat(map()) :: String.t()
  def sort_and_concat(params, case_sensitive \\ false)

  def sort_and_concat(params, true) do
    params
    |> Map.to_list()
    |> Enum.filter(fn {_, y} -> y != "" end)
    |> Enum.sort(fn {x, _}, {y, _} -> x < y end)
    |> Enum.map(fn {x, y} -> "#{x}=#{y}" end)
    |> Enum.join("&")
  end

  def sort_and_concat(params, false) do
    params
    |> Map.to_list()
    |> Enum.filter(fn {_, y} -> y != "" end)
    |> Enum.sort(fn {x, _}, {y, _} -> String.downcase(x) < String.downcase(y) end)
    |> Enum.map(fn {x, y} -> "#{x}=#{y}" end)
    |> Enum.join("&")
  end
end
