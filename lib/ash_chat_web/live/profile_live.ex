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
              <div>
                <AppWeb.Components.Chat.profile_photo user={@user} size={:sm} />
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
                <form id="photo-form" phx-submit="save_photo" phx-change="validate_photo">
                  <.live_file_input upload={@uploads.photo} />
                  <button type="submit">Upload</button>
                </form>

                <section phx-drop-target={@uploads.photo.ref}>
                  <%= for entry <- @uploads.photo.entries do %>
                    <article>
                      <figure>
                        <.live_img_preview entry={entry} />
                        <figcaption><%= entry.client_name %></figcaption>
                      </figure>

                      <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

                      <%= if entry.progress != 100 do %>
                        <button
                          type="button"
                          phx-click="cancel_upload"
                          phx-value-ref={entry.ref}
                          aria-label="cancel"
                        >
                          &times;
                        </button>
                      <% end %>

                      <%= for err <- upload_errors(@uploads.photo, entry) do %>
                        <p class="alert alert-danger"><%= error_to_string(err) %></p>
                      <% end %>
                    </article>
                  <% end %>
                </section>
              </div>
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
     |> assign(form: nil)
     |> allow_upload(:photo,
       accept: ~w(.jpg .jpeg),
       max_entries: 1,
       external: &presign_upload/2
     )}
  end

  def handle_params(%{"id" => user_id}, _uri, socket) do
    user = User.get_by_id!(user_id, actor: socket.assigns.current_user)

    {
      :noreply,
      socket |> assign(user: user) |> assign_form(user)
    }
  end

  def handle_event("validate_photo", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  def handle_event("save_photo", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :photo, fn %{key: key, url: url}, _entry ->
        {:ok, "#{url}/#{key}"}
      end)

    uploaded_file = uploaded_files |> Enum.at(0)
    path = uploaded_file

    socket.assigns.user
    |> Ash.Changeset.for_update(:update, %{photo_url: path})
    |> User.update!(actor: socket.assigns.current_user)

    {:noreply, socket}
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

  defp presign_upload(entry, socket) do
    uploads = socket.assigns.uploads
    bucket = "phoenix-ash-chat-dev"
    key = "profile_photo/#{socket.assigns.user.id}"

    config = %{
      region: "us-east-2",
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(config, bucket,
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads[entry.upload_config].max_file_size,
        expires_in: :timer.hours(1)
      )

    meta = %{
      uploader: "S3",
      key: key,
      url: "https://#{bucket}.s3-#{config.region}.amazonaws.com",
      fields: fields
    }

    {:ok, meta, socket}
  end

  defp assign_form(socket, user) do
    socket
    |> assign(
      form: Form.for_update(user, :update, api: App.Account, actor: socket.assigns.current_user)
    )
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
