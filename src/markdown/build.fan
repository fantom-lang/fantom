#! /usr/bin/env fan
//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   07 Oct 2024  Matthew Giannini  Creation
//

using build

**
** Build: markdown
**
class Build : BuildPod
{
  new make()
  {
    podName = "markdown"
    summary = "Markdown parsing and rendering"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0",
              ]
    srcDirs = [`fan/`,
               `fan/ast/`,
               `fan/ext/`,
               `fan/ext/xetodoc/`,
               `fan/ext/gfm-tables/`,
               `fan/ext/image-attributes/`,
               `fan/parser/`,
               `fan/parser/block/`,
               `fan/parser/inline/`,
               `fan/render/`,
               `fan/render/html/`,
               `fan/render/markdown/`,
               `fan/render/text/`,
               `fan/util/`,
               `test/`,
               `test/ext/`,
               `test/markdown/`,
              ]
    docSrc  = true
  }

  @Target { help = "Compile to pod file" }
  override Void compile()
  {
    codegen
    super.compile
  }

  @Target { help = "Auto-generate HTML5 entities" }
  Void codegen()
  {
    html5    := scriptDir + `fan/util/Html5.fan`
    entities := scriptDir + `res/entities.txt`

    // short-circuit if the entities file is older than the generated html5 file
    if (html5.modified != null && entities.modified != null &&
        html5.modified > entities.modified) { return }

    src := html5.readAllStr
    out := html5.out
    inStart := false
    lines := src.splitLines
    lines.each |line, i|
    {
      if (inStart && line.contains("/* codegen-end */"))
      {
        ts  := "  "
        out.writeChars("${ts}private static const [Str:Str] named_char_refs := [\n")
        entities.eachLine |entity|
        {
          if (entity.isEmpty) return
          parts := entity.split('=')
          out.writeChars("${ts}${ts}${parts[0].toCode}: ${parts[1].toCode},\n")
        }
        out.writeChars("${ts}${ts}\"NewLine\": \"\\n\",\n")
        out.writeChars("${ts}]\n")
        out.writeChars("${line}\n")
        inStart = false
      }
      else if (line.contains("/* codegen-start */"))
      {
        out.writeChars("${line}\n")
        inStart = true
      }
      else if (!inStart)
      {
        out.writeChars("${line}")
        if (i+1 != lines.size) out.writeChar('\n')
      }
    }
    out.close
  }
}