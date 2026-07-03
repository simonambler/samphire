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
    <div v-if="showModal" class="modal-overlay" @click="closeModal">
        <div class="modal-content" @click.stop>
             <slot name="content">
                <p>This is the modal content.</p>
             </slot>
            <div class="modal-footer">
                <button @click="closeModal(false)">{{ rejectButton }}</button>
                <button @click="closeModal(true)">{{ acceptButton }}</button>
            </div>
        </div>
    </div>
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

import { ref } from 'vue';

const emit = defineEmits(['open', 'close']);

const showModal = ref(false);

const openModal = () => {
    if (!props.disabled) {
        showModal.value = true;
        emit('open');
    }
};

const closeModal = (accepted) => {
    showModal.value = false;
    emit('close', accepted);
};

</script>

<style scoped>
@layer sfc {

    .modal-overlay {
        position: fixed;
        left: 0;
        top: 0;
        right: 0;
        bottom: 0;

        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 2;
    }

    .modal-content {
        background-color: white;
        padding: 20px;
        border-radius: 5px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        max-width: 500px;
        width: 100%;
    }

    .modal-footer {
        display: flex;
        justify-content: flex-end;
        margin-top: 20px;
    }

}
</style>