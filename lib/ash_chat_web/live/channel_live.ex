defmodule AppWeb.ChannelLive do
  use AppWeb, :live_view

  alias App.Chat.Channel
  alias App.Chat.Message

  def render(assigns) do
    ~H"""
    <div class="h-full w-100 flex flex-col items-stretch">
      <%= @channel_id %>

      <div class="flex flex-col">
        <%= for channel <- @channels do %>
          <%= channel.name %>
        <% end %>
      </div>

      <div class="flex flex-col">
        <%= for message <- @messages do %>
          <%= message.text %>
        <% end %>
      </div>

      <.simple_form for={@message_form} phx-submit="send_message">
        <.input field={@message_form[:text]} label="Message" />
        <:actions>
          <.button>Send</.button>
        </:actions>
      </.simple_form>
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
