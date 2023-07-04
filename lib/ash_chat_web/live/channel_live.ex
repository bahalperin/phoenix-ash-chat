defmodule AppWeb.ChannelLive do
  use AppWeb, :live_view

  alias App.Chat.Channel
  alias App.Chat.Message

  def render(assigns) do
    ~H"""
    <div class="flex flex-row flex-1 h-full w-full">
      <aside class="flex flex-col w-48 h-full flex-0 p-4 border-r border-slate-50 bg-slate-600 text-white">
        <%= for channel <- @channels do %>
          <%= channel.name %>
        <% end %>
      </aside>

      <div class="flex flex-col h-full flex-1 bg-slate-800 text-white">
        <div class="flex flex-col-reverse overflow-y-scroll">
          <%= for message <- @messages do %>
            <div class="px-4 font-sans">
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
    </div>
    """
  end

  def mount(%{"id" => channel_id}, _session, socket) do
    AppWeb.Endpoint.subscribe("message:created")

    channels = Channel.read_all!()

    current_channel = channels |> Enum.find(fn channel -> channel.id == channel_id end)

    current_channel =
      Ash.Api.load!(Channel, current_channel, :messages)

    socket =
      socket
      |> assign(
        channel_id: channel_id,
        channel: current_channel,
        channels: channels,
        messages: current_channel.messages,
        message_form: AshPhoenix.Form.for_create(Message, :send) |> to_form()
      )

    {:ok, socket}
  end

  def handle_event("send_message", %{"form" => params}, socket) do
    Message.send(%{text: params["text"], channel_id: socket.assigns.channel_id},
      actor: socket.assigns.current_user
    )

    {:noreply,
     socket |> assign(message_form: AshPhoenix.Form.for_create(Message, :send) |> to_form())}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: "message:created",
          payload: %Ash.Notifier.Notification{data: message}
        },
        socket
      ) do
    socket =
      if message.channel_id == socket.assigns.channel_id do
        socket |> assign(:messages, [message | socket.assigns.messages])
      else
        socket
      end

    {:noreply, socket}
  end
end
