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
    <div>
        <multiselect
            v-model="values"
            placeholder="Search..."
            :options="options"
            :loading="isLoading"
            label="label"
            track-by="url"
            @search-change="getOptions"
            @select="selectItem">
        </multiselect>
        <p>
            <show-item></show-item>
        </p>
    </div>
</template>

<script setup>
import Multiselect from 'vue-multiselect';
import { ref, h, compile } from 'vue';

import getit from '../modules/getit.js';
import postIt from '../modules/postit.js';

const props = defineProps({
    url: {
        type: String,
        required: true
    },
    filter: {
        type: String,
        required: false,
        default: ''
    }
});

const emit = defineEmits(['selectItem']);

const options = ref([]);
const isLoading = ref(false);
const values = ref([]);

const component = ref(compile(''));

const getOptions = (search) => {
    isLoading.value = true;
    const encodedSearch = encodeURIComponent(search || '');
    const url = props.url + '/search?filter=' + props.filter + '&query=' + encodedSearch;
    getit(url, setOptions, () => {
        isLoading.value = false;
    });
};

const setOptions = (text) => {
    options.value = JSON.parse(text);
};

const selectItem = (data) => {
    getit(data.url,
        (data) => {
            component.value = compile(data);
            emit('selectItem', data);
        }
    );
};

function showItem() {
    return h({render: component.value});
}
</script>

<style src="vue-multiselect/dist/vue-multiselect.min.css"/>
