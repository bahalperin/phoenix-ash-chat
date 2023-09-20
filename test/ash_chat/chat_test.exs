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
  end
end
