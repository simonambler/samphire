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

module namespace sheet = "http://www.jsodium.org/samphire/sheet";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';
declare namespace http = 'http://expath.org/ns/http-client';

import module namespace ids = "http://www.jsodium.org/samphire/ids" at "ids.xqm";
import module namespace image = "http://www.jsodium.org/samphire/image" at "image.xqm";
import module namespace login = "http://www.jsodium.org/samphire/login" at "login.xqm";
import module namespace summary = "http://www.jsodium.org/samphire/summary" at "summary.xqm";
import module namespace session = 'http://basex.org/modules/session';

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}")
  %rest:GET
  %output:method("xml")
  function sheet:get($database as xs:string, $type as xs:string, $document as xs:string) as document-node()
  {
    let $doc := doc(concat($database, '/', $type, '/', $document, '.xml'))
    return $doc
  };

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/download")
  %rest:GET
  %output:method("xml")
  function sheet:download($database as xs:string, $type as xs:string, $document as xs:string) as item()*
  {
    let $doc := doc(concat($database, '/', $type, '/', $document, '.xml'))
    let $filename := concat($document, '.xml')
    return (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Type" value="application/xml" />
          <http:header name="Content-Disposition" value="{ concat('attachment; filename=&quot;', $filename, '&quot;') }" />
        </http:response>
      </rest:response>,
      $doc
    )
  };

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}")
  %rest:PUT("{$value}")
  function sheet:put($database as xs:string, $type as xs:string, $document as xs:string, $value as document-node()) as empty-sequence()
  {
    let $path := concat($type, '/', $document, '.xml')
    let $authUser := session:get('authUser')
    let $doc := $value update {
      ids:refresh-ids((), .),
      delete node ./y-sheet/@owner,
      insert node attribute { 'owner' } { $authUser } into ./y-sheet
    }
    return db:put($database, $doc, $path)
  };

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}")
  %rest:DELETE
  function sheet:delete-sheet($database as xs:string, $type as xs:string, $document as xs:string) as empty-sequence()
  {
    let $path := concat($type, '/', $document, '.xml')
    let $sheet := if (doc-available(concat($database, '/', $path))) then doc(concat($database, '/', $path))/y-sheet else ()
    let $uuids := distinct-values($sheet//y-image-content/@uuid/string())
    return (
      for $uuid in $uuids
      return image:check-delete($database, $uuid),
      db:delete($database, $path)
    )
  };

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/link")
  %rest:GET
  %output:method("html")
  %output:version("5.0")
  function sheet:link($database as xs:string, $type as xs:string, $document as xs:string) as node()*
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $title := ($sheet//y-title/string(), $document)[1]
    let $href := concat('/samphire/data/', $database, '/type/', $type, '/sheet/', $document, '/view')
    let $tag := $sheet/@tag/string()
    let $config-path := concat($database, '/config.xml')
    let $config := if (doc-available($config-path)) then doc($config-path) else ()
    let $template := $config/configuration/summary[@tag=$tag]
    let $summary := if ($template) then summary:format($sheet, $template) else ()
    return
      <y-list-item>
        <a href="{$href}" target="_blank"><b>{ $title }</b></a>
        <y-summary url="{$href}">{ $summary }</y-summary>
      </y-list-item>
  };

declare function sheet:javascript-module($asset as xs:string) as node()* {
  let $isDev := fn:environment-variable('SAMPHIRE_DEPLOYMENT') = 'development'
  let $key := fn:replace($asset, '^/', '')
  return if ($isDev) then
      <script type="module" src="{ concat('/samphire/', $key) }"></script>
    else
      let $dist := concat(fn:environment-variable('JETTY_BASE'), '/basex/deploy/BaseX122/static/samphire/dist/')
      let $manifest := json-doc(concat($dist, '.vite/manifest.json'))
      return if (map:contains($manifest, $key)) then
        <script type="module" crossorigin="anonymous" src="{ concat('/static/samphire/dist/', $manifest($key)?file) }" />
      else
        <script type="module" src="{ concat('/samphire/', $key) }"></script>
};

declare function sheet:stylesheet-links($asset as xs:string) as node()* {
  let $isDev := fn:environment-variable('SAMPHIRE_DEPLOYMENT') = 'development'
  return if ($isDev) then
      ()
    else
      let $key := fn:replace($asset, '^/', '')
      let $dist := concat(fn:environment-variable('JETTY_BASE'), '/basex/deploy/BaseX122/static/samphire/dist/')
      let $manifest := json-doc(concat($dist, '.vite/manifest.json'))
      return if (map:contains($manifest, $key)) then
        for $css in ($manifest($key)?css, ())
        return <link rel="stylesheet" crossorigin="anonymous" href="{ concat('/static/samphire/dist/', $css) }" />
      else
        ()
};

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/view")
  %rest:GET
  %output:method("html")
  %output:version("5.0")
  function sheet:view($database as xs:string, $type as xs:string, $document as xs:string) as node()
  {
    let $authUser := session:get('authUser')
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $access := login:access-rights($authUser, $database, $sheet)
    let $readonly := not($access?hasWriteAccess)
    let $admin := $access?isAdmin
    let $output := $sheet update {
      if ($readonly) then ids:delete-ids(.),
      if ($admin) then insert node attribute { 'admin' } { 'true' } into . 
    }
    let $title := ($sheet//y-title/string(), $document)[1]
    let $dev := fn:environment-variable('SAMPHIRE_DEPLOYMENT') = 'development'
    let $config-path := concat($database, '/config.xml')
    let $config := if (doc-available($config-path)) then doc($config-path) else ()
    let $styles := for $style in (
        $config//style[not(@tag) or @tag = $sheet/@tag],
        $sheet//y-style
      )
      return <style type="text/css">{ $style/string() }</style>
    return
      <html lang="en">
        <head>
          { if ($dev) then <script type="module" src="/samphire/@vite/client"></script> else () }
          <meta charset="UTF-8" />
          <link rel="apple-touch-icon" sizes="180x180" href="/static/samphire/images/favicon_io/apple-touch-icon.png" />
          <link rel="icon" type="image/png" sizes="32x32" href="/static/samphire/images/favicon_io/favicon-32x32.png" />
          <link rel="icon" type="image/png" sizes="16x16" href="/static/samphire/images/favicon_io/favicon-16x16.png" />
          <link rel="manifest" href="/static/samphire/images/favicon_io/site.webmanifest" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>{ $title }</title>
          { sheet:javascript-module('/src/main.js') }
          { sheet:stylesheet-links('/src/main.js') }
          { $styles }
          <style>{"
            #app {
              opacity: 0;
              transition: opacity 350ms ease;
            }

            #app.mounted {
              opacity: 1;
            }

            #splash-screen {
              position: fixed;
              top: 0;
              left: 0;
              width: 100vw;
              height: 100vh;
              display: flex;
              align-items: center;
              justify-content: center;
              background: linear-gradient(160deg, #0c4a6e 0%, #134e4a 100%);
              z-index: 9999;
              opacity: 1;
              visibility: visible;
              transition: opacity 350ms ease, visibility 0s linear 350ms;
            }

            #splash-screen.hidden {
              opacity: 0;
              visibility: hidden;
              pointer-events: none;
            }
          "}</style>
        </head>
        <body>
          <div id="splash-screen">
            <div><h1>Samphire</h1></div>
          </div>
          <div id="app">{ $output }</div>
        </body>
      </html>
  };

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/sheet/{$document}/access")
  %rest:POST("{$data}")
  function sheet:update-access($database as xs:string, $type as xs:string, $document as xs:string, $data as document-node()) as empty-sequence()
  {
    let $sheet := doc(concat($database, '/', $type, '/', $document, '.xml'))/y-sheet
    let $json := $data/json
    let $owner := $json/owner/string()
    let $read := $json/read/string()
    let $write := $json/write/string()
    return (
      delete node $sheet/@owner,
      delete node $sheet/@read,
      delete node $sheet/@write,
      insert node attribute { 'owner' } { $owner } into $sheet,
      insert node attribute { 'read' } { $read } into $sheet,
      insert node attribute { 'write' } { $write } into $sheet
    )
  };

declare
  %rest:path("/samphire/data/{$database}/view")
  %rest:GET
  %output:method("html")
  %output:version("5.0")
  function sheet:database-index($database as xs:string) as node()
  {
    let $homeHref := '/samphire/home'
    let $types := distinct-values(
      for $path in db:list($database)
      let $parts := tokenize($path, '/')
      where count($parts) = 2 and $parts[1] ne '__media__'
      return $parts[1]
    )
    let $links :=
      for $type in sort($types)
      let $href := concat('/samphire/data/', $database, '/type/', fn:encode-for-uri($type), '/view')
      return <a class="type-button" href="{ $href }">{ $type }</a>
    return
      <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <link rel="apple-touch-icon" sizes="180x180" href="/static/samphire/images/favicon_io/apple-touch-icon.png" />
          <link rel="icon" type="image/png" sizes="32x32" href="/static/samphire/images/favicon_io/favicon-32x32.png" />
          <link rel="icon" type="image/png" sizes="16x16" href="/static/samphire/images/favicon_io/favicon-16x16.png" />
          <link rel="manifest" href="/static/samphire/images/favicon_io/site.webmanifest" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>{ $database }</title>
          <style>{
            "body { margin: 0; font-family: Cochin, Georgia, Times, 'Times New Roman', serif; background: #f3f6f8; color: #123; }
            .wrap { max-width: 1100px; margin: 0 auto; padding: 28px 20px 40px; }
            .top-nav { margin-bottom: 10px; }
            .back-link { display: inline-block; text-decoration: none; color: #0c4a6e; font-size: 0.95em; font-weight: 600; }
            .back-link:hover { text-decoration: underline; }
            h1 { margin: 0 0 22px; text-align: center; font-size: 2rem; color: #134e4a; }
            .types { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 14px; }
            .type-button { display: flex; align-items: center; justify-content: center; min-height: 86px; padding: 10px 14px; border-radius: 12px; text-decoration: none; font-size: 1.2rem; font-weight: 600; color: #ffffff; background: linear-gradient(140deg, #0c4a6e 0%, #134e4a 100%); box-shadow: 0 6px 14px rgba(12, 74, 110, 0.2); transition: transform 120ms ease, box-shadow 120ms ease, filter 120ms ease; }
            .type-button:hover { transform: translateY(-1px); filter: brightness(1.04); box-shadow: 0 9px 18px rgba(12, 74, 110, 0.3); }
            .type-button:active { transform: translateY(0); }
            .empty { text-align: center; font-size: 1.05rem; color: #456; margin-top: 20px; }
            @media (max-width: 560px) { .wrap { padding: 20px 14px 30px; } h1 { font-size: 1.7rem; } }
            "
          }</style>
        </head>
        <body>
          <div class="wrap">
            <div class="top-nav">
              <a class="back-link" href="{ $homeHref }">&#8592; Samphire</a>
            </div>
            <h1>{ $database }</h1>
            {
              if (exists($links)) then
                <div class="types">{ $links }</div>
              else
                <div class="empty">No content types were found in this database.</div>
            }
          </div>
        </body>
      </html>
  };

declare
  %updating
  %rest:path("/samphire/data/{$database}/type/{$type}/upload")
  %rest:POST
  %rest:form-param("file", "{$file}")
  function sheet:upload($database as xs:string, $type as xs:string, $file as item()?) as empty-sequence()
  {
    let $authUser := session:get('authUser')
    let $key := $file[. instance of map(*)] ! map:keys(.)
    return
      if (not($key)) then
        web:error(400, 'No input specified.')
      else
        let $filename := fn:replace(string($key[1]), '^.*[\\/]', '')
        let $document := fn:replace($filename, '\.[^.]*$', '')
        let $path := concat($type, '/', $document, '.xml')
        let $existing-sheet := if (doc-available(concat($database, '/', $path))) then doc(concat($database, '/', $path))/y-sheet else ()
        return (
          if (normalize-space($document) = '') then
            web:error(400, 'Unable to derive a document name from the uploaded filename.')
          else (),
          if ($existing-sheet and not(login:access-rights($authUser, $database, $existing-sheet)?hasWriteAccess)) then
            web:error(403, 'No write access to existing document')
          else (),
          let $input := $file($key[1])
          let $parsed :=
            try {
              fetch:binary-doc($input)
            } catch * {
              web:error(400, 'Invalid or unreadable XML upload.')
            }
          let $sheet := $parsed/y-sheet
          return (
            if (empty($sheet)) then
              web:error(400, 'Uploaded file must contain a y-sheet root element.')
            else (),
            let $doc := $parsed update {
              ids:refresh-ids((), .),
              delete node ./y-sheet/@owner,
              insert node attribute { 'owner' } { $authUser } into ./y-sheet
            }
            return db:put($database, $doc, $path),
            update:output(web:redirect(concat('/samphire/data/', $database, '/type/', $type, '/view')))
          )
        )
  };

declare
  %rest:path("/samphire/data/{$database}/type/{$type}/view")
  %rest:GET
  %output:method("html")
  %output:version("5.0")
  function sheet:listing($database as xs:string, $type as xs:string) as node()
  {
    let $title := $type
    let $backHref := concat('/samphire/data/', $database, '/view')
    let $uploadHref := concat('/samphire/data/', $database, '/type/', $type, '/upload')
    let $authUser := session:get('authUser')
    let $docs :=
      let $collection := collection($database || '/' || $type)
      for $doc in $collection
      let $sheet := $doc/y-sheet
      where login:access-rights($authUser, $database, $sheet)?hasReadAccess
      let $document := fn:replace(db:path($doc), '.*/|\.xml$', '')
      let $docTitle := ($sheet//y-title/string(), $document)[1]
      let $href := concat('/samphire/data/', $database, '/type/', $type, '/sheet/', $document, '/view')
      order by $docTitle
      return <document title="{$docTitle}" href="{$href}" />
    let $letters := distinct-values(
      for $doc in $docs
      let $docTitle := $doc/@title/string()
      let $letter := fn:upper-case(fn:substring(fn:normalize-space($docTitle), 1, 1))
      return if (matches($letter, '[A-Z]')) then $letter else '#'
    )
    let $entries := 
      for $letter in sort($letters)
      let $items :=
        for $doc in $docs
        let $docTitle := $doc/@title/string()
        let $docLetter := fn:upper-case(fn:substring(fn:normalize-space($docTitle), 1, 1))
        let $groupLetter := if (matches($docLetter, '[A-Z]')) then $docLetter else '#'
        where $groupLetter = $letter
        order by $docTitle
        return <a href="{ $doc/@href/string() }" target="_blank">{ $docTitle }</a>
      return
        <div class="letter-group">
          <div class="letter-heading">{ $letter }</div>
          { $items }
        </div>
    return
      <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <link rel="apple-touch-icon" sizes="180x180" href="/static/samphire/images/favicon_io/apple-touch-icon.png" />
          <link rel="icon" type="image/png" sizes="32x32" href="/static/samphire/images/favicon_io/favicon-32x32.png" />
          <link rel="icon" type="image/png" sizes="16x16" href="/static/samphire/images/favicon_io/favicon-16x16.png" />
          <link rel="manifest" href="/static/samphire/images/favicon_io/site.webmanifest" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>{ $title }</title>
          <style>{
            "body { font-family: Cochin, Georgia, Times, 'Times New Roman', serif; }
            .top-nav { max-width: 96%; margin: 16px auto 0; display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
            .back-link { display: inline-block; text-decoration: none; color: #0c4a6e; font-size: 0.95em; font-weight: 600; }
            .back-link:hover { text-decoration: underline; }
            h1 { text-align: center; color: #333; margin-bottom: 20px; font-size: 2em; }
            .upload-row { margin-left: auto; }
            .upload-form { display: inline-flex; align-items: center; gap: 6px; flex-wrap: wrap; padding: 4px 6px; border: 1px solid #d8dee3; border-radius: 6px; background: #f7f9fa; }
            .upload-form label { font-weight: 600; font-size: 0.82em; color: #567; }
            .upload-form input[type='file'] { max-width: 100%; }
            .upload-form button { border: 0; border-radius: 5px; padding: 4px 8px; font-size: 0.82em; font-family: inherit; background: #99f6e4; color: #134e4a; font-weight: 600; cursor: pointer; }
            .upload-form button:hover { background: #5eead4; }
            .entries { columns: 5; column-gap: 20px; column-rule: 1px solid #ddd; padding: 0 12px; }
            @media (max-width: 1600px) { .entries { columns: 4; } }
            @media (max-width: 1200px) { .entries { columns: 3; } }
            @media (max-width: 768px) { .entries { columns: 2; } }
            @media (max-width: 480px) { .entries { columns: 1; } }
            .letter-group { display: inline-block; width: 100%; margin-bottom: 10px; break-inside: avoid; -webkit-column-break-inside: avoid; page-break-inside: avoid; }
            .letter-heading { font-size: 1.1em; font-weight: bold; color: teal; margin-top: 12px; margin-bottom: 6px; break-after: avoid; }
            .entries a { display: block; padding: 3px 0; text-decoration: none; color: #0066cc; line-height: 1.5; break-inside: avoid; transition: color 150ms ease; font-size: 0.95em; }
            .entries a:hover { text-decoration: underline; color: #0052a3; }"
          }</style>
        </head>
        <body>
          <div class="top-nav">
            <a class="back-link" href="{ $backHref }">&#8592; { $database }</a>
            <div class="upload-row">
              <form class="upload-form" method="post" enctype="multipart/form-data" autocomplete="off" action="{ $uploadHref }">
                <input id="upload-file" type="file" name="file" accept=".xml,application/xml,text/xml" required="required" />
                <button type="submit">Upload XML</button>
              </form>
            </div>
          </div>
          <h1>{ $title }</h1>
          <div class="entries">
            { $entries }
          </div>
        </body>
      </html>
  };
