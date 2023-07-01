defmodule App.Account.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """
  use AshAuthentication.Sender
  use AppWeb, :verified_routes

  @impl AshAuthentication.Sender
  def send(user, token, _) do
    App.Account.Email.deliver_reset_password_instructions(
      user,
      url(~p"/password-reset/#{token}")
    )
  end
end
