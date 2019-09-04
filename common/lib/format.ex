defmodule Common.Format do
  @moduledoc """
  format tools
  """
  import Record, only: [defrecord: 2, extract: 2]

  defrecord :xml_element, extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  defrecord :xml_text, extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

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
  将xml转为map

  * xml_string   - xml文本
  * root_element - 根节点

  ## Examples

  iex> xml = "<xml><return_code><![CDATA[SUCCESS]]></return_code><return_msg><![CDATA[OK]]></return_msg></xml>"
  iex> Common.Format.xml_parse(xml)
  {:ok, %{return_code: "SUCCESS", return_msg: "OK"}}
  """
  @spec xml_parse(String.t(), String.t()) :: {:ok, map}
  def xml_parse(xml_string, root_element \\ "xml") when is_binary(xml_string) do
    {doc, _} =
      xml_string
      |> :binary.bin_to_list()
      |> :xmerl_scan.string()

    parsed_xml = extract_doc(doc, root_element)

    {:ok, parsed_xml}
  end

  defp extract_doc(doc, root) do
    "/#{root}/child::*"
    |> String.to_charlist()
    |> :xmerl_xpath.string(doc)
    |> Enum.into(%{}, &extract_element/1)
  end

  defp extract_element(element) do
    name = xml_element(element, :name)

    [content] = xml_element(element, :content)

    value =
      content
      |> xml_text(:value)
      |> String.Chars.to_string()

    {name, value}
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
