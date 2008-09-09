//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 08  Andy Frank  Creation
//

using web
using webapp

class TabPane : Widget
{
  Void addTab(Uri uri, Str label)
  {
    uris.add(uri)
    labels.add(label)
  }

  override Void onGet()
  {
    body.p("style='background: #eee; border:1px solid #ccc; padding: 10px'")
    uris.size.times |Int i|
    {
      if (i > 0) body.w(" | ")
      body.a(uris[i]).w(labels[i]).aEnd
    }
    body.pEnd
  }

  private Uri[] uris   := Uri[,]
  private Str[] labels := Str[,]

}