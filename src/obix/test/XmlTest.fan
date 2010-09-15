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
         <?pi?>
         <obj name='b'>
           <!-- comment -->
           <obj name='bx'/>
           <obj name='by'>
             <obj name='byi'/>
           </obj>
           <?pi?>
           <obj name='bz'><?pi?></obj>
         </obj>
       </obj>
       ",
       ObixObj
       {
         href = `http://foo/obix/`
         ObixObj
         {
           name = "a"
           ObixObj { name = "ax" },
         },
         ObixObj
         {
           name = "b"
           ObixObj { name = "bx" },
           ObixObj { name = "by"; ObixObj { name="byi"}, },
           ObixObj { name = "bz" },
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
         ObixObj { name="def"; val=false },
         ObixObj { name="a"; val=true },
         ObixObj { name="b"; val=false },
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
         ObixObj { name="def"; val=0 },
         ObixObj { name="a"; val=3 },
         ObixObj { name="b"; val=-1234},
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
         ObixObj { name="def"; val=0f },
         ObixObj { name="a"; val=2f },
         ObixObj { name="b"; val=-2.4f },
         ObixObj { name="c"; val=4e10f },
         ObixObj { name="nan"; val=Float.nan },
         ObixObj { name="posInf"; val=Float.posInf },
         ObixObj { name="negInf"; val=Float.negInf },
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
         ObixObj { name="def"; val="" },
         ObixObj { name="a"; val="hi" },
         ObixObj { name="b"; val="> ' & \" <" },
         ObixObj { name="c"; val="32\u00B0\nline2" },
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
         ObixObj { name="def"; val=`` },
         ObixObj { name="a"; val=`http://foo/` },
         ObixObj { name="b"; val=`http://foo/path name?foo=bar baz` },
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
         ObixObj { elemName="enum"; name="def"; isNull=true },
         ObixObj { elemName="enum"; name="a"; val="slow" },
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
        <abstime name='e' val='9999-12-31T23:59:59.999Z'/>
        <abstime name='f' val='0000-01-01T00:00:00Z'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; elemName="abstime"; isNull=true },
         ObixObj { name="a"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone.utc) },
         ObixObj { name="b"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone("Etc/GMT+5")) },
         ObixObj { name="c"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone("London")) },
         ObixObj { name="d"; val=DateTime(2009, Month.jan, 15, 13, 54, 0, 0, TimeZone("New_York")); tz=TimeZone("New_York") },
         ObixObj { name="e"; val=DateTime(2099, Month.dec, 31, 23, 59, 59, 999_000_000, TimeZone.utc) },
         ObixObj { name="f"; val=DateTime(1901, Month.jan,  1,  0,  0,  0, 0, TimeZone.utc) },
       })
  }

  Void testReltime()
  {
    verifyParse(
      "<obj>
        <reltime name='def'/>
        <reltime name='a' val='PT45S'/>
        <reltime name='b' val='PT0.1S'/>
        <reltime name='c' val='P2DT20H15M'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="def"; val=0sec },
         ObixObj { name="a";   val=45sec },
         ObixObj { name="b";   val=100ms },
         ObixObj { name="c";   val=2day+20hr+15min },
       })
  }

  Void testDate()
  {
    verifyParse(
      "<obj>
        <date name='def'/>
        <date name='a' val='2010-01-30'/>
        <date name='b' val='1995-12-05' tz='America/Chicago'/>
        <date name='c' val='9999-12-31'/>
       </obj>",
       ObixObj
       {
         ObixObj { elemName="date"; name="def"; isNull=true },
         ObixObj { name="a"; val=Date(2010, Month.jan, 30) },
         ObixObj { name="b"; val=Date(1995, Month.dec, 05); tz=TimeZone("Chicago") },
         ObixObj { name="c"; val=Date(9999, Month.dec, 31) },
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
         ObixObj { elemName="time"; name="def"; isNull=true },
         ObixObj { name="a"; val=Time(5, 30, 20) },
         ObixObj { name="b"; val=Time(23, 0, 0, 456ms.ticks); tz=TimeZone("London") },
       })
   }

  Void testValErrs()
  {
    // turn obj's with val into str
    verifyParse("<obj val='foo'/>", ObixObj { elemName="str"; val="foo" })

    verifyParseErr("<obj><op val='bad'/></obj>")
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  Void testDisplay()
  {
    verifyParse(
      "<obj>
        <obj name='a' displayName='Alpha' />
        <obj name='b' display='The Beta'/>
        <int name='c' displayName='Gamma' display='The Gamma' val='5'/>
        <obj name='d' displayName='&apos;\"&lt;&gt;' />
        <obj name='e' display='&apos;\"&lt;&gt;' />
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; displayName="Alpha" },
         ObixObj { name="b"; display="The Beta" },
         ObixObj { name="c"; displayName="Gamma"; display="The Gamma"; val=5 },
         ObixObj { name="d"; displayName="'\"<>" },
         ObixObj { name="e"; display="'\"<>" },
       })
   }

  Void testIcon()
  {
    verifyParse(
      "<obj>
        <obj name='a' icon='http://foo/icons/a.png' />
        <obj name='b' icon=\"http://foo/icon%20dir/?foo=bar+bar\" />
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; icon=`http://foo/icons/a.png` },
         ObixObj { name="b"; icon=`http://foo/icon dir/?foo=bar bar` },
       })
   }

  Void testMinMax()
  {
    verifyParse(
      "<obj>
        <int name='a' min='0'/>
        <int name='b' max='100'/>
        <real name='c' min='1' max='99' />
        <real name='d' min='-INF' max='INF'/>
        <str name='e' min='2' max='20'/>
        <abstime name='f' isNull='true' min='2000-01-01T00:00:00Z' max='2000-12-31T23:59:59Z'/>
        <reltime name='g' min='PT3S' max='PT1M'/>
        <date name='h' isNull='true' min='2000-01-01' max='2000-12-31'/>
        <time name='i' isNull='true' min='01:00:00' max='12:00:00'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; val=0; min=0 },
         ObixObj { name="b"; val=0; max=100 },
         ObixObj { name="c"; val=0f; min=1f; max=99f },
         ObixObj { name="d"; val=0f; min=Float.negInf; max=Float.posInf },
         ObixObj { name="e"; val=""; min=2; max=20 },
         ObixObj { name="f"; elemName="abstime"; isNull=true;
                   min=DateTime(2000, Month.jan, 1, 0, 0, 0, 0, TimeZone.utc)
                   max=DateTime(2000, Month.dec, 31, 23, 59, 59, 0, TimeZone.utc) },
         ObixObj { name="g"; val=0sec; min=3sec; max=1min },
         ObixObj { name="h"; elemName="date"; isNull=true
                   min=Date(2000, Month.jan, 1); max=Date(2000, Month.dec, 31) },
         ObixObj { name="i"; elemName="time"; isNull=true
                   min=Time(1, 0, 0); max=Time(12, 0, 0) },
       })
   }

  Void testPrecision()
  {
    verifyParse(
      "<obj>
        <real name='a' val='75.00' precision='2' />
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; val=75f; precision=2 },
       })
   }

  Void testRange()
  {
    verifyParse(
      "<obj>
        <enum name='a' val='1' range='http://foo/range' />
        <enum name='b' val='2' range=\"http://foo/range%20val/\" />
       </obj>",
       ObixObj
       {
         ObixObj { elemName="enum"; name="a"; val="1"; range=`http://foo/range` },
         ObixObj { elemName="enum"; name="b"; val="2"; range=`http://foo/range val/` },
       })
   }

  Void testStatus()
  {
    verifyParse(
      "<obj>
        <obj name='a' />
        <obj name='b' status='disabled'/>
        <obj name='c' status='fault'/>
        <obj name='d' status='down'/>
        <obj name='e' status='unackedAlarm'/>
        <obj name='f' status='alarm'/>
        <obj name='g' status='unacked'/>
        <obj name='h' status='overridden'/>
        <obj name='i' status='ok'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; status=Status.ok },
         ObixObj { name="b"; status=Status.disabled },
         ObixObj { name="c"; status=Status.fault },
         ObixObj { name="d"; status=Status.down },
         ObixObj { name="e"; status=Status.unackedAlarm },
         ObixObj { name="f"; status=Status.alarm },
         ObixObj { name="g"; status=Status.unacked },
         ObixObj { name="h"; status=Status.overridden },
         ObixObj { name="i"; status=Status.ok },
       })
   }

  Void testUnit()
  {
    verifyParse(
      "<obj>
        <int name='a' unit='obix:units/meter' />
        <int name='b' unit='obix:units/fahrenheit' />
        <int name='c' unit='obix:units/unknown_unit' />
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; val=0; unit=Unit("meter") },
         ObixObj { name="b"; val=0; unit=Unit("fahrenheit") },
         ObixObj { name="c"; val=0 },
       })
   }

  Void testWritable()
  {
    verifyParse(
      "<obj>
        <int name='a' />
        <int name='b' writable='true'/>
        <int name='c' writable='false'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; val=0; writable=false },
         ObixObj { name="b"; val=0; writable=true },
         ObixObj { name="c"; val=0; writable=false },
       })
   }

//////////////////////////////////////////////////////////////////////////
// Contracts
//////////////////////////////////////////////////////////////////////////

  Void testIs()
  {
    verifyParse(
      "<obj>
        <obj name='a' is='obix:Point'/>
        <obj name='b' is='obix:Point obix:WritablePoint'/>
        <obj name='c' is='http://foo/a%20b'/>
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; contract=Contract([`obix:Point`]) },
         ObixObj { name="b"; contract=Contract([`obix:Point`, `obix:WritablePoint`]) },
         ObixObj { name="c"; contract=Contract([`http://foo/a b`]) },
       })
  }

//////////////////////////////////////////////////////////////////////////
// List
//////////////////////////////////////////////////////////////////////////

  Void testList()
  {
    verifyParse(
      "<list of='obix:Point'>
         <real val='1'/>
         <real val='2'/>
       </list>",
       ObixObj
       {
         elemName = "list"
         of = Contract([`obix:Point`])
         ObixObj { val=1f },
         ObixObj { val=2f },
       })
  }

//////////////////////////////////////////////////////////////////////////
// Op
//////////////////////////////////////////////////////////////////////////

  Void testOp()
  {
    verifyParse(
      "<obj>
         <op name='a' in='/in'/>
         <op name='b' out='/out1 /out2'/>
         <op name='c' in='/in' out='/out' />
       </obj>",
       ObixObj
       {
         ObixObj { elemName="op"; name="a"; in=Contract([`/in`]) },
         ObixObj { elemName="op"; name="b"; out=Contract([`/out1`, `/out2`]) },
         ObixObj { elemName="op"; name="c"; in=Contract([`/in`]); out=Contract([`/out`]) },
       })
  }

//////////////////////////////////////////////////////////////////////////
// Feed
//////////////////////////////////////////////////////////////////////////

  Void testFeed()
  {
    verifyParse(
      "<obj>
         <feed name='a' of='/in'/>
         <feed name='b' out='/out1 /out2'/>
         <feed name='c' of='/in' out='/out' />
       </obj>",
       ObixObj
       {
         ObixObj { elemName="feed"; name="a"; of=Contract([`/in`]) },
         ObixObj { elemName="feed"; name="b"; out=Contract([`/out1`, `/out2`]) },
         ObixObj { elemName="feed"; name="c"; of=Contract([`/in`]); out=Contract([`/out`]) },
       })
  }

//////////////////////////////////////////////////////////////////////////
// Unknown Elements
//////////////////////////////////////////////////////////////////////////

  Void testUnknownElems()
  {
    verifyParse(
      "<obj>
         <newOne/>
         <int name='a' val='100' custom='foo'><custom/></int>
         <foo>
           <bar/>
           <obj name='foo'/>
         </foo>
         <obj name='b'>
           <real name='c' val='0'/>
         </obj>
       </obj>",
       ObixObj
       {
         ObixObj { name="a"; val=100 },
         ObixObj { name="b"; ObixObj { name="c"; val=0f }, },
       })
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
    verifyErr(XErr#) { ObixObj.readXml(s.in) }
  }

}