defmodule AppWeb.ChannelLive do
  use AppWeb, :live_view

  alias App.Chat.Channel
  alias App.Chat.ChannelMember
  alias App.Chat.Message
  alias App.Presence
  alias App.PubSub
  alias AppWeb.Components.Chat, as: Components

  @presence "online:presence"

  def render(assigns) do
    ~H"""
    <div class="flex flex-row flex-1 h-full w-full">
      <aside class="flex flex-col w-48 h-full flex-0 border-r border-slate-50 bg-slate-600 text-white">
        <div class="px-4 py-2 border-b border-slate-50 flex flex-row items-center">
          <h3 class="text-lg font-bold">Channels</h3>
          <.button
            phx-click={show_modal("add_channel_modal")}
            class="bg-transparent hover:bg-transparent p-0"
          >
            <Heroicons.plus_circle solid class="h-5 w-5" />
          </.button>
        </div>
        <Components.channel_list channels={@channels} channel={@channel} />
      </aside>

      <div class="flex flex-col h-full flex-1 bg-slate-800 text-white">
        <%= if @channel do %>
          <div class="flex flex-row items-center justify-between py-3 px-3 border-b border-white">
            <div class="flex flex-row gap-2 items-center">
              <Components.channel_icon channel={@channel} />
              <h3 class="text-lg font-bold">
                <%= @channel.name %>
              </h3>
            </div>

            <.button
              phx-click={show_modal("add_member_modal")}
              class="bg-transparent hover:bg-slate-900"
            >
              <div class="flex flex-row gap-3">
                <%= if @channel && @channel.members do %>
                  <div class="flex flex-row items-center gap-1">
                    <%= for member <- Enum.sort_by(@channel.members, fn m -> m.user.display_name end, :desc) do %>
                      <Components.profile_photo user={member.user} size={:xs} />
                    <% end %>
                  </div>
                <% end %>
                <span class="font-bold">
                  <%= Enum.count(@channel.members) %>
                </span>
              </div>
            </.button>
          </div>
          <Components.message_list
            messages={@streams.messages}
            current_user={@current_user}
            editing_message_id={@editing_message_id}
            form={@edit_message_form}
          />
          <%= if @channel.current_member do %>
            <Components.typing_status names={
              @users
              |> Enum.map(fn {key, value} -> {key, value} end)
              |> Enum.filter(fn {key, value} ->
                value.typing_in_channel == @channel.id && key !== @current_user.id
              end)
              |> Enum.map(fn {_key, value} -> value.name end)
            } />
            <Components.message_form form={@message_form} channel={@channel} />
          <% else %>
            <.button phx-click="join_channel">Join</.button>
          <% end %>
        <% end %>
      </div>

      <Components.add_channel_modal form={@add_channel_form} />
      <Components.add_member_modal
        search_user_text={@search_user_text}
        user_search_results={@user_search_results}
      />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      user = current_user(socket)

      {:ok, _} =
        Presence.track(self(), @presence, user.id, %{
          name: user.display_name,
          typing_in_channel: nil,
          joined_at: :os.system_time(:seconds)
        })

      Phoenix.PubSub.subscribe(PubSub, @presence)
    end

    AppWeb.Endpoint.subscribe("message:created")
    AppWeb.Endpoint.subscribe("message:updated")
    AppWeb.Endpoint.subscribe("message:deleted")
    AppWeb.Endpoint.subscribe("channel:created")
    AppWeb.Endpoint.subscribe("channel_member:joined")

    channels = Channel.read_all!(actor: current_user(socket))

    socket =
      socket
      |> assign(
        page: 0,
        channel: nil,
        channels: channels,
        message_form:
          AshPhoenix.Form.for_create(Message, :send,
            api: App.Chat,
            actor: socket.assigns.current_user
          )
          |> to_form(),
        edit_message_form: nil,
        add_channel_form:
          AshPhoenix.Form.for_create(Channel, :create,
            api: App.Chat,
            actor: socket.assigns.current_user
          )
          |> to_form(),
        editing_message_id: nil,
        users: %{},
        search_user_text: "",
        user_search_results: []
      )
      |> handle_joins(Presence.list(@presence))

    {:ok, socket}
  end

  def handle_params(%{"id" => channel_id}, _uri, socket) do
    socket =
      assign(socket,
        channel: socket.assigns.channels |> Enum.find(fn c -> c.id == channel_id end)
      )

    if current_channel(socket).current_member do
      ChannelMember.read_channel!(current_channel(socket).current_member,
        actor: current_user(socket)
      )
    end

    socket =
      socket
      |> refresh_channel(channel_id)
      |> stream(
        :messages,
        if(current_channel(socket),
          do: Message.list!(channel_id, page: [offset: 0], actor: current_user(socket)).results,
          else: []
        )
      )

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> stream(:messages, [])}
  end

  def handle_event("send_message", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.message_form, params: params) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(
           message_form:
             AshPhoenix.Form.for_create(Message, :send,
               api: App.Chat,
               actor: socket.assigns.current_user
             )
             |> to_form()
         )}

      {:error, form} ->
        {:noreply, socket |> assign(message_form: form)}
    end
  end

  def handle_event("edit_message", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.edit_message_form, params: params) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(
           editing_message_id: nil,
           edit_message_form: nil
         )}

      {:error, form} ->
        {:noreply, socket |> assign(edit_message_form: form)}
    end
  end

  def handle_event("create_channel", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.add_channel_form, params: params) do
      {:ok, channel} ->
        {:noreply, socket |> push_navigate(to: ~p"/channel/#{channel.id}")}

      {:error, form} ->
        {:noreply, socket |> assign(add_chanel_form: form)}
    end
  end

  def handle_event("join_channel", _, socket) do
    channel = current_channel(socket)

    ChannelMember.join_channel(
      %{
        channel_id: channel.id
      },
      actor: current_user(socket)
    )

    {:noreply, socket |> push_navigate(to: ~p"/channel/#{channel.id}", replace: true)}
  end

  def handle_event("validate_channel", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.add_channel_form, params)
    {:noreply, assign(socket, add_channel_form: form)}
  end

  def handle_event("load_more_messages", _params, socket) do
    page = socket.assigns.page + 1

    messages =
      Message.list!(socket.assigns.channel.id,
        page: [offset: page * 50, limit: 50],
        actor: current_user(socket)
      ).results

    socket =
      Enum.reduce(messages, socket, fn m, acc -> acc |> stream_insert(:messages, m) end)
      |> assign(page: page)

    {:noreply, socket}
  end

  def handle_event("delete_message", %{"message-id" => message_id}, socket) do
    message = Message.get_by_id!(message_id, actor: current_user(socket))
    Message.delete!(message, actor: current_user(socket))

    {:noreply, socket}
  end

  def handle_event("start_editing_message", %{"message-id" => message_id}, socket) do
    message = Message.get_by_id!(message_id, actor: current_user(socket))

    {:noreply,
     socket
     |> assign(
       editing_message_id: message_id,
       edit_message_form:
         AshPhoenix.Form.for_action(message, :edit, actor: current_user(socket), api: App.Chat)
     )
     |> stream_insert(:messages, message, at: -1)}
  end

  def handle_event("start_typing", _params, socket) do
    user = current_user(socket)

    metas =
      Presence.get_by_key(@presence, user.id)[:metas]
      |> List.first()
      |> Map.merge(%{
        typing_in_channel: current_channel(socket).id
      })

    Presence.update(self(), @presence, user.id, metas)
    {:noreply, socket}
  end

  def handle_event("stop_typing", _params, socket) do
    user = current_user(socket)

    metas =
      Presence.get_by_key(@presence, user.id)[:metas]
      |> List.first()
      |> Map.merge(%{
        typing_in_channel: nil
      })

    Presence.update(self(), @presence, user.id, metas)
    {:noreply, socket}
  end

  def handle_event("search_users", %{"user-search" => username}, socket) do
    users =
      App.Account.User
      |> Ash.Query.sort([:display_name])
      |> App.Account.read!()

    socket = socket |> assign(:user_search_results, users)

    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "message:created",
          payload: %Ash.Notifier.Notification{data: message}
        },
        socket
      ) do
    if message.channel_id == socket.assigns.channel.id do
      ChannelMember.read_channel!(socket.assigns.channel.current_member,
        actor: current_user(socket)
      )
    end

    socket =
      if message.channel_id == socket.assigns.channel.id do
        socket |> stream_insert(:messages, message, at: 0)
      else
        socket
      end

    socket =
      refresh_channel(socket, message.channel_id)

    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "message:updated",
          payload: %Ash.Notifier.Notification{data: message}
        },
        socket
      ) do
    socket =
      if message.channel_id == socket.assigns.channel.id do
        socket |> stream_insert(:messages, message, at: -1)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "message:deleted",
          payload: %Ash.Notifier.Notification{data: message}
        },
        socket
      ) do
    socket =
      if message.channel_id == socket.assigns.channel.id do
        socket |> stream_delete(:messages, message)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "channel:created",
          payload: %Ash.Notifier.Notification{data: _channel}
        },
        socket
      ) do
    socket =
      socket |> assign(:channels, Channel.read_all!(actor: current_user(socket)))

    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "channel_member:joined",
          payload: %Ash.Notifier.Notification{data: channel_member}
        },
        socket
      ) do
    socket =
      socket |> refresh_channel(channel_member.channel_id)

    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      assign(socket, :users, Map.put(socket.assigns.users, user, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users, Map.delete(socket.assigns.users, user))
    end)
  end

  defp refresh_channel(socket, id) do
    updated_channel = Channel.get_by_id!(id, actor: current_user(socket))

    updated_channels =
      socket.assigns.channels
      |> Enum.map(fn c -> if c.id == id, do: updated_channel, else: c end)

    socket =
      assign(socket,
        channels: updated_channels,
        channel:
          if(updated_channel.id == current_channel(socket).id,
            do: updated_channel,
            else: current_channel(socket)
          )
      )

    socket
  end

  defp current_channel(socket), do: socket.assigns.channel

  defp current_user(socket), do: socket.assigns.current_user
end
