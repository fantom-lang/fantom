//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 10  Andy Frank  Creation
//

using compiler

**
** JsProps
**
class JsProps : JsNode
{
  new make(PodDef pod, File file, Uri uri, JsCompilerSupport s) : super(s)
  {
    this.pod  = pod
    this.file = file
    this.uri  = uri
  }

  static Void writeProps(Pod pod, Uri uri, OutStream out)
  {
    base := `fan://$pod.name/`
    file := pod.files.find |f| { f.uri.relTo(base) == uri }
    if (file == null) throw Err("File not found $pod: $uri")
    doWrite(pod.name, file, uri, JsWriter(out))
  }

  override Void write(JsWriter out)
  {
    doWrite(pod.name, file, uri, out)
  }

  private static Void doWrite(Str pod, File file, Uri uri, JsWriter out)
  {
    key := "$pod:$uri"
    out.w("with (fan.sys.Env.cur().\$props($key.toCode))").nl
    out.w("{").nl
    out.indent
    file.in.readProps.each |v,k| { out.w("set($k.toCode,$v.toCode);").nl }
    out.unindent
    out.w("}").nl
  }

  PodDef pod  // pod container
  File file   // props file
  Uri uri     // relative uri to prop file
}

