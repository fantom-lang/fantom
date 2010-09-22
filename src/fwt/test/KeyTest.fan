//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Aug 08  Brian Frank  Creation
//

**
** KeyTest
**
class KeyTest : Test
{

  Void testMake()
  {
    verifyKey(Key.a, "A", [Key.a])
    verifyKey(Key.alt, "Alt", [Key.alt])
    verifyKey(Key.num7+Key.alt, "Alt+7", [Key.alt,Key.num7])
    verifyKey(Key.ctrl+Key.f3, "Ctrl+F3", [Key.ctrl,Key.f3])
    verifyKey(Key("Alt+Command+R"), "Alt+Command+R", [Key.alt, Key.command, Key.r])
    verifyKey(Key("Q+Shift"), "Shift+Q", [Key.shift, Key.q])

    verifyEq(Key("Alt+Up"), Key("Up+Alt"))
    verifySame(Key("Alt+Up").list[0], Key.alt)
    verifySame(Key("Up+Alt").list[1], Key.up)
    verifySame(Key("Alt+2").primary, Key.num2)
    verifySame(Key("Ctrl+F1+Shift").primary, Key.f1)
    verifySame(Key("Ctrl+F1+Shift").list[0], Key.shift)
    verifySame(Key("Ctrl+F1+Shift").list[1], Key.ctrl)
    verifySame(Key("Ctrl+F1+Shift").list[2], Key.f1)
    verifySame(Key("W").primary, Key.w)
  }

  Void testPlus()
  {
    verifyKey(Key.shift+Key.alt+Key.x, "Shift+Alt+X", [Key.shift, Key.alt, Key.x])
    verifyKey(Key.x+Key.shift+Key.alt, "Shift+Alt+X", [Key.shift, Key.alt, Key.x])
    verifyKey(Key.shift+Key.x+Key.alt, "Shift+Alt+X", [Key.shift, Key.alt, Key.x])
    verifyErr(ArgErr#) { k := Key.x + Key.y }
  }

  Void testParse()
  {
    eq := Key("=")
    verifyKey(eq, "=", [eq])
    verifyKey(Key("Command+="), "Command+=", [Key.command, eq])

    verifyEq(Key.fromStr("", false), null)
    verifyEq(Key.fromStr("==", false), null)
    verifyEq(Key.fromStr("e", false), null)
    verifyEq(Key.fromStr("Foo", false), null)
    verifyEq(Key.fromStr("R+W", false), null)

    verifyErr(ParseErr#) { Key("R+W") }
    verifyErr(ParseErr#) { Key.fromStr("2+3+4", true) }
  }

  Void verifyKey(Key k, Str s, Key[] ks)
  {
    verifyEq(k.toStr, s)
    verifyEq(k.list,  ks)
    verifyEq(Key.fromStr(s), k)
  }

  Void testReplace()
  {
    x := Key("Ctrl+T")
    verifySame(x.replace(Key.shift, Key.alt), x)
    verifyEq(x.replace(Key.ctrl, Key.command), Key("Command+T"))
    x = Key("Shift+Ctrl+Left")
    verifyEq(x.replace(Key.ctrl, Key.command), Key("Shift+Command+Left"))
  }

}