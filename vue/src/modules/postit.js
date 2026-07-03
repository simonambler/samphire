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

'use strict';

export default async function(url, headers, data, onSucceed, onFail, onDone) {
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: headers,
      body: data,
    });
    if (response.ok) {
      const data = await response.text();
      if (onSucceed) onSucceed(data);
    } else {
      throw new Error('Failure');
    }
  } catch (error) {
    if (onFail) onFail();
  } finally {
    if (onDone) onDone();
  }
}
