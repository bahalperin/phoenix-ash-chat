defmodule App.Chat.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  attributes do
    uuid_primary_key :id

    create_timestamp :created_at
    update_timestamp :updated_at

    attribute :display_name, :string do
      allow_nil? false
      default ""
    end

    attribute :account_user_id, :uuid do
      allow_nil? false
    end
  end

  pub_sub do
    module AppWeb.Endpoint
    prefix "user"

    publish :create, ["created", [:id, nil]]
  end

  postgres do
    table "chat_user"
    repo App.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :by_user_id do
      argument :user_id, :uuid, allow_nil?: false
      get? true
      filter expr(user_id == ^arg(:user_id))
    end
  end

  code_interface do
    define_for App.Chat
    define :get_by_user_id, args: [:user_id], action: :by_user_id
  end
end
