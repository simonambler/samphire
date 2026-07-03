## Plan: Simplify Auth Page Flow

Align the routing with the intended product flow: unauthenticated users should only reach the login page, authenticated users should reach a content page, and logout should immediately return to login. The recommended approach is to protect `/samphire/home`, simplify home to the authenticated state only, replace the logout success page with an immediate redirect, and add explicit login failure feedback so the flow is predictable and easier to extend when real home-page content is added.

**Steps**
1. Tighten route behavior in `/workspaces/samphire/basex/restxq/login.xqm` so `/samphire/home` is no longer reachable anonymously. Update `login:checkauth` to allow only the truly public routes and keep redirecting unauthenticated GET requests to `/samphire/login` while preserving `requestPath`. This blocks later simplification of the home page.
2. Simplify the login page GET handler in `/workspaces/samphire/basex/restxq/login.xqm`. Add a small error-display mechanism for failed login attempts and decide the behavior for already-authenticated users hitting `/samphire/login` directly; recommended behavior is immediate redirect to the saved `requestPath` or `/samphire/home` rather than rendering the form again.
3. Simplify the login POST handler in `/workspaces/samphire/basex/restxq/login.xqm`. Keep the existing successful redirect logic, but on authentication failure redirect back to `/samphire/login` with a lightweight error signal so the GET handler can render a clear message. Ensure any stale redirect state is handled predictably.
4. Replace the logout success page in `/workspaces/samphire/basex/restxq/login.xqm` with a direct redirect flow. `login:logout` should delete `authUser`, clear any stale `requestPath`, and immediately redirect to `/samphire/login`. This is independent of the login error work but depends on the agreed public/private route model from step 1.
5. Simplify `/workspaces/samphire/basex/restxq/home.xqm` to the authenticated-only state. Remove the conditional status/login button branches, keep only content appropriate for a signed-in user, and retain a single logout action. This can proceed after step 1 confirms the route is protected.
6. Tidy page copy and navigation between both pages so they match the new flow. In particular, remove or replace the login page back-link to `/samphire/home`, because once home is protected it ceases to be a meaningful public destination. Keep this change minimal because a broader visual redesign is intentionally deferred.
7. Run focused verification of the full auth journey: anonymous request to `/samphire/home`, anonymous request to a protected content URL, successful login with and without stored `requestPath`, failed login, authenticated request to `/samphire/login`, and logout. Confirm redirects, session cleanup, and rendered messaging all match the intended flow.

**Relevant files**
- `/workspaces/samphire/basex/restxq/login.xqm` — update `login:checkauth`, `login:login`, `login:checkpass`, and `login:logout`; reuse the existing `requestPath` redirect pattern rather than introducing a new auth mechanism.
- `/workspaces/samphire/basex/restxq/home.xqm` — remove the anonymous-state branches and leave a simpler authenticated landing page that is ready for real content later.

**Verification**
1. Request `/samphire/home` without a session and confirm it redirects to `/samphire/login` instead of rendering home.
2. Request another protected GET endpoint without a session, log in successfully, and confirm the stored `requestPath` still returns the user to the original destination.
3. Submit wrong credentials and confirm the login page re-renders with an explicit error message and no broken redirect state.
4. Visit `/samphire/login` while already authenticated and confirm it redirects to the intended content page instead of showing the form again.
5. Trigger `/samphire/logout` while authenticated and confirm the session is cleared and the response immediately redirects to `/samphire/login` with no intermediate success page.
6. Confirm the simplified home page contains only authenticated-state UI and no dead anonymous branches.

**Decisions**
- Include: protect `/samphire/home`, remove the logout success page, and show an explicit login error message.
- Include: tidy only the current login/home/logout flow and leave the home page structurally ready for later content.
- Exclude: broader visual redesign or shared layout extraction for the upcoming real home-page content work.
- Exclude: unrelated permission inconsistencies in other RESTXQ modules; those should be handled as a separate security-focused pass.

**Further Considerations**
1. Recommended: when an authenticated user requests `/samphire/login`, redirect them to `requestPath` if present, otherwise `/samphire/home`; this avoids exposing a pointless login form once signed in.
2. Recommended: implement failed-login feedback with a query parameter or equivalent lightweight GET-visible state, unless the codebase already has a preferred flash-message pattern.
3. Recommended: keep the current styling changes minimal now, then do a separate home-page design pass once the real content requirements are defined.
