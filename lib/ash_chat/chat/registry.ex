defmodule App.Chat.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry App.Account.User
    entry App.Chat.Channel
    entry App.Chat.ChannelMember
  end
end
