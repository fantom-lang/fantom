//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 10  Andy Frank  Creation
//

**
** JsProps compiles pod prop files into JavaScript source code
** that the Fantom JavaScript runtime can interpret.
**
class JsProps
{
  **
  ** Make for specified output stream.
  **
  new make(OutStream out)
  {
    this.out = out
    out.printLine("var p = null;")
  }

  **
  ** Write locale props for given pod.
  **
  Void writeLocale(Pod pod, Locale locale := Locale.cur)
  {
    writeProps(pod, `locale/${locale.lang}.props`)
    if (locale.country != null) writeProps(pod, `locale/${locale}.props`)
  }

  **
  ** Write prop file.
  **
  private Void writeProps(Pod pod, Uri uri)
  {
    key := "$pod.name:$uri"
    if (cache.containsKey(key)) return
    cache[key] = key

    out.printLine("p = fan.sys.Env.cur().\$props($key.toCode);")
    props := Env.cur.props(pod, uri, Duration.maxVal)
    props.each |v,k| { out.printLine("p.set($k.toCode,$v.toCode);") }
  }

  private OutStream out
  private Str:Str cache := Str:Str[:]
}