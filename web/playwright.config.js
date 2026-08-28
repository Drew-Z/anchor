import { defineConfig } from '@playwright/test';

const productionBaseUrl = process.env.ANCHOR_BASE_URL;

export default defineConfig({
  testDir: './tests',
  testMatch: '**/*.spec.js',
  outputDir: './test-results/run',
  timeout: 30_000,
  expect: { timeout: 8_000 },
  use: {
    baseURL: productionBaseUrl ?? 'http://127.0.0.1:4173',
    locale: 'en-US',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
  webServer: productionBaseUrl ? undefined : {
    command: 'npm run serve',
    url: 'http://127.0.0.1:4173',
    reuseExistingServer: true,
    timeout: 30_000,
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
});
