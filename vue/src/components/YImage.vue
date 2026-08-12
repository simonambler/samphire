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
    <div
        :id="id"
        class="y-image"
        :class="{ 'y-image-readonly': readonly }"
        :style="frameStyle"
        @click="openUploadDialog"
    >
        <active-slot></active-slot>
    </div>

    <div v-if="showUploadDialog" class="y-image-modal-overlay" @click.self="closeUploadDialog">
        <div class="y-image-modal" role="dialog" aria-modal="true" aria-label="Upload image">
            <h3>Upload image</h3>
            <p class="y-image-modal-help">Select an image file to replace this image.</p>
            <input
                ref="fileInput"
                class="y-image-file-input"
                type="file"
                accept="image/*"
                @change="onFileChange"
            />
            <div class="y-image-modal-actions">
                <button type="button" @click="closeUploadDialog" :disabled="isUploading">Cancel</button>
                <button type="button" @click="uploadImage" :disabled="isUploading || !selectedFile">Upload</button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, useSlots } from 'vue';

import postit from '../modules/postit';
import useActiveSlot from '../modules/useActiveSlot';

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
    }
});

const readonly = props.id === null;

const slots = useSlots();
const { ActiveSlot, refresh } = useActiveSlot(props, slots);

const showUploadDialog = ref(false);
const selectedFile = ref(null);
const isUploading = ref(false);
const fileInput = ref(null);

function asCssSize(value) {
    if (value === null || value === undefined || value === '') {
        return null;
    }
    return /^\d+$/.test(String(value)) ? `${value}px` : String(value);
}

const frameStyle = computed(() => ({
    width: asCssSize(props.width),
    height: asCssSize(props.height)
}));

function openUploadDialog() {
    if (readonly) {
        return;
    }
    showUploadDialog.value = true;
}

function closeUploadDialog() {
    showUploadDialog.value = false;
    selectedFile.value = null;
    if (fileInput.value) {
        fileInput.value.value = '';
    }
}

function onFileChange(event) {
    const files = event.target && event.target.files ? event.target.files : null;
    selectedFile.value = files && files.length > 0 ? files[0] : null;
}

function uploadImage() {
    if (!selectedFile.value || readonly) {
        return;
    }

    const payload = new FormData();
    payload.append('file', selectedFile.value);

    isUploading.value = true;

    postit(
        `./image/${props.id}`,
        {},
        payload,
        () => {
            closeUploadDialog();
            refresh();
        },
        () => {
            alert('Image upload failed.');
        },
        () => {
            isUploading.value = false;
        }
    );
}
</script>

<style scoped>
@layer sfc {

    .y-image {
        display: block;
        position: relative;
        overflow: hidden;
        min-width: 20px;
        min-height: 20px;
        margin: 0.5rem;
        background: rgba(20, 54, 66, 0.14);
        border: 1px solid rgba(20, 54, 66, 0.2);
        cursor: pointer;
    }

    .y-image-readonly {
        cursor: default;
    }

    .y-image-modal-overlay {
        position: fixed;
        inset: 0;
        z-index: 20;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(0, 0, 0, 0.35);
    }

    .y-image-modal {
        width: min(460px, 92vw);
        background: #fff;
        border-radius: 8px;
        border: 1px solid rgba(0, 0, 0, 0.12);
        box-shadow: 0 10px 28px rgba(0, 0, 0, 0.2);
        padding: 1rem;
    }

    .y-image-modal h3 {
        margin: 0 0 0.5rem;
    }

    .y-image-modal-help {
        margin: 0 0 0.8rem;
        opacity: 0.8;
    }

    .y-image-file-input {
        width: 100%;
    }

    .y-image-modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 0.5rem;
        margin-top: 0.9rem;
    }

}
</style>
