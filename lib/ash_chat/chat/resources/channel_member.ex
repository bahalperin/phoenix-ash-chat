defmodule App.Chat.ChannelMember do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  relationships do
    belongs_to :channel, App.Chat.Channel, primary_key?: true, allow_nil?: false
    belongs_to :user, App.Account.User, primary_key?: true, allow_nil?: false
  end

  postgres do
    table "channel_member"
    repo App.Repo
  end

  actions do
    defaults [:create, :read, :destroy]

    read :current do
      filter expr(user_id == ^actor(:id))
    end
  end
end
