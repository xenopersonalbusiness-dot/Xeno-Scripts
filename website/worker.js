// Cloudflare Worker — free tier, no server to maintain.
// Requires one KV namespace bound as "KEYS" (see wrangler.toml).

const KEY_TTL_SECONDS = 24 * 60 * 60; // 24 hours

// Restrict which sites can call this worker. Add your GitHub Pages URL.
const ALLOWED_ORIGINS = [
  "https://YOUR-USERNAME.github.io",
  "http://localhost:3000", // handy for local testing
];

function corsHeaders(origin) {
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}

function randomKey() {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  return Array.from(bytes, b => b.toString(16).padStart(2, "0")).join("");
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin") || "";
    const headers = { "Content-Type": "application/json", ...corsHeaders(origin) };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers });
    }

    // POST /generate — issue a new key
    if (url.pathname === "/generate" && request.method === "POST") {
      const key = randomKey();
      const expiresAt = Date.now() + KEY_TTL_SECONDS * 1000;

      await env.KEYS.put(key, JSON.stringify({ issuedAt: Date.now(), expiresAt }), {
        expirationTtl: KEY_TTL_SECONDS,
      });

      return new Response(JSON.stringify({ key, expiresAt }), { headers });
    }

    // GET /stats?guild=xxxx — real member count (widget.json only gives online count)
    // Requires a DISCORD_BOT_TOKEN secret and the bot to be a member of the server.
    if (url.pathname === "/stats" && request.method === "GET") {
      const guildId = url.searchParams.get("guild");
      if (!guildId) {
        return new Response(JSON.stringify({ error: "missing guild id" }), { status: 400, headers });
      }
      if (!env.DISCORD_BOT_TOKEN) {
        return new Response(JSON.stringify({ error: "bot token not configured" }), { status: 501, headers });
      }

      const discordRes = await fetch(
        `https://discord.com/api/v10/guilds/${guildId}?with_counts=true`,
        { headers: { Authorization: `Bot ${env.DISCORD_BOT_TOKEN}` } }
      );

      if (!discordRes.ok) {
        return new Response(JSON.stringify({ error: "discord api error" }), { status: 502, headers });
      }

      const guild = await discordRes.json();
      return new Response(
        JSON.stringify({
          approximate_member_count: guild.approximate_member_count,
          approximate_presence_count: guild.approximate_presence_count,
        }),
        { headers }
      );
    }

    // GET /roblox-game?placeId=xxxx — game name + front page image, by place ID
    // Runs server-side because Roblox's API doesn't allow browser-origin requests.
    if (url.pathname === "/roblox-game" && request.method === "GET") {
      const placeId = url.searchParams.get("placeId");
      if (!placeId) {
        return new Response(JSON.stringify({ error: "missing placeId" }), { status: 400, headers });
      }

      try {
        const uniRes = await fetch(`https://apis.roblox.com/universes/v1/places/${placeId}/universe`);
        if (!uniRes.ok) throw new Error("invalid place id");
        const { universeId } = await uniRes.json();

        const [gameRes, thumbRes] = await Promise.all([
          fetch(`https://games.roblox.com/v1/games?universeIds=${universeId}`),
          fetch(`https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=${universeId}&size=768x432&format=Png&isCircular=false`),
        ]);

        const gameData = await gameRes.json();
        const thumbData = await thumbRes.json();

        const game = gameData?.data?.[0];
        const thumb = thumbData?.data?.[0]?.thumbnails?.[0];

        return new Response(
          JSON.stringify({
            name: game?.name || null,
            playing: game?.playing ?? null,
            image: thumb?.imageUrl || null,
          }),
          { headers }
        );
      } catch (err) {
        return new Response(JSON.stringify({ error: "roblox lookup failed" }), { status: 502, headers });
      }
    }

    // GET /validate?key=xxxx — check if a key is still active
    if (url.pathname === "/validate" && request.method === "GET") {
      const key = url.searchParams.get("key");
      if (!key) {
        return new Response(JSON.stringify({ valid: false, reason: "no key provided" }), {
          status: 400,
          headers,
        });
      }

      const record = await env.KEYS.get(key);
      if (!record) {
        return new Response(JSON.stringify({ valid: false, reason: "expired or unknown" }), { headers });
      }

      const { expiresAt } = JSON.parse(record);
      return new Response(JSON.stringify({ valid: true, expiresAt }), { headers });
    }

    return new Response(JSON.stringify({ error: "not found" }), { status: 404, headers });
  },
};
