# samphire

This template should help get you started developing with Vue 3 in Vite.

## Recommended IDE Setup

[VSCode](https://code.visualstudio.com/) + [Volar](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur) + [TypeScript Vue Plugin (Volar)](https://marketplace.visualstudio.com/items?itemName=Vue.vscode-typescript-vue-plugin).

## Customize configuration

See [Vite Configuration Reference](https://vitejs.dev/config/).

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Compile and Minify for Production

```sh
npm run build
```

### Session Recovery Tests

Run `npm test` with Node.js 22 or later. These tests mock HTTP responses and cover
expired sessions, concurrent saves, invalid credentials, network failures,
request-body replay, and the existing success/failure/completion callbacks.

### Session Expiry

All four request helpers use a shared request wrapper. A 401 pauses the request
and opens an in-page sign-in dialog; successful authentication retries the
original request once. Concurrent failures share one sign-in, and new requests
wait while the dialog is open. Invalid credentials or a failed sign-in leave the
requests pending rather than invoking the edit rollback callbacks.

The RESTXQ `/samphire/login/session` endpoint authenticates without redirecting.
API requests carry `X-Samphire-Request: true`, so expired GET requests receive 401
instead of the HTML login page. Ordinary page navigation still redirects to login.
403 and other failures retain their existing behavior and are not retried.

Pending changes are held only in memory: keep the sheet open until sign-in and
saving complete. Closing or refreshing the page does not preserve pending edits.
Deploy the Vue bundle and the RESTXQ changes together.

### Lint with [ESLint](https://eslint.org/)

```sh
npm run lint
```
