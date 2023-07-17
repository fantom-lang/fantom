#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Aug 2022  Kiera O'Flynn   Pull out of buildfan
//

using util

**
** A set of non-exhaustive tests to ensure basic functionality.
**
@NoDoc
class PrepTest
{
  static Void main()
  {
    // Find target directory
    target := Env.cur.homeDir + `etc/yaml/tests/`

    // Delete old directory, if applicable
    if (target.exists) target.delete
    target.create

    // Download JSON to get URI for latest data
    tagsUri := `https://api.github.com/repos/yaml/yaml-test-suite/tags`
    json := ([Str:Str][])JsonInStream(httpGet(tagsUri)).readJson
    tag := json.find |tag| { tag["name"].startsWith("data") }

    // Download zip of latest data and unzip
    zipUri := tag["zipball_url"].toUri
    zip := Zip.read(httpGet(zipUri))
    File? f
    echo("Extracting...")
    while ((f = zip.readNext) != null)
    {
      if (f.uri == `/`) continue
      if (!f.uri.toStr.contains("/tags/") && !f.uri.toStr.contains("/name/"))
      {
        dst := f.uri.relTo(("/${f.uri.path[0]}/").toUri)
        if (!dst.isDir) echo("  Extract [$dst]")
        f.copyTo(target + dst, ["overwrite":false])
      }
    }

    echo
    echo("SUCCESS: downloaded tests [$target.osPath]")
    echo
  }

  static InStream httpGet(Uri uri)
  {
    // use reflection so we don't need to depend on web
    echo
    echo("Fetching $uri ...")
    echo
    client := Type.find("web::WebClient").make([uri])
    client->reqHeaders = Str:Str[:] { caseInsensitive = true }.add("User-Agent", "Fantom/1.0")
    return client->getIn
  }
}