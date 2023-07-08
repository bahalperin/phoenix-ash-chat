defmodule AppWeb.ChannelLive do
  use AppWeb, :live_view

  alias App.Chat.Channel
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
          <Components.message_list messages={@streams.messages} current_user={@current_user} />
          <Components.message_form form={@message_form} channel={@channel} />
        <% end %>
      </div>

      <Components.add_channel_modal form={@add_channel_form} />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    AppWeb.Endpoint.subscribe("message:created")
    AppWeb.Endpoint.subscribe("channel:created")

    channels = Channel.read_all!()

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
    current_channel =
      socket.assigns.channels |> Enum.find(fn channel -> channel.id == channel_id end)

    socket =
      socket
      |> assign(channel: current_channel)
      |> stream(
        :messages,
        if(current_channel, do: Message.list!(channel_id, page: [offset: 0]).results, else: [])
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
        {:noreply, socket |> push_navigate(to: ~p"/channel/#{channel.id}")}

      {:error, form} ->
        {:noreply, socket |> assign(add_chanel_form: form)}
    end
  end

  def handle_event("validate_channel", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.add_channel_form, params)
    {:noreply, assign(socket, add_channel_form: form)}
  end

  def handle_event("load_more_messages", _params, socket) do
    page = socket.assigns.page + 1

    messages =
      Message.list!(socket.assigns.channel.id, page: [offset: page * 50, limit: 50]).results

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
    socket =
      if message.channel_id == socket.assigns.channel.id do
        socket |> stream_insert(:messages, message, at: 0)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "channel:created",
          payload: %Ash.Notifier.Notification{data: channel}
        },
        socket
      ) do
    socket =
      socket |> assign(:channels, [channel | socket.assigns.channels])

    {:noreply, socket}
  end
end
