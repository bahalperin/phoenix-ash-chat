defmodule App.Account.User do
  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  authentication do
    api App.Account

    strategies do
      password :password do
        identity_field(:email)
        register_action_accept([:display_name])

        resettable do
          sender(App.Account.User.Senders.SendPasswordResetEmail)
        end
      end
    end

    tokens do
      enabled?(true)
      token_resource(App.Account.Token)

      signing_secret(fn _, _ ->
        {:ok, Application.get_env(:ash_chat, AppWeb.Endpoint)[:secret_key_base]}
      end)
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true

    attribute :display_name, :string do
      allow_nil? false
      default ""
    end

    attribute :photo_url, :string
  end

  policies do
    policy action_type(:destroy) do
      authorize_if expr(id == ^actor(:id))
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if expr(id == ^actor(:id))
    end
  end

  postgres do
    table "users"
    repo App.Repo
  end

  actions do
    read :read do
      primary? true
    end

    read :by_id do
      argument :id, :uuid, allow_nil?: false
      get? true
      filter expr(id == ^arg(:id))
    end

    update :update do
      accept [:display_name, :photo_url]
    end
  end

  code_interface do
    define_for App.Account
    define :get_by_id, args: [:id], action: :by_id
    define :update, action: :update
  end

  identities do
    identity :unique_email, [:email]
  end
end
