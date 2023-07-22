import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ash_chat, App.Repo,
  username: "benhalperin",
  password: "postgres",
  hostname: "localhost",
  database: "ash_chat_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ash_chat, AppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vBClw8DKLNf1HYEzo0TJeZ9XmsyWAtfTkr2/k1XWkLAO749s5Uu7j32olQyarByr",
  server: false

# In test we don't send emails.
config :ash_chat, App.Mailer, adapter: Swoosh.Adapters.Test

config :ash, :disable_async?, true
config :ash, :missed_notifications, :ignore

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
