import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import App from "../App";

describe("Project scaffold", () => {
  it("renders the app without crashing", () => {
    render(<App />);
    expect(screen.getByText("MINESWEEPER")).toBeInTheDocument();
  });

  it("jest-dom matchers are available", () => {
    render(<App />);
    const el = screen.getByText("MINESWEEPER");
    expect(el).toBeVisible();
    expect(el).not.toBeDisabled();
  });
});
