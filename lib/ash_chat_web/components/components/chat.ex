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
            <%= if channel.current_member && channel.current_member.unread_count > 0 do %>
              <span class="bg-red-100 text-red-800 text-sm font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-red-900 dark:text-red-300 ml-1">
                <%= channel.current_member.unread_count %>
              </span>
            <% end %>
          </.link>
        </div>
      <% end %>
    </div>
    """
  end

  def message_list(assigns) do
    ~H"""
    <div
      class="flex flex-col-reverse flex-1 gap-1 overflow-y-auto"
      id="chat-messages"
      phx-update="stream"
    >
      <div
        id="infinite_scroll_marker"
        phx-hook="InfiniteScroll"
        data-event-name="load_more_messages"
        class="order-1"
      />
      <div
        :for={{dom_id, message} <- @messages}
        id={dom_id}
        class="px-4 group hover:bg-slate-900 flex flex-row justify-between"
        phx-hook="Message"
        data-user-id={@current_user.id}
        data-sender-id={message.sender_id}
        data-created-at={message.created_at}
      >
        <div class="flex flex-col">
          <div class="flex flex-row items-end gap-2">
            <span class="font-bold"><%= message.sender.display_name %></span>
            <.local_datetime
              id={"#{message.id}-sent-at"}
              datetime={message.created_at}
              class="text-sm text-gray-300 hidden group-hover:block"
            />
          </div>
          <span><%= message.text %></span>
        </div>

        <div class="hidden group-hover:block">
          <%= if @current_user.id == message.sender.id do %>
            <.button phx-click="delete_message" phx-value-message-id={message.id}>
              X
            </.button>
          <% end %>
        </div>
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
