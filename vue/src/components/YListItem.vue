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
    <div :id = "id" class="y-list-item">
        <span v-if="!listSelectMode" class="sort-handle">&#x2727;&nbsp;</span> 
        <input v-if="listSelectMode" type="checkbox" @change="modifySelection" />
        <slot></slot>
    </div>
</template>

<script setup>
import { inject } from 'vue';

const props = defineProps({
    id: {
        type: String,
        required: false,
        default: null
    }
});

const listSelectMode = inject('listSelectMode');
const selection = inject('listSelection');

function modifySelection(event) {
    if (event.target.checked) {
        selection.value.add(props.id);
    } else {
        selection.value.delete(props.id);
    }
    console.log('Selection modified:', Array.from(selection.value));
}

</script>

<style scoped>
@layer sfc {

    .y-list-item {
        display: block;
    }

}
</style>