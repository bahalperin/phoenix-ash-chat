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
  end

  relationships do
    many_to_many :members, App.Account.User do
      through App.Chat.ChannelMember
      source_attribute_on_join_resource :channel_id
      destination_attribute_on_join_resource :user_id
    end
  end

  postgres do
    table "channel"
    repo App.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    # Defines custom read action which fetches post by id.
    read :by_id do
      argument :id, :uuid, allow_nil?: false
      get? true
      filter expr(id == ^arg(:id))
    end
  end

  code_interface do
    define_for App.Chat
    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, args: [:id], action: :by_id
  end
end
