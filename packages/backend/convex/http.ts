import { httpRouter } from "convex/server";
import { httpAction } from "./_generated/server.js";

/**
 * Public HTTP router for Convex.
 *
 * Currently exposes a /health endpoint for deploy / monitoring checks.
 * Clerk webhooks will be added in a later card (S1.6+).
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

// TODO(S1.6): add Clerk webhook POST handler (/clerk-webhook) to sync
// user deletion / email verification events. Keep webhook secret in Convex env.

export default http;
