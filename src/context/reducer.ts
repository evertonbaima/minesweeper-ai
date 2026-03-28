import {
  Cell,
  CellState,
  Difficulty,
  DIFFICULTY_CONFIG,
  GameState,
  GameStatus,
} from "../types";
import {
  checkWin,
  chordReveal,
  computeAdjacentCounts,
  countAdjacentFlags,
  createEmptyBoard,
  placeMines,
  revealCell,
} from "../logic";

// =============================================================================
// src/context/reducer.ts — action types and gameReducer
// =============================================================================

const BEST_TIMES_KEY = "minesweeper_best_times";

// ── Action types ──────────────────────────────────────────────────────────────

export type GameAction =
  | { type: "START_GAME"; difficulty: Difficulty }
  | { type: "REVEAL_CELL"; row: number; col: number }
  | { type: "TOGGLE_FLAG"; row: number; col: number }
  | { type: "CHORD_REVEAL"; row: number; col: number }
  | { type: "TICK" }
  | { type: "RESTART" };

// ── localStorage helpers ──────────────────────────────────────────────────────

function loadBestTimes(): Record<Difficulty, number | null> {
  try {
    const raw = localStorage.getItem(BEST_TIMES_KEY);
    if (!raw) return buildEmptyBestTimes();
    const parsed = JSON.parse(raw) as Record<Difficulty, number | null>;
    return parsed;
  } catch {
    return buildEmptyBestTimes();
  }
}

function saveBestTimes(bestTimes: Record<Difficulty, number | null>): void {
  try {
    localStorage.setItem(BEST_TIMES_KEY, JSON.stringify(bestTimes));
  } catch {
    // NOTE: localStorage may be unavailable in some environments — fail silently
  }
}

function buildEmptyBestTimes(): Record<Difficulty, number | null> {
  return {
    [Difficulty.Easy]: null,
    [Difficulty.Medium]: null,
    [Difficulty.Hard]: null,
  };
}

// ── Initial state factory ─────────────────────────────────────────────────────

function buildIdleState(
  difficulty: Difficulty,
  bestTimes: Record<Difficulty, number | null>,
): GameState {
  const { rows, cols, mines } = DIFFICULTY_CONFIG[difficulty];
  return {
    board: createEmptyBoard(rows, cols),
    status: GameStatus.Idle,
    difficulty,
    flagsRemaining: mines,
    elapsedSeconds: 0,
    bestTimes,
    shakingCell: null,
    explosionQueue: [],
  };
}

export function buildInitialState(difficulty = Difficulty.Easy): GameState {
  return buildIdleState(difficulty, loadBestTimes());
}

// ── Mine cells ordered for explosion animation ────────────────────────────────

function collectMineCells(board: Cell[][]): Cell[] {
  return board.flat().filter((cell) => cell.isMine);
}

// ── Reducer ───────────────────────────────────────────────────────────────────

export function gameReducer(state: GameState, action: GameAction): GameState {
  switch (action.type) {
    case "START_GAME": {
      return buildIdleState(action.difficulty, state.bestTimes);
    }

    case "REVEAL_CELL": {
      const { row, col } = action;
      const cell = state.board[row][col];

      // Ignore clicks on already-revealed or flagged cells and terminal states
      if (
        cell.state !== CellState.Hidden ||
        state.status === GameStatus.Won ||
        state.status === GameStatus.Lost
      ) {
        return state;
      }

      // First click: place mines and start the clock
      const isFirstClick = state.status === GameStatus.Idle;
      let board = state.board;

      if (isFirstClick) {
        board = placeMines(board, DIFFICULTY_CONFIG[state.difficulty].mines, row, col);
        board = computeAdjacentCounts(board);
      }

      // Reveal the clicked cell
      board = revealCell(board, row, col);
      const revealedCell = board[row][col];

      // Mine hit → Lost
      if (revealedCell.isMine) {
        return {
          ...state,
          board,
          status: GameStatus.Lost,
          explosionQueue: collectMineCells(board),
          shakingCell: null,
        };
      }

      // Check win condition
      if (checkWin(board)) {
        const elapsed = state.elapsedSeconds;
        const prev = state.bestTimes[state.difficulty];
        const isNewBest = prev === null || elapsed < prev;
        const bestTimes = isNewBest
          ? { ...state.bestTimes, [state.difficulty]: elapsed }
          : state.bestTimes;

        if (isNewBest) saveBestTimes(bestTimes);

        return {
          ...state,
          board,
          status: GameStatus.Won,
          bestTimes,
          shakingCell: null,
          explosionQueue: [],
        };
      }

      return {
        ...state,
        board,
        status: GameStatus.Playing,
        shakingCell: null,
        explosionQueue: [],
      };
    }

    case "TOGGLE_FLAG": {
      const { row, col } = action;
      const cell = state.board[row][col];

      // Only act on hidden cells during an active game
      if (
        state.status === GameStatus.Won ||
        state.status === GameStatus.Lost
      ) {
        return state;
      }

      if (cell.state === CellState.Hidden) {
        // Block placing a flag when the cap is reached
        if (state.flagsRemaining === 0) return state;

        const board = state.board.map((r) =>
          r.map((c) =>
            c.row === row && c.col === col
              ? { ...c, state: CellState.Flagged }
              : c,
          ),
        );
        return { ...state, board, flagsRemaining: state.flagsRemaining - 1 };
      }

      if (cell.state === CellState.Flagged) {
        const board = state.board.map((r) =>
          r.map((c) =>
            c.row === row && c.col === col
              ? { ...c, state: CellState.Hidden }
              : c,
          ),
        );
        return { ...state, board, flagsRemaining: state.flagsRemaining + 1 };
      }

      return state;
    }

    case "CHORD_REVEAL": {
      const { row, col } = action;
      const cell = state.board[row][col];

      if (
        state.status !== GameStatus.Playing ||
        cell.state !== CellState.Revealed ||
        cell.adjacentMines === 0
      ) {
        return state;
      }

      const flagCount = countAdjacentFlags(state.board, row, col);

      // Mismatch: shake the cell instead of revealing
      if (flagCount !== cell.adjacentMines) {
        return { ...state, shakingCell: [row, col] };
      }

      const { board, triggeredMine } = chordReveal(state.board, row, col);

      if (triggeredMine) {
        return {
          ...state,
          board,
          status: GameStatus.Lost,
          explosionQueue: collectMineCells(board),
          shakingCell: null,
        };
      }

      if (checkWin(board)) {
        const elapsed = state.elapsedSeconds;
        const prev = state.bestTimes[state.difficulty];
        const isNewBest = prev === null || elapsed < prev;
        const bestTimes = isNewBest
          ? { ...state.bestTimes, [state.difficulty]: elapsed }
          : state.bestTimes;

        if (isNewBest) saveBestTimes(bestTimes);

        return {
          ...state,
          board,
          status: GameStatus.Won,
          bestTimes,
          shakingCell: null,
          explosionQueue: [],
        };
      }

      return { ...state, board, shakingCell: null };
    }

    case "TICK": {
      if (state.status !== GameStatus.Playing) return state;
      return { ...state, elapsedSeconds: state.elapsedSeconds + 1 };
    }

    case "RESTART": {
      return buildIdleState(state.difficulty, state.bestTimes);
    }

    default:
      return state;
  }
}
