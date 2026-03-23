import { Cell, CellState } from "../types";

// =============================================================================
// src/logic/index.ts — pure game rule functions
// All functions are stateless: they receive data and return new data.
// =============================================================================

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Returns all valid [row, col] neighbours for a given cell position. */
function getNeighbours(board: Cell[][], row: number, col: number): Cell[] {
  const neighbours: Cell[] = [];
  const rows = board.length;
  const cols = board[0].length;

  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      if (dr === 0 && dc === 0) continue;
      const r = row + dr;
      const c = col + dc;
      if (r >= 0 && r < rows && c >= 0 && c < cols) {
        neighbours.push(board[r][c]);
      }
    }
  }

  return neighbours;
}

/** Deep-clones the board so all functions remain pure. */
function cloneBoard(board: Cell[][]): Cell[][] {
  return board.map((row) => row.map((cell) => ({ ...cell })));
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * Creates an empty rows×cols board where every cell is Hidden and mine-free.
 */
export function createEmptyBoard(rows: number, cols: number): Cell[][] {
  return Array.from({ length: rows }, (_, row) =>
    Array.from({ length: cols }, (_, col) => ({
      row,
      col,
      isMine: false,
      adjacentMines: 0,
      state: CellState.Hidden,
    })),
  );
}

/**
 * Randomly distributes `mines` mines across the board.
 * Guarantees the cell at (safeRow, safeCol) and all 8 of its neighbours
 * are never assigned a mine.
 */
export function placeMines(
  board: Cell[][],
  mines: number,
  safeRow: number,
  safeCol: number,
): Cell[][] {
  const next = cloneBoard(board);
  const rows = next.length;
  const cols = next[0].length;

  // Build exclusion set: safe cell + its 8 neighbours
  const excluded = new Set<string>();
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      const r = safeRow + dr;
      const c = safeCol + dc;
      if (r >= 0 && r < rows && c >= 0 && c < cols) {
        excluded.add(`${r},${c}`);
      }
    }
  }

  let placed = 0;
  while (placed < mines) {
    const r = Math.floor(Math.random() * rows);
    const c = Math.floor(Math.random() * cols);
    if (!next[r][c].isMine && !excluded.has(`${r},${c}`)) {
      next[r][c].isMine = true;
      placed++;
    }
  }

  return next;
}

/**
 * Computes the `adjacentMines` count for every non-mine cell.
 * Mine cells keep adjacentMines = 0.
 */
export function computeAdjacentCounts(board: Cell[][]): Cell[][] {
  const next = cloneBoard(board);

  for (const row of next) {
    for (const cell of row) {
      if (cell.isMine) continue;
      cell.adjacentMines = getNeighbours(next, cell.row, cell.col).filter(
        (n) => n.isMine,
      ).length;
    }
  }

  return next;
}

/**
 * Reveals the cell at (row, col).
 * If the cell has adjacentMines === 0, flood-fills recursively to reveal
 * all connected empty cells and their numbered borders.
 * Already-revealed and flagged cells are never re-processed.
 */
export function revealCell(
  board: Cell[][],
  row: number,
  col: number,
): Cell[][] {
  const next = cloneBoard(board);

  const stack: Array<[number, number]> = [[row, col]];
  const visited = new Set<string>();

  while (stack.length > 0) {
    const [r, c] = stack.pop()!;
    const key = `${r},${c}`;
    const cell = next[r][c];

    if (visited.has(key)) {
      continue;
    }

    visited.add(key);

    if ([CellState.Flagged, CellState.Revealed].includes(cell.state)) {
      continue;
    }

    cell.state = CellState.Revealed;

    // Flood-fill: only expand from empty (zero-adjacent) non-mine cells
    if (!cell.isMine && cell.adjacentMines === 0) {
      const neighbours: Cell[] = getNeighbours(next, r, c);
      const flood = floodFill(neighbours, visited);
      stack.push(...flood);
    }
  }

  return next;
}

export function floodFill(
  neighbours: Cell[],
  visited: Set<string>,
): Array<[number, number]> {
  const stack: Array<[number, number]> = [];

  for (const neighbour of neighbours) {
    const nKey = `${neighbour.row},${neighbour.col}`;
    if (!visited.has(nKey) && neighbour.state === CellState.Hidden) {
      stack.push([neighbour.row, neighbour.col]);
    }
  }

  return stack;
}

/**
 * Returns the number of Flagged neighbours around (row, col).
 */
export function countAdjacentFlags(
  board: Cell[][],
  row: number,
  col: number,
): number {
  return getNeighbours(board, row, col).filter(
    (n) => n.state === CellState.Flagged,
  ).length;
}

/**
 * Chord-reveals all non-flagged neighbours of a number cell at (row, col).
 * Returns the updated board and whether any revealed cell was a mine.
 */
export function chordReveal(
  board: Cell[][],
  row: number,
  col: number,
): { board: Cell[][]; triggeredMine: boolean } {
  let next = cloneBoard(board);
  let triggeredMine = false;

  const neighbours = getNeighbours(next, row, col);

  for (const neighbour of neighbours) {
    if (neighbour.state === CellState.Flagged) continue;
    if (neighbour.state === CellState.Revealed) continue;

    if (neighbour.isMine) {
      triggeredMine = true;
    }

    next = revealCell(next, neighbour.row, neighbour.col);
  }

  return { board: next, triggeredMine };
}

/**
 * Returns true when every non-mine cell has state === Revealed.
 */
export function checkWin(board: Cell[][]): boolean {
  return board.every((row) =>
    row.every((cell) => cell.isMine || cell.state === CellState.Revealed),
  );
}
