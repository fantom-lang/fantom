//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jul 2023  Matthew Giannini  Creation
//

**
** JsExtToMime
**
class JsExtToMime
{
  new make(ModuleSystem ms) { this.ms = ms }

  private ModuleSystem ms

  Void write(OutStream out)
  {
    ms.writeBeginModule(out)
    ms.writeInclude(out, "sys.ext")

    props := Env.cur.findFile(`etc/sys/ext2mime.props`).readProps
    out.printLine("const c=sys.MimeType.__cache;")
    props.each |mime, ext|
    {
      out.printLine("c(${ext.toCode},${mime.toCode});")
    }
    ms.writeEndModule(out)
  }
}
