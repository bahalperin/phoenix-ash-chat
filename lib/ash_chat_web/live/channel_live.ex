defmodule AppWeb.ChannelLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="h-full w-100 flex items-stretch">
      <%= @channel_id %>
    </div>
    """
  end

  def mount(%{"id" => channel_id}, _session, socket) do
    socket =
      socket
      |> assign(
        :channel_id,
        channel_id
      )

    {:ok, socket}
  end
end
