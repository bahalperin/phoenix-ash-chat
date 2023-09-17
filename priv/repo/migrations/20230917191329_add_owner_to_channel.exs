defmodule App.Repo.Migrations.AddOwnerToChannel do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:channel) do
      add :owner_id,
          references(:users,
            column: :id,
            name: "channel_owner_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end
  end

  def down do
    drop constraint(:channel, "channel_owner_id_fkey")

    alter table(:channel) do
      remove :owner_id
    end
  end
end