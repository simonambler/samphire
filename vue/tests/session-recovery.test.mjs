import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import request from '../src/modules/request.js';
import { sessionState, signIn } from '../src/modules/session.js';
import getit from '../src/modules/getit.js';
import postit from '../src/modules/postit.js';
import putit from '../src/modules/putit.js';
import deleteit from '../src/modules/deleteit.js';

const originalFetch = globalThis.fetch;
afterEach(() => { globalThis.fetch = originalFetch; });
const tick = () => new Promise(resolve => setImmediate(resolve));
const response = (status = 200, body = '') => new Response(status === 204 ? null : body, { status });

test('an expired save keeps its body and callbacks pending until sign-in succeeds', async () => {
  const calls = [];
  let succeeded = 0;
  let failed = 0;
  let done = 0;
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    if (url === '/samphire/login/session') {
      assert.equal(options.body.get('name'), 'player');
      assert.equal(options.body.get('pass'), 'test-password');
      return response(204);
    }
    return response(calls.length === 1 ? 401 : 200, 'saved');
  };
  const saving = postit('./edit/cell', { 'Content-Type': 'text/plain' }, 'new value',
    data => { assert.equal(data, 'saved'); succeeded++; }, () => failed++, () => done++);
  await tick();
  assert.equal(sessionState.required, true);
  assert.deepEqual([succeeded, failed, done], [0, 0, 0]);
  assert.equal(await signIn('player', 'test-password'), true);
  await saving;
  assert.deepEqual([succeeded, failed, done], [1, 0, 1]);
  assert.equal(calls.length, 3);
  assert.equal(calls[0].options, calls[2].options);
  assert.equal(calls[2].options.body, 'new value');
  assert.equal(calls[0].options.headers.get('X-Samphire-Request'), 'true');
});

test('concurrent failures share one sign-in and new requests wait too', async () => {
  const attempts = new Map();
  let logins = 0;
  let releaseLate;
  globalThis.fetch = async url => {
    if (url === '/samphire/login/session') { logins++; return response(204); }
    const count = (attempts.get(url) || 0) + 1;
    attempts.set(url, count);
    if (url === '/late' && count === 1) return new Promise(resolve => { releaseLate = resolve; });
    return response(url !== '/new' && count === 1 ? 401 : 200);
  };
  const first = request('/first');
  const second = request('/second');
  const late = request('/late');
  await tick();
  const fresh = request('/new');
  await tick();
  assert.equal(attempts.has('/new'), false);
  await signIn('player', 'test-password');
  releaseLate(response(401));
  assert.equal((await Promise.all([first, second, late, fresh])).every(result => result.ok), true);
  assert.equal(logins, 1);
  assert.equal(sessionState.required, false);
  assert.deepEqual([...attempts.values()], [2, 2, 2, 1]);
});

test('wrong credentials and network failures leave edits waiting for another attempt', async () => {
  let loginAttempt = 0;
  let saveAttempt = 0;
  globalThis.fetch = async url => {
    if (url === '/samphire/login/session') {
      loginAttempt++;
      if (loginAttempt === 1) return response(401);
      if (loginAttempt === 2) throw new TypeError('offline');
      return response(204);
    }
    return response(++saveAttempt === 1 ? 401 : 200);
  };
  const saving = request('/save');
  await tick();
  assert.equal(await signIn('player', 'wrong-password'), false);
  assert.match(sessionState.error, /Wrong username or password/);
  assert.equal(await signIn('player', 'test-password'), false);
  assert.match(sessionState.error, /Unable to reach/);
  assert.equal(sessionState.required, true);
  assert.equal(saveAttempt, 1);
  await signIn('player', 'test-password');
  assert.equal((await saving).ok, true);
});

test('a repeated 401 fails once instead of causing an endless login loop', async () => {
  let failures = 0;
  let completions = 0;
  let attempts = 0;
  globalThis.fetch = async url => {
    if (url === '/samphire/login/session') return response(204);
    attempts++;
    return response(401);
  };
  const saving = putit('/save', {}, 'text', null, () => failures++, () => completions++);
  await tick();
  await signIn('player', 'test-password');
  await saving;
  assert.deepEqual([attempts, failures, completions], [2, 1, 1]);
  assert.equal(sessionState.required, false);
});

test('403, server errors and network errors are not retried or treated as session expiry', async () => {
  for (const status of [403, 500, null]) {
    let attempts = 0;
    let failures = 0;
    let completions = 0;
    globalThis.fetch = async () => {
      attempts++;
      if (status === null) throw new TypeError('offline');
      return response(status);
    };
    await postit('/save', {}, 'text', null, () => failures++, () => completions++);
    assert.deepEqual([attempts, failures, completions], [1, 1, 1]);
    assert.equal(sessionState.required, false);
  }
});

test('GET, PUT and DELETE helpers recover too, including FormData request bodies', async () => {
  for (const method of ['GET', 'PUT', 'DELETE']) {
    let attempts = 0;
    let succeeded = 0;
    let done = 0;
    const body = new FormData();
    body.append('file', new Blob(['image']), 'image.txt');
    globalThis.fetch = async (url, options) => {
      if (url === '/samphire/login/session') return response(204);
      assert.equal(options.method || 'GET', method);
      if (method === 'PUT') assert.equal(options.body, body);
      return response(++attempts === 1 ? 401 : 200, 'content');
    };
    const success = () => succeeded++;
    const fail = () => assert.fail('unexpected failure');
    const finish = () => done++;
    const operation = method === 'GET' ? getit('/read', success, fail, finish)
      : method === 'PUT' ? putit('/upload', {}, body, success, fail, finish)
      : deleteit('/delete', success, fail, finish);
    await tick();
    await signIn('player', 'test-password');
    await operation;
    assert.deepEqual([attempts, succeeded, done], [2, 1, 1]);
  }
});