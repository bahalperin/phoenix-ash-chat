defmodule App.Chat.ChannelMember do
  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  alias App.Chat.Checks

  attributes do
    uuid_primary_key :id
    attribute :last_read_at, :utc_datetime_usec

    attribute :channel_id, :uuid
    attribute :user_id, :uuid
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

  pub_sub do
    module AppWeb.Endpoint
    prefix "channel_member"

    publish :join_channel, "joined"
  end

  policies do
    policy action_type(:create) do
      authorize_if actor_attribute_equals(:type, :admin)
      authorize_if Checks.ChannelIsPublic
      authorize_if Checks.ActorIsChannelMember
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:destroy) do
      forbid_if always()
    end
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

    read :get_by_channel do
      argument :channel_id, :uuid

      get? true

      filter expr(user_id == ^actor(:id) && channel_id == ^arg(:channel_id))
    end

    read :current do
      prepare build(load: [:unread_count])
      filter expr(user_id == ^actor(:id))
    end

    create :join_channel do
      accept [:channel_id]

      change set_attribute(:user_id, actor(:id))
    end

    create :add_to_channel do
      accept [:channel_id, :user_id]
    end

    update :read_channel do
      change set_attribute(:last_read_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    define_for App.Chat

    define :get_by_channel, action: :get_by_channel, args: [:channel_id]
    define :read_channel, action: :read_channel
    define :join_channel, action: :join_channel
    define :add_to_channel, action: :add_to_channel
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
