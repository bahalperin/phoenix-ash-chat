defmodule App.Chat do
  use Ash.Api

  resources do
    registry App.Chat.Registry
  end
end
