//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 08  Andy Frank  Creation
//

using web
using webapp

class Flash : Widget
{

  override Void onGet()
  {
    f := flash["flashTest"]
    if (f != null)
    {
      body.div("style='color:$fg; background:#ffc; padding:10px;'")
      body.esc(f)
      body.divEnd
    }

    f = flash["flashTest.$uri"]
    if (f != null)
    {
      body.div("style='color:$fg; background:$bg; padding:10px;'")
      body.esc(f)
      body.divEnd
    }

    action := toInvoke(&onPost)
    body.form("method='post' action='$action'")
    body.p
    body.submit("value='$label'")
    body.pEnd
    body.formEnd
  }

  override Void onPost()
  {
    flash["flashTest"] = "Everyone gets this flash!"
    flash["flashTest.$uri"] = "Only me: $text"
    res.redirect(req.uri)
  }

  Str label := "Flash"
  Str text  := "You got flashed!"
  Str fg    := "#000"
  Str bg    := "#ff8"

}