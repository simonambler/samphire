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

module namespace page = "http://www.jsodium.org/samphire/home";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = 'http://www.w3.org/2010/xslt-xquery-serialization';
declare namespace db = 'http://basex.org/modules/db';
declare namespace web = 'http://basex.org/modules/web';
declare namespace update = 'http://basex.org/modules/update';

import module namespace session = 'http://basex.org/modules/session';

declare variable $page:demo-database-name := 'demo';
declare variable $page:demo-database-source := '/var/lib/jetty/basex/sample/demo';

declare
  %rest:path("/samphire/home")
  %rest:GET
  %output:method("html")
  %output:version("5.0")
  function page:home() as element(Q{http://www.w3.org/1999/xhtml}html) {
    let $authUser := session:get('authUser')
    let $databases := sort(db:list())
    let $databaseLinks :=
      for $database in $databases
      let $href := concat('/samphire/data/', fn:encode-for-uri($database), '/view')
      return <a class="btn btn-primary db-button" href="{$href}">{$database}</a>
    return
        <html xmlns='http://www.w3.org/1999/xhtml'>
            <head>
              <meta charset="UTF-8" />
              <link rel="apple-touch-icon" sizes="180x180" href="/static/samphire/images/favicon_io/apple-touch-icon.png" />
              <link rel="icon" type="image/png" sizes="32x32" href="/static/samphire/images/favicon_io/favicon-32x32.png" />
              <link rel="icon" type="image/png" sizes="16x16" href="/static/samphire/images/favicon_io/favicon-16x16.png" />
              <link rel="manifest" href="/static/samphire/images/favicon_io/site.webmanifest" />
              <meta name="viewport" content="width=device-width, initial-scale=1.0" />
              <title>Samphire - Character Sheet Server</title>
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
                
                .container {{
                  background: white;
                  border-radius: 20px;
                  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                  padding: 60px 50px;
                  max-width: 900px;
                  width: 100%;
                  text-align: center;
                }}

                .site-logo {{
                  width: 120px;
                  max-width: 40%;
                  height: auto;
                  margin-bottom: 16px;
                }}
                
                h1 {{
                  color: #333;
                  font-size: 3em;
                  margin-bottom: 10px;
                  font-weight: 700;
                  background: linear-gradient(135deg, #0891b2 0%, #10b981 100%);
                  -webkit-background-clip: text;
                  -webkit-text-fill-color: transparent;
                  background-clip: text;
                }}
                
                h2 {{
                  color: #666;
                  font-size: 1.3em;
                  margin-bottom: 20px;
                  font-weight: 400;
                }}
                
                .status {{
                  color: #555;
                  font-size: 1.1em;
                  margin-bottom: 30px;
                  padding: 15px;
                  background: #f8f9fa;
                  border-radius: 10px;
                }}
                
                .status strong {{
                  color: #0891b2;
                  font-weight: 600;
                }}

                .intro {{
                  color: #5f6b76;
                  font-size: 1em;
                  line-height: 1.6;
                  margin-bottom: 24px;
                }}

                .db-grid {{
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
                  gap: 12px;
                  margin-bottom: 28px;
                }}

                .db-button {{
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  min-height: 78px;
                  font-size: 1.15em;
                }}

                .demo-form {{
                  margin-bottom: 28px;
                }}
                
                .btn {{
                  display: inline-block;
                  padding: 15px 40px;
                  font-size: 1.1em;
                  font-weight: 600;
                  font-family: inherit;
                  text-decoration: none;
                  border-radius: 10px;
                  transition: all 0.3s ease;
                  border: none;
                  cursor: pointer;
                }}
                
                .btn-primary {{
                  background: linear-gradient(135deg, #0891b2 0%, #0d9488 100%);
                  color: white;
                }}
                
                .btn-primary:hover {{
                  transform: translateY(-2px);
                  box-shadow: 0 10px 25px rgba(8, 145, 178, 0.45);
                }}
                
                .btn-secondary {{
                  background: #197a91;
                  color: white;
                }}
                
                .btn-secondary:hover {{
                  background: #15677a;
                  transform: translateY(-2px);
                  box-shadow: 0 10px 25px rgba(25, 122, 145, 0.35);
                }}

                .btn-demo {{
                  background: #5a71ed;
                  color: white;
                }}

                .btn-demo:hover {{
                  transform: translateY(-2px);
                  box-shadow: 0 10px 25px rgba(37, 99, 235, 0.35);
                }}

                @media (max-width: 640px) {{
                  .container {{
                    padding: 36px 20px;
                  }}
                  h1 {{
                    font-size: 2.4em;
                  }}
                }}
              </style>
            </head>
            <body>
              <div class="container">
                <img class="site-logo" src="/static/samphire/images/logo.svg" alt="Samphire logo" />
                <h1>Samphire</h1>
                <h2>Character sheet server</h2>
                <p class="status">Signed in as <strong>{$authUser}</strong>.</p>
                <p class="intro">{
                  if (exists($databaseLinks))
                  then 'Select a database.'
                  else 'No databases are currently available.'
                }</p>
                {
                  if (exists($databaseLinks)) then
                    <div class="db-grid">{ $databaseLinks }</div>
                  else
                    <form class="demo-form" action="/samphire/home/load-demo" method="post">
                      <button class="btn btn-demo" type="submit">Load demo database</button>
                    </form>
                }
                <a class="btn btn-secondary" href="/samphire/logout">Logout</a>
                <p style="margin-top: 20px; font-size: 0.9em; color: #999;">
                  Copyright © 2022-2026 Simon Ambler · <a href="/static/samphire/src/samphire.zip" target="_blank" style="color: #0891b2; text-decoration: none;">Source</a> · <a href="/static/samphire/LICENSE.txt" target="_blank" style="color: #0891b2; text-decoration: none;">License (AGPL-3.0)</a>
                </p>
              </div>
            </body>
        </html>
    };

declare
  %updating
  %rest:path('/samphire/home/load-demo')
  %rest:POST
  function page:load-demo() as empty-sequence() {
    (
      if (not(db:exists($page:demo-database-name))) then
        db:create(
          $page:demo-database-name,
          $page:demo-database-source,
          (),
          map {
            'createfilter': '*.xml',
            'addraw': true()
          }
        )
      else (),
      update:output(web:redirect('/samphire/home'))
    )
  };
