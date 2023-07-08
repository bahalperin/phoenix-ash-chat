defmodule App.Chat.Message do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  attributes do
    uuid_primary_key :id

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :text, :string do
      allow_nil? false
    end
  end

  pub_sub do
    module AppWeb.Endpoint
    prefix "message"

    publish :send, ["created", [:id, nil]]
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

  postgres do
    table "message"
    repo App.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :send do
      accept [:text, :channel_id]

      change relate_actor(:sender)
    end

    read :list do
      argument :channel_id, :uuid do
        allow_nil? false
      end

      pagination offset?: true, default_limit: 50
      prepare build(sort: [created_at: :desc])

      filter expr(channel_id == ^arg(:channel_id))
    end
  end

  code_interface do
    define_for App.Chat
    define :send, action: :send
    define :list, action: :list, args: [:channel_id]
  end
end
