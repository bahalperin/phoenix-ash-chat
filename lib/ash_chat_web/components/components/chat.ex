defmodule AppWeb.Components.Chat do
  use Phoenix.Component

  import AppWeb.CoreComponents

  attr :channels, :list
  attr :channel, :map

  def channel_list(assigns) do
    ~H"""
    <div class="flex flex-col flex-1 py-2 gap-0.5 overflow-y-auto w-full items-stretch">
      <%= for channel <- @channels do %>
        <div
          class="px-2"
          phx-hook={if(@channel && channel.id == @channel.id, do: "ScrollIntoView", else: nil)}
          id={"channel-item-#{channel.id}"}
        >
          <.link
            navigate={"/channel/#{channel.id}"}
            class={[
              @channel && channel.id === @channel.id && "font-bold",
              "hover:bg-slate-800 p-2 w-full inline-block rounded-md flex flex-row gap-2 items-center"
            ]}
          >
            <%= if channel.private do %>
              <Heroicons.lock_closed class="h-5 w-5" />
            <% else %>
              <Heroicons.hashtag class="h-5 w-5" />
            <% end %>
            <%= channel.name %>
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
        class="px-4 py-1 group hover:bg-slate-900 flex flex-row justify-between"
        phx-hook="Message"
        data-user-id={@current_user.id}
        data-sender-id={message.sender_id}
        data-created-at={message.created_at}
      >
        <div class="flex flex-row items-center gap-3">
          <.profile_photo user={message.sender} size={:sm} />
          <div class="flex flex-col">
            <div class="flex flex-row items-end gap-2">
              <.user_name user={message.sender} %></.user_name>
              <.local_datetime
                id={"#{message.id}-sent-at"}
                datetime={message.created_at}
                class="text-sm text-gray-300 hidden group-hover:block"
              />
            </div>

            <%= if @editing_message_id == message.id do %>
              <.simple_form
                :let={f}
                for={@form}
                id="edit-message-form"
                phx-submit="edit_message"
                container_class="pb-4 bg-transparent"
              >
                <.input id="edit-message-input" field={f[:text]} class="bg-slate-800 text-white" />
              </.simple_form>
            <% else %>
              <div class="flex flex-row items-end gap-2">
                <span><%= message.text %></span>
                <%= if message.edited do %>
                  <span class="text-sm text-gray-300">(edited)</span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <div class="hidden group-hover:block">
          <%= if @current_user.id == message.sender.id && message.id != @editing_message_id do %>
            <.button phx-click="start_editing_message" phx-value-message-id={message.id}>
              Edit
            </.button>
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
      container_class="px-4 pb-4 bg-slate-800"
    >
      <.input
        id="message-input"
        phx-hook="MessageInput"
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
        container_class="bg-slate-800 text-white flex flex-col gap-2"
      >
        <.input
          field={@form[:name]}
          label="Channel Name"
          label_class="text-white"
          class="bg-slate-800 text-white"
        />
        <.input
          id="channel-privacy"
          type="checkbox"
          field={@form[:private]}
          class="bg-slate-800 text-white"
          label="Private?"
          label_class="text-white"
        />
        <:actions>
          <.button>Submit</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  def user_name(assigns) do
    ~H"""
    <.link navigate={"/profile/#{@user.id}"} class="font-bold hover:underline">
      <%= if @user.display_name != "" do %>
        <%= @user.display_name %>
      <% else %>
        Unknown
      <% end %>
    </.link>
    """
  end

  def online_status(assigns) do
    ~H"""
    <div class={[
      "rounded-full h-2 w-2",
      if(@online, do: "bg-green-500", else: "bg-gray-100 border-gray-700")
    ]} />
    """
  end

  def typing_status(assigns) do
    ~H"""
    <div class="px-4 pt-2 text-sm text-gray-300">
      <.typing_status_line names={@names} />
    </div>
    """
  end

  def typing_status_line(%{names: []} = assigns) do
    ~H"""

    """
  end

  def typing_status_line(%{names: [_name]} = assigns) do
    ~H"""
    <%= Enum.at(@names, 0) %> is typing...
    """
  end

  def typing_status_line(%{names: [_, _]} = assigns) do
    ~H"""
    <%= Enum.at(@names, 0) %> and <%= Enum.at(@names, 1) %> are typing...
    """
  end

  def typing_status_line(%{names: [_, _, _]} = assigns) do
    ~H"""
    <%= Enum.at(@names, 0) %>, <%= Enum.at(@names, 1) %>, and <%= Enum.at(@names, 2) %> are typing...
    """
  end

  def typing_status_line(assigns) do
    ~H"""
    Several people are typing...
    """
  end

  def profile_photo(assigns) do
    ~H"""
    <img
      src={profile_photo_url(@user)}
      class={[
        "rounded-md",
        case @size do
          :xs -> "h-6 w-6"
          :sm -> "h-10 w-10"
        end
      ]}
    />
    """
  end

  defp profile_photo_url(%{photo_url: nil} = user) do
    "https://picsum.photos/seed/#{user.id}/200/200"
  end

  defp profile_photo_url(user) do
    user.photo_url
  end
end
