<!-- A Vue3 component for a modal dialog box. -->

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
    <div @click="openModal">
        <slot>
            <font-awesome-icon icon="ellipsis"/>
        </slot>
    </div>
    <dialog v-if="showModal" ref="dialog" class="modal-dialog"
        @cancel.prevent="closeModal(false)" @click.self="closeModal(false)">
        <div class="modal-content" @click.stop>
             <slot name="content">
                <p>This is the modal content.</p>
             </slot>
            <div class="modal-footer">
                <button type="button" @click="closeModal(false)">{{ rejectButton }}</button>
                <button type="button" @click="closeModal(true)">{{ acceptButton }}</button>
            </div>
        </div>
    </dialog>
</template>

<script setup>

import { library } from '@fortawesome/fontawesome-svg-core';
import {
    faEllipsis
} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
library.add(
    faEllipsis
);

const props = defineProps({
    disabled: {
        type: Boolean,
        default: false
    },
    acceptButton: {
        type: String,
        default: 'Submit'
    },
    rejectButton: {
        type: String,
        default: 'Cancel'
    },
});

import { nextTick, ref } from 'vue';

const emit = defineEmits(['open', 'close']);

const showModal = ref(false);
const dialog = ref(null);

const openModal = async () => {
    if (!props.disabled && !showModal.value) {
        showModal.value = true;
        emit('open');
        await nextTick();
        dialog.value?.showModal();
    }
};

const closeModal = (accepted) => {
    if (!showModal.value) return;
    dialog.value?.close();
    showModal.value = false;
    emit('close', accepted);
};

</script>

<style scoped>
@layer sfc {

    .modal-dialog {
        width: min(500px, calc(100vw - 32px));
        max-width: none;
        max-height: calc(100vh - 32px);
        /* Let dropdowns extend beyond the native dialog's frame. */
        overflow: visible;
        padding: 0;
        border: 0;
        border-radius: 5px;
        color: inherit;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }

    .modal-dialog::backdrop {
        background-color: rgba(0, 0, 0, 0.2);
    }

    .modal-content {
        background-color: white;
        padding: 20px;
    }

    .modal-footer {
        display: flex;
        justify-content: flex-end;
        gap: 10px;
        margin-top: 20px;
    }

}
</style>