(:
 : Samphire - generic character sheet server for tabletop RPGs
 : Copyright (C) 2022-2026 Simon Ambler
 :
 : This program is free software: you can redistribute it and/or modify
 : it under the terms of the GNU Affero General Public License as published
 : by the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 : This program is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 : GNU Affero General Public License for more details.
 :
 : You should have received a copy of the GNU Affero General Public License
 : along with this program.  If not, see <https://www.gnu.org/licenses/>.
 :)

module namespace cell = "http://www.jsodium.org/samphire/cell";

declare namespace rest = "http://exquery.org/ns/restxq";

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/edit/{$id}")
  %rest:POST("{$value}")
  function cell:edit($database as xs:string, $type as xs:string, $document as xs:string, $id as xs:string, $value as xs:string?) as empty-sequence()
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $field := $sheet//node()[@id=$id]
    return
      replace value of node $field with $value
  };
