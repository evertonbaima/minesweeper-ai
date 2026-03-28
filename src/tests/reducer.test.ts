import { beforeEach, describe, expect, it, vi } from "vitest";
import { gameReducer, buildInitialState, GameAction } from "../context/reducer";
import { Difficulty, GameStatus, CellState, DIFFICULTY_CONFIG } from "../types";
import { computeAdjacentCounts, createEmptyBoard, placeMines } from "../logic";

// =============================================================================
// Mock localStorage so tests run in jsdom without side-effects leaking
// =============================================================================

const localStorageMock = (() => {
  let store: Record<string, string> = {};
  return {
    getItem: vi.fn((key: string) => store[key] ?? null),
    setItem: vi.fn((key: string, value: string) => {
      store[key] = value;
    }),
    clear: () => {
      store = {};
    },
  };
})();

Object.defineProperty(globalThis, "localStorage", { value: localStorageMock });

// =============================================================================
// Helpers
// =============================================================================

function dispatch(state = buildInitialState(), action: GameAction) {
  return gameReducer(state, action);
}

/** Produces a Playing state after one safe first click on a known-safe board. */
function playingState() {
  const state = buildInitialState(Difficulty.Easy);
  // START_GAME is implicit in buildInitialState — go straight to first reveal
  return dispatch(state, { type: "REVEAL_CELL", row: 0, col: 0 });
}

// =============================================================================
// START_GAME
// =============================================================================

describe("START_GAME", () => {
  it("should set status to Idle", () => {
    const state = dispatch(undefined, {
      type: "START_GAME",
      difficulty: Difficulty.Easy,
    });
    expect(state.status).toBe(GameStatus.Idle);
  });

  it("should set flagsRemaining to mine count for the chosen difficulty", () => {
    const state = dispatch(undefined, {
      type: "START_GAME",
      difficulty: Difficulty.Hard,
    });
    expect(state.flagsRemaining).toBe(DIFFICULTY_CONFIG[Difficulty.Hard].mines);
  });

  it("should create an empty board with no mines", () => {
    const state = dispatch(undefined, {
      type: "START_GAME",
      difficulty: Difficulty.Easy,
    });
    expect(state.board.flat().every((c) => !c.isMine)).toBe(true);
  });

  it("should preserve bestTimes from previous state", () => {
    const base = buildInitialState();
    const withTime = {
      ...base,
      bestTimes: { ...base.bestTimes, [Difficulty.Easy]: 42 },
    };
    const state = gameReducer(withTime, {
      type: "START_GAME",
      difficulty: Difficulty.Easy,
    });
    expect(state.bestTimes[Difficulty.Easy]).toBe(42);
  });
});

// =============================================================================
// REVEAL_CELL
// =============================================================================

describe("REVEAL_CELL", () => {
  beforeEach(() => localStorageMock.clear());

  it("should place mines on first click and set status to Playing", () => {
    const state = buildInitialState();
    const next = dispatch(state, { type: "REVEAL_CELL", row: 0, col: 0 });
    expect(next.status).toBe(GameStatus.Playing);
    expect(next.board.flat().some((c) => c.isMine)).toBe(true);
  });

  it("should reveal the clicked cell", () => {
    const next = playingState();
    // (0,0) is safe — first click guarantee
    expect(next.board[0][0].state).toBe(CellState.Revealed);
  });

  it("should not place a mine on the first-clicked cell", () => {
    const next = playingState();
    expect(next.board[0][0].isMine).toBe(false);
  });

  it("should set status to Lost when a mine is revealed", () => {
    // Build a board with a known mine and manually reach Playing
    let board = createEmptyBoard(8, 8);
    board[3][3].isMine = true;
    board = computeAdjacentCounts(board);
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
    };
    const next = dispatch(state, { type: "REVEAL_CELL", row: 3, col: 3 });
    expect(next.status).toBe(GameStatus.Lost);
  });

  it("should populate explosionQueue on loss", () => {
    let board = createEmptyBoard(8, 8);
    board[3][3].isMine = true;
    board[4][4].isMine = true;
    board = computeAdjacentCounts(board);
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
    };
    const next = dispatch(state, { type: "REVEAL_CELL", row: 3, col: 3 });
    expect(next.explosionQueue.length).toBe(2);
    expect(next.explosionQueue.every((c) => c.isMine)).toBe(true);
  });

  it("should set status to Won when last safe cell is revealed", () => {
    // 2×2 board with one mine, reveal the remaining three cells
    let board = createEmptyBoard(2, 2);
    board[0][0].isMine = true;
    board = computeAdjacentCounts(board);
    board[0][1].state = CellState.Revealed;
    board[1][0].state = CellState.Revealed;
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
      elapsedSeconds: 30,
    };
    const next = dispatch(state, { type: "REVEAL_CELL", row: 1, col: 1 });
    expect(next.status).toBe(GameStatus.Won);
  });

  it("should update bestTimes on win when no previous record exists", () => {
    let board = createEmptyBoard(2, 2);
    board[0][0].isMine = true;
    board = computeAdjacentCounts(board);
    board[0][1].state = CellState.Revealed;
    board[1][0].state = CellState.Revealed;
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
      elapsedSeconds: 30,
    };
    const next = dispatch(state, { type: "REVEAL_CELL", row: 1, col: 1 });
    expect(next.bestTimes[Difficulty.Easy]).toBe(30);
    expect(localStorageMock.setItem).toHaveBeenCalled();
  });

  it("should not update bestTimes when new time is worse than previous record", () => {
    let board = createEmptyBoard(2, 2);
    board[0][0].isMine = true;
    board = computeAdjacentCounts(board);
    board[0][1].state = CellState.Revealed;
    board[1][0].state = CellState.Revealed;
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
      elapsedSeconds: 99,
      bestTimes: { ...buildInitialState().bestTimes, [Difficulty.Easy]: 20 },
    };
    const next = dispatch(state, { type: "REVEAL_CELL", row: 1, col: 1 });
    expect(next.bestTimes[Difficulty.Easy]).toBe(20);
  });

  it("should ignore clicks on revealed cells", () => {
    let board = createEmptyBoard(8, 8);
    board = computeAdjacentCounts(board);
    board[1][1].state = CellState.Revealed;
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
    };
    const next = dispatch(state, { type: "REVEAL_CELL", row: 1, col: 1 });
    expect(next).toBe(state);
  });

  it("should ignore clicks when game is Won or Lost", () => {
    const won = { ...buildInitialState(), status: GameStatus.Won };
    const lost = { ...buildInitialState(), status: GameStatus.Lost };
    expect(dispatch(won, { type: "REVEAL_CELL", row: 0, col: 0 })).toBe(won);
    expect(dispatch(lost, { type: "REVEAL_CELL", row: 0, col: 0 })).toBe(lost);
  });
});

// =============================================================================
// TOGGLE_FLAG
// =============================================================================

describe("TOGGLE_FLAG", () => {
  it("should flag a hidden cell and decrement flagsRemaining", () => {
    const state = playingState();
    const target = state.board.flat().find((c) => c.state === CellState.Hidden)!;
    const next = dispatch(state, {
      type: "TOGGLE_FLAG",
      row: target.row,
      col: target.col,
    });
    expect(next.board[target.row][target.col].state).toBe(CellState.Flagged);
    expect(next.flagsRemaining).toBe(state.flagsRemaining - 1);
  });

  it("should unflag a flagged cell and increment flagsRemaining", () => {
    const state = playingState();
    const target = state.board.flat().find((c) => c.state === CellState.Hidden)!;
    const flagged = dispatch(state, {
      type: "TOGGLE_FLAG",
      row: target.row,
      col: target.col,
    });
    const unflagged = dispatch(flagged, {
      type: "TOGGLE_FLAG",
      row: target.row,
      col: target.col,
    });
    expect(unflagged.board[target.row][target.col].state).toBe(
      CellState.Hidden,
    );
    expect(unflagged.flagsRemaining).toBe(state.flagsRemaining);
  });

  it("should block placing a flag when flagsRemaining is 0", () => {
    const state = { ...playingState(), flagsRemaining: 0 };
    const target = state.board.flat().find((c) => c.state === CellState.Hidden)!;
    const next = dispatch(state, {
      type: "TOGGLE_FLAG",
      row: target.row,
      col: target.col,
    });
    expect(next).toBe(state);
  });

  it("should not flag a revealed cell", () => {
    const state = playingState();
    // (0,0) was revealed by first click
    const next = dispatch(state, { type: "TOGGLE_FLAG", row: 0, col: 0 });
    expect(next).toBe(state);
  });

  it("should ignore flags in Won or Lost state", () => {
    const won = { ...buildInitialState(), status: GameStatus.Won };
    const next = dispatch(won, { type: "TOGGLE_FLAG", row: 0, col: 0 });
    expect(next).toBe(won);
  });
});

// =============================================================================
// CHORD_REVEAL
// =============================================================================

describe("CHORD_REVEAL", () => {
  it("should set shakingCell when flag count does not match adjacentMines", () => {
    // 3×3, mine at (0,0), (1,1) is a number cell, no flags placed
    let board = createEmptyBoard(3, 3);
    board[0][0].isMine = true;
    board = computeAdjacentCounts(board);
    board[1][1].state = CellState.Revealed;
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
    };
    const next = dispatch(state, { type: "CHORD_REVEAL", row: 1, col: 1 });
    expect(next.shakingCell).toEqual([1, 1]);
  });

  it("should chord-reveal neighbours when flag count matches adjacentMines", () => {
    let board = createEmptyBoard(3, 3);
    board[0][0].isMine = true;
    board = computeAdjacentCounts(board);
    board[1][1].state = CellState.Revealed;
    board[0][0].state = CellState.Flagged;
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
      flagsRemaining: 7,
    };
    const next = dispatch(state, { type: "CHORD_REVEAL", row: 1, col: 1 });
    expect(next.shakingCell).toBeNull();
    // At least one previously hidden neighbour should now be revealed
    expect(
      next.board.flat().some(
        (c) => c.state === CellState.Revealed && !(c.row === 1 && c.col === 1),
      ),
    ).toBe(true);
  });

  it("should set Lost when chord triggers an unflagged mine", () => {
    // Mine at (0,0) NOT flagged — chord on (1,1) should trigger it
    let board = createEmptyBoard(3, 3);
    board[0][0].isMine = true;
    board = computeAdjacentCounts(board);
    board[1][1].state = CellState.Revealed;
    // Fake the adjacent flag count by flagging a non-mine neighbour
    board[0][1].state = CellState.Flagged;
    const state: ReturnType<typeof buildInitialState> = {
      ...buildInitialState(),
      board,
      status: GameStatus.Playing,
      flagsRemaining: 7,
    };
    // adjacentMines of (1,1) is 1, flagCount is 1 (flagged (0,1)) → chord fires
    const next = dispatch(state, { type: "CHORD_REVEAL", row: 1, col: 1 });
    expect(next.status).toBe(GameStatus.Lost);
    expect(next.explosionQueue.length).toBeGreaterThan(0);
  });

  it("should ignore CHORD_REVEAL when game is not Playing", () => {
    const state = buildInitialState(); // Idle
    const next = dispatch(state, { type: "CHORD_REVEAL", row: 0, col: 0 });
    expect(next).toBe(state);
  });
});

// =============================================================================
// TICK
// =============================================================================

describe("TICK", () => {
  it("should increment elapsedSeconds when Playing", () => {
    const state = { ...playingState(), elapsedSeconds: 5 };
    const next = dispatch(state, { type: "TICK" });
    expect(next.elapsedSeconds).toBe(6);
  });

  it("should not increment elapsedSeconds when Idle", () => {
    const state = buildInitialState();
    const next = dispatch(state, { type: "TICK" });
    expect(next).toBe(state);
  });

  it("should not increment elapsedSeconds when Won", () => {
    const state = { ...buildInitialState(), status: GameStatus.Won, elapsedSeconds: 10 };
    const next = dispatch(state, { type: "TICK" });
    expect(next).toBe(state);
  });

  it("should not increment elapsedSeconds when Lost", () => {
    const state = { ...buildInitialState(), status: GameStatus.Lost, elapsedSeconds: 10 };
    const next = dispatch(state, { type: "TICK" });
    expect(next).toBe(state);
  });
});

// =============================================================================
// RESTART
// =============================================================================

describe("RESTART", () => {
  it("should reset board, status, and timer", () => {
    const state = { ...playingState(), elapsedSeconds: 42 };
    const next = dispatch(state, { type: "RESTART" });
    expect(next.status).toBe(GameStatus.Idle);
    expect(next.elapsedSeconds).toBe(0);
    expect(next.board.flat().every((c) => !c.isMine)).toBe(true);
  });

  it("should preserve difficulty", () => {
    const state = dispatch(buildInitialState(), {
      type: "START_GAME",
      difficulty: Difficulty.Hard,
    });
    const next = dispatch(state, { type: "RESTART" });
    expect(next.difficulty).toBe(Difficulty.Hard);
  });

  it("should preserve bestTimes", () => {
    const state = {
      ...buildInitialState(),
      bestTimes: { ...buildInitialState().bestTimes, [Difficulty.Easy]: 15 },
    };
    const next = dispatch(state, { type: "RESTART" });
    expect(next.bestTimes[Difficulty.Easy]).toBe(15);
  });

  it("should reset shakingCell and explosionQueue", () => {
    const state = {
      ...buildInitialState(),
      shakingCell: [2, 2] as [number, number],
      explosionQueue: [buildInitialState().board[0][0]],
    };
    const next = dispatch(state, { type: "RESTART" });
    expect(next.shakingCell).toBeNull();
    expect(next.explosionQueue).toHaveLength(0);
  });
});
