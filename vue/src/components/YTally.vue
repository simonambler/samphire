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
  <span :id="id" class="y-tally" :aria-readonly="readonly ? 'true' : 'false'">
    <span v-if="!isInitialized" ref="sourceEl" class="y-tally-source"><slot></slot></span>
    <button
      v-for="index in boxCount"
      :key="index"
      type="button"
      class="y-tally-box"
      :disabled="readonly || pending"
      :aria-label="`Set tally to ${index}`"
      @click="toggle(index)"
    >
      <font-awesome-icon :icon="iconFor(index)" />
    </button>
    <span class="y-tally-value">{{ currentValue }}</span>
  </span>
</template>

<script setup>
  import { computed, onMounted, ref } from 'vue';
  import { library } from '@fortawesome/fontawesome-svg-core';
  import { faSquare as faSquareRegular, faSquareCaretLeft } from '@fortawesome/free-regular-svg-icons';
  import { faSquare as faSquareSolid, faSquareCaretRight } from '@fortawesome/free-solid-svg-icons';
  import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
  import postit from '../modules/postit.js';

  library.add(faSquareRegular, faSquareCaretLeft, faSquareSolid, faSquareCaretRight);

  const props = defineProps({
    id: {
      type: String,
      required: false,
      default: null
    },
    max: {
      type: [Number, String],
      required: false,
      default: 0
    }
  });

  const sourceEl = ref(null);
  const currentValue = ref(0);
  const savedValue = ref(0);
  const pendingTransition = ref(null);
  const pending = ref(false);
  const isInitialized = ref(false);

  const readonly = props.id === null;

  const toInt = (value, fallback = 0) => {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : fallback;
  };

  const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

  const boxCount = computed(() => {
    return Math.max(0, toInt(props.max, 0));
  });

  const toggle = (index) => {
    if (readonly || pending.value) {
      return;
    }

    const fromValue = currentValue.value;
    const wasFilled = index <= fromValue;
    const nextValue = wasFilled ? index - 1 : index;
    const boundedValue = clamp(nextValue, 0, boxCount.value);
    const direction = wasFilled ? 'down' : 'up';

    if (boundedValue === fromValue) {
      return;
    }

    pendingTransition.value = {
      direction,
      from: fromValue,
      to: boundedValue
    };
    currentValue.value = boundedValue;
    pending.value = true;

    postit(
      `./edit/${props.id}`,
      {},
      String(boundedValue),
      () => {
        savedValue.value = boundedValue;
      },
      () => {
        currentValue.value = savedValue.value;
      },
      () => {
        pendingTransition.value = null;
        pending.value = false;
      }
    );
  };

  const iconFor = (index) => {
    if (pendingTransition.value) {
      const { direction, from, to } = pendingTransition.value;

      if (direction === 'up' && index > from && index <= to) {
        return faSquareCaretRight;
      }

      if (direction === 'down' && index > to && index <= from) {
        return faSquareCaretLeft;
      }
    }

    return index <= currentValue.value ? faSquareSolid : faSquareRegular;
  };

  onMounted(() => {
    const text = sourceEl.value?.textContent?.trim() ?? '';
    const parsed = toInt(text, 0);
    const bounded = clamp(parsed, 0, boxCount.value);
    currentValue.value = bounded;
    savedValue.value = bounded;
    isInitialized.value = true;
  });
</script>

<style scoped>
@layer sfc {

  .y-tally {
    display: inline-flex;
    align-items: center;
    gap: 0.2rem;
    margin-left: 4px;
    margin-right: 4px;
  }

  .y-tally-source {
    display: none;
  }

  .y-tally-box {
    border: 0;
    background: transparent;
    padding: 0;
    margin: 0;
    line-height: 1;
    color: inherit;
    cursor: pointer;
  }

  .y-tally-box:disabled {
    cursor: default;
    opacity: 0.8;
  }

  .y-tally-value {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }

}
</style>
