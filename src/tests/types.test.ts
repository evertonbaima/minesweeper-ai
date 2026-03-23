import { describe, it, expect } from "vitest";
import { CellState, Difficulty, GameStatus, DIFFICULTY_CONFIG } from "../types";

describe("CellState enum", () => {
  it("has Hidden, Revealed and Flagged values", () => {
    expect(CellState.Hidden).toBe("Hidden");
    expect(CellState.Revealed).toBe("Revealed");
    expect(CellState.Flagged).toBe("Flagged");
  });
});

describe("Difficulty enum", () => {
  it("has Easy, Medium and Hard values", () => {
    expect(Difficulty.Easy).toBe("Easy");
    expect(Difficulty.Medium).toBe("Medium");
    expect(Difficulty.Hard).toBe("Hard");
  });
});

describe("GameStatus enum", () => {
  it("has Idle, Playing, Won and Lost values", () => {
    expect(GameStatus.Idle).toBe("Idle");
    expect(GameStatus.Playing).toBe("Playing");
    expect(GameStatus.Won).toBe("Won");
    expect(GameStatus.Lost).toBe("Lost");
  });
});

describe("DIFFICULTY_CONFIG", () => {
  it("maps Easy to 8x8 grid with 8 mines", () => {
    expect(DIFFICULTY_CONFIG[Difficulty.Easy]).toEqual({
      rows: 8,
      cols: 8,
      mines: 8,
    });
  });

  it("maps Medium to 12x12 grid with 16 mines", () => {
    expect(DIFFICULTY_CONFIG[Difficulty.Medium]).toEqual({
      rows: 12,
      cols: 12,
      mines: 16,
    });
  });

  it("maps Hard to 16x16 grid with 32 mines", () => {
    expect(DIFFICULTY_CONFIG[Difficulty.Hard]).toEqual({
      rows: 16,
      cols: 16,
      mines: 32,
    });
  });

  it("covers all Difficulty values", () => {
    const configuredDifficulties = Object.keys(DIFFICULTY_CONFIG);
    const allDifficulties = Object.values(Difficulty) as string[];
    configuredDifficulties.sort((a, b) => a.localeCompare(b));
    allDifficulties.sort((a, b) => a.localeCompare(b));
    expect(configuredDifficulties).toEqual(allDifficulties);
  });
});
