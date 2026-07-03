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

module namespace list = "http://www.jsodium.org/samphire/list";

declare namespace rest = "http://exquery.org/ns/restxq";

import module namespace ids = "http://www.jsodium.org/samphire/ids" at "ids.xqm";

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/move/{$from}/{$fromIndex}/to/{$to}/{$toIndex}")
  %rest:POST
  function list:move($database as xs:string, $type as xs:string, $document as xs:string, $from as xs:string, $fromIndex as xs:integer, $to as xs:string, $toIndex as xs:integer) as empty-sequence()
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $fromList := $sheet//y-list[@id=$from]
    let $toList := $sheet//y-list[@id=$to]
    let $listItem := $fromList/y-list-item[$fromIndex]
    let $offset := if ($from eq $to and $fromIndex le $toIndex) then 0 else - 1
    return (
      delete node $listItem,
      if ($toIndex eq 1) then
        insert node $listItem as first into $toList
      else
        insert node $listItem after $toList/y-list-item[$toIndex + $offset]
    )
  };

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/add/{$list}")
  %rest:POST("{$value}")
  %input:html("nons=true")
  %rest:consumes("text/html")
  function list:add($database as xs:string, $type as xs:string, $document as xs:string, $list as xs:string, $value as document-node()) as empty-sequence()
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $clone := $value/html/body/y-list-item
    where not(empty($clone))
    let $listItem := $clone update {
      ids:refresh-ids($sheet, .)
    }
    let $targetList := $sheet//y-list[@id=$list]
    return (
      if (exists($targetList/y-list-item)) then
        insert node $listItem after $targetList/y-list-item[last()]
      else
        insert node $listItem as first into $targetList
    )
  };

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/delete/{$list}")
  %rest:POST("{$marked}")
  function list:delete-items($database as xs:string, $type as xs:string, $document as xs:string, $list as xs:string, $marked as xs:string) as empty-sequence()
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $targetList := $sheet//y-list[@id=$list]
    let $ids := fn:tokenize($marked, ',')
    for $id in $ids
    return delete node $targetList/y-list-item[@id=$id]
  };

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/duplicate/{$list}")
  %rest:POST("{$marked}")
  function list:duplicate-items($database as xs:string, $type as xs:string, $document as xs:string, $list as xs:string, $marked as xs:string) as empty-sequence()
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $targetList := $sheet//y-list[@id=$list]
    let $ids := fn:tokenize($marked, ',')
    for $id in $ids
    let $item := $targetList/y-list-item[@id=$id]
    where exists($item)
    let $clone := $item update {
      ids:refresh-ids($sheet, .)
    }
    return insert node $clone after $item
  };
