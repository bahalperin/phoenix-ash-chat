defmodule App.Repo.Migrations.UniqueChannelMemberUserChannel do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create unique_index(:channel_member, [:user_id, :channel_id],
             name: "channel_member_user_channel_index"
           )
  end

  def down do
    drop_if_exists unique_index(:channel_member, [:user_id, :channel_id],
                     name: "channel_member_user_channel_index"
                   )
  end
end
