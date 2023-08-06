defmodule App.Presence do
  use Phoenix.Presence, otp_app: :ash_chat, pubsub_server: App.PubSub
end
