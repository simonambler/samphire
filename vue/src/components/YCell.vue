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
      @keyup.esc="cancel"
      @blur="done"
      :class="['y-cell', { 'is-saving': saving }]"
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
  const saving = ref(false);

  const readonly = props.id === null;

  const ready = (e) => {
    e.target.innerText = e.target.innerText.trim();
    bak.value = e.target.innerText;
  };

  const submit = (e) => {
    e.target.blur();
  };

  const cancel = (e) => {
    revert(e);
    e.target.blur();
  };

  const done = (e) => {
    e.target.innerText = e.target.innerText.trim();
    if (bak.value !== e.target.innerText) {
      // the shade is cleared only on success, so failed or hung saves stay marked
      saving.value = true;
      postit(
        `./edit/${props.id}`,
        {},
        e.target.innerText,
        () => { saving.value = false; },
        () => revert(e),
        null
      );
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
    border-radius: 2px;
    transition: background-color .4s ease-out, box-shadow .4s ease-out;
  }

  .y-cell.is-saving {
    background-color: rgba(0, 0, 0, .18);
    box-shadow: 0 0 0 2px rgba(0, 0, 0, .18);
    transition: none;
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
