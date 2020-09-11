//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 20  Matthew Giannini  Creation
//

**
** JsExtToMime
**
class JsExtToMime
{
  Void write(OutStream out)
  {
    props := Env.cur.findFile(`etc/sys/ext2mime.props`).readProps
    out.printLine(
      "(function() {
        ${JsPod.requireSys}
        var c=fan.sys.MimeType.cache\$;
        ")

    props.each |mime, ext|
    {
      out.printLine("c($ext.toCode,$mime.toCode);")
    }

    out.printLine("}).call(this);")
  }
}
