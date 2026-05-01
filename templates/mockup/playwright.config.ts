import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright config — emitted by /gabe-mockup template scaffold.
 *
 * Tests live under tests/mockups/. Static server serves docs/mockups/ on port
 * 4173 (avoids file:// protocol restrictions on cssRules introspection +
 * @import resolution). Single chromium project; no cross-browser by default.
 *
 * Customize: change port if 4173 conflicts; add more projects in `projects: []`.
 */
export default defineConfig({
  testDir: "./tests/mockups",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? "list" : "list",
  use: {
    baseURL: "http://localhost:4173",
    trace: "on-first-retry",
    video: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  webServer: {
    command: "npx http-server docs/mockups -p 4173 -c-1 --silent",
    url: "http://localhost:4173/index.html",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
