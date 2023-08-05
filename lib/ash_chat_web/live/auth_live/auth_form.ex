defmodule AppWeb.AuthLive.AuthForm do
  use AppWeb, :live_component
  use Phoenix.HTML
  alias AshPhoenix.Form

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(trigger_action: false)

    {:ok, socket}
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    form = socket.assigns.form |> Form.validate(params)

    socket =
      socket
      |> assign(:form, form)
      |> assign(:errors, Form.errors(form))
      |> assign(:trigger_action, form.valid?)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <ul class="error-messages">
        <%= if @form.errors do %>
          <%= for {k, v} <- @errors do %>
            <li>
              <%= humanize("#{k} #{v}") %>
            </li>
          <% end %>
        <% end %>
      </ul>
      <.simple_form
        :let={f}
        for={@form}
        id="auth-form"
        phx-submit="submit"
        phx-trigger-action={@trigger_action}
        phx-target={@myself}
        action={@action}
        method="POST"
        container_class="bg-slate-800"
      >
        <%= if @is_register? do %>
          <.input field={f[:display_name]} placeholder="Display Name" class="bg-slate-800 text-white" />
        <% end %>
        <.input field={f[:email]} placeholder="Email" class="bg-slate-800 text-white" />
        <.input
          field={f[:password]}
          type="password"
          placeholder="Password"
          class="bg-slate-800 text-white"
        />
        <%= if @is_register? do %>
          <.input
            field={f[:password_confirmation]}
            type="password"
            placeholder="Confirm Password"
            class="bg-slate-800 text-white"
          />
        <% end %>
        <:actions>
          <.button>
            <%= @cta %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
