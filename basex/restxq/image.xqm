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

module namespace image = "http://www.jsodium.org/samphire/image";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";

declare namespace web = "http://basex.org/modules/web";

import module namespace ids = "http://www.jsodium.org/samphire/ids" at "ids.xqm";

declare function image:mime-type($filename as xs:string?) as xs:string {
  let $ext :=
    if (exists($filename) and normalize-space($filename) != '') then
      lower-case(replace($filename, '^.*\.([^.]+)$', '$1'))
    else
      ''
  return switch ($ext)
    case 'jpg' return 'image/jpeg'
    case 'jpeg' return 'image/jpeg'
    case 'png' return 'image/png'
    case 'gif' return 'image/gif'
    case 'webp' return 'image/webp'
    case 'svg' return 'image/svg+xml'
    case 'bmp' return 'image/bmp'
    case 'avif' return 'image/avif'
    case 'heic' return 'image/heic'
    default return 'application/octet-stream'
};

declare function image:file-content-type($file as item()?) as xs:string? {
  if ($file instance of map(*) and map:contains($file, 'content-type')) then
    normalize-space(string($file('content-type')))
  else
    ()
};

declare function image:file-filename($file as item()?) as xs:string? {
  if (not($file instance of map(*))) then
    ()
  else
    let $named :=
      if (map:contains($file, 'filename')) then
        normalize-space(string($file('filename')))
      else
        ()
    let $keyed :=
      if ($named != '') then
        ()
      else
        let $key :=
          (for $k in map:keys($file)
           where not($k = ('content-type', 'tempfile', 'body', 'value', 'size', 'name', 'filename'))
           return $k)[1]
        return
          if (exists($key)) then string($key) else ()
    let $raw := ($named, $keyed)[1]
    return
      if (exists($raw) and $raw != '') then replace($raw, '^.*[\\/]', '') else ()
};

declare function image:to-binary($candidate as item()?) as xs:base64Binary? {
  if (empty($candidate)) then
    ()
  else if ($candidate instance of xs:base64Binary) then
    $candidate
  else if ($candidate instance of xs:hexBinary) then
    xs:base64Binary($candidate)
  else if ($candidate instance of xs:string) then
    let $text := normalize-space($candidate)
    return
      if ($text = '') then
        ()
      else
        (try {
          fetch:binary-doc($text)
        } catch * {
          try {
            xs:base64Binary($text)
          } catch * {
            ()
          }
        })
  else
    ()
};

declare function image:file-binary($file as item()?) as xs:base64Binary? {
  if (not($file instance of map(*))) then
    ()
  else
    let $candidates := (
      if (map:contains($file, 'tempfile')) then $file('tempfile') else (),
      if (map:contains($file, 'body')) then $file('body') else (),
      if (map:contains($file, 'value')) then $file('value') else (),
      for $k in map:keys($file)
      where not($k = ('content-type', 'tempfile', 'body', 'value', 'size', 'name', 'filename'))
      return $file($k)
    )
    return (for $candidate in $candidates
            let $binary := image:to-binary($candidate)
            where exists($binary)
            return $binary)[1]
};

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/image/{$id}")
  %rest:POST
  %rest:form-param("file", "{$file}")
  function image:upload(
    $database as xs:string,
    $type as xs:string,
    $document as xs:string,
    $id as xs:string,
    $file as item()?
  ) as empty-sequence()
  {
    let $path := concat($database, '/', $type, '/', $document, '.xml')
    let $sheet := doc($path)/y-sheet
    let $target := $sheet//y-image[@id = $id][1]
    return
      if (empty($target)) then
        web:error(404, concat('y-image not found: ', $id))
      else
        let $filename := (image:file-filename($file), 'upload.bin')[1]
        let $binary := image:file-binary($file)
        return
          if (empty($binary)) then
            web:error(400, 'No image file was provided.')
          else
            let $uuid := upper-case(random:uuid())
            let $contentType := (image:file-content-type($file), image:mime-type($filename), 'application/octet-stream')[1]
            let $existing := $target/y-image-content[1]
            let $oldUuid := $existing/@uuid/string()
            let $allIds := $sheet//@id/string()
            let $contentId := ids:fresh-id(4, 1, $allIds)[1]
            let $replacement :=
              <y-image-content
                id="{$contentId}"
                height="{ $target/@height/string() }"
                width="{ $target/@width/string() }"
                uuid="{$uuid}"
                filename="{$filename}"
                content-type="{$contentType}"
                src="{ concat('./media/', $uuid) }"
              />
            return (
              if ($oldUuid != '') then
                db:delete($database, concat('__media__/', $oldUuid))
              else
                (),
              db:put-binary($database, $binary, concat('__media__/', $uuid)),
              delete node $target/node(),
              insert node $replacement as first into $target
            )
  };

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/media/{$uuid}")
  %rest:GET
  function image:media(
    $database as xs:string,
    $type as xs:string,
    $document as xs:string,
    $uuid as xs:string
  ) as item()*
  {
    let $sheetPath := concat($database, '/', $type, '/', $document, '.xml')
    let $sheet := doc($sheetPath)/y-sheet
    let $imageContent := $sheet//y-image-content[@uuid = $uuid][1]
    return
      if (empty($imageContent)) then
        web:error(404, concat('Image metadata not found for uuid: ', $uuid))
      else
        let $binaryPath := concat('__media__/', $uuid)
        let $binary :=
          try {
            db:get-binary($database, $binaryPath)
          } catch * {
            web:error(404, concat('Image binary not found for uuid: ', $uuid))
          }
        let $contentType :=
          ($imageContent/@content-type/string(), image:mime-type($imageContent/@filename/string()), 'application/octet-stream')[1]
        return (
          <rest:response>
            <http:response status="200">
              <http:header name="Content-Type" value="{$contentType}" />
              <http:header name="Cache-Control" value="private, max-age=3600" />
            </http:response>
          </rest:response>,
          $binary
        )
  };
