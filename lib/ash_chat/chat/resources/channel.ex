defmodule App.Chat.Channel do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Ash.Notifier.PubSub]

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end
  end

  pub_sub do
    module App.PubSub
    prefix "channel"

    publish :create, ["created", [:id, nil]]
  end

  relationships do
    has_many :members, App.Chat.ChannelMember do
      writable? true
    end

    has_one :current_member, App.Chat.ChannelMember do
      read_action :current
    end

    has_many :messages, App.Chat.Message, sort: [created_at: :desc]
  end

  postgres do
    table "channel"
    repo App.Repo
  end

  actions do
    defaults [:read, :update, :destroy]

    # Defines custom read action which fetches post by id.
    read :by_id do
      argument :id, :uuid, allow_nil?: false
      get? true
      prepare build(load: [:members, :current_member])
      filter expr(id == ^arg(:id))
    end

    read :read_all do
      prepare build(sort: [:name], load: [:members, :current_member])
      filter expr(exists(members, user_id == ^actor(:id)))
    end

    create :create do
      accept [:name]

      validate match(:name, ~r/^[[:graph:]]+$/), message: "No whitespace allowed in channel name"

      change relate_actor(:members)
    end
  end

  code_interface do
    define_for App.Chat
    define :create, action: :create
    define :read_all, action: :read_all
    define :get_by_id, args: [:id], action: :by_id
  end
end
