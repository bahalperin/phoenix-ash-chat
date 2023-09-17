defmodule App.Chat.Checks.ChannelIsPublic do
  use Ash.Policy.SimpleCheck

  def describe(_), do: "Is it a public channel?"

  def match?(actor, %{changeset: %{attributes: %{channel_id: channel_id}}}, _) do
    case App.Chat.Channel.get_by_id(channel_id, actor: actor) do
      {:ok, %{private: private}} -> !private
      _ -> false
    end
  end
end
