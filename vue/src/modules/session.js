import { reactive } from 'vue';

// All requests interrupted by session expiry wait for the same sign-in.
export const sessionState = reactive({ required: false, busy: false, error: '' });
let pendingSignIn = null;
let finishSignIn = null;
let version = 0;

export const sessionVersion = () => version;

export function requireSignIn() {
  if (!pendingSignIn) {
    pendingSignIn = new Promise(resolve => { finishSignIn = resolve; });
    sessionState.error = '';
    sessionState.required = true;
  }
  return pendingSignIn;
}

export async function waitForSignIn() {
  if (pendingSignIn) await pendingSignIn;
}

export async function signIn(name, pass) {
  if (sessionState.busy || !pendingSignIn) return false;
  sessionState.busy = true;
  sessionState.error = '';
  try {
    const response = await fetch('/samphire/login/session', {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'X-Samphire-Request': 'true' },
      body: new URLSearchParams({ name, pass })
    });
    if (!response.ok) {
      sessionState.error = response.status === 401
        ? 'Wrong username or password. Please try again.'
        : 'Sign-in failed. Please try again; your changes are still waiting.';
      return false;
    }
    version += 1;
    const resolve = finishSignIn;
    pendingSignIn = null;
    finishSignIn = null;
    sessionState.required = false;
    resolve();
    return true;
  } catch {
    sessionState.error = 'Unable to reach the server. Please try again; your changes are still waiting.';
    return false;
  } finally {
    sessionState.busy = false;
  }
}