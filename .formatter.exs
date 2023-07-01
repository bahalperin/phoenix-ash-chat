[
  import_deps: [:ecto, :phoenix, :ash, :ash_phoenix, :ash_postgres, :ash_authentication_phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, Spark.Formatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
