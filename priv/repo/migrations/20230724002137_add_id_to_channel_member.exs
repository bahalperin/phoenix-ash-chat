defmodule App.Repo.Migrations.AddIdToChannelMember do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    drop constraint("channel_member", "channel_member_pkey")

    alter table(:channel_member) do
      modify :user_id, :uuid, null: true, primary_key: false
      modify :channel_id, :uuid, null: true, primary_key: false
      add :id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true
    end
  end

  def down do
    drop constraint("channel_member", "channel_member_pkey")

    alter table(:channel_member) do
      remove :id
      modify :channel_id, :uuid, null: false, primary_key: true
      modify :user_id, :uuid, null: false, primary_key: true
    end
  end
end
