<!--
  Samphire - generic character sheet server for tabletop RPGs
  Copyright (C) 2022-2026 Simon Ambler

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published
  by the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->

<template>
    <span
      :id="id"
      :contenteditable="readonly ? 'false' : 'true'"
      @focus="ready"
      @keydown.enter.prevent="submit"
      @keydown.tab="submit"
      @keyup.esc="cancel"
      @blur="done"
      class="y-cell"
    >
      <slot></slot>
    </span>
</template>

<script setup>
  import { ref } from 'vue';
  import postit from '../modules/postit.js';

  const props = defineProps({
    id: {
      type: String,
      required: false,
      default: null
    }
  });

  const bak = ref('');
  const pending = ref(false);

  const readonly = props.id === null;

  const ready = (e) => {
    bak.value = e.target.innerText;
  };

  const submit = (e) => {
    // trim whitespace
    e.target.innerText = e.target.innerText.trim();
    // if the text has changed, mark as pending
    pending.value = (bak.value !== e.target.innerText);
    // blur the element to trigger the done event
    if (e.key === 'Enter') {
      e.target.blur();
    }
  };

  const cancel = (e) => {
    e.target.blur();
  };

  const done = (e) => {
    if (pending.value) {
      pending.value = false;
      postit(`./edit/${props.id}`, {}, e.target.innerText, null, () => revert(e), null);
    } else {
      revert(e);
    }
  };

  const revert = (e) => {
    e.target.innerText = bak.value;
  };
</script>

<style scoped>
@layer sfc {

  .y-cell {
    white-space: normal;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

    .y-cell:empty:focus {
        display: inline-block;
        min-width: 1ch;
    }

    .y-cell:empty:not(:focus)::before {
        content: "\2014";
    }

}
</style>
