defmodule Common.Xml do
  @moduledoc false

  import Record, only: [defrecord: 2, extract: 2]

  defrecord :xml_element, extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  defrecord :xml_text, extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  @spec parse(String.t(), String.t()) :: {:ok, map}
  def parse(xml_string, root_element \\ "xml") when is_binary(xml_string) do
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

end
