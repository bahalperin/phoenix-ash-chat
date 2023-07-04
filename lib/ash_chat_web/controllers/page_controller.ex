defmodule AppWeb.PageController do
  use AppWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/channel")
  end
end
