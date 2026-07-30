/**
 * Clerk JWT provider configuration for Convex.
 *
 * The issuer domain is set from the Convex environment variable
 * CLERK_JWT_ISSUER_DOMAIN (e.g. https://your-app.clerk.accounts.dev).
 *
 * The JWT template in Clerk must be named exactly "convex".
 */
export default {
  providers: [
    {
      domain: process.env.CLERK_JWT_ISSUER_DOMAIN,
      applicationID: "convex",
    },
  ],
};
