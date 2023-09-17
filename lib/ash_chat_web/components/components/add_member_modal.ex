defmodule AppWeb.Components.AddMemberModal do
  use AppWeb, :live_component

  require Ash.Query

  alias AppWeb.Components.Chat, as: Components

  def render(%{channel: nil} = assigns) do
    ~H"""
    <div />
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id={@id}
        container_class="bg-slate-800 text-white"
        background_class="bg-black opacity-80"
      >
        <:title>
          <span class="text-white">
            Add User to <%= @channel.name %>
          </span>
        </:title>
        <form phx-change="search_users" phx-throttle={200} phx-target={@myself}>
          <div class="flex flex-col gap-4">
            <.input
              id="user-search"
              name="user-search"
              value={@user_input_text}
              placeholder="Search for a user"
              class="bg-slate-800 text-white"
            />
            <div class="flex flex-col gap-2">
              <%= for user <- @users do %>
                <.button
                  class="bg-transparent hover:bg-slate-900"
                  phx-click="add_member"
                  phx-value-user-id={user.id}
                  phx-target={@myself}
                >
                  <div class="flex flex-row gap-2">
                    <Components.profile_photo user={user} size={:xs} />
                    <Components.user_name user={user} />
                  </div>
                </.button>
              <% end %>
            </div>
          </div>
        </form>
      </.modal>
    </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(:user_input_text, "")
      |> assign(:users, [])

    {:ok, socket}
  end

  def handle_event("add_member", %{"user-id" => user_id}, socket) do
    App.Chat.ChannelMember.add_to_channel!(
      %{
        channel_id: socket.assigns.channel.id,
        user_id: user_id
      },
      actor: socket.assigns.current_user
    )

    {:noreply, socket}
  end

  def handle_event("search_users", %{"user-search" => ""}, socket) do
    socket =
      socket |> assign(:users, [])

    {:noreply, socket}
  end

  def handle_event("search_users", %{"user-search" => username}, socket) do
    channel_member_ids =
      socket.assigns.channel.members
      |> Enum.map(fn member -> member.user_id end)

    users =
      App.Account.User
      |> Ash.Query.filter(ilike(display_name, ^"%#{username}%"))
      |> Ash.Query.filter(id != ^socket.assigns.current_user.id)
      |> App.Account.read!()
      |> Enum.filter(fn user -> !Enum.member?(channel_member_ids, user.id) end)

    socket =
      socket |> assign(:users, users)

    {:noreply, socket}
  end
end
