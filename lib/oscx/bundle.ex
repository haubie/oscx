defmodule OSCx.Bundle do
  defstruct time: %{seconds: nil, fraction: nil}, elements: []
  alias OSCx.Encoder

  def encode(time, elements) do
    [
      "#bundle",
      0,
      Encoder.time(time[:seconds], time[:fraction]),
      elements
    ]
  end

  # defp encode_elements(elements) do
  #   for element <- elements do
  #     element
  #     |> OSC.Encoder.encode()
  #     |> OSC.Encoder.prefix_size()
  #   end
  # end

end
