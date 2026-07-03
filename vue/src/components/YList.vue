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
    <div :id="id" class="y-list" ref="sortable">
        <div class="y-list-buttons">
            <button class="y-list-button" @click="toggleSelectMode">
                <font-awesome-icon icon="skull-crossbones" />
            </button>
            <button v-if="selectMode && selection.size > 0" class="y-list-button" @click="duplicateSelectedItems">
                <font-awesome-icon icon="fa-copy" />
            </button>
            <button v-if="selectMode && selection.size > 0" class="y-list-button" @click="deleteSelectedItems">
                <font-awesome-icon icon="xmark" />
            </button>
        </div>
        <active-slot></active-slot>
    </div>
</template>

<script setup>
import { onMounted, ref, useSlots, useTemplateRef, provide, inject } from 'vue';
import Sortable from 'sortablejs'
import postit from '../modules/postit';
import useActiveSlot from '../modules/useActiveSlot';

import { library } from '@fortawesome/fontawesome-svg-core';
import {
    faCopy, faFlag, faSkullCrossbones, faXmark
} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
library.add(
    faCopy, faFlag, faSkullCrossbones, faXmark
);

const props = defineProps({
    id: {
        type: String,
        required: false,
        default: null
    },
    tag: {
        type: String,
        required: false,
        default: null
    }
});

const slots = useSlots();

const { ActiveSlot, refresh } = useActiveSlot(props, slots);

const element = useTemplateRef('sortable')

const sortable = ref(null);

var order = [];

const selectMode = ref(false);
const selection = ref(new Set());

const readonly = props.id === null;

onMounted(() => {
    const sortOptions = {
        sort: true,
        dataIdAttr: 'id',
        group: props.tag || 'default',
        handle: '.sort-handle',
        draggable:'.y-list-item',
        disabled: readonly,
        onStart: (evt) => {
            order = sortable.value.toArray()
        },
        onEnd: (evt) => {
            move(evt.from.id, evt.to.id, evt.oldDraggableIndex + 1, evt.newDraggableIndex + 1);
        }
    };
    sortable.value = new Sortable(element.value, sortOptions);
});

function move(from, to, fromIndex, toIndex) {
    // Replace with actual server update logic
    console.log(`Moved item from ${from}/${fromIndex} to ${to}/${toIndex}`);
    // Use postit to make a POST request to the URL ./list/${id}/move/${from}/to/${to}
    // If the request fails then revert the change.
    postit(`./move/${from}/${fromIndex}/to/${to}/${toIndex}`, {}, null, null, () => revert(from, to, fromIndex, toIndex), null);
}

function revert(from, to, fromIndex, toIndex) {
    // Replace with actual client side revert logic
    console.log(`Reverted item from ${to}/${toIndex} to ${from}/${fromIndex}`);
    sortable.value.sort(order, true);
}

function toggleSelectMode() {
    selectMode.value = !readonly && !selectMode.value;
    if (!selectMode.value) {
        selection.value.clear();
    }
}

function deleteSelectedItems() {
    if (selection.value.size === 0) {
        return;
    }
    if (!confirm(`Are you sure you want to delete ${selection.value.size} selected items?`)) {
        return;
    }
    postit(`./delete/${props.id}`, {}, Array.from(selection.value).join(','), null, null, () => {
        selectMode.value = false;
        selection.value.clear();
        refresh();
    });
}

function duplicateSelectedItems() {
    if (selection.value.size === 0) {
        return;
    }
    postit(`./duplicate/${props.id}`, {}, Array.from(selection.value).join(','), null, null, () => {
        selection.value.clear();
        refresh();
    });
}

// Provide the list id and refresh function to child components so that
// they can be delegated to update the list.
provide('listid', props.id);
provide('listId', props.id);
provide('listRefresh', refresh);

// Provide the selection mode and selection set to child components.
provide('listSelectMode', selectMode);
provide('listSelection', selection);

</script>

<style scoped>
@layer sfc {

    .y-list {
        display: block;
        position: relative;
    }

    .y-list-buttons {
        display: flex;
        justify-content: center;
        gap: 0.2rem;
    }

    .y-list-button {
        display: inline-flex;
        background: rgba(0, 0, 0, 0);
        border: 0;
        color: #000;
        padding: .2rem .2rem;
        margin-right: 0;
        cursor: pointer;
    }

}
</style>