#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Sep 09  Brian Frank  Creation
//

using build
using compiler
using docCompiler

**
** Build: examples
**
class Build : BuildScript
{
  Str[] toc :=
  [
    "sys/",          "sys",
      "stmts",       "Basic language statement constructs",
      "lists",       "Working with sys::List",
      "maps",        "Working with sys::Map",
      "files",       "Working with sys::File",
      "logging",     "Working with sys::Log",
      "reflection",  "Working with sys::Pod, sys::Type, sys::Slot",
      "wordcount",   "File IO, Str split, Maps",
    "concurrent/",   "concurrent",
      "actors",      "Working with sys::Actor",
    "fwt/",          "fwt",
      "hello",       "Hello world with FWT",
      "demo",        "Shows off just about everything at once",
      "desktop",     "Paints desktop monitor configuration",
      "clock",       "FWT combined with Actors",
      "richtext",    "Basic RichText document model",
      "scrollpane",  "Using ScrollPane",
      "gradient",    "Gradients (at least what SWT supports)",
    "email/",        "email",
      "sending",     "Sending email via SMTP",
    "js/",           "js",
      "demo",        "Run web server to demo Fantom to JavaScript in browser",
    "java/",         "java",
      "hello",       "Hello world with Java FFI",
      "swing",       "Swing application using Java FFI",
      "buildjardist","Build fansh into a single JAR for deployment",
    "util/",         "util",
      "main",        "Working with util::AbstractMain",
    "web/",          "web",
      "client",      "Working with web::WebClient",
      "hello",       "Hello world web server application",
      "demo",        "Illustrates some basic web APIs",
  ]

  @Target { help = "Compile example code into HTML" }
  Void compile()
  {
    log.info("Compile code into HTML!")

    // create fresh directory
    dir := scriptDir
    docDir := scriptDir + `../doc/examples/`
    Delete(this, docDir).run
    CreateDir(this, docDir).run

    // walk index which is structured as name/blurb pairs
    fail := false      // keep track of failures
    odd := true        // for index color banding
    index := StrBuf()  // HTML content for index page
    for (i:=0; i<toc.size; i += 2)
    {
      name  := toc[i]
      blurb := toc[i+1]

      // if name ends in slash it is a directory heading
      if (name[-1] == '/')
      {
        dir = scriptDir + name.toUri
        log.info("  --- $blurb ---")
        if (!index.isEmpty) index.add("</table>\n")
        index.add("<h1>$blurb</h1>\n")
        index.add("<table>\n")
        continue
      }

      // map to file
      srcFile := dir + `${name}.fan`
      if (!srcFile.exists)
      {
        log.err("index file missing $srcFile")
        fail = true
        continue
      }

      // process the file
      log.info("    $srcFile ...")

      // verify it compiles
      Type? t
      try
        t = Env.cur.compileScript(srcFile)
      catch (Err e)
      {
        log.err("Failed to compile $srcFile", e)
        fail = true
        continue
      }

      // compile to source
      docFile := docDir + `${dir.name}-${name}.html`
      DocCompiler().compileSourceToHtml(t, srcFile, docFile, "examples", docFile.name)

      // add to index content
      cls := odd ? "odd" : "even"; odd = !odd
      index.add("<tr class='$cls'>\n")
      index.add("  <td><a href='$docFile.name'>$name</a></td>\n")
      index.add("  <td>$blurb</td>\n")
      index.add("</tr>\n")
    }

    // finish up index
    index.add("</table>\n")
    indexFile := docDir + `index.html`
    ExampleIndexGenerator(DocCompiler(), indexFile.out, index.toStr).generate

    // if we had any failures
    if (fail) throw fatal("One or more files failed to compile!")
  }

}

**************************************************************************
** ExampleIndexGenerator
**************************************************************************

class ExampleIndexGenerator : HtmlGenerator
{

  new make(DocCompiler compiler, OutStream out, Str contentStr)
    : super(compiler, Loc("example index"), out)
  {
    this.contentStr = contentStr
  }

  override Str title() { "examples" }

  override Void header()
  {
    out.print("<ul>\n")
    out.print("  <li><a href='../index.html'>$docHome</a></li>\n")
    out.print("  <li><a href='index.html'>$title</a></li>\n")
    out.print("</ul>\n")
  }

  override Void content() { out.print(contentStr) }

  Str contentStr
}

