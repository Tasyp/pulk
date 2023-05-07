defmodule PulkWeb.PageController do
  use PulkWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
