defmodule App.Account do
  use Ash.Api

  resources do
    registry App.Account.Registry
  end
end
