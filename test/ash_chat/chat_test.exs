defmodule App.ChatTest do
  alias App.Chat.ChannelMember
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

    test "get_by_id fails for a private channel the user isn't a member of" do
      user1 = Factory.user()
      user2 = Factory.user()

      channel = Channel.create!(%{name: "test", private: true}, actor: user1)

      assert {:error, %Ash.Error.Query.NotFound{}} =
               Channel.get_by_id(channel.id, actor: user2)
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

  describe "message" do
    alias App.Chat.Channel
    alias App.Chat.ChannelMember
    alias App.Chat.Message

    setup do
      user1 = Factory.user()
      channel = Channel.create!(%{name: "general", private: false}, actor: user1)
      user2 = Factory.user()

      user3 = Factory.user()
      ChannelMember.join_channel!(%{channel_id: channel.id}, actor: user3)

      {:ok, members: [user1, user3], non_member: user2, channel: channel}
    end

    test "sending a message fails without an actor", %{channel: channel} do
      assert_raise(Ash.Error.Forbidden.ApiRequiresActor, fn ->
        Message.send(%{text: "hello", channel_id: channel.id})
      end)
    end

    test "cannot send a message if not a channel member", %{
      non_member: non_member,
      channel: channel
    } do
      assert {:error, %Ash.Error.Forbidden{}} =
               Message.send(%{text: "hello", channel_id: channel.id}, actor: non_member)
    end

    test "can send message if a channel member", %{members: [member, _], channel: channel} do
      assert {:ok, _} = Message.send(%{text: "hello", channel_id: channel.id}, actor: member)
    end

    test "can edit your own message", %{members: [member, _], channel: channel} do
      {:ok, message} = Message.send(%{text: "hello", channel_id: channel.id}, actor: member)
      assert {:ok, edited_message} = Message.edit(message, %{text: "hi"}, actor: member)
      assert edited_message.text == "hi"
    end

    test "cannot edit someone else's message", %{members: [member1, member2], channel: channel} do
      {:ok, message} = Message.send(%{text: "hello", channel_id: channel.id}, actor: member1)

      assert {:error, %Ash.Error.Forbidden{}} =
               Message.edit(message, %{text: "hi"}, actor: member2)
    end

    test "can view messages in a public channel even if not a member", %{
      members: [member, _],
      non_member: non_member,
      channel: channel
    } do
      Message.send!(%{text: "message", channel_id: channel.id}, actor: member)

      {:ok, %{results: [_]}} = Message.list(channel.id, actor: non_member)
    end

    test "can only view messages in a private channel if a member", %{
      members: [member, _],
      non_member: non_member
    } do
      private_channel = Channel.create!(%{name: "shhh", private: true}, actor: member)
      Message.send!(%{text: "secret", channel_id: private_channel.id}, actor: member)

      assert {:ok, %{results: []}} = Message.list(private_channel.id, actor: non_member)
      assert {:ok, %{results: [message]}} = Message.list(private_channel.id, actor: member)
      assert message.text == "secret"
    end

    test "can only delete your own messages", %{
      members: [member1, member2],
      non_member: non_member,
      channel: channel
    } do
      message = Message.send!(%{text: "delete", channel_id: channel.id}, actor: member1)

      assert {:error, %Ash.Error.Forbidden{}} = Message.delete(message, actor: member2)
      assert :ok = Message.delete(message, actor: member1)
    end
  end
end
