// =============================================================================
// src/types/index.ts — all shared game types and constants
// =============================================================================

// ── Cell ──────────────────────────────────────────────────────────────────────

export enum CellState {
  Hidden = "Hidden",
  Revealed = "Revealed",
  Flagged = "Flagged",
}

export type Cell = {
  row: number;
  col: number;
  isMine: boolean;
  adjacentMines: number;
  state: CellState;
};

// ── Difficulty ────────────────────────────────────────────────────────────────

export enum Difficulty {
  Easy = "Easy",
  Medium = "Medium",
  Hard = "Hard",
}

export type DifficultyConfig = {
  rows: number;
  cols: number;
  mines: number;
};

export const DIFFICULTY_CONFIG: Record<Difficulty, DifficultyConfig> = {
  [Difficulty.Easy]: { rows: 8, cols: 8, mines: 8 },
  [Difficulty.Medium]: { rows: 12, cols: 12, mines: 16 },
  [Difficulty.Hard]: { rows: 16, cols: 16, mines: 32 },
};

// ── Game ──────────────────────────────────────────────────────────────────────

export enum GameStatus {
  Idle = "Idle",
  Playing = "Playing",
  Won = "Won",
  Lost = "Lost",
}

export type GameState = {
  board: Cell[][];
  status: GameStatus;
  difficulty: Difficulty;
  flagsRemaining: number;
  elapsedSeconds: number;
  bestTimes: Record<Difficulty, number | null>;
  /** Coordinate of the cell to animate with a shake (chord mismatch). Cleared after animation. */
  shakingCell: [number, number] | null;
  /** Ordered queue of mine cells to reveal sequentially during loss animation. */
  explosionQueue: Cell[];
};
