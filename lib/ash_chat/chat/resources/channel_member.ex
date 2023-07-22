defmodule App.Chat.ChannelMember do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    attribute :last_read_at, :utc_datetime_usec
  end

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

    update :read_channel do
      change set_attribute(:last_read_at, DateTime.utc_now())
    end
  end

  code_interface do
    define_for App.Chat

    define :read_channel, action: :read_channel
  end
end
