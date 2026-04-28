import { test, expect } from "@playwright/test";

/**
 * Hub coverage spec — emitted by /gabe-mockup M0 template scaffold.
 *
 * Tests cover the centralized navigation pattern emitted by the principal hub
 * template (templates/mockup/index.html) and section sub-hub template
 * (templates/mockup/section-index.html):
 *
 *   /index.html (top hub)         — section cards, no breadcrumb (it IS home)
 *   /<section>/index.html         — sub-hub + "← Mockups home" breadcrumb
 *   /<section>/<page>.html        — page + "← <Section> index" breadcrumb
 *
 * Breadcrumb logic lives in tweaks.js (section-aware via location.pathname).
 *
 * The principal hub starts with 6 placeholder section cards. As recipes (M2/M3/M4)
 * emit sections, they flip data-status from "placeholder" → "live". This spec
 * verifies the live cards point to resolvable destinations and the placeholder
 * cards remain non-broken.
 */

const EXPECTED_TOP_SECTIONS = [
  "design-system",
  "atoms",
  "molecules",
  "flows",
  "screens",
  "handoff",
];

test.describe("Top hub (/index.html)", () => {
  test("renders all 6 canonical section cards", async ({ page }) => {
    await page.goto("/index.html");
    const cards = page.locator(".section-card");
    await expect(cards).toHaveCount(6);

    const sections = await page.locator(".section-card").evaluateAll((els) =>
      els.map((el) => el.getAttribute("data-section"))
    );
    expect(sections.sort()).toEqual([...EXPECTED_TOP_SECTIONS].sort());
  });

  test("each section card has data-status (live OR placeholder)", async ({ page }) => {
    await page.goto("/index.html");
    const statuses = await page.locator(".section-card").evaluateAll((els) =>
      els.map((el) => el.getAttribute("data-status"))
    );
    for (const status of statuses) {
      expect(status).toMatch(/^(live|placeholder)$/);
    }
  });

  test("top hub does NOT inject the breadcrumb (it IS home)", async ({ page }) => {
    await page.goto("/index.html");
    await expect(page.locator("#tweaks-panel")).toBeVisible();
    await expect(page.locator(".tweaks__breadcrumb")).toHaveCount(0);
  });

  test("live section cards link to resolvable destinations", async ({ page, request }) => {
    await page.goto("/index.html");
    const liveCards = page.locator('.section-card[data-status="live"]');
    const liveCount = await liveCards.count();

    // Fresh-scaffold projects have zero live sections — skip rather than fail
    if (liveCount === 0) test.skip(true, "no live sections yet (fresh scaffold)");

    const hrefs = await liveCards.evaluateAll((els) =>
      els.map((el) => (el as HTMLAnchorElement).getAttribute("href"))
    );
    for (const href of hrefs) {
      expect(href, `live card href: ${href}`).toBeTruthy();
      expect(href, `live card href should not be #: ${href}`).not.toBe("#");
      const response = await request.get(`/${href}`);
      expect(response.status(), `${href} HTTP status`).toBe(200);
    }
  });

  test("placeholder cards have status badge", async ({ page }) => {
    await page.goto("/index.html");
    const placeholderCards = page.locator('.section-card[data-status="placeholder"]');
    const count = await placeholderCards.count();
    if (count === 0) test.skip(true, "no placeholders left (all sections live)");
    for (let i = 0; i < count; i++) {
      await expect(placeholderCards.nth(i).locator(".status-badge--placeholder")).toBeVisible();
    }
  });
});

test.describe("Section sub-hubs", () => {
  // Recipe contract: when a section emits, it adds its slug to this list.
  // Empty array = fresh scaffold (no sections live yet) → tests skip.
  // Filled by /gabe-mockup recipes when sections emit.
  const LIVE_SECTIONS: string[] = [
    // {{LIVE_SECTIONS}} - filled by recipe. e.g. "atoms", "molecules", "flows"
  ];

  for (const section of LIVE_SECTIONS) {
    test.describe(`${section} sub-hub (/${section}/index.html)`, () => {
      test("renders + injects '← Mockups home' breadcrumb", async ({ page }) => {
        await page.goto(`/${section}/index.html`);
        await expect(page.locator("#tweaks-panel")).toBeVisible();
        const breadcrumb = page.locator(".tweaks__breadcrumb");
        await expect(breadcrumb).toBeVisible();
        await expect(breadcrumb).toHaveAttribute("href", "../index.html");
        await expect(breadcrumb).toHaveText(/Mockups home/);
      });

      test("breadcrumb returns to top hub", async ({ page }) => {
        await page.goto(`/${section}/index.html`);
        await page.locator(".tweaks__breadcrumb").click();
        await expect(page).toHaveURL(/\/index\.html$/);
        await expect(page.locator(".tweaks__breadcrumb")).toHaveCount(0);
      });
    });
  }

  test("guard: skip if no sections live yet (fresh scaffold)", async () => {
    if (LIVE_SECTIONS.length === 0) test.skip(true, "no sections built yet — recipe will populate LIVE_SECTIONS");
  });
});
