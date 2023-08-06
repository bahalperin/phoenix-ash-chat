defmodule AppWeb.ProfileLive do
  use AppWeb, :live_view

  alias App.Account.User
  alias AshPhoenix.Form

  def render(assigns) do
    ~H"""
    <div>
      <div class="container page">
        <div class="row">
          <div class="col-md-6 offset-md-3 col-xs-12">
            <%= if @current_user.id == @user.id do %>
              <.simple_form
                :let={f}
                for={@form}
                id="user-form"
                phx-submit="save_user"
                container_class="p-4 bg-slate-800"
              >
                <.input
                  field={f[:display_name]}
                  placeholder="Display Name"
                  class="bg-slate-800 text-white"
                />
              </.simple_form>
            <% else %>
              <span>
                <%= @user.display_name %>
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_, _, socket) do
    {:ok,
     socket
     |> assign(user: nil)
     |> assign(form: nil)}
  end

  def handle_params(%{"id" => user_id}, _uri, socket) do
    user = User.get_by_id!(user_id, actor: socket.assigns.current_user)

    {
      :noreply,
      socket |> assign(user: user) |> assign_form(user)
    }
  end

  def handle_event("save_user", %{"form" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign_form(user)}

      {:error, form} ->
        {:noreply, socket |> assign(form: form)}
    end
  end

  defp assign_form(socket, user) do
    socket
    |> assign(
      form: Form.for_update(user, :update, api: App.Account, actor: socket.assigns.current_user)
    )
  end
end
