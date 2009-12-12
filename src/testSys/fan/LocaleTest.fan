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
  Locale? orig

  override Void setup()
  {
    orig = Locale.cur
  }

  override Void teardown()
  {
    Locale.setCur(orig)
  }

  Void testIdentity()
  {
    verifyLocale("en",    "en", null)
    verifyLocale("en-US", "en", "US")
    verifyLocale("fr",    "fr", null)
    verifyLocale("fr-CA", "fr", "CA")

    verifyEq(Locale.fromStr("", false), null)
    verifyErr(ParseErr#) { Locale.fromStr("x") }
    verifyErr(ParseErr#) { Locale.fromStr("x", true) }
    verifyErr(ParseErr#) { Locale.fromStr("e2") }
    verifyErr(ParseErr#) { Locale.fromStr("en_US") }
    verifyErr(ParseErr#) { Locale.fromStr("en-x") }
    verifyErr(ParseErr#) { Locale.fromStr("en-x2") }
    verifyErr(ParseErr#) { Locale.fromStr("en-xxx") }
    verifyErr(ParseErr#) { Locale.fromStr("EN") }
    verifyErr(ParseErr#) { Locale.fromStr("EN-US") }
    verifyErr(ParseErr#) { Locale.fromStr("en-us") }
  }

  Void verifyLocale(Str str, Str lang, Str? country)
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
    Locale.setCur(fr)
    verifyEq(Locale.cur.toStr, "fr-FR")

    // change to Taiwan
    zh := Locale.fromStr("zh-TW")
    Locale.setCur(zh)
    verifyEq(Locale.cur.toStr, "zh-TW")

    // can't set to null
    //verifyErr(NullErr#) { Locale.setCurrent(null) }

    // check with closure which throws exception
    try
    {
      fr.use
      {
        verifyEq(Locale.cur.toStr, "fr-FR")
        throw Err.make
      }
    }
    catch
    {
    }
    verifyEq(Locale.cur.toStr, "zh-TW")

    // create actor that accepts
    // messages to change its own locale
    actor := Actor(ActorPool()) |Obj msg->Obj|
    {
      if (msg == ".")  return Locale.cur
      loc := Locale.fromStr(msg)
      Locale.setCur(loc)
      return Locale.cur
    }

    // check that changes on other thread don't effect my thread
    verifyEq(actor.send(".").get, Locale("zh-TW"))
    verifyEq(actor.send("fr-FR").get, fr)
    verifyEq(Locale.cur.toStr, "zh-TW")
    verifyEq(actor.send("de").get, Locale("de"))
    verifyEq(Locale.cur.toStr, "zh-TW")
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

  Void verifyProp(Locale x, Str key, Str? expected, Str? def := "_no_def_")
  {
    old := Locale.cur
    Locale.setCur(x)
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
      Locale.setCur(old)
    }
  }

}