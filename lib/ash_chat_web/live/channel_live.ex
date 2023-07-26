defmodule AppWeb.ChannelLive do
  use AppWeb, :live_view

  alias App.Chat.Channel
  alias App.Chat.ChannelMember
  alias App.Chat.Message
  alias AppWeb.Components.Chat, as: Components

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
          <%= if @channel.current_member do %>
            <Components.message_list messages={@streams.messages} current_user={@current_user} />
            <Components.message_form form={@message_form} channel={@channel} />
          <% else %>
            <.button phx-click="join_channel">Join</.button>
          <% end %>
        <% end %>
      </div>

      <Components.add_channel_modal form={@add_channel_form} />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    AppWeb.Endpoint.subscribe("message:created")
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
        add_channel_form:
          AshPhoenix.Form.for_create(Channel, :create,
            api: App.Chat,
            actor: socket.assigns.current_user
          )
          |> to_form()
      )

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

  def handle_event("create_channel", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.add_channel_form, params: params) do
      {:ok, channel} ->
        ChannelMember.join_channel(%{channel_id: channel.id}, actor: current_user(socket))
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
