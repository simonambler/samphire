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

module namespace login = "http://www.jsodium.org/samphire/login";
declare namespace perm = 'http://basex.org/modules/perm';

import module namespace session = 'http://basex.org/modules/session';

declare function login:is-public-path($path as xs:string?) as xs:boolean {
  $path = ('/samphire/login')
};

declare function login:consume-request-path() as xs:string {
  let $requestPath := session:get('requestPath')
  let $_ := session:delete('requestPath')
  return if (exists($requestPath) and normalize-space($requestPath) != '')
    then $requestPath
    else '/samphire/home'
};

(: Compute access rights for a user to a document
   Returns a map with hasReadAccess and hasWriteAccess boolean keys :)
declare function login:access-rights(
  $authUser as xs:string,
  $database as xs:string,
  $sheet as element(y-sheet)
) as map(*) {
  let $owner := $sheet/@owner/string()
  let $readList := $sheet/@read/string()
  let $writeList := $sheet/@write/string()
  let $authUserInfo := user:info($authUser)
  let $isAdmin := exists($authUser) and (
    $authUserInfo/role[not(@database) and text() = 'admin'] or
    $authUserInfo/role[@database = $database and text() = 'admin']
  )
  let $isOwner := $authUser = $owner
  let $readTokens := tokenize($readList, ',\s*')
  let $writeTokens := tokenize($writeList, ',\s*')
  let $isInReadList := $authUser = $readTokens
  let $isInWriteList := $authUser = $writeTokens
  let $isReadPublic := $readList = ('public', 'all', 'everyone')
  let $isWritePublic := $writeList = ('public', 'all', 'everyone')
  let $hasReadAccess := 
    $isAdmin or 
    $isOwner or 
    $isInReadList or 
    $isReadPublic
  let $hasWriteAccess := 
    $isAdmin or 
    $isOwner or 
    $isInWriteList or 
    $isWritePublic
  return map {
    'isAdmin': $isAdmin,
    'hasReadAccess': $hasReadAccess,
    'hasWriteAccess': $hasWriteAccess
  }
};

declare
  %perm:check("/samphire", "{$info}")
  function login:checkauth($info as map(*)) as element()? {
    let $authUser := session:get('authUser')
    where empty($authUser)
      and not(login:is-public-path($info?path))
    return
      if ($info?method = 'GET')
      then (
        session:set('requestPath', $info?path),
        web:redirect('/samphire/login')
      )
      else web:error(401, 'Unauthorized')
  };

declare
  %perm:check('/samphire', '{$info}')
  function login:checkperm($info as map(*)) as empty-sequence() {
    let $tokens := tokenize($info?path, '/')
    where $tokens[2] = 'data' and count($tokens) >= 7
    let $database := $tokens[3]
    let $type := $tokens[5]
    let $document := $tokens[7]
    where exists($database) and exists($type) and exists($document)
    let $path := $database || '/' || $type || '/' || $document || '.xml'
    where doc-available($path)
    let $authUser := session:get('authUser')
    let $method := $info?method
    let $doc := doc($path)
    let $sheet := $doc/y-sheet
    let $access := login:access-rights($authUser, $database, $sheet)
    let $hasReadAccess := $method = 'GET' and $access?hasReadAccess
    let $hasWriteAccess := ($method = 'PUT' or $method = 'POST') and $access?hasWriteAccess
    where not($hasReadAccess or $hasWriteAccess)
    return web:error(403, 'No permission.')
  };

declare
  %rest:path("/samphire/login")
  %rest:GET
  %rest:query-param("error", "{$error}")
  %output:method("html")
  function login:login($error as xs:string?) as element() {
    let $authUser := session:get('authUser')
    let $loginError := if (exists($error))
      then <p class="error">Wrong username or password.</p>
      else ()
    return
      if (exists($authUser))
      then web:redirect(login:consume-request-path())
      else <html>
      <head>
        <meta charset="UTF-8" />
        <link rel="apple-touch-icon" sizes="180x180" href="/static/samphire/images/favicon_io/apple-touch-icon.png" />
        <link rel="icon" type="image/png" sizes="32x32" href="/static/samphire/images/favicon_io/favicon-32x32.png" />
        <link rel="icon" type="image/png" sizes="16x16" href="/static/samphire/images/favicon_io/favicon-16x16.png" />
        <link rel="manifest" href="/static/samphire/images/favicon_io/site.webmanifest" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Login - Samphire</title>
        <style>
          * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }}
          
          body {{
            font-family: Cochin, Georgia, Times, 'Times New Roman', serif;
            background: linear-gradient(160deg, #0c4a6e 0%, #134e4a 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }}
          
          .login-container {{
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 50px 40px;
            width: 400px;
            max-width: 100%;
            text-align: center;
          }}

          .site-logo {{
            width: 102px;
            max-width: 40%;
            height: auto;
            margin-bottom: 14px;
          }}
          
          h1 {{
            color: #333;
            font-size: 2.5em;
            margin-bottom: 10px;
            text-align: center;
            font-weight: 700;
            background: linear-gradient(135deg, #0891b2 0%, #10b981 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
          }}
          
          .subtitle {{
            color: #666;
            text-align: center;
            margin-bottom: 35px;
            font-size: 1em;
          }}

          .error {{
            color: #9f1239;
            background: #ffe4e6;
            border: 1px solid #fecdd3;
            border-radius: 10px;
            padding: 12px 14px;
            margin-bottom: 20px;
            text-align: center;
            font-weight: 600;
          }}
          
          .form-group {{
            margin-bottom: 25px;
          }}
          
          label {{
            display: block;
            color: #555;
            font-weight: 600;
            margin-bottom: 8px;
            font-size: 0.95em;
          }}
          
          input[type="text"],
          input[type="password"] {{
            width: 100%;
            padding: 14px 16px;
            border: 2px solid #e1e8ed;
            border-radius: 10px;
            font-size: 1em;
            transition: all 0.3s ease;
            background: #f8f9fa;
          }}
          
          input[type="text"]:focus,
          input[type="password"]:focus {{
            outline: none;
            border-color: #0891b2;
            background: white;
            box-shadow: 0 0 0 3px rgba(8, 145, 178, 0.15);
          }}
          
          input[type="submit"] {{
            width: 100%;
            padding: 15px;
            background: linear-gradient(160deg, #0c4a6e 0%, #134e4a 100%);
            color: white;
            border: none;
            border-radius: 10px;
            font-family: Cochin, Georgia, Times, 'Times New Roman', serif;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 10px;
          }}
          
          input[type="submit"]:hover {{
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(8, 145, 178, 0.45);
          }}
          
          input[type="submit"]:active {{
            transform: translateY(0);
          }}

          .note {{
            color: #666;
            text-align: center;
            margin-top: 24px;
            font-size: 0.95em;
          }}
        </style>
      </head>
      <body>
        <div class="login-container">
          <img class="site-logo" src="/static/samphire/images/logo.svg" alt="Samphire logo" />
          <h1>Samphire</h1>
          <p class="subtitle">Please log in to continue</p>
          {$loginError}
          <form action="/samphire/login" method="post">
            <div class="form-group">
              <label for="name">Username</label>
              <input type="text" id="name" name="name" required="required" autofocus="autofocus" placeholder="Enter your username" />
            </div>
            <div class="form-group">
              <label for="pass">Password</label>
              <input type="password" id="pass" name="pass" required="required" placeholder="Enter your password" />
            </div>
            <input type="submit" value="Login" />
          </form>
          <p class="note">Use your Samphire account credentials to continue.</p>
        </div>
      </body>
    </html>
  };

declare
  %rest:path("/samphire/login")
  %rest:POST
  %rest:form-param("name", "{$name}")
  %rest:form-param("pass", "{$pass}")
  function login:checkpass($name as xs:string, $pass as xs:string) as element() {
    try {
      user:check($name, $pass),
      session:set('authUser', $name),
      web:redirect(login:consume-request-path())
    } catch user:* {
      web:redirect('/samphire/login?error=1')
    }
  };

declare
  %rest:path("/samphire/logout")
  %rest:GET
  function login:logout() as element() {
    session:delete('authUser'),
    session:delete('requestPath'),
    web:redirect('/samphire/login')
  };
