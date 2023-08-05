defmodule App.Chat.Message do
  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  attributes do
    uuid_primary_key :id

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :text, :string do
      allow_nil? false
    end

    attribute :edited, :boolean do
      default false
    end
  end

  relationships do
    belongs_to :channel, App.Chat.Channel do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :sender, App.Account.User do
      allow_nil? false
      attribute_writable? true
    end
  end

  pub_sub do
    module AppWeb.Endpoint
    prefix "message"

    publish :send, ["created", [:id, nil]]
    publish :edit, ["updated", [:id, nil]]
    publish :destroy, ["deleted", [:id, nil]]
  end

  policies do
    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:sender)
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:sender)
    end
  end

  postgres do
    table "message"
    repo App.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :by_id do
      argument :id, :uuid, allow_nil?: false
      get? true
      prepare build(load: [:sender])
      filter expr(id == ^arg(:id))
    end

    create :send do
      accept [:text, :channel_id]

      change relate_actor(:sender)
    end

    update :edit do
      accept [:text]

      change set_attribute(:edited, true)
    end

    read :list do
      argument :channel_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true, default_limit: 50
      prepare build(sort: [created_at: :desc], load: [:sender])

      filter expr(channel_id == ^arg(:channel_id))
    end
  end

  code_interface do
    define_for App.Chat
    define :get_by_id, args: [:id], action: :by_id
    define :send, action: :send
    define :edit, action: :edit
    define :list, action: :list, args: [:channel_id]
    define :delete, action: :destroy
  end
end
