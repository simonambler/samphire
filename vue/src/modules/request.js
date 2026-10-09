import { requireSignIn, sessionVersion, waitForSignIn } from './session.js';

export default async function request(url, options = {}) {
  // Keep the original body (including FormData uploads) for replay after login.
  const headers = new Headers(options.headers);
  headers.set('X-Samphire-Request', 'true');
  const requestOptions = { ...options, headers, credentials: 'same-origin' };
  await waitForSignIn();
  const version = sessionVersion();
  let response = await fetch(url, requestOptions);
  if (response.status === 401) {
    // A late 401 from an old session must not open a second login dialog.
    if (version === sessionVersion()) await requireSignIn();
    else await waitForSignIn();
    // Retry only once: never loop on permission errors or replay uncertain writes.
    response = await fetch(url, requestOptions);
  }
  return response;
}