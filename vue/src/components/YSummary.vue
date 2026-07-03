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
    <div class="y-summary">
        <active-slot></active-slot>
        <button class="y-list-button" @click="update"><font-awesome-icon icon="sync" /></button>
    </div>
</template>

<script setup>
import { ref, useSlots } from 'vue';
import postit from '../modules/postit';
import useActiveSlot from '../modules/useActiveSlot';

import { library } from '@fortawesome/fontawesome-svg-core';
import {
    faSync
} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
library.add(
    faSync
);

const props = defineProps({
    id: {
        type: String,
        required: false,
        default: null
    },
    url: {
        type: String,
        required: false,
        default: null
    }
});

const slots = useSlots();

const { ActiveSlot, refresh } = useActiveSlot(props, slots);

function update() {
    postit(`./update/${props.id}`, {}, null, null, null, () => { refresh() });
}   

</script>

<style scoped>
@layer sfc {

    /*
        .y-summary {

        } 
    */

}
</style>