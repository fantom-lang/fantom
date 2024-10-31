//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

**
** HTML writer for markdown rendering
**
@Js
class HtmlWriter
{
  new make(OutStream out)
  {
    this.out = out
  }

  private OutStream out
  private Int lastChar := 0

  This line()
  {
    if (lastChar != 0 && lastChar != '\n') w("\n")
    return this
  }

  This raw(Str s) { w(s) }

  This text(Str text) { w(Esc.escapeHtml(text)) }

  This tag(Str name, [Str:Str?]? attrs := null, Bool empty := false)
  {
    w("<")
    w(name)
    if (attrs != null && !attrs.isEmpty)
    {
      attrs.each |v, k|
      {
        w(" ")
        w(Esc.escapeHtml(k))
        if (v != null)
        {
          w("=\"")
          w(Esc.escapeHtml(v))
          w("\"")

        }
      }
    }
    if (empty) w(" /")
    w(">")
    return this
  }

  protected This w(Str s)
  {
    out.writeChars(s)
    if (!s.isEmpty) lastChar = s[-1]
    return this
  }
}