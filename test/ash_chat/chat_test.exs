defmodule App.ChatTest do
  use App.DataCase

  alias App.Factory

  describe "channel" do
    alias App.Chat.Channel

    test "create fails without an actor" do
      assert_raise(Ash.Error.Forbidden.ApiRequiresActor, fn ->
        Channel.create(%{name: "test", private: false})
      end)
    end

    test "create succeeds with valid args" do
      user = Factory.user()
      assert {:ok, %Channel{}} = Channel.create(%{name: "general", private: false}, actor: user)
    end

    test "create fails with invalid args" do
      user = Factory.user()

      assert {:error, %Ash.Error.Invalid{}} =
               Channel.create(%{name: "", private: false}, actor: user)
    end

    test "get_by_id fails without an actor" do
      user = Factory.user()
      channel = Channel.create!(%{name: "test", private: false}, actor: user)

      assert_raise(Ash.Error.Forbidden.ApiRequiresActor, fn ->
        Channel.get_by_id(channel.id)
      end)
    end

    test "get_by_id fails with not found when no channel exists" do
      user = Factory.user()

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Channel.get_by_id(Ash.UUID.generate(), actor: user)
    end

    test "get_by_id succeeds when channel does exist" do
      user = Factory.user()
      channel = Channel.create!(%{name: "test", private: false}, actor: user)
      assert {:ok, %Channel{}} = Channel.get_by_id(channel.id, actor: user)
    end

    test "read_all fails without an actor" do
      assert_raise(Ash.Error.Forbidden.ApiRequiresActor, fn ->
        Channel.read_all()
      end)
    end

    test "read_all returns public channels and private channels the actor is a member of" do
      user1 = Factory.user()
      user2 = Factory.user()
      Channel.create!(%{name: "test", private: false}, actor: user1)
      Channel.create!(%{name: "main", private: false}, actor: user2)
      Channel.create!(%{name: "secret", private: true}, actor: user2)
      channel = Channel.create!(%{name: "super-secret", private: true}, actor: user2)

      App.Chat.ChannelMember.add_to_channel!(
        %{
          user_id: user1.id,
          channel_id: channel.id
        },
        actor: user2
      )

      assert {:ok, channels1} = Channel.read_all(actor: user1)
      channel_names_1 = Enum.map(channels1, fn channel -> channel.name end)
      assert channel_names_1 == ["main", "super-secret", "test"]

      assert {:ok, channels2} = Channel.read_all(actor: user2)
      channel_names_2 = Enum.map(channels2, fn channel -> channel.name end)
      assert channel_names_2 == ["main", "secret", "super-secret", "test"]
    end
  end
end
