//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 2011  Andy Frank  Creation
//

using fwt
using gfx
using web

**
** WebListTest
**
@Js
internal class WebListTest : ContentPane
{
  new make()
  {
    content = InsetPane(12)
    {
      GridPane
      {
        vgap = 3
        BorderPane {                      insets=Insets(12); treeListWhite, },
        BorderPane { bg=Color("#d4dbe3"); insets=Insets(12); treeListPale,  },
        BorderPane { bg=Color("#333");    insets=Insets(12); treeListHud,   },
      },
    }
  }

  Widget treeListWhite()
  {
    GridPane
    {
      hgap = 24
      numCols = 4

      TestList {
        items=[
          TestItem { text="Boulevard" },
          TestItem { text="Grove" },
          TestItem { text="Mulberry" },
          TestItem { text="Stuart" }
        ]
      },

      TestList {
        items=[
          TestItem { text="Boulevard"; icon=iconFolder; aux="10" },
          TestItem { text="Grove";     icon=iconFolder; aux="7"  },
          TestItem { text="Mulberry";  icon=iconFolder; aux="8"  },
          TestItem { text="Stuart" ;   icon=iconFolder; aux="22" }
        ]
      },

      TestList {
        //borderColor = Color("#d2d2d2")
        style = "pill"
        items=[
          TestItem { text="Boulevard"; icon=iconFolder; aux="2" },
          TestItem { text="Grove";     icon=iconFolder; depth=1; aux="3" },
          TestItem { text="Mulberry";  icon=iconFolder; depth=2 },
          TestItem { text="Stuart" ;   icon=iconFolder; depth=3; aux="1"; }
        ]
      },

      TestList {
        items=[
          TestItem { text="Zone A"; group=true },
          TestItem { text="Boulevard"; icon=iconFolder },
          TestItem { text="Grove";     icon=iconFolder },
          TestItem { text="Zone B"; group=true },
          TestItem { text="Mulberry";  icon=iconFolder },
          TestItem { text="Stuart" ;   icon=iconFolder }
        ]
      },
    }
  }

  Widget treeListPale()
  {
    GridPane
    {
      hgap = 24
      numCols = 4

      TestPaleList {
        items=[
          TestItem { text="Boulevard" },
          TestItem { text="Grove" },
          TestItem { text="Mulberry" },
          TestItem { text="Stuart" }
        ]
      },

      TestPaleList {
        items=[
          TestItem { text="Boulevard"; icon=iconFolder; aux="10" },
          TestItem { text="Grove";     icon=iconFolder; aux="7"  },
          TestItem { text="Mulberry";  icon=iconFolder; aux="8"  },
          TestItem { text="Stuart" ;   icon=iconFolder; aux="22" }
        ]
      },

      TestPaleList {
        style = "pill"
        items=[
          TestItem { text="Boulevard"; icon=iconFolder; aux="2" },
          TestItem { text="Grove";     icon=iconFolder; depth=1; aux="3" },
          TestItem { text="Mulberry";  icon=iconFolder; depth=2 },
          TestItem { text="Stuart" ;   icon=iconFolder; depth=3; aux="1"; }
        ]
      },

      TestPaleList {
        items=[
          TestItem { text="Zone A"; group=true },
          TestItem { text="Boulevard"; icon=iconFolder },
          TestItem { text="Grove";     icon=iconFolder },
          TestItem { text="Zone B"; group=true },
          TestItem { text="Mulberry";  icon=iconFolder },
          TestItem { text="Stuart" ;   icon=iconFolder }
        ]
      },
    }
  }

  Widget treeListHud()
  {
    GridPane
    {
      hgap = 24
      numCols = 4

      TestHudList {
        items=[
          TestItem { text="Boulevard" },
          TestItem { text="Grove" },
          TestItem { text="Mulberry" },
          TestItem { text="Stuart" }
        ]
      },

      TestHudList {
        items=[
          TestItem { text="Boulevard"; icon=iconFolder; aux="10" },
          TestItem { text="Grove";     icon=iconFolder; aux="7"  },
          TestItem { text="Mulberry";  icon=iconFolder; aux="8"  },
          TestItem { text="Stuart" ;   icon=iconFolder; aux="22" }
        ]
      },

      TestHudList {
        style = "pill"
        //borderColor = Color("#444")
        items=[
          TestItem { text="Boulevard"; icon=iconFolder; aux="2" },
          TestItem { text="Grove";     icon=iconFolder; depth=1; aux="3" },
          TestItem { text="Mulberry";  icon=iconFolder; depth=2 },
          TestItem { text="Stuart" ;   icon=iconFolder; depth=3; aux="1"; }
        ]
      },

      TestHudList {
        items=[
          TestItem { text="Zone A"; group=true },
          TestItem { text="Boulevard"; icon=iconFolder },
          TestItem { text="Grove";     icon=iconFolder },
          TestItem { text="Zone B"; group=true },
          TestItem { text="Mulberry";  icon=iconFolder },
          TestItem { text="Stuart" ;   icon=iconFolder }
        ]
      },
    }
  }

  static const Image iconFolder := Image(`fan://icons/x16/folder.png`)
}

@Js
internal class TestList : TreeList
{
  Str? style
  override Size prefSize(Hints hints := Hints.defVal) { Size(175,225) }
  override Bool isHeading(Obj item) { item->group }
  override Str text(Obj item) { item->text }
  override Image? icon(Obj item, Bool sel) { item->icon }
  override Int depth(Obj item) { item->depth }
  override Str? aux(Obj item) { item->aux }
  override Str auxStyle() { style ?: super.auxStyle }
}

@Js
internal class TestPaleList : PaleTreeList
{
  Str? style
  override Size prefSize(Hints hints := Hints.defVal) { Size(175,225) }
  override Bool isHeading(Obj item) { item->group }
  override Str text(Obj item) { item->text }
  override Image? icon(Obj item, Bool sel) { item->icon }
  override Int depth(Obj item) { item->depth }
  override Str? aux(Obj item) { item->aux }
  override Str auxStyle() { style ?: super.auxStyle }
}

@Js
internal class TestHudList : HudList
{
  Str? style
  override Size prefSize(Hints hints := Hints.defVal) { Size(175,225) }
  override Bool isHeading(Obj item) { item->group }
  override Str text(Obj item) { item->text }
  override Image? icon(Obj item, Bool sel) { item->icon }
  override Int depth(Obj item) { item->depth }
  override Str? aux(Obj item) { item->aux }
  override Str auxStyle() { style ?: super.auxStyle }
}

@Js
internal class TestItem
{
  Str? text
  Image? icon
  Int depth := 0
  Str? aux
  Bool group := false
}
