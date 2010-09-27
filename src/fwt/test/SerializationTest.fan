//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 08  Brian Frank  Creation
//

using gfx

**
** SerializationTest
**
class SerializationTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Menu
/////////////////////////////////////////////////////////////////////////

  Void testMenu()
  {
    Menu x := verifySer(
     "fwt::Menu
      {
        fwt::MenuItem
        {
          text=\"a\"
        },
        fwt::MenuItem
        {
          mode=fwt::MenuItemMode(\"check\")
          text=\"b\"
        },
      }")

    verifyEq(x.children.size, 2)
    verifyEq(x.children[0]->text, "a")
    verifyEq(x.children[1]->text, "b")
    verifyEq(x.children[1]->mode, MenuItemMode.check)
  }

//////////////////////////////////////////////////////////////////////////
// InsetPane
/////////////////////////////////////////////////////////////////////////

  Void testInsetPane()
  {
    short :=
    "fwt::InsetPane
     {
       fwt::Label
       {
         text=\"hi\"
       },
     }"

    full :=
    "fwt::InsetPane
     {
       content=fwt::Label
       {
         text=\"hi\"
       }
     }"

    InsetPane x := verifySer(full)
    verifyType(x.content, Label#)
    verifyEq(x.content->text, "hi")
    verifyEq(x.children, Widget[x.content])

    x = verifySer(short, full)
    verifyType(x.content, Label#)
    verifyEq(x.content->text, "hi")
    verifyEq(x.children, Widget[x.content])
  }

//////////////////////////////////////////////////////////////////////////
// Window
/////////////////////////////////////////////////////////////////////////

  Void testWindow()
  {
    short :=
    "fwt::Window
     {
       menuBar=fwt::Menu
       {
         fwt::MenuItem
         {
           text=\"File\"
         },
       }
       fwt::Label
       {
         text=\"content\"
       },
     }"

    full :=
    "fwt::Window
     {
       content=fwt::Label
       {
         text=\"content\"
       }
       menuBar=fwt::Menu
       {
         fwt::MenuItem
         {
           text=\"File\"
         },
       }
     }"

    Window x := verifySer(full)
    verifyType(x.menuBar, Menu#)
    verifyEq(x.menuBar.children.size, 1)
    verifyEq(x.menuBar.children.first->text, "File")
    verifyType(x.content, Label#)
    verifyEq(x.content->text, "content")
    verifyEq(x.children.dup.sort, Widget[x.content, x.menuBar].sort)

    x = verifySer(short, full)
    verifyType(x.menuBar, Menu#)
    verifyEq(x.menuBar.children.size, 1)
    verifyEq(x.menuBar.children.first->text, "File")
    verifyType(x.content, Label#)
    verifyEq(x.content->text, "content")
    verifyEq(x.children.dup.sort, Widget[x.menuBar, x.content].sort)
  }

//////////////////////////////////////////////////////////////////////////
// EdgePane
/////////////////////////////////////////////////////////////////////////

  Void testEdgePane()
  {
    EdgePane x := verifySer(
     "fwt::EdgePane
      {
        left=fwt::Label
        {
          text=\"left\"
        }
        right=fwt::Label
        {
          layout=gfx::Valign(\"bottom\")
          text=\"right\"
        }
      }")

    verifyType(x.left, Label#)
    verifyType(x.right, Label#)
    verifyEq(x.children.dup.sort, Widget[x.left, x.right].sort)
    verifyEq(x.left->text, "left")
    verifyEq(x.right->text, "right")
    verifyEq(x.right->layout, Valign.bottom)
  }

//////////////////////////////////////////////////////////////////////////
// GridPane
/////////////////////////////////////////////////////////////////////////

  Void testGridPane()
  {
    GridPane x := verifySer(
     "fwt::GridPane
      {
        hgap=7
        fwt::Label
        {
          text=\"a\"
          fg=gfx::Color(\"#aabbcc\")
        },
        fwt::Label
        {
          layout=\"fill\"
          text=\"b\"
          bg=gfx::Color(\"#a1b2c3d4\")
        },
      }")

    verifyEq(x.hgap, 7)
    verifyEq(x.children.size, 2)
    verifyEq(x.children[0]->text, "a")
    verifyEq(x.children[0]->fg, Color(0xaabbcc))
    verifyEq(x.children[1]->text, "b")
    verifyEq(x.children[1]->bg, Color(0xa1b2c3d4, true))
    verifyEq(x.children[1]->layout, "fill")
  }

//////////////////////////////////////////////////////////////////////////
// Common
/////////////////////////////////////////////////////////////////////////

  Obj verifySer(Str input, Str expected := input)
  {
    w := input.in.readObj
    x := Buf().writeObj(w, ["indent":2, "skipDefaults":true]).flip.readAllStr
    // echo(x)
    verifyEqTrim(expected, x)
    return w
  }

  Void verifyEqTrim(Str sa, Str sb)
  {
    a := sa.in.readAllLines
    b := sb.in.readAllLines
    if (a.size != b.size)
    {
      echo("--- $sa.size\n$sa")
      echo("--- $sb.size\n$sb")
      fail
    }
    a.size.times |Int i|
    {
      verifyEq(a[i].trim, b[i].trim)
    }
  }

}