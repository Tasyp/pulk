defmodule Pulk.Board do
  @moduledoc """
  Entity that is used to represent all metadata about the game field required to display it
  """

  require Logger

  use TypedStruct
  use Domo, gen_constructor_name: :_new

  alias Pulk.Piece.PieceUpdate
  alias Pulk.Piece.PieceBag
  alias Pulk.Piece
  alias Pulk.Matrix
  alias Pulk.Board.BoardUpdate
  alias Pulk.Board.BoardSnapshot
  alias Pulk.Piece.PositionedPiece

  @points_per_line 100

  @type status() :: :initial | :ongoing | :complete

  typedstruct enforce: true do
    field :size_x, pos_integer()
    field :size_y, pos_integer()
    field :buffer_zone_size, non_neg_integer(), default: 1
    field :lock_delay, pos_integer(), default: 500
    field :score, non_neg_integer(), default: 0
    field :cleared_lines_count, non_neg_integer(), default: 0
    field :piece_in_hold, Piece.t(), enforce: false
    # TODO: Replace with :initial when start logic is implemented
    field :status, status(), default: :ongoing
    field :placement, pos_integer(), enforce: false
    field :piece_bag, PieceBag.t(), enforce: true

    field :active_piece, PositionedPiece.t(), enforce: false
    field :can_update_active_piece?, boolean(), default: true
    field :matrix, Matrix.t()
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

  @spec matrix(t()) :: Matrix.t()
  def matrix(%__MODULE__{matrix: matrix, active_piece: active_piece}) do
    Matrix.add_ghost_piece(matrix, active_piece)
  end

  @spec to_snapshot(t()) :: BoardSnapshot.t()
  def to_snapshot(%__MODULE__{
        active_piece: active_piece,
        matrix: matrix,
        status: status,
        buffer_zone_size: buffer_zone_size
      }) do
    BoardSnapshot.new!(
      active_piece: active_piece,
      buffer_zone_size: buffer_zone_size,
      matrix: matrix,
      status: status
    )
  end

  @spec set_placement(t(), placement :: pos_integer()) :: {:ok, t()} | {:error, term()}
  def set_placement(%__MODULE__{} = board, placement) do
    ensure_type(%{board | status: :complete, placement: placement})
  end

  @spec has_lines_cleared(t(), count :: non_neg_integer()) :: boolean()
  def has_lines_cleared(%__MODULE__{} = board, count) do
    board.cleared_lines_count >= count
  end

  @spec update(t(), BoardUpdate.t()) :: t()
  @spec update(t(), BoardUpdate.t(), Keyword.t()) :: t()
  def update(board, board_update, opts \\ [])

  def update(%__MODULE__{status: :complete}, %BoardUpdate{}, _opts) do
    {:error, :board_complete}
  end

  def update(%__MODULE__{} = board, %BoardUpdate{} = board_update, opts) do
    recalculate? = should_recalculate?(board_update, opts)

    with {:ok, board} <- update_active_piece(board, board_update.active_piece_update),
         {:ok, board} <- maybe_recalculate(board, recalculate?),
         {:ok, board} <- ensure_type(board),
         {:ok, board} <- calculate_can_update_active_piece(board) do
      {:ok, board}
    end
  end

  defp should_recalculate?(board_update, opts) do
    cond do
      Keyword.has_key?(opts, :recalculate?) ->
        Keyword.fetch!(opts, :recalculate?)

      BoardUpdate.has_piece_update_type?(board_update, :hard_drop) ->
        true

      true ->
        # By default, let's not recalculate board
        false
    end
  end

  @spec update_active_piece(t(), PieceUpdate.t() | nil) ::
          {:ok, t()} | {:error, :invalid_move}
  def update_active_piece(%__MODULE__{} = board, nil) do
    {:ok, board}
  end

  def update_active_piece(
        %__MODULE__{active_piece: active_piece} = board,
        %PieceUpdate{piece: piece} = piece_update
      ) do
    if PositionedPiece.has_piece_type?(active_piece, piece) do
      do_update_active_piece(board, piece_update)
    else
      {:error, :invalid_move}
    end
  end

  defp do_update_active_piece(
         %__MODULE__{} = board,
         %PieceUpdate{update_type: :simple} = piece_update
       ) do
    update_result =
      cond do
        piece_update.direction != nil ->
          PositionedPiece.move(board.active_piece, piece_update.direction)

        piece_update.relative_rotation != nil ->
          PositionedPiece.rotate(
            board.active_piece,
            piece_update.relative_rotation
          )
      end

    with {:ok, active_piece} <- update_result do
      set_active_piece(board, active_piece)
    end
  end

  defp do_update_active_piece(
         %__MODULE__{active_piece: nil},
         %PieceUpdate{update_type: :hold}
       ) do
    {:error, :invalid_move}
  end

  defp do_update_active_piece(
         %__MODULE__{} = board,
         %PieceUpdate{update_type: :hold}
       ) do
    {:ok, hold_active_piece(board)}
  end

  defp do_update_active_piece(
         %__MODULE__{} = board,
         %PieceUpdate{update_type: :soft_drop_start}
       ) do
    next_piece =
      board.active_piece
      |> PositionedPiece.move(:down)

    with {:ok, piece} <- next_piece do
      set_active_piece(board, piece)
    end
  end

  defp do_update_active_piece(
         %__MODULE__{} = board,
         %PieceUpdate{update_type: :soft_drop_stop}
       ) do
    {:ok, board}
  end

  defp do_update_active_piece(
         %__MODULE__{} = board,
         %PieceUpdate{update_type: :hard_drop}
       ) do
    active_piece = Matrix.do_hard_drop(board.matrix, board.active_piece)
    set_active_piece(board, active_piece)
  end

  def maybe_recalculate(%__MODULE__{} = board, false) do
    {:ok, board}
  end

  def maybe_recalculate(%__MODULE__{} = board, true) do
    recalculate(board)
  end

  @spec recalculate(t()) :: {:ok, t()}
  def recalculate(%__MODULE__{} = board) do
    next_board =
      board
      |> maybe_change_active_piece()
      |> remove_filled_lines()
      |> detect_end_state()

    {:ok, next_board}
  end

  @spec maybe_change_active_piece(t()) :: t()
  def maybe_change_active_piece(%__MODULE__{} = board) do
    if can_update_active_piece?(board) do
      board
    else
      change_active_piece(board)
    end
  end

  def change_active_piece(
        %__MODULE__{piece_bag: piece_bag, size_x: size_x, size_y: size_y} = board,
        opts \\ []
      ) do
    add_to_matrix? = Keyword.get(opts, :add_to_matrix?, true)

    {piece_bag, active_piece} = PieceBag.get_piece(piece_bag, {size_x, size_y})

    %{
      board
      | active_piece: active_piece,
        piece_bag: piece_bag,
        matrix:
          if add_to_matrix? do
            Matrix.add_piece(board.matrix, board.active_piece)
          else
            board.matrix
          end
    }
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
  def detect_end_state(%__MODULE__{matrix: matrix, active_piece: active_piece} = board) do
    if Matrix.can_insert_peace?(matrix, active_piece) do
      board
    else
      %{board | status: :complete, active_piece: nil}
    end
  end

  @spec hold_active_piece(t()) :: t()
  defp hold_active_piece(
         %__MODULE__{active_piece: %PositionedPiece{piece: %Piece{} = piece}, piece_in_hold: nil} =
           board
       ) do
    board
    |> change_active_piece(add_to_matrix?: false)
    |> Map.put(:piece_in_hold, piece)
  end

  @spec hold_active_piece(t()) :: t()
  defp hold_active_piece(
         %__MODULE__{
           active_piece: %PositionedPiece{piece: %Piece{} = piece},
           piece_in_hold: %Piece{} = piece_in_hold,
           size_x: size_x,
           size_y: size_y
         } = board
       ) do
    positioned_piece = PositionedPiece.new_initial_piece!(piece_in_hold, {size_x, size_y})

    board
    |> Map.put(:active_piece, positioned_piece)
    |> Map.put(:piece_in_hold, piece)
  end

  defp set_active_piece(%__MODULE__{} = board, active_piece) do
    if Matrix.can_insert_peace?(board.matrix, active_piece) do
      case ensure_type(%{board | active_piece: active_piece}) do
        {:ok, board} -> {:ok, board}
        {:error, _} -> {:error, :invalid_move}
      end
    else
      {:error, :invalid_move}
    end
  end

  defp calculate_can_update_active_piece(%__MODULE__{} = board) do
    {:ok, %{board | can_update_active_piece?: can_update_active_piece?(board)}}
  end

  defp can_update_active_piece?(%__MODULE__{active_piece: nil}), do: false

  defp can_update_active_piece?(%__MODULE__{} = board) do
    case update_active_piece(
           board,
           PieceUpdate.update_active_piece(board, :simple, %{direction: :down})
         ) do
      {:ok, _board} -> true
      {:error, _reason} -> false
    end
  end
end

defimpl Jason.Encoder, for: [Pulk.Board] do
  alias Pulk.Board

  @visible_fields [
    :score,
    :cleared_lines_count,
    :piece_in_hold,
    :active_piece,
    :buffer_zone_size,
    :status,
    :placement
  ]

  def encode(struct, opts) do
    next_struct =
      struct
      |> Map.from_struct()
      |> Map.take(@visible_fields)
      |> Map.put(:level, Board.level(struct))
      |> Map.put(:piece_queue, Board.piece_queue(struct))
      |> Map.put(:matrix, Board.matrix(struct))

    Jason.Encode.map(next_struct, opts)
  end
end
