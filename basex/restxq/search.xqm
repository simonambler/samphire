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

module namespace search = "http://www.jsodium.org/samphire/search";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';

import module namespace login = "http://www.jsodium.org/samphire/login" at "login.xqm";
import module namespace ids = "http://www.jsodium.org/samphire/ids" at "ids.xqm";

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/search")
  %rest:GET
  %rest:query-param("filter", "{$filter}")
  %rest:query-param("query", "{$query}")
  %output:method("json")
  function search:search($database as xs:string, $type as xs:string, $document as xs:string, $filter as xs:string, $query as xs:string?) as array(map(xs:string, xs:string))
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    return array {
      (
        let $substring := if ($query) then fn:lower-case($query) else ""
        let $target := fn:tokenize(fn:normalize-space($filter), '\s?,\s?')
        for $item in $sheet//y-list/y-list-item[empty($target) or (@tag=$target)]
        let $name := $item//*[@tag='Name']/string()
        where fn:contains(fn:lower-case($name), $substring)
        return map:merge((
          map:entry("label", $name),
          map:entry("url", concat("/samphire/data/", $database, "/type/", $type, "/sheet/", $document, "/copy/", $item/@id/string()))
          ))
      )[position() <= 10]
    }
  };

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/search")
  %rest:GET
  %rest:query-param("filter", "{$filter}")
  %rest:query-param("query", "{$query}")
  %output:method("json")
  function search:search-type($database as xs:string, $type as xs:string, $filter as xs:string?, $query as xs:string?) as array(map(xs:string, xs:string))
  {
    let $authUser := session:get('authUser')
    let $substring := if ($query) then fn:lower-case($query) else ""
    let $collection := collection($database || '/' || $type)
    return array {
      (
        for $doc in $collection
        let $sheet := $doc/y-sheet
        let $target := fn:tokenize(fn:normalize-space($filter), '\s?,\s?')
        where login:access-rights($authUser, $database, $sheet)?hasReadAccess and (empty($target) or $sheet/@tag/string()=$target)
        let $document := fn:replace(db:path($doc), '.*/|\.xml$', '')
        let $title := ($sheet//y-title/string(), $document)[1]
        let $compare := fn:lower-case($title)
        where fn:contains($compare, $substring)
        order by $title
        return map:merge((
          map:entry("label", $title),
          map:entry("url", concat("/samphire/data/", $database, "/type/", $type, "/sheet/", $document, "/link"))
        ))
      )[position() <= 10]
    }
  };

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/frag/{$id}")
  %rest:GET
  %output:method("html")
  %output:version("5.0")
  function search:frag($database as xs:string, $type as xs:string, $document as xs:string, $id as xs:string) as node()*
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $content:= $sheet//node()[@id=$id]/node()
    return $content
  };

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/copy/{$id}")
  %rest:GET
  %output:method("html")
  %output:version("5.0")
  function search:copy($database as xs:string, $type as xs:string, $document as xs:string, $id as xs:string) as node()*
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $clone:= $sheet//node()[@id=$id] update {
      ids:delete-ids(.)
    }
    return $clone
  };
