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

module namespace summary = "http://www.jsodium.org/samphire/summary";

declare namespace rest = "http://exquery.org/ns/restxq";

declare function summary:format($source as element(), $template as node()) as node()* {
  typeswitch($template)

    case element(summary) return
      for $child in $template/node()
      return summary:format($source, $child)

    case element(cell) return
      let $tag := $template/@tag/string()
      return <y-cell>{ $source//y-cell[@tag=$tag]/string() }</y-cell>
    
    case element(list) return
      let $tag := $template/@tag/string()
      let $sep := if ($template/@sep) then $template/@sep/string() else ', '
      for $listItem at $pos in $source//y-list[@tag=$tag]/y-list-item
      return (
      	if ($pos > 1) then text { $sep } else (),
        for $child in $template/item
        return summary:format($listItem, $child)
      )
    
    case element(item) return
      let $itemTag := $template/@tag/string()
      return
        if ($itemTag) then
          (: Check if current $source context has a matching tag :)
          if ($source/@tag/string()=$itemTag) then
            for $child in $template/node()
            return summary:format($source, $child)
          else
            ()
        else
          for $child in $template/node()
          return summary:format($source, $child)
    
    case element(sp) return
      text { ' ' }

    case element() return
      element { name($template) } {
        $template/@*,
        for $child in $template/node()
        return summary:format($source, $child)
      }

    case text() return
      let $normalized := normalize-space($template/string())
      return if ($normalized) then
        text { normalize-space($template) }
        else
            ()
    
    default return
      ()
};

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/update/{$id}")
  %rest:POST
  function summary:update($database as xs:string, $type as xs:string, $document as xs:string, $id as xs:string) as empty-sequence()
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $fragment := $sheet//node()[@id=$id]
    return typeswitch($fragment)
      case element(y-summary) return
        let $href := $fragment/@url/string()
        (: Extract database, type and document from URL using regex :)
        let $pattern := '^/samphire/data/([^/]+)/type/([^/]+)/sheet/([^/]+)/view$'
        let $matches := fn:analyze-string($href, $pattern)/fn:match
        where exists($matches)
        let $db := $matches/fn:group[@nr="1"]/string()
        let $loc := $matches/fn:group[@nr="2"]/string()
        let $doc := $matches/fn:group[@nr="3"]/string()
        let $sheet := doc(concat($db, '/', $loc, '/', $doc, '.xml'))/y-sheet
        let $tag := $sheet/@tag/string()
        let $config-path := concat($database, '/config.xml')
        let $config := if (doc-available($config-path)) then doc($config-path) else ()
        let $template := $config/configuration/summary[@tag=$tag]
        let $summary := if ($template) then summary:format($sheet, $template) else ()
        (: Replace the content of y-summary element but preserve attributes :)
        return replace node $fragment with element y-summary { $fragment/@*, $summary }
      default return ()
  };

