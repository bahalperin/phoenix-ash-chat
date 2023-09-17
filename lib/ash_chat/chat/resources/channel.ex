defmodule App.Chat.Channel do
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub]

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :private, :boolean do
      default false
    end
  end

  relationships do
    has_many :members, App.Chat.ChannelMember do
      writable? true
      read_action :list
    end

    has_one :current_member, App.Chat.ChannelMember do
      read_action :current
    end

    has_many :messages, App.Chat.Message, sort: [created_at: :desc]

    belongs_to :owner, App.Account.User do
      api App.Account
      source_attribute :owner_id
      destination_attribute :id
    end
  end

  pub_sub do
    module AppWeb.Endpoint
    prefix "channel"

    publish :create, ["created", [:id, nil]]
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(private == false || exists(members, user_id == ^actor(:id)))
    end

    policy action_type(:destroy) do
      forbid_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:owner)
    end
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
      prepare build(sort: [name: :desc], load: [:members, :current_member])
    end

    create :create do
      accept [:name, :private]

      validate match(:name, ~r/^[[:graph:]]+$/), message: "No whitespace allowed in channel name"

      change relate_actor(:owner)

      change fn changeset, _ ->
        Ash.Changeset.after_action(changeset, fn changeset, channel ->
          App.Chat.create!(
            Ash.Changeset.for_create(
              App.Chat.ChannelMember,
              :create,
              %{
                channel_id: channel.id,
                user_id: channel.owner_id
              }
            ),
            actor: %{type: :admin}
          )

          {:ok, channel}
        end)
      end
    end
  end

  code_interface do
    define_for App.Chat
    define :create, action: :create
    define :read_all, action: :read_all
    define :get_by_id, args: [:id], action: :by_id
  end
end
