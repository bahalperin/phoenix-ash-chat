defmodule AppWeb.ChannelLive do
  use AppWeb, :live_view

  alias App.Chat.Channel
  alias App.Chat.Message

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
        <div class="flex flex-col flex-1 py-2 gap-2 overflow-y-scroll">
          <%= for channel <- @channels do %>
            <div class="px-4">
              <.link
                navigate={~p"/channel/#{channel.id}"}
                class={[channel.id === @channel.id && "font-bold"]}
              >
                <%= channel.name %>
              </.link>
            </div>
          <% end %>
        </div>
      </aside>

      <div class="flex flex-col h-full flex-1 bg-slate-800 text-white">
        <div
          class="flex flex-col-reverse flex-1 overflow-y-scroll"
          id="chat-messages"
          phx-update="prepend"
        >
          <%= for message <- @messages do %>
            <div id={"message-#{message.id}"} class="px-4 font-sans">
              <%= message.text %>
            </div>
          <% end %>
        </div>
        <.simple_form for={@message_form} phx-submit="send_message" container_class="p-4 bg-slate-800">
          <.input
            field={@message_form[:text]}
            placeholder={"Message ##{@channel.name}"}
            class="bg-slate-800 text-white"
          />
        </.simple_form>
      </div>

      <.modal
        id="add_channel_modal"
        show={@adding_new_channel}
        container_class="bg-slate-800 text-white"
        background_class="bg-black opacity-80"
      >
        <.simple_form
          for={@add_channel_form}
          phx-submit="create_channel"
          phx-change="validate_channel"
          container_class="bg-slate-800 text-white"
        >
          <.input
            field={@add_channel_form[:name]}
            label="Channel Name"
            label_class="text-white"
            class="bg-slate-800 text-white"
          />
          <:actions>
            <.button>Submit</.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  def mount(%{"id" => channel_id}, _session, socket) do
    AppWeb.Endpoint.subscribe("message:created")
    AppWeb.Endpoint.subscribe("channel:created")

    channels = Channel.read_all!()

    current_channel = channels |> Enum.find(fn channel -> channel.id == channel_id end)

    current_channel =
      Ash.Api.load!(Channel, current_channel, :messages)

    socket =
      socket
      |> assign(
        channel: current_channel,
        channels: channels,
        messages: current_channel.messages,
        message_form: AshPhoenix.Form.for_create(Message, :send) |> to_form(),
        add_channel_form:
          AshPhoenix.Form.for_create(Channel, :create,
            api: App.Chat,
            actor: socket.assigns.current_user
          )
          |> to_form(),
        adding_new_channel: false
      )

    {:ok, socket, temporary_assigns: [messages: []]}
  end

  def handle_params(%{"id" => channel_id}, _uri, socket) do
    current_channel =
      socket.assigns.channels |> Enum.find(fn channel -> channel.id == channel_id end)

    current_channel =
      Ash.Api.load!(Channel, current_channel, :messages)

    socket =
      socket
      |> assign(
        channel: current_channel,
        messages: current_channel.messages
      )

    {:noreply, socket}
  end

  def handle_event("send_message", %{"form" => params}, socket) do
    Message.send(%{text: params["text"], channel_id: socket.assigns.channel.id},
      actor: socket.assigns.current_user
    )

    {:noreply,
     socket |> assign(message_form: AshPhoenix.Form.for_create(Message, :send) |> to_form())}
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

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "message:created",
          payload: %Ash.Notifier.Notification{data: message}
        },
        socket
      ) do
    socket =
      if message.channel_id == socket.assigns.channel.id do
        socket |> assign(:messages, [message])
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
