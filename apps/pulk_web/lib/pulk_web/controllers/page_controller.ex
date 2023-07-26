defmodule PulkWeb.PageController do
  use PulkWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, get_frontend_path())
  end

  defp get_frontend_path() do
    Application.app_dir(:pulk_web, "priv/static/frontend/index.html")
  end
end
