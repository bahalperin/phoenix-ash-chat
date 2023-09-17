defmodule App.Chat.Checks.ActorIsChannelMember do
  use Ash.Policy.SimpleCheck

  def describe(_), do: "Is the actor a member of the channel?"

  def match?(actor, %{changeset: %{attributes: %{channel_id: channel_id}}}, _) do
    case App.Chat.ChannelMember.get_by_channel(channel_id, actor: actor) do
      {:ok, _} -> true
      _ -> false
    end
  end
end
