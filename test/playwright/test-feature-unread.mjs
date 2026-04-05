/**
 * Playwright E2E test: Unread Message Separator
 *
 * Tests that:
 * 1. Login as arif via API
 * 2. Get a channel and its last read timestamp
 * 3. Post a new message as demo (creating an unread)
 * 4. Login arif in browser
 * 5. Open the channel
 * 6. Verify the page has loaded (screenshot)
 * 7. Post another message via API from user1
 * 8. Wait 3 seconds, take screenshot (should show new message arriving with animation)
 */

import { chromium } from 'playwright';
import { strict as assert } from 'node:assert';
import fs from 'node:fs';
import path from 'node:path';

const API = 'https://mm.vista.inum.com/api/v4';
const APP_URL = 'https://app.vista.inum.com';

const ARIF_LOGIN = 'arif';
const ARIF_PASS = 'inum2024!';
const DEMO_LOGIN = 'demo';
const DEMO_PASS = 'inum2024!';

const SCREENSHOT_DIR = path.resolve('screenshots');
if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });

async function apiLogin(loginId, password) {
  const res = await fetch(`${API}/users/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ login_id: loginId, password }),
  });
  assert.ok(res.ok, `Login failed for ${loginId}: ${res.status}`);
  const token = res.headers.get('token');
  const user = await res.json();
  return { token, userId: user.id, username: user.username };
}

async function apiGet(token, endpoint) {
  const res = await fetch(`${API}${endpoint}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  assert.ok(res.ok, `GET ${endpoint} failed: ${res.status}`);
  return res.json();
}

async function apiPost(token, endpoint, body) {
  const res = await fetch(`${API}${endpoint}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  assert.ok(res.ok, `POST ${endpoint} failed: ${res.status}`);
  return res.json();
}

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  console.log('=== Unread Message Separator E2E Test ===\n');

  // Step 1: Login as arif via API
  console.log('1. Logging in as arif via API...');
  const arif = await apiLogin(ARIF_LOGIN, ARIF_PASS);
  console.log(`   Arif userId: ${arif.userId}`);

  // Step 2: Get arif's channels and pick one with messages
  console.log('2. Getting channels...');
  const teams = await apiGet(arif.token, '/users/me/teams');
  assert.ok(teams.length > 0, 'No teams found');
  const teamId = teams[0].id;

  const channels = await apiGet(arif.token, `/users/me/teams/${teamId}/channels`);
  // Find a non-DM channel or the first channel
  const targetChannel = channels.find((ch) => ch.type === 'O') || channels[0];
  assert.ok(targetChannel, 'No channel found');
  console.log(`   Target channel: ${targetChannel.display_name} (${targetChannel.id})`);

  // Get last read timestamp
  const member = await apiGet(arif.token, `/channels/${targetChannel.id}/members/${arif.userId}`);
  const lastViewedAt = member.last_viewed_at || 0;
  console.log(`   Last viewed at: ${lastViewedAt} (${new Date(lastViewedAt).toISOString()})`);

  // Step 3: Post a message as demo to create an unread for arif
  console.log('3. Logging in as demo and posting a message...');
  const demo = await apiLogin(DEMO_LOGIN, DEMO_PASS);
  const timestamp = new Date().toISOString().slice(11, 19);
  const unreadMsg = `Unread test message at ${timestamp}`;
  await apiPost(demo.token, '/posts', {
    channel_id: targetChannel.id,
    message: unreadMsg,
  });
  console.log(`   Posted: "${unreadMsg}"`);

  // Step 4: Login arif in browser
  console.log('4. Launching browser and logging in as arif...');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();

  await page.goto(APP_URL, { waitUntil: 'networkidle', timeout: 30000 });
  await sleep(2000);

  // Fill login form
  const emailField = page.locator('input[type="text"], input[type="email"]').first();
  const passField = page.locator('input[type="password"]').first();
  const loginBtn = page.locator('button:has-text("Sign In"), button:has-text("Log In"), button[type="submit"]').first();

  if (await emailField.isVisible({ timeout: 5000 }).catch(() => false)) {
    await emailField.fill(ARIF_LOGIN);
    await passField.fill(ARIF_PASS);
    await loginBtn.click();
    console.log('   Login form submitted');
    await sleep(3000);
  } else {
    console.log('   Already logged in or different UI state');
  }

  // Step 5: Navigate to the channel
  console.log('5. Opening channel...');
  // Try clicking the channel in the list
  const channelLink = page.locator(`text=${targetChannel.display_name}`).first();
  if (await channelLink.isVisible({ timeout: 5000 }).catch(() => false)) {
    await channelLink.click();
    await sleep(2000);
  } else {
    console.log('   Channel link not visible, navigating via URL...');
    // Try direct navigation
    await page.goto(`${APP_URL}/#/chat?channelId=${targetChannel.id}&channelName=${encodeURIComponent(targetChannel.display_name)}`, {
      waitUntil: 'networkidle',
      timeout: 15000,
    });
    await sleep(2000);
  }

  // Step 6: Verify page loaded - screenshot
  console.log('6. Taking screenshot of loaded chat...');
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'unread-01-chat-loaded.png') });
  console.log('   Screenshot saved: unread-01-chat-loaded.png');

  // Verify the unread message is visible
  const msgVisible = await page.locator(`text=${unreadMsg}`).isVisible({ timeout: 5000 }).catch(() => false);
  console.log(`   Unread message visible: ${msgVisible}`);

  // Check for "New Messages" separator
  const separatorVisible = await page.locator('text=New Messages').isVisible({ timeout: 3000 }).catch(() => false);
  console.log(`   Unread separator visible: ${separatorVisible}`);

  // Step 7: Post another message via API from demo
  console.log('7. Posting another message from demo...');
  const timestamp2 = new Date().toISOString().slice(11, 19);
  const newMsg = `Live message at ${timestamp2}`;
  await apiPost(demo.token, '/posts', {
    channel_id: targetChannel.id,
    message: newMsg,
  });
  console.log(`   Posted: "${newMsg}"`);

  // Step 8: Wait 3 seconds, take screenshot
  console.log('8. Waiting 3 seconds for animation...');
  await sleep(3000);
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'unread-02-new-message-arrived.png') });
  console.log('   Screenshot saved: unread-02-new-message-arrived.png');

  // Check new message appeared
  const newMsgVisible = await page.locator(`text=${newMsg}`).isVisible({ timeout: 3000 }).catch(() => false);
  console.log(`   New message visible: ${newMsgVisible}`);

  await browser.close();

  console.log('\n=== Test Complete ===');
  console.log(`Screenshots: ${SCREENSHOT_DIR}/`);
}

main().catch((err) => {
  console.error('Test failed:', err);
  process.exit(1);
});
