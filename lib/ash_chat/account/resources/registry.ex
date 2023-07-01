defmodule App.Account.Registry do
  use Ash.Registry, extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry App.Account.User
    entry App.Account.Token
  end
end
