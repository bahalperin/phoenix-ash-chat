defmodule AppWeb.Components.Chat do
  use Phoenix.Component

  import AppWeb.CoreComponents

  attr :channels, :list
  attr :channel, :map

  def channel_list(assigns) do
    ~H"""
    <div class="flex flex-col flex-1 py-2 gap-0.5 overflow-y-auto w-full items-stretch">
      <%= for channel <- @channels do %>
        <div class="px-2">
          <.link
            navigate={"/channel/#{channel.id}"}
            class={[
              @channel && channel.id === @channel.id && "font-bold",
              "hover:bg-slate-800 p-2 w-full inline-block rounded-md"
            ]}
          >
            # <%= channel.name %>
          </.link>
        </div>
      <% end %>
    </div>
    """
  end

  def message_list(assigns) do
    ~H"""
    <div class="flex flex-col-reverse flex-1 overflow-y-auto" id="chat-messages" phx-update="stream">
      <div
        id="infinite_scroll_marker"
        phx-hook="InfiniteScroll"
        data-event-name="load_more_messages"
        class="order-1"
      />
      <div
        :for={{dom_id, message} <- @messages}
        id={dom_id}
        class="px-4"
        phx-hook="Message"
        data-user-id={@current_user.id}
        data-sender-id={message.sender_id}
        data-created-at={message.created_at}
      >
        <%= message.text %>
      </div>
    </div>
    """
  end

  def message_form(assigns) do
    ~H"""
    <.simple_form
      for={@form}
      id="message-form"
      phx-submit="send_message"
      phx-hook="MessageForm"
      container_class="p-4 bg-slate-800"
    >
      <.input
        id="message-input"
        field={@form[:text]}
        placeholder={"Message ##{@channel.name}"}
        class="bg-slate-800 text-white"
      />

      <.input id="channel_input" field={@form[:channel_id]} value={@channel.id} type="hidden" />
    </.simple_form>
    """
  end

  def add_channel_modal(assigns) do
    ~H"""
    <.modal
      id="add_channel_modal"
      container_class="bg-slate-800 text-white"
      background_class="bg-black opacity-80"
    >
      <.simple_form
        for={@form}
        phx-submit="create_channel"
        phx-change="validate_channel"
        container_class="bg-slate-800 text-white"
      >
        <.input
          field={@form[:name]}
          label="Channel Name"
          label_class="text-white"
          class="bg-slate-800 text-white"
        />
        <:actions>
          <.button>Submit</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end
end