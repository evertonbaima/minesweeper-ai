import { describe, it, expect } from 'vitest'
import {
  createEmptyBoard,
  placeMines,
  computeAdjacentCounts,
  revealCell,
  countAdjacentFlags,
  chordReveal,
  checkWin,
} from '../logic'
import { CellState } from '../types'

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Counts total mines on a board. */
function countMines(board: ReturnType<typeof createEmptyBoard>): number {
  return board.flat().filter(c => c.isMine).length
}

/** Returns true if a cell is in the 3×3 safe zone around (sr, sc). */
function isInSafeZone(r: number, c: number, sr: number, sc: number): boolean {
  return Math.abs(r - sr) <= 1 && Math.abs(c - sc) <= 1
}

// ── createEmptyBoard ──────────────────────────────────────────────────────────

describe('createEmptyBoard', () => {
  it('creates a board with correct dimensions', () => {
    const board = createEmptyBoard(8, 8)
    expect(board.length).toBe(8)
    expect(board[0].length).toBe(8)
  })

  it('every cell is Hidden and mine-free', () => {
    const board = createEmptyBoard(4, 4)
    board.flat().forEach(cell => {
      expect(cell.state).toBe(CellState.Hidden)
      expect(cell.isMine).toBe(false)
      expect(cell.adjacentMines).toBe(0)
    })
  })

  it('cells carry correct row and col coordinates', () => {
    const board = createEmptyBoard(3, 3)
    for (let r = 0; r < 3; r++) {
      for (let c = 0; c < 3; c++) {
        expect(board[r][c].row).toBe(r)
        expect(board[r][c].col).toBe(c)
      }
    }
  })
})

// ── placeMines ────────────────────────────────────────────────────────────────

describe('placeMines', () => {
  it('places the exact number of mines', () => {
    const board = createEmptyBoard(8, 8)
    const result = placeMines(board, 8, 0, 0)
    expect(countMines(result)).toBe(8)
  })

  it('never places a mine on the safe cell', () => {
    for (let i = 0; i < 20; i++) {
      const board = createEmptyBoard(8, 8)
      const result = placeMines(board, 10, 3, 3)
      expect(result[3][3].isMine).toBe(false)
    }
  })

  it('never places a mine in the 3×3 safe zone', () => {
    for (let i = 0; i < 20; i++) {
      const board = createEmptyBoard(8, 8)
      const result = placeMines(board, 10, 4, 4)
      result.flat().forEach(cell => {
        if (isInSafeZone(cell.row, cell.col, 4, 4)) {
          expect(cell.isMine).toBe(false)
        }
      })
    }
  })

  it('does not mutate the original board', () => {
    const board = createEmptyBoard(8, 8)
    placeMines(board, 8, 0, 0)
    expect(countMines(board)).toBe(0)
  })
})

// ── computeAdjacentCounts ─────────────────────────────────────────────────────

describe('computeAdjacentCounts', () => {
  it('counts adjacent mines correctly for a corner cell', () => {
    // Place a mine at (0,0) and check (0,1) and (1,0) get count 1
    let board = createEmptyBoard(3, 3)
    board[0][0].isMine = true
    board = computeAdjacentCounts(board)
    expect(board[0][1].adjacentMines).toBe(1)
    expect(board[1][0].adjacentMines).toBe(1)
    expect(board[1][1].adjacentMines).toBe(1)
  })

  it('mine cells keep adjacentMines = 0', () => {
    let board = createEmptyBoard(3, 3)
    board[1][1].isMine = true
    board = computeAdjacentCounts(board)
    expect(board[1][1].adjacentMines).toBe(0)
  })

  it('a cell surrounded by 8 mines gets count 8', () => {
    let board = createEmptyBoard(3, 3)
    for (let r = 0; r < 3; r++) {
      for (let c = 0; c < 3; c++) {
        if (r !== 1 || c !== 1) board[r][c].isMine = true
      }
    }
    board = computeAdjacentCounts(board)
    expect(board[1][1].adjacentMines).toBe(8)
  })

  it('does not mutate the original board', () => {
    const board = createEmptyBoard(3, 3)
    board[0][0].isMine = true
    computeAdjacentCounts(board)
    expect(board[0][1].adjacentMines).toBe(0)
  })
})

// ── revealCell ────────────────────────────────────────────────────────────────

describe('revealCell', () => {
  it('reveals the targeted cell', () => {
    const board = createEmptyBoard(4, 4)
    const result = revealCell(board, 2, 2)
    expect(result[2][2].state).toBe(CellState.Revealed)
  })

  it('flood-fills from an empty cell — reveals the whole empty region', () => {
    // 4×4 board with a mine at (0,3) — cells in the left region are all empty
    let board = createEmptyBoard(4, 4)
    board[0][3].isMine = true
    board = computeAdjacentCounts(board)
    const result = revealCell(board, 3, 0)

    // All non-mine cells should be revealed
    result.flat().forEach(cell => {
      if (!cell.isMine) {
        expect(cell.state).toBe(CellState.Revealed)
      }
    })
  })

  it('does not flood-fill past a numbered cell border', () => {
    // 3×3 board, mine at (0,2). Clicking (2,0) should stop at the numbered border.
    let board = createEmptyBoard(3, 3)
    board[0][2].isMine = true
    board = computeAdjacentCounts(board)
    const result = revealCell(board, 2, 0)
    // Mine itself stays hidden
    expect(result[0][2].state).toBe(CellState.Hidden)
  })

  it('does not reveal flagged cells', () => {
    const board = createEmptyBoard(4, 4)
    board[2][2].state = CellState.Flagged
    const result = revealCell(board, 2, 2)
    expect(result[2][2].state).toBe(CellState.Flagged)
  })

  it('does not mutate the original board', () => {
    const board = createEmptyBoard(4, 4)
    revealCell(board, 1, 1)
    expect(board[1][1].state).toBe(CellState.Hidden)
  })
})

// ── countAdjacentFlags ────────────────────────────────────────────────────────

describe('countAdjacentFlags', () => {
  it('returns 0 when no neighbours are flagged', () => {
    const board = createEmptyBoard(3, 3)
    expect(countAdjacentFlags(board, 1, 1)).toBe(0)
  })

  it('counts flagged neighbours correctly', () => {
    const board = createEmptyBoard(3, 3)
    board[0][0].state = CellState.Flagged
    board[0][1].state = CellState.Flagged
    expect(countAdjacentFlags(board, 1, 1)).toBe(2)
  })

  it('does not count revealed cells as flags', () => {
    const board = createEmptyBoard(3, 3)
    board[0][0].state = CellState.Revealed
    expect(countAdjacentFlags(board, 1, 1)).toBe(0)
  })
})

// ── chordReveal ───────────────────────────────────────────────────────────────

describe('chordReveal', () => {
  it('reveals non-flagged neighbours and returns triggeredMine: false when safe', () => {
    // 3×3 board, mine at (0,0) flagged — chord on (1,1) should be safe
    let board = createEmptyBoard(3, 3)
    board[0][0].isMine = true
    board = computeAdjacentCounts(board)
    board[1][1].state = CellState.Revealed
    board[0][0].state = CellState.Flagged

    const { board: result, triggeredMine } = chordReveal(board, 1, 1)

    expect(triggeredMine).toBe(false)
    // All non-mine, non-flagged neighbours of (1,1) should now be revealed
    expect(result[0][1].state).toBe(CellState.Revealed)
    expect(result[1][0].state).toBe(CellState.Revealed)
  })

  it('returns triggeredMine: true when an unflagged mine is revealed', () => {
    // 3×3 board, mine at (0,0) NOT flagged — chord on (1,1) triggers it
    let board = createEmptyBoard(3, 3)
    board[0][0].isMine = true
    board = computeAdjacentCounts(board)
    board[1][1].state = CellState.Revealed

    const { triggeredMine } = chordReveal(board, 1, 1)

    expect(triggeredMine).toBe(true)
  })

  it('skips already-revealed neighbours', () => {
    let board = createEmptyBoard(3, 3)
    board[0][1].state = CellState.Revealed
    board[1][1].state = CellState.Revealed
    const { board: result } = chordReveal(board, 1, 1)
    // Already revealed — state unchanged
    expect(result[0][1].state).toBe(CellState.Revealed)
  })

  it('does not mutate the original board', () => {
    const board = createEmptyBoard(3, 3)
    board[1][1].state = CellState.Revealed
    chordReveal(board, 1, 1)
    expect(board[0][0].state).toBe(CellState.Hidden)
  })
})

// ── checkWin ──────────────────────────────────────────────────────────────────

describe('checkWin', () => {
  it('returns false when some safe cells are still hidden', () => {
    const board = createEmptyBoard(2, 2)
    expect(checkWin(board)).toBe(false)
  })

  it('returns true when all non-mine cells are revealed', () => {
    let board = createEmptyBoard(2, 2)
    board[0][0].isMine = true
    // Reveal all non-mine cells
    board[0][1].state = CellState.Revealed
    board[1][0].state = CellState.Revealed
    board[1][1].state = CellState.Revealed
    expect(checkWin(board)).toBe(true)
  })

  it('returns false if a non-mine cell is flagged but not revealed', () => {
    let board = createEmptyBoard(2, 2)
    board[0][0].isMine = true
    board[0][1].state = CellState.Revealed
    board[1][0].state = CellState.Revealed
    board[1][1].state = CellState.Flagged // flagged but not revealed
    expect(checkWin(board)).toBe(false)
  })

  it('returns true when all mines are flagged and all safe cells revealed', () => {
    let board = createEmptyBoard(2, 2)
    board[0][0].isMine = true
    board[0][0].state = CellState.Flagged
    board[0][1].state = CellState.Revealed
    board[1][0].state = CellState.Revealed
    board[1][1].state = CellState.Revealed
    expect(checkWin(board)).toBe(true)
  })
})
