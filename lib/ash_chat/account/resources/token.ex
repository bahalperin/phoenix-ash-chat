defmodule App.Account.Token do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  token do
    api App.Account
  end

  postgres do
    table "token"
    repo App.Repo
  end
end
