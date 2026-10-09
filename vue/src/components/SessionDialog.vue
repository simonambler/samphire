<template>
  <dialog ref="dialog" class="session-dialog" aria-labelledby="session-title"
    aria-describedby="session-description" @cancel.prevent>
    <form @submit.prevent="submit">
      <h2 id="session-title">Please sign in again</h2>
      <p id="session-description">
        Your session has expired. Your changes are waiting and will be saved after you sign in.
        Keep this page open; refreshing it would lose the pending changes.
      </p>
      <label for="session-name">Username</label>
      <input id="session-name" v-model="name" name="username" autocomplete="username"
        :readonly="!!originalUser" :disabled="sessionState.busy" required />
      <label for="session-password">Password</label>
      <input id="session-password" ref="passwordInput" v-model="password" name="password"
        type="password" autocomplete="current-password" :disabled="sessionState.busy" required />
      <p v-if="sessionState.error" class="session-error" role="alert">{{ sessionState.error }}</p>
      <button type="submit" :disabled="sessionState.busy">
        {{ sessionState.busy ? 'Signing in…' : 'Sign in and save changes' }}
      </button>
    </form>
  </dialog>
</template>

<script setup>
import { nextTick, ref, watch } from 'vue';
import { sessionState, signIn } from '../modules/session.js';

// Replay edits as the user who originally opened this sheet.
const originalUser = document.getElementById('app')?.dataset.authUser || '';
const name = ref(originalUser);
const password = ref('');
const dialog = ref(null);
const passwordInput = ref(null);

watch(() => sessionState.required, async required => {
  await nextTick();
  if (required) {
    dialog.value.showModal();
    if (name.value) passwordInput.value.focus();
  } else {
    dialog.value.close();
  }
}, { immediate: true });

async function submit() {
  const attempt = signIn(name.value, password.value);
  password.value = '';
  if (!await attempt) {
    await nextTick();
    passwordInput.value.focus();
  }
}
</script>

<style scoped>
.session-dialog {
  box-sizing: border-box;
  width: min(440px, calc(100vw - 32px));
  max-height: calc(100vh - 32px);
  padding: 28px;
  border: 0;
  border-radius: 16px;
  background: white;
  color: #243746;
  box-shadow: 0 20px 60px #0005;
  font-family: inherit;
  text-align: left;
}
.session-dialog::backdrop { background: #102a43aa; }
h2 { margin: 0 0 12px; font-size: 1.4rem; }
p { line-height: 1.5; }
label { display: block; margin: 16px 0 6px; font-weight: 600; }
input, button {
  box-sizing: border-box;
  width: 100%;
  padding: 12px;
  border-radius: 8px;
  font: inherit;
}
input { border: 1px solid #9aabb8; background: white; color: #243746; }
input:focus-visible, button:focus-visible { outline: 3px solid #0891b2; outline-offset: 2px; }
input[readonly] { background: #f1f5f9; }
button { margin-top: 22px; border: 0; background: #134e4a; color: white; cursor: pointer; }
button:disabled { opacity: .65; cursor: wait; }
.session-error { padding: 10px; border-radius: 8px; background: #ffe4e6; color: #9f1239; }
</style>