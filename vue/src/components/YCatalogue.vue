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
    <div class="y-catalogue">
        <slot></slot>
    </div>
</template>

<script setup>

const props = defineProps({
    id : {
        type: String,
        required: false,
        default: null
    }
});

</script>

<style scoped>
@layer sfc {

    .y-catalogue {
        display: flex;
        flex-direction: row;
        align-items: stretch;
        justify-content: left;
        margin-top: 0.5em;
        padding-top: 0.5em;
        border-top: 1px solid black;
    }

}
</style>
