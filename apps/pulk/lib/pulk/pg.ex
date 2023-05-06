defmodule Pulk.Pg do
  def child_spec(_arg) do
    %{
      id: :pg,
      start: {:pg, :start_link, []}
    }
  end
end
