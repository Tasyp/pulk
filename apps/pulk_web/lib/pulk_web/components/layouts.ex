defmodule PulkWeb.Layouts do
  @moduledoc """
  Helper module for layouts
  """

  use PulkWeb, :html

  embed_templates "layouts/*"
end
