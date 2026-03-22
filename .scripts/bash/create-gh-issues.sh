#!/bin/bash

# Minesweeper — GitHub Issue Creator
# Repository: evertonbaima/minesweeper-ai
# Usage: chmod +x create_issues.sh && ./create_issues.sh

REPO="evertonbaima/minesweeper-ai"

echo "Creating Minesweeper issues in $REPO..."

# ─────────────────────────────────────────
# Task 1 — Project Scaffolding
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Project Scaffolding" \
  --body "Set up the base project using Vite with the React + TypeScript template. Install and configure all required dependencies: Styled Components, Vitest, and the React Testing Library adapter.

## Acceptance Criterias

- [ ] Project is initialised with \`npm create vite\` using the \`react-ts\` template
- [ ] Styled Components and \`@types/styled-components\` are installed
- [ ] Vitest is installed and configured in \`vite.config.ts\` with \`globals: true\` and \`environment: jsdom\`
- [ ] \`@testing-library/react\` and \`@testing-library/user-event\` are installed
- [ ] \`@testing-library/jest-dom\` matchers are configured in a \`setupTests.ts\` file referenced by Vitest
- [ ] A \`src/\` folder structure is created: \`components/\`, \`context/\`, \`hooks/\`, \`logic/\`, \`types/\`, \`tests/\`
- [ ] Running \`npm run dev\` starts the app without errors
- [ ] Running \`npm run test\` executes Vitest without errors"

echo "✅ Issue 1 created: Project Scaffolding"

# ─────────────────────────────────────────
# Task 2 — Type Definitions
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Type Definitions" \
  --body "Define all shared TypeScript types and enums used across the game. This task produces no UI, only the type contract the rest of the codebase depends on.

## Acceptance Criterias

- [ ] A \`CellState\` enum is defined with values: \`Hidden\`, \`Revealed\`, \`Flagged\`
- [ ] A \`Cell\` type is defined with fields: \`row: number\`, \`col: number\`, \`isMine: boolean\`, \`adjacentMines: number\`, \`state: CellState\`
- [ ] A \`Difficulty\` enum is defined with values: \`Easy\`, \`Medium\`, \`Hard\`
- [ ] A \`DifficultyConfig\` type is defined with fields: \`rows: number\`, \`cols: number\`, \`mines: number\`
- [ ] A \`DIFFICULTY_CONFIG\` constant maps each \`Difficulty\` to its \`DifficultyConfig\`: Easy → 8×8/8, Medium → 12×12/16, Hard → 16×16/32
- [ ] A \`GameStatus\` enum is defined with values: \`Idle\`, \`Playing\`, \`Won\`, \`Lost\`
- [ ] A \`GameState\` type is defined with fields: \`board: Cell[][]\`, \`status: GameStatus\`, \`difficulty: Difficulty\`, \`flagsRemaining: number\`, \`elapsedSeconds: number\`, \`bestTimes: Record<Difficulty, number | null>\`
- [ ] All types are exported from a single \`src/types/index.ts\` barrel file"

echo "✅ Issue 2 created: Type Definitions"

# ─────────────────────────────────────────
# Task 3 — Core Game Logic
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Core Game Logic" \
  --body "Implement all pure functions that power the game rules. These functions are stateless, receive data and return new data, and must be fully unit-tested with Vitest.

## Acceptance Criterias

- [ ] \`createEmptyBoard(rows, cols): Cell[][]\` creates a grid of hidden, mine-free cells
- [ ] \`placeMines(board, mines, safeRow, safeCol): Cell[][]\` randomly distributes mines, guaranteeing the cell at \`(safeRow, safeCol)\` and its 8 neighbours are never mines
- [ ] \`computeAdjacentCounts(board): Cell[][]\` fills the \`adjacentMines\` field for every non-mine cell
- [ ] \`revealCell(board, row, col): Cell[][]\` reveals a single cell; if \`adjacentMines === 0\`, flood-fills recursively to reveal all connected empty cells and their numbered borders
- [ ] \`chordReveal(board, row, col): { board: Cell[][], triggeredMine: boolean }\` reveals all non-flagged neighbours of a number cell; returns \`triggeredMine: true\` if any revealed cell is a mine
- [ ] \`countAdjacentFlags(board, row, col): number\` returns the number of flagged neighbours around a given cell
- [ ] \`checkWin(board): boolean\` returns \`true\` when every non-mine cell has \`state === Revealed\`
- [ ] Unit tests cover: empty board creation, mine placement exclusion zone, adjacency counts, flood-fill reveal, chord reveal hitting a mine, chord reveal not hitting a mine, win detection positive and negative cases"

echo "✅ Issue 3 created: Core Game Logic"

# ─────────────────────────────────────────
# Task 4 — Game State Reducer
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Game State Reducer" \
  --body "Implement the \`gameReducer\` function and its action types that manage all game state transitions. The reducer must be pure and fully unit-tested.

## Acceptance Criterias

- [ ] Action types are defined: \`START_GAME\`, \`REVEAL_CELL\`, \`TOGGLE_FLAG\`, \`CHORD_REVEAL\`, \`TICK\`, \`RESTART\`
- [ ] \`START_GAME\` initialises the board as empty (mines not yet placed) and sets status to \`Idle\`
- [ ] \`REVEAL_CELL\` on the first click places mines (excluding clicked cell), sets status to \`Playing\`, and reveals the clicked cell
- [ ] \`REVEAL_CELL\` on a mine cell sets status to \`Lost\` and triggers the explosion sequence flag on the board
- [ ] \`REVEAL_CELL\` checks win condition after each reveal and sets status to \`Won\` if met; best time is updated in state and persisted to localStorage if it is a new record
- [ ] \`TOGGLE_FLAG\` toggles \`CellState.Flagged\` on a hidden cell; placing a flag is blocked when \`flagsRemaining === 0\`; removing a flag increments \`flagsRemaining\`
- [ ] \`CHORD_REVEAL\` dispatches a chord reveal only when adjacent flag count equals the cell's \`adjacentMines\` value; otherwise sets a \`shakingCell\` coordinate in state for the shake animation
- [ ] \`TICK\` increments \`elapsedSeconds\` by 1 only when status is \`Playing\`
- [ ] \`RESTART\` resets the board and timer but preserves \`difficulty\` and \`bestTimes\`
- [ ] Unit tests cover every action type including edge cases: flagging at cap, chord with mismatched flag count, win on last reveal, best time update"

echo "✅ Issue 4 created: Game State Reducer"

# ─────────────────────────────────────────
# Task 5 — Game Context & Provider
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Game Context & Provider" \
  --body "Wrap the reducer in a React Context so any component in the tree can read state and dispatch actions without prop drilling.

## Acceptance Criterias

- [ ] \`GameContext\` is created with \`React.createContext\` and typed to \`{ state: GameState, dispatch: React.Dispatch<GameAction> }\`
- [ ] \`GameProvider\` component initialises state via \`useReducer(gameReducer, initialState)\` and provides it through \`GameContext\`
- [ ] \`initialState\` loads \`bestTimes\` from localStorage on mount; missing or malformed entries default to \`null\`
- [ ] A \`useGame()\` custom hook is exported; it throws a descriptive error if used outside \`GameProvider\`
- [ ] \`GameProvider\` is mounted at the root of the app in \`main.tsx\`
- [ ] A test verifies that \`useGame()\` returns the correct initial state when wrapped in \`GameProvider\`
- [ ] A test verifies that \`useGame()\` throws when called outside \`GameProvider\`"

echo "✅ Issue 5 created: Game Context & Provider"

# ─────────────────────────────────────────
# Task 6 — Timer Hook
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Timer Hook" \
  --body "Implement a \`useTimer\` custom hook that drives the in-game clock by dispatching \`TICK\` every second.

## Acceptance Criterias

- [ ] \`useTimer()\` sets up a \`setInterval\` that dispatches \`TICK\` every 1000 ms
- [ ] The interval only runs when \`GameStatus\` is \`Playing\`
- [ ] The interval is cleared when status changes to \`Won\`, \`Lost\`, or \`Idle\`
- [ ] The interval is cleared on component unmount to prevent memory leaks
- [ ] Vitest tests use fake timers (\`vi.useFakeTimers\`) to assert that \`TICK\` is dispatched exactly N times after N seconds while \`Playing\`
- [ ] Tests assert the interval does not fire when status is \`Idle\`, \`Won\`, or \`Lost\`"

echo "✅ Issue 6 created: Timer Hook"

# ─────────────────────────────────────────
# Task 7 — Cell Component
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Cell Component" \
  --body "Build the individual \`Cell\` component that renders a single board cell and handles all three mouse interactions.

## Acceptance Criterias

- [ ] The component accepts a \`Cell\` data prop plus \`onLeftClick\`, \`onRightClick\`, \`onMiddleClick\` callback props
- [ ] A hidden cell renders as a raised, clickable square with no content
- [ ] A flagged cell renders the 🚩 emoji and is not left-clickable
- [ ] A revealed empty cell (\`adjacentMines === 0\`) renders as a flat, empty square
- [ ] A revealed number cell renders its \`adjacentMines\` value; each number 1–8 has a distinct colour via Styled Components
- [ ] A revealed mine cell renders the 💣 emoji
- [ ] A wrongly-flagged mine cell (game over state) renders 🚩 with a red background
- [ ] Right-click calls \`onRightClick\` and calls \`event.preventDefault()\` to suppress the browser context menu
- [ ] Middle-click (button === 1) calls \`onMiddleClick\` only on revealed number cells
- [ ] When the \`shaking\` prop is \`true\`, a CSS shake keyframe animation plays on the cell
- [ ] Component tests cover: correct rendering for each cell state, left/right/middle click handlers fire with correct coordinates, shake animation class is applied when \`shaking\` is true"

echo "✅ Issue 7 created: Cell Component"

# ─────────────────────────────────────────
# Task 8 — Board Component
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Board Component" \
  --body "Build the \`Board\` component that renders the full grid and wires cell interactions to the game context dispatcher.

## Acceptance Criterias

- [ ] \`Board\` reads \`state.board\`, \`state.status\`, and \`state.shakingCell\` from \`useGame()\`
- [ ] It renders a CSS grid whose column count matches \`DIFFICULTY_CONFIG[difficulty].cols\`
- [ ] Each cell in the grid renders a \`Cell\` component with the correct props
- [ ] \`onLeftClick(row, col)\` dispatches \`REVEAL_CELL\` unless status is \`Won\` or \`Lost\`
- [ ] \`onRightClick(row, col)\` dispatches \`TOGGLE_FLAG\` unless status is \`Won\` or \`Lost\`
- [ ] \`onMiddleClick(row, col)\` dispatches \`CHORD_REVEAL\` unless status is \`Won\` or \`Lost\`
- [ ] The cell matching \`state.shakingCell\` receives \`shaking={true}\`; \`shakingCell\` is cleared from state after the animation duration (300 ms)
- [ ] During a \`Lost\` game, mines are revealed sequentially with a 120 ms delay between each explosion using a local effect
- [ ] Component tests cover: board renders correct number of cells for each difficulty, click handlers dispatch correct actions, dead board ignores clicks"

echo "✅ Issue 8 created: Board Component"

# ─────────────────────────────────────────
# Task 9 — HUD Component
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "HUD Component" \
  --body "Build the heads-up display bar that shows the difficulty selector, remaining flag count, timer, restart button, and best time.

## Acceptance Criterias

- [ ] The HUD reads \`difficulty\`, \`flagsRemaining\`, \`elapsedSeconds\`, \`status\`, and \`bestTimes\` from \`useGame()\`
- [ ] Timer displays elapsed time in MM:SS format (e.g. \`01:45\`)
- [ ] Timer shows \`00:00\` when status is \`Idle\`
- [ ] Timer freezes on the final value when status is \`Won\` or \`Lost\`
- [ ] The flag counter displays remaining flags as \`🚩 N\`
- [ ] The difficulty selector renders three buttons (\`Easy\`, \`Medium\`, \`Hard\`); the active difficulty is visually highlighted
- [ ] Changing difficulty dispatches \`RESTART\` with the new difficulty and is only enabled when status is \`Idle\`, \`Won\`, or \`Lost\` — disabled while \`Playing\`
- [ ] The restart button dispatches \`RESTART\` at any time
- [ ] Best time for the current difficulty is displayed below the timer in MM:SS format; shows \`--:--\` if no record exists
- [ ] Component tests cover: timer formats \`0\`, \`65\`, and \`3599\` seconds correctly, difficulty buttons highlight correct active level, flag counter reflects state, best time displays \`--:--\` when null"

echo "✅ Issue 9 created: HUD Component"

# ─────────────────────────────────────────
# Task 10 — Win & Loss Overlay
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "Win & Loss Overlay" \
  --body "Build a modal overlay that appears on game completion, showing the outcome, final time, and a prompt to restart.

## Acceptance Criterias

- [ ] The overlay renders only when \`status === Won\` or \`status === Lost\`
- [ ] A \`Won\` overlay displays a victory message and the final time in MM:SS format
- [ ] A \`Won\` overlay highlights if the final time is a new best record for the current difficulty
- [ ] A \`Lost\` overlay displays a game-over message
- [ ] Both overlays contain a \"Play Again\" button that dispatches \`RESTART\`
- [ ] The overlay is centred on screen and rendered above the board using a high \`z-index\`
- [ ] The overlay entrance is animated with a fade-in via Styled Components keyframes
- [ ] Component tests cover: overlay not present during \`Idle\` and \`Playing\`, correct message shown for \`Won\` vs \`Lost\`, \"Play Again\" button dispatches \`RESTART\`"

echo "✅ Issue 10 created: Win & Loss Overlay"

# ─────────────────────────────────────────
# Task 11 — App Assembly & Layout
# ─────────────────────────────────────────
gh issue create \
  --repo "$REPO" \
  --title "App Assembly & Layout" \
  --body "Compose all components into the final \`App\` layout, apply global styles, and ensure the game is fully playable end-to-end.

## Acceptance Criterias

- [ ] \`App\` renders \`GameProvider\` wrapping \`HUD\`, \`Board\`, and \`WinLossOverlay\`
- [ ] A \`GlobalStyle\` Styled Components file resets margins, sets \`box-sizing: border-box\`, and defines a background colour and base font
- [ ] The layout is centred horizontally and vertically on the viewport
- [ ] The board does not overflow the viewport on any of the three grid sizes; it scrolls gracefully if the window is too small
- [ ] Right-clicking anywhere on the board does not open the browser context menu
- [ ] The game is playable on desktop browsers: Chrome, Firefox, and Safari
- [ ] An end-to-end functional test using \`@testing-library/react\` simulates a full Easy game: start → reveal safe cells → win → restart
- [ ] An end-to-end functional test simulates hitting a mine on the first non-safe click after first-click safety"

echo "✅ Issue 11 created: App Assembly & Layout"

echo ""
echo "🎉 All 11 issues created successfully in $REPO"
