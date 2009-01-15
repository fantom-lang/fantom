//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 09  Brian Frank  Creation
//

using xml

**
** XmlTest - test XML encoding/decoding
**
class XmlTest : ObixTest
{

//////////////////////////////////////////////////////////////////////////
// ObjTree
//////////////////////////////////////////////////////////////////////////

  Void testObjTree()
  {
    // simple
    verifyParse(
      "<?xml version='1.0?>
       <obj href='http://foo/obix/'/>",
       ObixObj { href = `http://foo/obix/` })

    // with children and PI
    verifyParse(
      "<?xml version='1.0?>
       <obj href='http://foo/obix/'>
         <obj name='a'>
           <obj name='ax'/>
         </obj>
         <!-- pi -->
         <obj name='b'>
           <obj name='bx'/>
           <obj name='by'>
             <obj name='byi'/>
           </obj>
           <!-- pi -->
           <obj name='bz'><!-- pi --></obj>
         </obj>
       </obj>
       ",
       ObixObj
       {
         href = `http://foo/obix/`
         ObixObj
         {
           name = "a"
           ObixObj { name = "ax" }
         }
         ObixObj
         {
           name = "b"
           ObixObj { name = "bx" }
           ObixObj { name = "by"; ObixObj { name="byi"} }
           ObixObj { name = "bz" }
         }
       })
  }

//////////////////////////////////////////////////////////////////////////
// Vals
//////////////////////////////////////////////////////////////////////////

  Void testBool()
  {
    verifyParse(
      "<obj>
        <bool name='def'/>
        <bool name='a' val='true'/>
        <bool name='b' val='false'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; val=false }
         ObixObj { name="a"; val=true }
         ObixObj { name="b"; val=false }
       })
   }

  Void testInt()
  {
    verifyParse(
      "<obj>
        <int name='def'/>
        <int name='a' val='3'/>
        <int name='b' val='-1234'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; val=0 }
         ObixObj { name="a"; val=3 }
         ObixObj { name="b"; val=-1234}
       })
   }

  Void testReal()
  {
    verifyParse(
      "<obj>
        <real name='def'/>
        <real name='a' val='2'/>
        <real name='b' val='-2.4'/>
        <real name='c' val='4e10'/>
        <real name='nan' val='NaN'/>
        <real name='posInf' val='INF'/>
        <real name='negInf' val='-INF'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; val=0f }
         ObixObj { name="a"; val=2f }
         ObixObj { name="b"; val=-2.4f }
         ObixObj { name="c"; val=4e10f }
         ObixObj { name="nan"; val=Float.nan }
         ObixObj { name="posInf"; val=Float.posInf }
         ObixObj { name="negInf"; val=Float.negInf }
       })

     verifyEq(ObixObj { val = Float.nan }.valToStr, "NaN")
     verifyEq(ObixObj { val = Float.posInf }.valToStr, "INF")
     verifyEq(ObixObj { val = Float.negInf }.valToStr, "-INF")
   }

  Void testStr()
  {
    verifyParse(
      "<obj>
        <str name='def'/>
        <str name='a' val='hi'/>
        <str name='b' val='&gt; &apos; &amp; &quot; &lt;'/>
        <str name='c' val='32\u00B0\nline2'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; val="" }
         ObixObj { name="a"; val="hi" }
         ObixObj { name="b"; val="> ' & \" <" }
         ObixObj { name="c"; val="32\u00B0\nline2" }
       })
   }

  Void testUri()
  {
    verifyParse(
      "<obj>
        <uri name='def'/>
        <uri name='a' val='http://foo/'/>
        <uri name='b' val='http://foo/path%20name?foo=bar+baz'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; val=`` }
         ObixObj { name="a"; val=`http://foo/` }
         ObixObj { name="b"; val=`http://foo/path name?foo=bar baz` }
       })
   }

  Void testEnum()
  {
    verifyParse(
      "<obj>
        <enum name='def'/>
        <enum name='a' val='slow'/>
       </obj>",
       ObixObj
       {
         ObixObj { elemName="enum"; name="def"; isNull=true }
         ObixObj { elemName="enum"; name="a"; val="slow" }
       })
   }

  Void testAbstime()
  {
    verifyParse(
      "<obj>
        <abstime name='def'/>
        <abstime name='a' val='2009-01-15T13:54:00Z'/>
        <abstime name='b' val='2009-01-15T13:54:00-05:00'/>
        <abstime name='c' val='2009-01-15T13:54:00Z' tz='London'/>
        <abstime name='d' val='2009-01-15T13:54:00-05:00' tz='America/New_York'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; elemName="abstime"; isNull=true }
         ObixObj { name="a"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone.utc) }
         ObixObj { name="b"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone("Etc/GMT+5")) }
         ObixObj { name="c"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone("London")) }
         ObixObj { name="d"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone("New_York")); tz=TimeZone("New_York") }
       })
  }

  Void testDate()
  {
    verifyParse(
      "<obj>
        <date name='def'/>
        <date name='a' val='2010-01-30'/>
        <date name='b' val='1995-12-05' tz='America/Chicago'/>
       </obj>",
       ObixObj
       {
         ObixObj { elemName="date"; name="def"; isNull=true }
         ObixObj { name="a"; val=Date(2010, Month.jan, 30) }
         ObixObj { name="b"; val=Date(1995, Month.dec, 05); tz=TimeZone("Chicago") }
       })
   }

  Void testTime()
  {
    verifyParse(
      "<obj>
        <time name='def'/>
        <time name='a' val='05:30:20'/>
        <time name='b' val='23:00:00.456' tz='Europe/London'/>
       </obj>",
       ObixObj
       {
         ObixObj { elemName="time"; name="def"; isNull=true }
         ObixObj { name="a"; val=Time(5, 30, 20) }
         ObixObj { name="b"; val=Time(23, 0, 0, 456ms.ticks); tz=TimeZone("London") }
       })
   }

  Void testValErrors()
  {
    verifyParseErr("<obj val='bad'/>")
    verifyParseErr("<obj><op val='bad'/></obj>")
   }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void verifyParse(Str s, ObixObj expected)
  {
    // parse and compare actual result
    actual := ObixXmlParser(s.in).parse
    verifyObj(actual, expected)

    // write to string and roundtrip
    buf := Buf()
    actual.writeXml(buf.out)
    rt := ObixObj.readXml(buf.flip.readAllStr.in)
    verifyObj(rt, expected)
  }

  Void verifyParseErr(Str s)
  {
    verifyErr(XErr#) |,| { ObixObj.readXml(s.in) }
  }

}