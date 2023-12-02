defmodule OSCx.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :oscx,
      name: "OSCx",
      description: "An Open Sound Control (OSC) message encoding and decoding library.",
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        source_url: "https://github.com/haubie/oscx",
        homepage_url: "https://github.com/haubie/oscx",
        logo: "logo-hexdoc.png",
        assets: "assets",
        extras: [
          "README.md",
          "examples.md",
          "arguments_and_types.md",
          "time_tags.md",
          "livebook/oscx_tour.livemd",
          {:"LICENSE", [title: "License (MIT)"]},
        ],
        groups_for_modules: [
          Main: [
            OSCx,
            OSCx.Message,
            OSCx.Bundle
          ],
          Helpers: [
            OSCx.Encoder,
            OSCx.Decoder
          ]
        ],
        groups_for_docs: [
          "Primary function": &(&1[:section] == :primary),
          "Type functions": &(&1[:section] == :type),
          "Tag specific": &(&1[:section] == :tag),
          "Helper functions": &(&1[:section] == :helper),
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/haubie/oscx"
        },
      maintainers: ["David Haubenschild"]
    ]
  end


end
