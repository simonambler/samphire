/*
 * Samphire - generic character sheet server for tabletop RPGs
 * Copyright (C) 2022-2026 Simon Ambler
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import { createApp } from 'vue'
import YArray from './components/YArray.vue'
import YArrayItem from './components/YArrayItem.vue'
import YCatalogue from './components/YCatalogue.vue'
import YCatalogueItem from './components/YCatalogueItem.vue'
import YCell from './components/YCell.vue'
import YImage from './components/YImage.vue'
import YImageContent from './components/YImageContent.vue'
import YList from './components/YList.vue'
import YListItem from './components/YListItem.vue'
import YPanel from './components/YPanel.vue'
import YPanelItem from './components/YPanelItem.vue'
import YSheet from './components/YSheet.vue'
import YStyle from './components/YStyle.vue'
import YSummary from './components/YSummary.vue'
import YTally from './components/YTally.vue'
import YText from './components/YText.vue'
import YTitle from './components/YTitle.vue'

import './assets/main.css'

const app = createApp({})

app.component('y-array-item', YArrayItem)
app.component('y-array', YArray)
app.component('y-catalogue-item', YCatalogueItem)
app.component('y-catalogue', YCatalogue)
app.component('y-cell', YCell)
app.component('y-image-content', YImageContent)
app.component('y-image', YImage)
app.component('y-list-item', YListItem)
app.component('y-list', YList)
app.component('y-panel-item', YPanelItem)
app.component('y-panel', YPanel)
app.component('y-sheet', YSheet)
app.component('y-style', YStyle)
app.component('y-summary', YSummary)
app.component('y-tally', YTally)
app.component('y-text', YText)
app.component('y-title', YTitle)
app.mount('#app')

const appEl = document.getElementById('app')
const splashEl = document.getElementById('splash-screen')

if (appEl) appEl.classList.add('mounted')
if (splashEl) {
	// Run on the next frame so the initial splash styles are painted before fading out.
	requestAnimationFrame(() => {
		splashEl.classList.add('hidden')
	})
}
