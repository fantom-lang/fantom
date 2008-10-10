//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Nov 07  Brian Frank  Creation
//

**
** LocaleTest
**
class LocaleTest : Test
{
  Locale orig

  override Void setup()
  {
    orig = Locale.current
  }

  override Void teardown()
  {
    Locale.setCurrent(orig)
  }

  Void testIdentity()
  {
    verifyLocale("en",    "en", null)
    verifyLocale("en-US", "en", "US")
    verifyLocale("fr",    "fr", null)
    verifyLocale("fr-CA", "fr", "CA")

    verifyEq(Locale.fromStr("", false), null)
    verifyErr(ParseErr#) |,| { Locale.fromStr("x") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("x", true) }
    verifyErr(ParseErr#) |,| { Locale.fromStr("e2") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("en_US") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("en-x") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("en-x2") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("en-xxx") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("EN") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("EN-US") }
    verifyErr(ParseErr#) |,| { Locale.fromStr("en-us") }
  }

  Void verifyLocale(Str str, Str lang, Str country)
  {
    locale := Locale.fromStr(str)
    verifyEq(locale.lang,    lang)
    verifyEq(locale.country, country)
    verifyEq(locale.toStr,   str)
    verifyEq(locale.hash,    str.hash)
    verifyEq(locale,         Locale.fromStr(str))
  }

  Void testCurrent()
  {
    // change to France
    fr := Locale.fromStr("fr-FR")
    Locale.setCurrent(fr)
    verifyEq(Locale.current.toStr, "fr-FR")

    // change to Taiwan
    zh := Locale.fromStr("zh-TW")
    Locale.setCurrent(zh)
    verifyEq(Locale.current.toStr, "zh-TW")

    // can't set to null
    verifyErr(NullErr#) |,| { Locale.setCurrent(null) }

    // check with closure which throws exception
    try
    {
      fr.with |,|
      {
        verifyEq(Locale.current.toStr, "fr-FR")
        throw Err.make
      }
    }
    catch
    {
    }
    verifyEq(Locale.current.toStr, "zh-TW")

    // create thread that accepts
    // messages to change its own locale
    thread := Thread.make(null) |Thread t|
    {
      t.loop |Obj msg->Obj|
      {
        if (msg == ".")  return Locale.current
        loc := Locale.fromStr(msg)
        Locale.setCurrent(loc)
        return Locale.current
      }
    }
    thread.start

    // check that changes on other thread don't effect my thread
    verifyEq(thread.sendSync("."), orig)
    verifyEq(thread.sendSync("fr-FR"), fr)
    verifyEq(Locale.current.toStr, "zh-TW")
    verifyEq(thread.sendSync("de"), Locale.fromStr("de"))
    verifyEq(Locale.current.toStr, "zh-TW")
    thread.stop
  }

  Void testProps()
  {
    x := Locale.fromStr("en")
    verifyProp(x, "a", "a en")
    verifyProp(x, "b", "b en")
    verifyProp(x, "c", "c en")
    verifyProp(x, "d", "d en")
    verifyProp(x, "x", "testSys::x")
    verifyProp(x, "x", null, null)
    verifyProp(x, "x", "foo", "foo")

    x = Locale.fromStr("en-US")
    verifyProp(x, "a", "a en-US")
    verifyProp(x, "b", "b en")
    verifyProp(x, "c", "c en")
    verifyProp(x, "d", "d en")
    verifyProp(x, "x", "testSys::x")
    verifyProp(x, "x", null, null)
    verifyProp(x, "x", "foo", "foo")

    x = Locale.fromStr("es")
    verifyProp(x, "a", "a es")
    verifyProp(x, "b", "b es")
    verifyProp(x, "c", "c es")
    verifyProp(x, "d", "d en")
    verifyProp(x, "x", "testSys::x")
    verifyProp(x, "x", null, null)
    verifyProp(x, "x", "foo", "foo")

    x = Locale.fromStr("es-MX")
    verifyProp(x, "a", "a es-MX")
    verifyProp(x, "b", "b es")
    verifyProp(x, "c", "c es")
    verifyProp(x, "d", "d en")
    verifyProp(x, "x", "testSys::x")
    verifyProp(x, "x", null, null)
    verifyProp(x, "x", "foo", "foo")

    x = Locale.fromStr("fr-CA")
    verifyProp(x, "a", "a en")
    verifyProp(x, "b", "b en")
    verifyProp(x, "c", "c en")
    verifyProp(x, "d", "d en")
    verifyProp(x, "x", "testSys::x")
    verifyProp(x, "x", null, null)
    verifyProp(x, "x", "foo", "foo")
  }

  Void verifyProp(Locale x, Str key, Str expected, Str def := "_no_def_")
  {
    old := Locale.current
    Locale.setCurrent(x)
    try
    {
      if (def == "_no_def_")
      {
        verifyEq(x.get("testSys", key), expected)
        verifyEq(type.pod.loc(key), expected)
        verifyEq(LocaleTest#.loc(key), expected)
      }
      else
      {
        verifyEq(x.get("testSys", key, def), expected)
        verifyEq(type.pod.loc(key, def), expected)
        verifyEq(LocaleTest#.loc(key, def), expected)
      }
    }
    finally
    {
      Locale.setCurrent(old)
    }
  }

}