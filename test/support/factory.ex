defmodule App.Factory do
  def user do
    changeset =
      App.Account.User
      |> Ash.Changeset.for_create(:create, %{
        display_name: "Name",
        email: "test-#{Ash.UUID.generate()}@example.com",
        hashed_password: "hashed_password"
      })

    Ash.Api.create!(
      App.Account,
      changeset,
      []
    )
  end
end
