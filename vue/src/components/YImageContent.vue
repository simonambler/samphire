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
    <img
        v-if="resolvedSrc"
        :id="id"
        class="y-image-content"
        :src="resolvedSrc"
        :alt="filename || 'Image'"
        :style="imageStyle"
    />
    <span
        v-else
        :id="id"
        class="y-image-content y-image-content-missing"
        :style="imageStyle"
        aria-hidden="true"
    ></span>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
    id: {
        type: String,
        required: false,
        default: null
    },
    height: {
        type: [Number, String],
        required: false,
        default: null
    },
    width: {
        type: [Number, String],
        required: false,
        default: null
    },
    uuid: {
        type: String,
        required: true
    },
    filename: {
        type: String,
        required: false,
        default: null
    },
    contentType: {
        type: String,
        required: false,
        default: null
    },
    src: {
        type: String,
        required: false,
        default: null
    }
});

function asCssSize(value) {
    if (value === null || value === undefined || value === '') {
        return null;
    }
    return /^\d+$/.test(String(value)) ? `${value}px` : String(value);
}

const resolvedSrc = computed(() => {
    if (props.src) {
        return props.src;
    }
    if (props.uuid) {
        return `./media/${props.uuid}`;
    }
    return null;
});

const imageStyle = computed(() => ({
    width: asCssSize(props.width),
    height: asCssSize(props.height)
}));
</script>

<style scoped>
@layer sfc {

    .y-image-content {
        display: block;
        object-fit: cover;
    }

    .y-image-content-missing {
        background: rgba(0, 0, 0, 0.08);
    }

}
</style>
