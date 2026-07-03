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
    <div :id="id" class="y-sheet">
        <!-- Content. -->
        <slot></slot>
        <!-- Icon buttons container -->
        <div class="y-sheet-buttons">
            <!-- Modal dialog for access control. -->
            <modal-dialog :disabled="id === null" @open="backupAccess" @close="updateAccess" :acceptButton="'Update'" :rejectButton="'Cancel'">
                <div>
                    <font-awesome-icon icon="fa-cog"/>
                </div>
                <template #content>
                    <div class="access-control-form">
                        <div class="form-field">
                            <label for="owner-input">Owner:</label>
                            <input id="owner-input" v-model="accessOwner" type="text" :disabled="admin !== 'true'"></input>
                        </div>
                        <div class="form-field">
                            <label for="read-input">Read:</label>
                            <input id="read-input" v-model="accessRead" type="text"></input>
                        </div>
                        <div class="form-field">
                            <label for="write-input">Write:</label>
                            <input id="write-input" v-model="accessWrite" type="text"></input>
                        </div>
                    </div>
                </template>
            </modal-dialog>
            <!-- Modal dialog for cloning as a new sheet. -->
            <modal-dialog @close="cloneSheet" :acceptButton="'Clone'" :rejectButton="'Cancel'">
                <div>
                    <font-awesome-icon icon="fa-copy"/>
                </div>
                <template #content>
                    <div class="clone-form">
                        <div class="form-field">
                            <label for="clone-location">Location:</label>
                            <input id="clone-location" v-model="cloneLocation" type="text"></input>
                        </div>
                        <div class="form-field">
                            <label for="clone-name">Clone sheet as:</label>
                            <input id="clone-name" v-model="cloneAs" type="text"></input>
                        </div>
                    </div>
                </template>
            </modal-dialog>
            <a class="y-sheet-icon-link" href="./download">
                <font-awesome-icon icon="fa-arrow-down"/>
            </a>
            <modal-dialog :disabled="id === null" @open="prepareUpload" @close="uploadSheet" :acceptButton="'Upload'" :rejectButton="'Cancel'">
                <div>
                    <font-awesome-icon icon="fa-arrow-up"/>
                </div>
                <template #content>
                    <div class="upload-form">
                        <div class="form-field">
                            <label for="sheet-upload-input">Upload XML :</label>
                            <input id="sheet-upload-input" ref="uploadInput" type="file" accept=".xml,application/xml,text/xml" @change="setUploadFile"></input>
                        </div>
                    </div>
                </template>
            </modal-dialog>
            <!-- Modal dialog for deleting the sheet. -->
            <modal-dialog :disabled="id === null" @close="deleteSheet" :acceptButton="'Delete'" :rejectButton="'Cancel'">
                <div>
                    <font-awesome-icon icon="fa-trash"/>
                </div>
                <template #content>
                    <p>
                        Are you sure you want to delete this sheet? This action cannot be undone.
                    </p>
                </template>
            </modal-dialog>
        </div>
    </div>
</template>

<script setup>
import { library } from '@fortawesome/fontawesome-svg-core';
import {
    faArrowDown,
    faArrowUp,
    faCopy,
    faCog,
    faTrash
} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
library.add(
    faArrowDown,
    faArrowUp,
    faCopy,
    faCog,
    faTrash
);

import ModalDialog from './ModalDialog.vue';
import getit from '../modules/getit.js';
import putit from '../modules/putit.js';
import postit from '../modules/postit.js';
import deleteit from '../modules/deleteit.js';

import { provide, ref, computed } from 'vue';

const props = defineProps({
    id: {
        type: String,
        required: false,
        default: null
    },
    admin: {
        type: String,
        required: false,
        default: 'false'
    },
    owner: {
        type: String,
        required: false
    },
    read: {
        type: String,
        required: false
    },
    write: {
        type: String,
        required: false
    }
});

const cloneAs = ref('NewSheet')
const cloneLocation = ref('')
const accessOwner = ref(props.owner || '')
const accessRead = ref(props.read || '')
const accessWrite = ref(props.write || '')
const accessBackup = ref({})
const uploadInput = ref(null)
const uploadFile = ref(null)

// Extract current database and location from URL path
function extractFromURL() {
    const pathParts = window.location.pathname.split('/');
    // /samphire/data/{database}/type/{location}/sheet/{document}/view
    return {
        database: pathParts[3],
        location: pathParts[5],
        document: pathParts[7]
    };
}

// Initialize location on component mount
const { database, location, document } = extractFromURL();
cloneLocation.value = location;

function setUploadFile(event) {
    uploadFile.value = event.target.files && event.target.files.length > 0 ? event.target.files[0] : null;
}

function prepareUpload() {
    uploadFile.value = null;
    if (uploadInput.value) {
        uploadInput.value.value = '';
    }
}

async function uploadSheet(accepted) {
    if (!accepted) {
        return;
    }
    if (!uploadFile.value) {
        alert('Please select an XML file to upload.');
        return;
    }

    try {
        const data = await uploadFile.value.text();
        const path = `/samphire/data/${database}/type/${location}/sheet/${document}`;
        putit(
            path,
            {'Content-Type': 'application/xml'},
            data,
            () => {
                window.location.reload();
            },
            () => {
                alert('Failed to upload XML.');
            },
            null
        );
    } catch (error) {
        alert('Unable to read the selected file.');
    }
}

function cloneSheet(accepted) {
    if (accepted) {
        getit('./',
            (data) => {
                // Use provided location or default to 'general' if blank/whitespace
                let location = cloneLocation.value.trim();
                if (!location) {
                    location = 'general';
                }
                
                const documentName = cloneAs.value.replace(' ', '_');
                const path = `/samphire/data/${database}/type/${location}/sheet/${documentName}`;
                putit(path,
                    {'Content-Type': 'application/xml'},
                    data,
                    () => {
                        // On success, open the new sheet in a new tab
                        window.open(path + '/view', '_blank');
                    },
                    null,
                    null
                )
            }
        )
    }
}

function backupAccess() {
    accessBackup.value = {
        owner: accessOwner.value,
        read: accessRead.value,
        write: accessWrite.value
    };
}

function updateAccess(accepted) {
    if (accepted) {
        const accessData = {
            owner: accessOwner.value,
            read: accessRead.value,
            write: accessWrite.value
        };
        
        postit(
            './access',
            {'Content-Type': 'application/json'},
            JSON.stringify(accessData),
            null,
            () => {
                // Revert on error
                accessOwner.value = accessBackup.value.owner;
                accessRead.value = accessBackup.value.read;
                accessWrite.value = accessBackup.value.write;
                alert('Failed to update access control settings.');
            },
            null
        );
    } else {
        // Revert if cancelled
        accessOwner.value = accessBackup.value.owner;
        accessRead.value = accessBackup.value.read;
        accessWrite.value = accessBackup.value.write;
    }
}

function deleteSheet(accepted) {
    if (accepted) {
        deleteit(
            './',
            () => {
                // On success, redirect to the listing page
                window.location.href = `/samphire/data/${database}/type/${location}/view`;
            },
            () => {
                alert('Failed to delete the sheet.');
            },
            null
        );
    }
}

</script>

<style scoped>
@layer sfc {

    .y-sheet {
        display: flex;
        flex-direction: column;
        padding: 1%;
        border-width: 40px;
        border-style: solid;
        border-color: transparent;
    }

    .y-sheet-buttons {
        display: flex;
        flex-direction: row;
        justify-content: flex-end;
        gap: 10px;
        margin-top: auto;
    }

    .y-sheet-icon-link {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        color: inherit;
        text-decoration: none;
    }

    .access-control-form {
        display: flex;
        flex-direction: column;
        gap: 15px;
        padding: 10px 0;
    }

    .clone-form {
        display: flex;
        flex-direction: column;
        gap: 15px;
        padding: 10px 0;
    }

    .upload-form {
        display: flex;
        flex-direction: column;
        gap: 15px;
        padding: 10px 0;
    }

    .form-field {
        display: flex;
        flex-direction: column;
        gap: 5px;
    }

    .form-field label {
        font-weight: bold;
    }

    .form-field input {
        padding: 5px;
        border: 1px solid #ccc;
        border-radius: 3px;
    }

}
</style>
