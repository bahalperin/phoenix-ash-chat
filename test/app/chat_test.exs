defmodule App.ChatTest do
  use App.DataCase

  alias App.Chat

  describe "channel" do
    alias App.Chat.Channel

    @invalid_attrs %{name: 47}
    @actor %{id: "uuid"}

    test "create with valid data and actor creates channel" do
      assert {:ok, %Channel{} = channel} = Channel.create(%{name: "main"}, actor: @actor)
    end

    test "create without an actor fails" do
      assert_raise Ash.Error.Forbidden.ApiRequiresActor, fn ->
        Channel.create(%{name: "main"})
      end
    end

    test "create fails with invalid data" do
      assert {:error, _} = Channel.create(@invalid_attrs, actor: @actor)
    end
  end
end
