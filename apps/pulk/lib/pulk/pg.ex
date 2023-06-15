defmodule Pulk.Pg do
  @moduledoc """
  Utility module to start :pg
  """

  def child_spec(_arg) do
    %{
      id: :pg,
      start: {:pg, :start_link, []}
    }
  end
end
