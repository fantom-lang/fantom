//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   16 Aug 2023  Matthew Giannini  Creation
//

using util

internal class ExtractCmd : NodeJsCmd
{
  override Str name() { "extract" }

  override Str summary() { "Extract JavaScript files from pods" }

  @Opt { help = "Directory to extract files into" }
  override File dir := Env.cur.tempDir.plus(`extract/`)

  @Opt { help = "Clean target directory before extracting files" }
  Bool clean := false

  @Arg { help = "If specified, only extract for these pods. Otherwise, extract for all pods" }
  Str[] pods := [,]

  override Int run()
  {
    if (this.clean) this.dir.delete

    todo := Pod.list
    if (!pods.isEmpty) todo = pods.map |name->Pod| { Pod.find(name) }
    todo.each |pod|
    {
      f := pod.file(`/js/${pod.name}.js`, false)
      if (f == null) return
      log.info("Extract ${pod.name}.js")
      out := dir.plus(`${pod.name}.js`).out
      f.in.pipe(out)
      out.flush.close
    }
    log.info("Extracted JavaScript to ${this.dir}")
    return 0
  }

}