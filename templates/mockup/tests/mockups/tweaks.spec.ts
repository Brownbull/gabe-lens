import { test, expect } from "@playwright/test";

/**
 * Tweaks panel coverage spec — emitted by /gabe-mockup M0 template scaffold.
 *
 * Strong visible-effect assertions — catches the "JS works but CSS doesn't react"
 * regression class that prompted this harness. Tests run against the principal
 * hub (/index.html) which always exists after M0.
 *
 * Note on localStorage: tweaks.js persists state across reloads via the
 * `gabe-mockup-tweaks-v1` localStorage key. Each test starts with a clean slate.
 */

test.describe("Tweaks panel — boot + state", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/index.html");
    await page.evaluate(() => window.localStorage.clear());
    await page.reload();
    await expect(page.locator("#tweaks-panel")).toBeVisible();
    // Wait for tweaks.js to detect themes from loaded stylesheets and render chips
    await expect(page.locator('.tweaks__chip[data-act="theme"]')).not.toHaveCount(0);
  });

  test("default viewport is 'desktop'", async ({ page }) => {
    await expect(page.locator("body")).toHaveAttribute("data-viewport", "desktop");
  });

  test("loadState normalizer maps stale theme:'default' → first detected theme", async ({ page }) => {
    // Plant legacy localStorage value, reload, verify migration ran
    await page.evaluate(() => {
      window.localStorage.setItem(
        "gabe-mockup-tweaks-v1",
        JSON.stringify({ theme: "default", mode: "light" })
      );
    });
    await page.reload();
    await expect(page.locator("#tweaks-panel")).toBeVisible();
    const theme = await page.evaluate(() => document.body.getAttribute("data-theme"));
    expect(theme, "stale 'default' should have been replaced").not.toBe("default");
  });

  test("collapse toggle hides .tweaks__body and shrinks panel width", async ({ page }) => {
    await expect(page.locator("#tweaks-panel .tweaks__body")).toBeVisible();
    const widthBefore = await page.locator("#tweaks-panel").evaluate((el) => el.getBoundingClientRect().width);
    expect(widthBefore).toBeGreaterThan(200);

    await page.locator('[data-act="collapse"]').click();
    await expect(page.locator("body")).toHaveClass(/tweaks-collapsed/);
    await expect
      .poll(async () => page.locator("#tweaks-panel").evaluate((el) => el.getBoundingClientRect().width), {
        timeout: 2000,
      })
      .toBeLessThan(80);

    await page.locator('[data-act="collapse"]').click();
    await expect(page.locator("body")).not.toHaveClass(/tweaks-collapsed/);
  });

  test("clicking the font <select> does NOT re-render the panel (dropdown stays open)", async ({ page }) => {
    // Tag the select with a sentinel; if the panel re-renders, the select is replaced.
    await page.locator('select[data-act="font"]').evaluate((el) => {
      el.setAttribute("data-render-sentinel", "before-click");
    });
    await page.locator('select[data-act="font"]').click();
    const sentinelAfter = await page
      .locator('select[data-act="font"]')
      .getAttribute("data-render-sentinel");
    expect(sentinelAfter).toBe("before-click");
  });
});

test.describe("Tweaks panel — theme + font visible effects", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/index.html");
    await page.evaluate(() => window.localStorage.clear());
    await page.reload();
    await expect(page.locator("#tweaks-panel")).toBeVisible();
  });

  test("dark mode toggle changes body background color", async ({ page }) => {
    // Project-agnostic assertion: switching to dark mode produces a different
    // computed body background-color than the light default. Strong enough to
    // catch CSS-doesn't-react regressions; loose enough to work with any theme.
    const themeChips = page.locator('.tweaks__chip[data-act="theme"]');
    const themeCount = await themeChips.count();
    if (themeCount === 0) test.skip(true, "no themes detected — project's canonical CSS has no [data-theme] rules");

    const bgLight = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);

    // Use the first theme + dark mode (project-agnostic)
    const firstTheme = await themeChips.first().getAttribute("data-val");
    if (firstTheme) {
      await page.locator(`.tweaks__chip[data-act="theme"][data-val="${firstTheme}"]`).click();
    }
    await page.locator('.tweaks__chip[data-act="mode"][data-val="dark"]').click();

    await expect(page.locator("body")).toHaveAttribute("data-mode", "dark");

    await expect
      .poll(async () => page.evaluate(() => getComputedStyle(document.body).backgroundColor), {
        timeout: 2000,
      })
      .not.toBe(bgLight);
  });

  test("font picker exposes ≥1 option + switches body font-family", async ({ page }) => {
    const opts = await page.locator('select[data-act="font"] option').evaluateAll((els) =>
      els.map((el) => (el as HTMLOptionElement).value)
    );
    expect(opts.length, "font select should have at least one option").toBeGreaterThanOrEqual(1);

    if (opts.length < 2) test.skip(true, "only one font registered — can't test switching");

    const beforeFont = await page.evaluate(() => getComputedStyle(document.body).fontFamily);

    // Pick the second option (skip 'default' which is the same as no override)
    const targetFont = opts.find((o) => o !== "default") ?? opts[1];
    await page.locator('select[data-act="font"]').selectOption(targetFont);
    await expect(page.locator("body")).toHaveAttribute("data-font", targetFont);

    const afterFont = await page.evaluate(() => getComputedStyle(document.body).fontFamily);
    expect(afterFont).not.toBe(beforeFont);
  });
});
