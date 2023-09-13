defmodule App.Repo do
  use AshPostgres.Repo, otp_app: :ash_chat

  # Installs Postgres extensions that ash commonly uses
  def installed_extensions do
    ["uuid-ossp", "citext", "ash-functions"]
  end
end
