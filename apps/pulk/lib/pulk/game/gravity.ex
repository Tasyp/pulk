defmodule Pulk.Game.Gravity do
  @spec calculate(pos_integer()) :: float()
  def calculate(level) do
    # https://harddrop.com/wiki/Tetris_Worlds#Gravity
    (0.8 - (level - 1) * 0.007) ** (level - 1);
  end
end
