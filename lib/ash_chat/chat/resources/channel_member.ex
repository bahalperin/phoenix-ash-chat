defmodule App.Chat.ChannelMember do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  attributes do
    uuid_primary_key :id
    attribute :last_read_at, :utc_datetime_usec

    attribute :channel_id, :uuid
    attribute :user_id, :uuid
  end

  pub_sub do
    module AppWeb.Endpoint
    prefix "channel_member"

    publish :join_channel, "joined"
  end

  relationships do
    belongs_to :channel, App.Chat.Channel,
      primary_key?: true,
      allow_nil?: false,
      writable?: true,
      private?: false

    belongs_to :user, App.Account.User,
      primary_key?: true,
      allow_nil?: false,
      writable?: true,
      private?: false
  end

  postgres do
    table "channel_member"
    repo App.Repo
  end

  actions do
    defaults [:create, :read, :destroy]

    read :list do
      prepare build(load: [:user])
    end

    read :current do
      prepare build(load: [:unread_count])
      filter expr(user_id == ^actor(:id))
    end

    create :join_channel do
      accept [:channel_id]

      change set_attribute(:user_id, actor(:id))
    end

    update :read_channel do
      change set_attribute(:last_read_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for App.Chat

    define :read_channel, action: :read_channel
    define :join_channel, action: :join_channel
  end

  calculations do
    calculate :unread_count,
              :integer,
              expr(
                fragment(
                  "select count(*) from message where channel_id = ? and created_at > ? and sender_id != ?",
                  channel_id,
                  last_read_at,
                  user_id
                )
              )
  end
end
