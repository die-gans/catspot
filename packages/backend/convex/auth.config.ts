/**
 * Firebase Auth provider configuration for Convex.
 *
 * The issuer domain is built from the Convex environment variable
 * FIREBASE_PROJECT_ID as `https://securetoken.google.com/<project-id>`.
 *
 * The client sends the Firebase ID token obtained from the firebase_auth SDK;
 * Convex validates it as an OIDC token issued by Google Secure Token Service.
 */
export default {
  providers: [
    {
      domain: `https://securetoken.google.com/${process.env.FIREBASE_PROJECT_ID}`,
      applicationID: process.env.FIREBASE_PROJECT_ID,
    },
  ],
};
