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
    <modal-dialog :disabled="readonly"  @close="addItem" :acceptButton="'Add'" :rejectButton="'Cancel'">
        <div class="y-catalogue-item">
            <font-awesome-icon icon="fa-plus"/> {{ label }}
        </div>
        <template #content>
            <item-selector
                :url="url"
                :filter="filter"
                @selectItem="selectItem">
            </item-selector>
        </template>
    </modal-dialog>
</template>

<script setup>

import { library } from '@fortawesome/fontawesome-svg-core';
import {
    faPlus
} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
library.add(
    faPlus
);

import ModalDialog from './ModalDialog.vue';
import ItemSelector from './ItemSelector.vue';
import { ref, inject, computed } from 'vue';

import postIt from '../modules/postit.js';

const props = defineProps ({
    id: {
        type: String,
        required: false,
        default: null
    },
    label: {
        type: String,
        required: false,
        default: 'Item'
    },
    filter: {
        type: String,
        required: false,
        default: ''
    },
    url: {
        type: String,
        required: true
    }
});

const listId = inject('listId')
const listRefresh = inject('listRefresh')
const readonly = props.id === null;

const selectedItem = ref(null);

function selectItem(item) {
    selectedItem.value = item;
};

const content = computed(() => {
    return `<html><body>${selectedItem.value}</body></html>`;
});

function addItem(accepted) {
    if (accepted && selectedItem.value) {
        console.log('Adding item:', selectedItem.value);
        // Update the list in the database and refresh the parent component
        postIt(`./add/${listId}`, {'Content-Type': 'text/html'}, content.value, () => {
            listRefresh();
        }, null, null);
        // Reset the selected item
        selectedItem.value = null;
    }
}

</script>

<style scoped>
@layer sfc {

    .y-catalogue-item {
        padding-left: 0.25em;
        padding-right: 0.25em;
    }

}
</style>