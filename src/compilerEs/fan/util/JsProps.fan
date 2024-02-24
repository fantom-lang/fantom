//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Feb 2024  Matthew Giannini  Creation
//

**
** JsProps
**
class JsProps
{
  static Void writePod(OutStream out, Pod pod, Uri uri, Duration maxAge := 1sec)
  {
    props := Env.cur.props(pod, uri, maxAge)
    writeProps(out, "${pod.name}:${uri}", props)
  }

  static Void writeProps(OutStream out, Str key, Str:Str props)
  {
    if (!props.isEmpty) doWrite(JsWriter(out), key, props)
  }

  internal static Void doWrite(JsWriter js, Str key, Str:Str props)
  {
    js.wl("(function() {")
    js.wl("let m = sys.Map.make(sys.Str.type\$, sys.Str.type\$);")
    props.each |v,k| { js.wl("m.set(${k.toCode},${v.toCode});") }
    js.wl("sys.Env.cur().__props(${key.toCode}, m);")
    js.wl("})();")
  }
}
