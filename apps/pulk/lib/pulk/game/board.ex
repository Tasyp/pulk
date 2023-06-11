defmodule Pulk.Game.Board do
  @moduledoc """
  Entity that is used to represent all metadata about the game field required to display it
  """

  require Logger

  use TypedStruct
  use Domo, gen_constructor_name: :_new

  alias Pulk.Game.PiecePositionUpdate
  alias Pulk.Game.PieceBag
  alias Pulk.Game.Piece
  alias Pulk.Game.Matrix
  alias Pulk.Game.BoardUpdate
  alias Pulk.Game.BoardSnapshot
  alias Pulk.Game.PositionedPiece

  @points_per_line 100

  @type status() :: :initial | :ongoing | :complete

  typedstruct enforce: true do
    field(:size_x, pos_integer())
    field(:size_y, pos_integer())
    field(:score, non_neg_integer(), default: 0)
    field(:cleared_lines_count, non_neg_integer(), default: 0)
    field(:piece_in_hold, Piece.t(), enforce: false)
    # TODO: Replace with :initial when start logic is implemented
    field(:status, status(), default: :ongoing)
    field(:placement, pos_integer(), enforce: false)
    field(:piece_bag, PieceBag.t(), enforce: true)

    field(:active_piece, PositionedPiece.t(), enforce: false)

    field(:matrix, Matrix.t())
  end

  @spec new(pos_integer(), pos_integer()) :: {:ok, t()} | {:error, term()}
  def new(size_x, size_y, attrs \\ %{}) do
    {piece_bag, active_piece} =
      PieceBag.new!()
      |> PieceBag.get_piece({size_x, size_y})

    _new(
      %{
        size_x: size_x,
        size_y: size_y,
        matrix: Matrix.new!(size_x, size_y),
        active_piece: active_piece,
        piece_bag: piece_bag
      }
      |> Map.merge(attrs)
    )
  end

  @spec level(t()) :: pos_integer()
  def level(%__MODULE__{cleared_lines_count: cleared_lines_count}) do
    trunc(cleared_lines_count / 10) + 1
  end

  @spec piece_queue(t()) :: list(Piece.t())
  def piece_queue(%__MODULE__{piece_bag: piece_bag}) do
    PieceBag.get_queue_preview(piece_bag)
  end

  @spec to_snapshot(t()) :: BoardSnapshot.t()
  def to_snapshot(%__MODULE__{active_piece: active_piece, matrix: matrix, status: status}) do
    BoardSnapshot.new!(active_piece: active_piece, matrix: matrix, status: status)
  end

  @spec update_status(t(), state :: status()) :: {:ok, t()}
  def update_status(%__MODULE__{} = board, status) do
    {:ok, ensure_type!(%{board | status: status})}
  end

  @spec update_matrix(t(), Matrix.t()) ::
          {:ok, t()} | {:error, :invalid_size} | {:error, :invalid_matrix}
  def update_matrix(%__MODULE__{} = board, matrix) do
    with :ok <- Matrix.has_matching_size?(matrix, {board.size_x, board.size_y}),
         {:ok, next_board} <- ensure_type(%{board | matrix: matrix}) do
      {:ok, next_board}
    else
      {:error, list_reason} when is_list(list_reason) ->
        {:error, :invalid_matrix}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec update(t(), BoardUpdate.t()) ::
          {:ok, t()}
          | {:error, :invalid_update}
          | {:error, :board_complete}
          | {:error, :invalid_move}

  def update(%__MODULE__{status: :complete}, %BoardUpdate{}) do
    {:error, :board_complete}
  end

  def update(%__MODULE__{} = board, %BoardUpdate{} = board_update) do
    with {:ok, board} <- set_piece_in_hold(board, board_update),
         {:ok, board} <- move_active_piece(board, board_update.active_piece_update),
         {:ok, board} <- recalculate(board),
         {:ok, board} <-
           ensure_type(board) do
      {:ok, board}
    else
      {:error, list_reason} when is_list(list_reason) ->
        {:error, :invalid_update}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec move_active_piece(t(), PiecePositionUpdate.t() | nil) ::
          {:ok, t()} | {:error, :invalid_move}
  def move_active_piece(%__MODULE__{} = board, nil) do
    board
  end

  def move_active_piece(%__MODULE__{} = board, %PiecePositionUpdate{} = piece_position_update) do
    active_piece =
      case piece_position_update.update_type do
        :simple ->
          {:ok, positioned_piece} =
            cond do
              piece_position_update.direction != nil ->
                PositionedPiece.move(board.active_piece, piece_position_update.direction)

              piece_position_update.rotation != nil ->
                PositionedPiece.rotate(board.active_piece, piece_position_update.rotation)
            end

          positioned_piece

        :soft_drop_start ->
          PositionedPiece.move(board.active_piece, :down)

        :hard_drop ->
          do_hard_drop(board)

        :soft_drop_stop ->
          board.active_piece
      end

    if can_insert_peace?(board, active_piece) do
      case ensure_type(%{board | active_piece: active_piece}) do
        {:ok, board} -> {:ok, board}
        {:error, _} -> {:error, :invalid_move}
      end
    else
      {:error, :invalid_move}
    end
  end

  @spec recalculate(t()) :: t()
  def recalculate(%__MODULE__{} = board) do
    next_board =
      board
      |> remove_filled_lines()
      |> detect_end_state()
      |> maybe_rotate_active_piece()

    {:ok, next_board}
  end

  @spec remove_filled_lines(t()) :: t()
  def remove_filled_lines(%__MODULE__{} = board) do
    {matrix, filled_lines_count} = Matrix.remove_filled_lines(board.matrix)

    next_board =
      board
      |> Map.put(:matrix, matrix)
      |> recalculate_score(filled_lines_count)

    next_board
  end

  @spec recalculate_score(t(), non_neg_integer()) :: t()
  def recalculate_score(%__MODULE__{} = board, cleared_lines_count_increase) do
    score_increase =
      if cleared_lines_count_increase == 4 do
        @points_per_line * 10
      else
        cleared_lines_count_increase * @points_per_line
      end

    %{
      board
      | cleared_lines_count: board.cleared_lines_count + cleared_lines_count_increase,
        score: board.score + score_increase
    }
  end

  @spec detect_end_state(t()) :: t()
  def detect_end_state(%__MODULE__{} = board) do
    if Matrix.is_complete?(board.matrix) do
      %{board | status: :complete}
    else
      board
    end
  end

  @spec maybe_rotate_active_piece(t()) :: t()
  def maybe_rotate_active_piece(%__MODULE__{} = board) do
    if can_move_active_piece?(board) do
      board
    else
      rotate_active_piece(board)
    end
  end

  def rotate_active_piece(
        %__MODULE__{piece_bag: piece_bag, size_x: size_x, size_y: size_y} = board
      ) do
    {piece_bag, active_piece} = PieceBag.get_piece(piece_bag, {size_x, size_y})

    %{
      board
      | active_piece: active_piece,
        piece_bag: piece_bag,
        matrix: Matrix.add_piece(board.matrix, board.active_piece)
    }
  end

  @spec has_lines_cleared(t(), count :: non_neg_integer()) :: boolean()
  def has_lines_cleared(%__MODULE__{} = board, count) do
    board.cleared_lines_count >= count
  end

  @spec set_placement(t(), placement :: pos_integer()) :: {:ok, t()} | {:error, term()}
  def set_placement(%__MODULE__{} = board, placement) do
    ensure_type(%{board | status: :complete, placement: placement})
  end

  @spec set_piece_in_hold(t(), BoardUpdate.t()) :: {:ok, t()}
  defp set_piece_in_hold(%__MODULE__{} = board, %BoardUpdate{} = board_update) do
    {:ok,
     %{
       board
       | piece_in_hold: board_update.piece_in_hold || board.piece_in_hold
     }}
  end

  defp can_move_active_piece?(%__MODULE__{} = board) do
    case move_active_piece(
           board,
           PiecePositionUpdate.update_active_piece(board, :simple, %{direction: :down})
         ) do
      {:ok, _board} -> true
      {:error, _reason} -> false
    end
  end

  defp can_insert_peace?(%__MODULE__{} = board, %PositionedPiece{coordinates: coordinates}) do
    matrix_map = Matrix.to_map(board.matrix)

    coordinates
    |> Enum.all?(fn coordinates ->
      current_value =
        matrix_map
        |> Map.get(coordinates)

      current_value !== nil && Piece.is_empty?(current_value)
    end)
  end

  defp do_hard_drop(%__MODULE__{} = board, positioned_piece \\ nil) do
    current_piece = positioned_piece || board.active_piece

    case PositionedPiece.move(current_piece, :down) do
      {:ok, positioned_piece} ->
        if can_insert_peace?(board, positioned_piece) do
          do_hard_drop(board, positioned_piece)
        else
          current_piece
        end

      {:error, :invalid_move} ->
        current_piece
    end
  end
end
