defmodule Pulk.Repo do
  use Ecto.Repo,
    otp_app: :pulk,
    adapter: Ecto.Adapters.Postgres
end
