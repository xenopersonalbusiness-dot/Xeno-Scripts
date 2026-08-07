// ====================== CONFIG ======================
// 1. Enable "Server Widget" in Discord: Server Settings → Widget
// 2. Copy your Server ID (right-click server icon → Copy Server ID)
const GUILD_ID = "1421020869957910571";

// 3. After deploying the Cloudflare Worker (see /discord-worker/README.md),
//    paste its URL here, e.g. "https://access-keys.yourname.workers.dev"
const WORKER_URL = "YOUR_WORKER_URL_HERE";

// 4. Add one entry per game here. placeId is the number in a game's Roblox URL
//    (roblox.com/games/PLACE_ID/game-name). Name + front page image are fetched
//    automatically from Roblox using that ID — you only need to supply the loader.
const GAMES = [
  {
    placeId: "PLACE_ID_HERE",
    loaderScript: `-- paste your loader script for this game here`,
  },
  // { placeId: "ANOTHER_PLACE_ID", loaderScript: `-- ...` },
];
// ======================================================

const KEY_LIFETIME_MS = 24 * 60 * 60 * 1000; // 24 hours

// ---------- Clock ----------
function tickClock() {
  document.getElementById("clock").textContent = new Date().toLocaleTimeString();
}
setInterval(tickClock, 1000);
tickClock();

// ---------- Discord server info ----------
// Online count + name + invite come from Discord's public widget.json (no auth needed).
// Real total member count needs a bot token (Discord doesn't expose it publicly),
// so that piece comes from your Worker's /stats endpoint. See discord-worker/README.md.
async function loadServerInfo() {
  const nameEl = document.getElementById("serverName");
  const subEl = document.getElementById("serverSub");
  const onlineEl = document.getElementById("statOnline");
  const totalEl = document.getElementById("statTotal");
  const joinBtn = document.getElementById("joinBtn");
  const dot = document.getElementById("statusDot");

  if (!GUILD_ID || GUILD_ID === "YOUR_GUILD_ID_HERE") {
    nameEl.textContent = "SET GUILD_ID IN script.js";
    subEl.textContent = "Enable the widget in Discord server settings, then paste your Server ID above.";
    dot.style.animation = "none";
    return;
  }

  try {
    const res = await fetch(`https://discord.com/api/guilds/${GUILD_ID}/widget.json`);
    if (!res.ok) throw new Error("widget disabled or invalid guild id");
    const data = await res.json();

    nameEl.textContent = data.name || "UNNAMED SERVER";
    onlineEl.textContent = data.presence_count ?? "—";
    joinBtn.href = data.instant_invite || "#";
    subEl.textContent = `${data.presence_count ?? 0} members active right now`;
  } catch (err) {
    nameEl.textContent = "COULD NOT LOAD SERVER";
    subEl.textContent = "Check that the widget is enabled and the Guild ID is correct.";
    dot.style.animation = "none";
    console.error(err);
    return;
  }

  // Real total member count, via the Worker (needs the bot-token setup in the README).
  if (WORKER_URL && WORKER_URL !== "YOUR_WORKER_URL_HERE") {
    try {
      const statsRes = await fetch(`${WORKER_URL}/stats?guild=${GUILD_ID}`);
      if (statsRes.ok) {
        const stats = await statsRes.json();
        totalEl.textContent = stats.approximate_member_count ?? "—";
      } else {
        totalEl.textContent = "—";
      }
    } catch {
      totalEl.textContent = "—";
    }
  }
}
loadServerInfo();
setInterval(loadServerInfo, 30000); // refresh every 30s

// ---------- Key generation ----------
const generateBtn = document.getElementById("generateBtn");
const copyBtn = document.getElementById("copyBtn");
const keyValueEl = document.getElementById("keyValue");
const keyExpiresEl = document.getElementById("keyExpires");
const keyBarFill = document.getElementById("keyBarFill");
const accessNote = document.getElementById("accessNote");

let countdownTimer = null;

function formatTimeLeft(ms) {
  if (ms <= 0) return "expired";
  const h = Math.floor(ms / 3.6e6);
  const m = Math.floor((ms % 3.6e6) / 6e4);
  const s = Math.floor((ms % 6e4) / 1000);
  return `${h}h ${m}m ${s}s`;
}

function renderKey(key, expiresAt) {
  keyValueEl.textContent = key;
  copyBtn.disabled = false;

  clearInterval(countdownTimer);
  countdownTimer = setInterval(() => {
    const remaining = expiresAt - Date.now();
    if (remaining <= 0) {
      keyExpiresEl.textContent = "EXPIRED";
      keyBarFill.style.width = "0%";
      accessNote.textContent = "This key has expired. Generate a new one.";
      copyBtn.disabled = true;
      clearInterval(countdownTimer);
      return;
    }
    keyExpiresEl.textContent = formatTimeLeft(remaining);
    keyBarFill.style.width = `${(remaining / KEY_LIFETIME_MS) * 100}%`;
  }, 1000);
}

async function generateKey() {
  if (!WORKER_URL || WORKER_URL === "YOUR_WORKER_URL_HERE") {
    accessNote.textContent = "Set WORKER_URL in script.js first (see discord-worker/README.md).";
    return;
  }

  generateBtn.disabled = true;
  accessNote.textContent = "Requesting key…";

  try {
    const res = await fetch(`${WORKER_URL}/generate`, { method: "POST" });
    if (!res.ok) throw new Error("worker error");
    const data = await res.json(); // { key, expiresAt }

    localStorage.setItem("access_key", JSON.stringify(data));
    renderKey(data.key, data.expiresAt);
    accessNote.textContent = "Key issued. Valid for 24 hours from now.";
  } catch (err) {
    accessNote.textContent = "Couldn't reach the key server. Try again shortly.";
    console.error(err);
  } finally {
    generateBtn.disabled = false;
  }
}

copyBtn.addEventListener("click", async () => {
  const key = keyValueEl.textContent;
  await navigator.clipboard.writeText(key);
  accessNote.textContent = "Key copied to clipboard.";
});

generateBtn.addEventListener("click", generateKey);

// Restore an unexpired key on page load
(function restoreKey() {
  const saved = localStorage.getItem("access_key");
  if (!saved) return;
  try {
    const { key, expiresAt } = JSON.parse(saved);
    if (expiresAt > Date.now()) {
      renderKey(key, expiresAt);
      accessNote.textContent = "Restored your active key.";
    } else {
      localStorage.removeItem("access_key");
    }
  } catch {
    localStorage.removeItem("access_key");
  }
})();

// ---------- Sound effects (synthesized, no audio files needed) ----------
let audioCtx = null;
let soundOn = localStorage.getItem("sfx_on") !== "off";
const soundToggle = document.getElementById("soundToggle");
soundToggle.textContent = `SFX: ${soundOn ? "ON" : "OFF"}`;
soundToggle.setAttribute("aria-pressed", String(soundOn));

function ensureAudio() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === "suspended") audioCtx.resume();
  return audioCtx;
}

function beep({ freq = 440, duration = 0.06, type = "square", gain = 0.05 } = {}) {
  if (!soundOn) return;
  const ctx = ensureAudio();
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  g.gain.value = gain;
  g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + duration);
  osc.connect(g).connect(ctx.destination);
  osc.start();
  osc.stop(ctx.currentTime + duration);
}

const sfxHover = () => beep({ freq: 820, duration: 0.03, gain: 0.02 });
const sfxClick = () => beep({ freq: 220, duration: 0.09, gain: 0.06, type: "square" });
const sfxSuccess = () => {
  beep({ freq: 440, duration: 0.05, gain: 0.05 });
  setTimeout(() => beep({ freq: 660, duration: 0.08, gain: 0.05 }), 60);
};

// Delegated so it also covers buttons/cards added later (cube grid, modal)
document.addEventListener("mouseover", e => {
  if (e.target.closest("button, a.fx")) sfxHover();
});
document.addEventListener("click", e => {
  if (e.target.closest("button, a.fx")) sfxClick();
});

// swap the click blip on Generate for a two-note success chime once a key lands
generateBtn.addEventListener("click", () => {
  const check = setInterval(() => {
    if (!generateBtn.disabled) {
      clearInterval(check);
      if (keyValueEl.textContent !== "••••••••••••••••") sfxSuccess();
    }
  }, 150);
});

soundToggle.addEventListener("click", () => {
  soundOn = !soundOn;
  localStorage.setItem("sfx_on", soundOn ? "on" : "off");
  soundToggle.textContent = `SFX: ${soundOn ? "ON" : "OFF"}`;
  soundToggle.setAttribute("aria-pressed", String(soundOn));
  if (soundOn) beep({ freq: 660, duration: 0.05 });
});

// ---------- Custom cursor: dot + trailing ring ----------
(function cursorFx() {
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const isFinePointer = window.matchMedia("(pointer: fine)").matches;
  if (reduceMotion || !isFinePointer) return;

  const canvas = document.getElementById("cursorFx");
  const ctx = canvas.getContext("2d");
  let w, h;
  function resize() {
    w = canvas.width = window.innerWidth;
    h = canvas.height = window.innerHeight;
  }
  resize();
  window.addEventListener("resize", resize);

  const mouse = { x: w / 2, y: h / 2 };
  const ring = { x: mouse.x, y: mouse.y };
  const trail = [];
  const MAX_TRAIL = 10;

  window.addEventListener("mousemove", e => {
    mouse.x = e.clientX;
    mouse.y = e.clientY;
    trail.push({ x: e.clientX, y: e.clientY, life: 1 });
    if (trail.length > MAX_TRAIL) trail.shift();
  });

  function draw() {
    ctx.clearRect(0, 0, w, h);

    // fading trail dots
    trail.forEach((p, i) => {
      p.life -= 0.06;
      const r = 2 + (i / MAX_TRAIL) * 2;
      ctx.beginPath();
      ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(236, 236, 230, ${Math.max(p.life, 0) * 0.35})`;
      ctx.fill();
    });
    for (let i = trail.length - 1; i >= 0; i--) {
      if (trail[i].life <= 0) trail.splice(i, 1);
    }

    // lagging outer ring
    ring.x += (mouse.x - ring.x) * 0.18;
    ring.y += (mouse.y - ring.y) * 0.18;
    ctx.beginPath();
    ctx.arc(ring.x, ring.y, 14, 0, Math.PI * 2);
    ctx.strokeStyle = "rgba(236, 236, 230, 0.5)";
    ctx.lineWidth = 1;
    ctx.stroke();

    // sharp core dot
    ctx.beginPath();
    ctx.arc(mouse.x, mouse.y, 2.5, 0, Math.PI * 2);
    ctx.fillStyle = "#ececE6";
    ctx.fill();

    requestAnimationFrame(draw);
  }
  draw();

  // ring snaps bigger over interactive elements
  document.querySelectorAll("button, a").forEach(el => {
    el.addEventListener("mouseenter", () => canvas.classList.add("cursor-hover"));
    el.addEventListener("mouseleave", () => canvas.classList.remove("cursor-hover"));
  });
})();

// ---------- Click ripple, for every button/link marked .fx ----------
document.addEventListener("click", e => {
  const el = e.target.closest(".fx");
  if (!el) return;

  const rect = el.getBoundingClientRect();
  const size = Math.max(rect.width, rect.height) * 1.6;
  const ripple = document.createElement("span");
  ripple.className = "ripple";
  ripple.style.width = ripple.style.height = `${size}px`;
  ripple.style.left = `${e.clientX - rect.left - size / 2}px`;
  ripple.style.top = `${e.clientY - rect.top - size / 2}px`;
  el.appendChild(ripple);
  ripple.addEventListener("animationend", () => ripple.remove());
});

// ---------- Scripts section: cube grid + modal ----------
const cubeGrid = document.getElementById("cubeGrid");
const scriptModal = document.getElementById("scriptModal");
const modalBackdrop = document.getElementById("modalBackdrop");
const modalClose = document.getElementById("modalClose");
const modalImage = document.getElementById("modalImage");
const modalGameName = document.getElementById("modalGameName");
const modalScriptCode = document.getElementById("modalScriptCode");
const copyScriptBtn = document.getElementById("copyScriptBtn");

async function fetchGameInfo(placeId) {
  if (!WORKER_URL || WORKER_URL === "YOUR_WORKER_URL_HERE") return null;
  try {
    const res = await fetch(`${WORKER_URL}/roblox-game?placeId=${placeId}`);
    if (!res.ok) return null;
    return await res.json(); // { name, image, playing }
  } catch {
    return null;
  }
}

function openScriptModal(game, info) {
  modalGameName.textContent = info?.name || `Game ${game.placeId}`;
  modalImage.src = info?.image || "";
  modalImage.alt = info?.name || "Game thumbnail";
  modalImage.style.display = info?.image ? "block" : "none";
  modalScriptCode.textContent = game.loaderScript;
  scriptModal.classList.add("open");
  scriptModal.setAttribute("aria-hidden", "false");
}

function closeScriptModal() {
  scriptModal.classList.remove("open");
  scriptModal.setAttribute("aria-hidden", "true");
}

modalBackdrop.addEventListener("click", closeScriptModal);
modalClose.addEventListener("click", closeScriptModal);
document.addEventListener("keydown", e => {
  if (e.key === "Escape") closeScriptModal();
});

copyScriptBtn.addEventListener("click", async () => {
  await navigator.clipboard.writeText(modalScriptCode.textContent);
  const original = copyScriptBtn.textContent;
  copyScriptBtn.textContent = "Copied!";
  setTimeout(() => (copyScriptBtn.textContent = original), 1500);
});

async function renderCubes() {
  if (!GAMES.length) return;

  cubeGrid.innerHTML = "";

  for (const game of GAMES) {
    const cube = document.createElement("button");
    cube.className = "cube fx";
    cube.innerHTML = `
      <div class="cube-placeholder">LOADING…</div>
    `;
    cubeGrid.appendChild(cube);

    const info = await fetchGameInfo(game.placeId);

    cube.innerHTML = `
      ${info?.image ? `<img class="cube-image" src="${info.image}" alt="${info.name || ""}">` : ""}
      <span class="cube-tag">Updated</span>
      <div class="cube-overlay">
        <span class="cube-name">${info?.name || `Game ${game.placeId}`}</span>
      </div>
    `;

    cube.addEventListener("click", () => openScriptModal(game, info));
  }
}
renderCubes();
