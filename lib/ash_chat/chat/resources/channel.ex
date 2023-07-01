defmodule App.Chat.Channel do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "channel"
    repo App.Repo
  end

  code_interface do
    define_for App.Chat
    define :create, action: :create
    define :read_all, action: :read
    define :get_by_id, args: [:id], action: :by_id
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

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end
  end
end
