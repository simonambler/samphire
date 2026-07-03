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
    <div :id="id" @focusin="isFocused = true" @focusout="isFocused = false">
        <div v-if="editor" :class="{ 'menubar': true, 'is-focused': isFocused, 'is-hidden': !isFocused }">
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('bold') }" @click="editor.chain().focus().toggleBold().run()">
                <font-awesome-icon icon="bold" />
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('italic') }" @click="editor.chain().focus().toggleItalic().run()">
                <font-awesome-icon icon="italic" />
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('underline') }" @click="editor.chain().focus().toggleUnderline().run()">
                <font-awesome-icon icon="underline" />
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('strike') }" @click="editor.chain().focus().toggleStrike().run()">
                <font-awesome-icon icon="strikethrough" />
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('heading', { level: 1 }) }" @click="editor.chain().focus().toggleHeading({ level: 1 }).run()">
                <font-awesome-icon icon="heading" />1
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('heading', { level: 2 }) }" @click="editor.chain().focus().toggleHeading({ level: 2 }).run()">
                <font-awesome-icon icon="heading" />2
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('heading', { level: 3 }) }" @click="editor.chain().focus().toggleHeading({ level: 3 }).run()">
                <font-awesome-icon icon="heading" />3
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('paragraph') }" @click="editor.chain().focus().setParagraph().run()">
                <font-awesome-icon icon="paragraph" />
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('bullet_list') }" @click="editor.chain().focus().toggleBulletList().run()">
                <font-awesome-icon icon="list-ul" />
            </button>
            <button class="menubar_button" :class="{ 'is-active': editor.isActive('ordered_list') }" @click="editor.chain().focus().toggleOrderedList().run()">
                <font-awesome-icon icon="list-ol" />
            </button>
            <button class="menubar_button" @click="editor.chain().focus().setHorizontalRule().run()">
                <font-awesome-icon icon="divide" />
            </button>
            <button class="menubar_button" @click="editor.chain().focus().undo().run()" :disabled="!editor.can().undo()">
                <font-awesome-icon icon="undo" />
            </button>
            <button class="menubar_button" @click="editor.chain().focus().redo().run()" :disabled="!editor.can().undo()">
                <font-awesome-icon icon="redo" />
            </button>
            <button class="menubar_button" @click="saveContent">
                <font-awesome-icon icon="save" />
            </button>
        </div>
        <editor-content class="editor" :editor="editor"/>
    </div>
</template>
  
<script setup>
import { createApp, ref, inject, onMounted, onBeforeUnmount, useSlots, h } from 'vue';

import { Editor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'

import { library } from '@fortawesome/fontawesome-svg-core';
import {
    faBold, faItalic, faUnderline, faStrikethrough,
    faHeading, faParagraph, faListUl, faListOl,
    faDivide, faUndo, faRedo, faSave
} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
library.add(
    faBold, faItalic, faUnderline, faStrikethrough,
    faHeading, faParagraph, faListUl, faListOl,
    faDivide, faUndo, faRedo, faSave
);

import putIt from '../modules/putit.js';

const props = defineProps({
    id: {
        type: String,
        required: false,
        default: null
    }
});

const slots = useSlots();

const editor = ref(null);

const isFocused = ref(false);

const lastSavedContent = ref(null);

const readonly = props.id === null;

const getContent = () => {
    return `<html><body>${editor.value.getHTML()}</body></html>`;
};

const saveContent = () => {
    const currentContent = getContent();
    putIt(
        `./save/${props.id}`, 
        {'Content-Type': 'text/html'}, 
        currentContent,
        // onSucceed: update last saved content
        () => {
            lastSavedContent.value = currentContent;
        },
        // onFail: revert to last saved content
        () => {
            if (lastSavedContent.value && editor.value) {
                editor.value.commands.setContent(lastSavedContent.value);
            }
            alert('Save failed! Content has been reverted to the last saved version.');
        }
    );
};

onMounted(() => {
    const wrapper = document.createElement('div');
    const content = createApp({
        render: () => h('div', {}, slots.default && slots.default())
    }).mount(wrapper).$el.innerHTML;
    editor.value = new Editor({
        content: content,
        extensions: [StarterKit, Underline],
        editable: !readonly
    });
    // Store the initial content as the last saved content
    lastSavedContent.value = content;
});

onBeforeUnmount(() => {
    editor.value.destroy();
});

</script>

<style scoped>
@layer sfc {

    .menubar {
        margin-bottom: 1rem;
        -webkit-transition: visibility .2s .4s, opacity .2s .4s;
        transition: visibility .2s .4s, opacity .2s .4s
    }

    .menubar.is-hidden {
        visibility: hidden;
        opacity: 0
    }

    .menubar.is-focused {
        visibility: visible;
        opacity: 1;
        -webkit-transition: visibility .2s, opacity .2s;
        transition: visibility .2s, opacity .2s
    }

    .menubar_button {
        font-weight: 700;
        display: -webkit-inline-box;
        display: -ms-inline-flexbox;
        display: inline-flex;
        background: rgba(0, 0, 0, 0);
        border: 0;
        color: #000;
        padding: .2rem .5rem;
        margin-right: .2rem;
        border-radius: 3px;
        cursor: pointer
    }

    .menubar_button:hover {
        background-color: rgba(0, 0, 0, .05)
    }

    .menubar_button.is-active {
        background-color: rgba(0, 0, 0, .1)
    }

    .editor {
        text-align: left;
        margin: 10px;
    }

}
</style>
  