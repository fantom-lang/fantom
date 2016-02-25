//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 May 10  Andy Frank  Creation
//   25 Feb 16  Matthew Giannini - binary encode time zone
//

**
** JsTimeZone
**
class JsTimeZone
{
  new make(TimeZone tz)
  {
    this.tz = tz
  }

  Void write(OutStream out)
  {
    continent := tz.fullName.split('/').first
    city      := tz.name

    // encode
    buf := Buf().writeUtf(continent).writeUtf(city)
    rules := ([Str:Obj][])tz->rules
    rules.each |r| { encodeRule(r, buf.out) }

    // write js
    out.printLine("fan.sys.TimeZone.cache\$($continent.toCode, $city.toCode, ${buf.toBase64.toCode});")
  }

  private Void encodeRule(Str:Obj r, OutStream out)
  {
    dstOffset := r["dstOffset"]
    out.writeI2(r["startYear"])
       .writeI4(r["offset"])
       .writeUtf(r["stdAbbr"])
       .writeI4(dstOffset)
    if (dstOffset != 0)
    {
      out.writeUtf(r["dstAbbr"])
      encodeDst(r["dstStart"], out)
      encodeDst(r["dstEnd"], out)
    }
  }

  private Void encodeDst(Str:Obj dst, OutStream out)
  {
    out.write(dst["mon"])
       .write(dst["onMode"])
       .write(dst["onWeekday"])
       .write(dst["onDay"])
       .writeI4(dst["atTime"])
       .write(dst["atMode"])
  }
  
  TimeZone tz
}
