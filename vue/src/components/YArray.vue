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
    <div :id="id" class="y-array">
        <slot></slot>
    </div>
</template>

<script setup>
const props = defineProps({
    id: {
        type: String,
        required: false,
        default: null
    }
});
</script>

<style scoped>
@layer sfc {

    .y-array {
        display: grid;
        width: 100%;
        grid-template-columns: max-content minmax(0, 1fr);
        grid-gap: 5px 5px;
        align-content: start;
    }

    .y-array > :nth-child(odd) {
        justify-self: end;
    }

    .y-array > :nth-child(even) {
        justify-self: stretch;
        min-width: 0;
    }

}
</style>