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
  map key从string转为atom
  ps: 当params的key不确定的时候慎用，防止大量产出atom

  * params - string key map

  ## Examples

  iex> params = %{"a"=>1, "b"=>2}
  %{"a" => 1, "b" => 2}
  iex> Common.Format.stringkey2atom(params) 
  %{a: 1, b: 2}
  """
  def stringkey2atom(params),
    do:
      params
      |> Enum.into(%{}, fn
        {k, v} when is_map(v) -> {String.to_atom(k), stringkey2atom(v)}
        {k, v} -> {String.to_atom(k), v}
      end)

  @doc """
  map => xml string

  * params - map

  ## Examples

  iex> Common.Format.map2xml(%{"a" => 1, "b" => 2})
  "<xml><a>1</a><b>2</b></xml>"
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
  map按照key字典序列排列并用&链接，value为空串，map，list，非string的binary等不参与

  * params - map
  * case_sensetive - 是否大小写敏感

  ## Examples

  iex> params = %{"a" => 1, "B" => "2", "c" => "", "d" => [], "e" => %{}}
  %{"a" => 1, "B" => "2", "c" => "", "d" => [], "e" => %{}}
  iex> Common.Format.sort_and_concat(params)
  "a=1&B=2"
  iex> Common.Format.sort_and_concat(params, true)
  "B=2&a=1"
  """
  @spec sort_and_concat(map()) :: String.t()
  def sort_and_concat(params, case_sensitive \\ false)

  def sort_and_concat(params, true) do
    params
    |> Map.to_list()
    |> Enum.filter(fn {_, y} -> y != "" and valid_value(y) end)
    |> Enum.sort(fn {x, _}, {y, _} -> x < y end)
    |> Enum.map(fn {x, y} -> "#{x}=#{y}" end)
    |> Enum.join("&")
  end

  def sort_and_concat(params, false) do
    params
    |> Map.to_list()
    |> Enum.filter(fn {_, y} -> y != "" and valid_value(y) end)
    |> Enum.sort(fn {x, _}, {y, _} ->
      String.downcase(to_string(x)) < String.downcase(to_string(y))
    end)
    |> Enum.map(fn {x, y} -> "#{x}=#{y}" end)
    |> Enum.join("&")
  end

  defp valid_value(value), do: String.valid?(value) or is_integer(value) or is_float(value)
end
