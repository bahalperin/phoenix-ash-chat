defmodule App.Chat do
  use Ash.Api

  resources do
    registry App.Chat.Registry
  end

  authorization do
    require_actor? true
    authorize :by_default
  end
end
