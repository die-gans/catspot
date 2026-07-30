import { httpRouter } from "convex/server";
import { httpAction } from "./_generated/server.js";

/**
 * Public HTTP router for Convex.
 *
 * Currently exposes a /health endpoint for deploy / monitoring checks.
 * Firebase Auth has no server-side webhook for user sync; the client calls
 * `upsertFromFirebase` on first sign-in to create the user row.
 */
const http = httpRouter();

http.route({
  path: "/health",
  method: "GET",
  handler: httpAction(async () => {
    return new Response(JSON.stringify({ status: "ok" }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  }),
});

export default http;
