//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 2011  Andy Frank  Creation
//

using fwt
using gfx
using web

**
** TransitionPaneTest
**
@Js
internal class TransitionPaneTest : ContentPane
{
  new make()
  {
    content = InsetPane(24)
    {
      GridPane
      {
        vgap = 24
        hgap = 24
        sample("style=\"flip\"",    "flip"),
        sample("style=\"slideUp\"", "slideUp"),
      },
    }
  }

  Widget sample(Str text, Str style)
  {
    ConstraintPane
    {
      minw=300; maxw=300
      minh=300; maxh=300
      p := TransitionPane { it.style=style }
      p.content = foo(text, p)
      p,
    }
  }

  Widget foo(Str text, TransitionPane p)
  {
    BorderPane
    {
      bg = Color("#eee")
      GridPane
      {
        halignPane = Halign.center
        valignPane = Valign.center
        Label { it.text=text },
        Button
        {
          it.text = "Transition"
          it.onAction.add |e| { p.transitionTo(bar(text, p)) }
        },
      },
    }
  }

  Widget bar(Str text, TransitionPane p)
  {
    BorderPane
    {
      bg = Color("#666")
      GridPane
      {
        halignPane = Halign.center
        valignPane = Valign.center
        Label { it.text=text; fg=Color.white },
        Button
        {
          it.text = "Transition"
          it.onAction.add |e| { p.transitionTo(foo(text, p)) }
        },
      },
    }
  }
}