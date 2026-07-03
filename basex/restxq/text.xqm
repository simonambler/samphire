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

module namespace text = "http://www.jsodium.org/samphire/text";

declare namespace rest = "http://exquery.org/ns/restxq";

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/save/{$id}")
  %rest:PUT("{$value}")
  %rest:consumes("text/html")
  %input:html("nons=true")
  function text:save($database as xs:string, $type as xs:string, $document as xs:string,  $id as xs:string, $value as document-node()) {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $text := $sheet//y-text[@id=$id]
    return (
      delete node $text/node(),
      insert nodes $value/html/body/node() into $text
    )
  };
