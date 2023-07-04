defmodule AppWeb.PageController do
  use AppWeb, :controller

  def home(conn, _params) do
    first_channel =
      App.Chat.Channel.read_all!()
      |> Enum.at(0)

    redirect(conn, to: ~p"/channel/#{first_channel.id}")
  end
end
