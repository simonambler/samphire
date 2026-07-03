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

module namespace ids = "http://www.jsodium.org/samphire/ids";

declare function ids:fresh-id($len as xs:nonNegativeInteger) as xs:string {
    let $m := xs:int(math:pow(36, $len)) - 1,
    	$r := random:integer($m),
    	$s := convert:integer-to-base($r, 36),
        $padding := string-join(for $_ in 1 to $len - string-length($s) return '0', '')
    return concat($padding, $s)
};

declare function ids:fresh-id(
      $len as xs:nonNegativeInteger,
      $n as xs:nonNegativeInteger,
      $excluded as xs:string*
	) as xs:string* {
    if ($n = 0) then ()
    else
        let $id := ids:fresh-id($len)
        return
            if ($id = $excluded)
            then ids:fresh-id($len + 1, $n, $excluded)
            else ($id, ids:fresh-id($len, $n - 1, ($id, $excluded)))
};

declare %updating function ids:update-with-id($id as xs:string, $target as element()) as empty-sequence() {
  if (exists($target/@id)) then
  replace value of node $target/@id with $id
  else
  insert node attribute { 'id' } { $id } into $target
};

declare %updating function ids:insert-ids($fragment as node()*) as empty-sequence() {
  let $excluded := $fragment//@id/string()
  let $targets := $fragment/descendant-or-self::node()[starts-with(name(), 'y-')][not(@id)]
  let $ids := ids:fresh-id(4, count($targets), $excluded)
  return update:for-each-pair(
  	$ids,
    $targets,
    ids:update-with-id#2
  )
};

declare %updating function ids:delete-ids($fragment as node()*) as empty-sequence() {
  delete nodes $fragment/descendant-or-self::node()[starts-with(name(), 'y-')]/@id
};

declare %updating function ids:refresh-ids($context as node()*, $fragment as node()*) as empty-sequence() {
  let $excluded := $context//@id/string()
  let $targets := $fragment/descendant-or-self::node()[starts-with(name(), 'y-')]
  let $ids := ids:fresh-id(4, count($targets), $excluded) 
  return update:for-each-pair(
    $ids,
    $targets,
    ids:update-with-id#2
  )
};
