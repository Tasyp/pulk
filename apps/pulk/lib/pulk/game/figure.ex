defmodule Pulk.Game.Figure do
  @type t :: %__MODULE__{
          figure_type: String.t()
        }

  @supported_figures MapSet.new(["", "I", "O", "T", "S", "Z", "J", "L"])

  @enforce_keys [:figure_type]
  defstruct [:figure_type]

  @spec create!() :: t()
  @spec create!(String.t()) :: t()
  def create!(figure_type \\ "") do
    if is_supported_figure?(figure_type) do
      %__MODULE__{figure_type: figure_type}
    else
      raise ArgumentError, message: "#{figure_type} is not a valid figure type"
    end
  end

  @spec is_supported_figure?(String.t()) :: boolean()
  def is_supported_figure?(raw_figure) do
    MapSet.member?(@supported_figures, raw_figure)
  end

  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{figure_type: figure_type}) do
    figure_type
  end
end

defimpl Inspect, for: Pulk.Game.Figure do
  def inspect(figure, _opts) do
    figure.figure_type
  end
end
