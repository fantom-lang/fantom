//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Charset.
 */
fan.sys.Charset = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.Charset.prototype.$ctor = function(name, encoder)
{
  this.m_name = name;
  this.m_encoder = encoder;
}

fan.sys.Charset.prototype.$typeof = function() { return fan.sys.Charset.$type; }

fan.sys.Charset.utf16BE = function()
{
  return new fan.sys.Charset("UTF-16BE", new fan.sys.Charset.Encoder(
      fan.sys.Charset.Utf16BEEncoder.encodeOut,
      fan.sys.Charset.Utf16BEEncoder.encodeIn,
      fan.sys.Charset.Utf16BEEncoder.decode));
}

fan.sys.Charset.utf16LE = function()
{
  return new fan.sys.Charset("UTF-16LE", new fan.sys.Charset.Encoder(
      fan.sys.Charset.Utf16LEEncoder.encodeOut,
      fan.sys.Charset.Utf16LEEncoder.encodeIn,
      fan.sys.Charset.Utf16LEEncoder.decode));
}

fan.sys.Charset.utf8 = function()
{
  return new fan.sys.Charset("UTF-8", new fan.sys.Charset.Encoder(
      fan.sys.Charset.Utf8Encoder.encodeOut,
      fan.sys.Charset.Utf8Encoder.encodeIn,
      fan.sys.Charset.Utf8Encoder.decode));
}

fan.sys.Charset.iso8851_1 = function()
{
  return new fan.sys.Charset("ISO-8859-1", new fan.sys.Charset.Encoder(
      fan.sys.Charset.Iso8859_1Encoder.encodeOut,
      fan.sys.Charset.Iso8859_1Encoder.encodeIn,
      fan.sys.Charset.Iso8859_1Encoder.decode));
}

fan.sys.Charset.iso8851_2 = function()
{
  return new fan.sys.Charset("ISO-8859-2", new fan.sys.Charset.Iso8859Encoder(
      fan.sys.Charset.Iso8859Encoder.iso2_u2i,
      fan.sys.Charset.Iso8859Encoder.iso2_i2u
   ));
}

fan.sys.Charset.iso8851_5 = function()
{
  return new fan.sys.Charset("ISO-8859-5", new fan.sys.Charset.Iso8859Encoder(
      fan.sys.Charset.Iso8859Encoder.iso5_u2i,
      fan.sys.Charset.Iso8859Encoder.iso5_i2u
   ));
}

fan.sys.Charset.iso8851_8 = function()
{
  return new fan.sys.Charset("ISO-8859-8", new fan.sys.Charset.Iso8859Encoder(
      fan.sys.Charset.Iso8859Encoder.iso8_u2i,
      fan.sys.Charset.Iso8859Encoder.iso8_i2u
   ));
}

fan.sys.Charset.fromStr = function(name, checked)
{
  if (checked === undefined) checked = true;
  var nname = name.toUpperCase();
  try
  {
    switch(nname)
    {
      case "UTF-8":      return fan.sys.Charset.utf8();
      case "UTF-16BE":   return fan.sys.Charset.utf16BE();
      case "UTF-16LE":   return fan.sys.Charset.utf16LE();
      case "ISO-8859-1": return fan.sys.Charset.iso8851_1();
      case "ISO-8859-2": return fan.sys.Charset.iso8851_2();
      case "ISO-8859-5": return fan.sys.Charset.iso8851_5();
      case "ISO-8859-8": return fan.sys.Charset.iso8851_8();
      default: throw new Error();
    }
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("Unsupported charset '" + nname + "'");
  }
}

fan.sys.Charset.defVal = function() { return fan.sys.Charset.utf8(); }
fan.sys.Charset.prototype.name = function() { return this.m_name; }
fan.sys.Charset.prototype.hash = function() { return 0; }
fan.sys.Charset.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Charset)
  {
    return this.m_name == that.m_name;
  }
  return false;
}
fan.sys.Charset.prototype.toStr = function() { return this.name(); }

//////////////////////////////////////////////////////////////////////////
// Charset.Encoder
//////////////////////////////////////////////////////////////////////////

fan.sys.Charset.Encoder = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.Charset.Encoder.prototype.$ctor = function(encodeOut, encodeIn, decode)
{
  this.m_encodeOut = encodeOut;
  this.m_encodeIn = encodeIn;
  this.m_decode = decode;
}

fan.sys.Charset.Encoder.prototype.encodeOut = function(c, outStream) { this.m_encodeOut(c, outStream); }
fan.sys.Charset.Encoder.prototype.encodeIn = function(c, inStream) { this.m_encodeIn(c, inStream); }
fan.sys.Charset.Encoder.prototype.decode = function(inStream) { return this.m_decode(inStream); }

//////////////////////////////////////////////////////////////////////////
// Utf8
//////////////////////////////////////////////////////////////////////////

fan.sys.Charset.Utf8Encoder = fan.sys.Obj.$extend(fan.sys.Charset.Encoder);

fan.sys.Charset.Utf8Encoder.encodeOut = function(c, outStream)
{
  if (c <= 0x007F)
  {
    outStream.write(c);
  }
  else if (c > 0x07FF)
  {
    outStream.write(0xE0 | ((c >>> 12) & 0x0F))
       .write(0x80 | ((c >>>  6) & 0x3F))
       .write(0x80 | ((c >>>  0) & 0x3F));
  }
  else
  {
    outStream.write(0xC0 | ((c >>>  6) & 0x1F))
             .write(0x80 | ((c >>>  0) & 0x3F));
  }
}

fan.sys.Charset.Utf8Encoder.encodeIn = function(c, inStream)
{
  if (c <= 0x007F)
  {
    inStream.unread(c);
  }
  else if (c > 0x07FF)
  {
    inStream.unread(0x80 | ((c >>  0) & 0x3F))
       .unread(0x80 | ((c >>  6) & 0x3F))
       .unread(0xE0 | ((c >> 12) & 0x0F));
  }
  else
  {
    inStream.unread(0x80 | ((c >>  0) & 0x3F))
       .unread(0xC0 | ((c >>  6) & 0x1F));
  }
}

fan.sys.Charset.Utf8Encoder.decode = function(inStream)
{
  var c = inStream.read();
  if (c == null) return -1;
  var c2, c3;
  switch (c >>> 4)
  {
    case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
      /* 0xxxxxxx*/
      return c;
    case 12: case 13:
      /* 110x xxxx   10xx xxxx*/
      c2 = inStream.read();
      if ((c2 & 0xC0) != 0x80)
        throw fan.sys.IOErr.make("Invalid UTF-8 encoding");
      return ((c & 0x1F) << 6) | (c2 & 0x3F);
    case 14:
      /* 1110 xxxx  10xx xxxx  10xx xxxx */
      c2 = inStream.read();
      c3 = inStream.read();
      if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))
        throw fan.sys.IOErr.make("Invalid UTF-8 encoding");
      return (((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
    default:
      throw fan.sys.IOErr.make("Invalid UTF-8 encoding");
  }
}

//////////////////////////////////////////////////////////////////////////
// Utf16BE
//////////////////////////////////////////////////////////////////////////

fan.sys.Charset.Utf16BEEncoder = fan.sys.Obj.$extend(fan.sys.Charset.Encoder);

fan.sys.Charset.Utf16BEEncoder.encodeOut = function(c, outStream)
{
  outStream.write((c >>> 8) & 0xFF).write((c >>> 0) & 0xFF);
}

fan.sys.Charset.Utf16BEEncoder.encodeIn = function(c, inStream)
{
  inStream.unread((c >>> 0) & 0xFF).unread((c >>> 8) & 0xFF);
}

fan.sys.Charset.Utf16BEEncoder.decode = function(inStream)
{
  var c1 = inStream.read();
  var c2 = inStream.read();
  if (c1 == null || c2 == null) return -1;
  return ((c1 << 8) | c2);
}

//////////////////////////////////////////////////////////////////////////
// Utf16LE
//////////////////////////////////////////////////////////////////////////

fan.sys.Charset.Utf16LEEncoder = fan.sys.Obj.$extend(fan.sys.Charset.Encoder);

fan.sys.Charset.Utf16LEEncoder.encodeOut = function(c, outStream)
{
  outStream.write((c >>> 0) & 0xFF).write((c >>> 8) & 0xFF);
}

fan.sys.Charset.Utf16LEEncoder.encodeIn = function(c, inStream)
{
  inStream.unread((c >>> 8) & 0xFF).unread((c >>> 0) & 0xFF);
}

fan.sys.Charset.Utf16LEEncoder.decode = function(inStream)
{
  var c1 = inStream.read();
  var c2 = inStream.read();
  if (c1 == null || c2 == null) return -1;
  return (c1 | (c2 << 8));
}

//////////////////////////////////////////////////////////////////////////
// Iso8859-1
//////////////////////////////////////////////////////////////////////////

fan.sys.Charset.Iso8859_1Encoder = fan.sys.Obj.$extend(fan.sys.Charset.Encoder);

fan.sys.Charset.Iso8859_1Encoder.encodeOut = function(c, outStream)
{
  if (c > 0xFF) throw fan.sys.IOErr.make("Invalid ISO-8859-1 char");
  outStream.write((c >>> 0) & 0xFF);
}

fan.sys.Charset.Iso8859_1Encoder.encodeIn = function(c, inStream)
{
  inStream.unread((c >>> 0) & 0xFF);
}

fan.sys.Charset.Iso8859_1Encoder.decode = function(inStream)
{
  var c = inStream.read();
  if (c == null) return -1;
  return (c & 0xFF);
}

//////////////////////////////////////////////////////////////////////////
// Iso8859
//////////////////////////////////////////////////////////////////////////

fan.sys.Charset.Iso8859Encoder = fan.sys.Obj.$extend(fan.sys.Charset.Encoder);
fan.sys.Charset.Iso8859Encoder.prototype.$ctor = function(u2i, i2u)
{
  this.m_encodeOut = fan.sys.Charset.Iso8859Encoder.encodeOut;
  this.m_encodeIn = fan.sys.Charset.Iso8859Encoder.encodeIn;
  this.m_decode = fan.sys.Charset.Iso8859Encoder.decode;
  this.m_u2i = u2i;
  this.m_i2u = i2u;
}

fan.sys.Charset.Iso8859Encoder.prototype.encodeOut = function(c, outStream)
{
  this.m_encodeOut(this.m_u2i(c), outStream);
}

fan.sys.Charset.Iso8859Encoder.prototype.encodeIn = function(c, inStream)
{
  this.m_encodeIn(this.m_u2i(c), inStream);
}

fan.sys.Charset.Iso8859Encoder.prototype.decode = function(inStream)
{
  var c = this.m_decode(inStream);
  if (c == -1) return -1;
  return this.m_i2u(c);
}

fan.sys.Charset.Iso8859Encoder.encodeOut = function(c, outStream)
{
  if (c > 0xFF) throw fan.sys.IOErr.make("Invalid ISO-8859 char");
  outStream.write(c);
}

fan.sys.Charset.Iso8859Encoder.encodeIn = function(c, inStream)
{
  inStream.unread(c);
}

fan.sys.Charset.Iso8859Encoder.decode = function(inStream)
{
  var c = inStream.read();
  if (c == null) return -1;
  return c & 0xFF;
}

fan.sys.Charset.Iso8859Encoder.iso2_i2u = function(c)
{
  switch(c)
  {
    case 0xA1: return 0x0104; case 0xA2: return 0x02D8; case 0xA3: return 0x0141;
    case 0xA5: return 0x013D; case 0xA6: return 0x015A; case 0xA9: return 0x0160;
    case 0xAA: return 0x015E; case 0xAB: return 0x0164; case 0xAC: return 0x0179;
    case 0xAE: return 0x017D; case 0xAF: return 0x017B; case 0xB1: return 0x0105;
    case 0xB2: return 0x02DB; case 0xB3: return 0x0142; case 0xB5: return 0x013E;
    case 0xB6: return 0x015B; case 0xB7: return 0x02C7; case 0xB9: return 0x0161;
    case 0xBA: return 0x015F; case 0xBB: return 0x0165; case 0xBC: return 0x017A;
    case 0xBD: return 0x02DD; case 0xBE: return 0x017E; case 0xBF: return 0x017C;
    case 0xC0: return 0x0154; case 0xC3: return 0x0102; case 0xC5: return 0x0139;
    case 0xC6: return 0x0106; case 0xC8: return 0x010C; case 0xCA: return 0x0118;
    case 0xCC: return 0x011A; case 0xCF: return 0x010E; case 0xD0: return 0x0110;
    case 0xD1: return 0x0143; case 0xD2: return 0x0147; case 0xD5: return 0x0150;
    case 0xD8: return 0x0158; case 0xD9: return 0x016E; case 0xDB: return 0x0170;
    case 0xDE: return 0x0162; case 0xDF: return 0x00DF; case 0xE0: return 0x0155;
    case 0xE3: return 0x0103; case 0xE5: return 0x013A; case 0xE6: return 0x0107;
    case 0xE8: return 0x010D; case 0xEA: return 0x0119; case 0xEC: return 0x011B;
    case 0xEF: return 0x010F; case 0xF0: return 0x0111; case 0xF1: return 0x0144;
    case 0xF2: return 0x0148; case 0xF5: return 0x0151; case 0xF8: return 0x0159;
    case 0xF9: return 0x016F; case 0xFB: return 0x0171; case 0xFE: return 0x0163;
    case 0xFF: return 0x02D9;
    default: return c;
  }
}

fan.sys.Charset.Iso8859Encoder.iso2_u2i = function(c)
{
  switch(c)
  {
    case 0x0104: return 0xA1; case 0x02D8: return 0xA2; case 0x0141: return 0xA3;
    case 0x013D: return 0xA5; case 0x015A: return 0xA6; case 0x0160: return 0xA9;
    case 0x015E: return 0xAA; case 0x0164: return 0xAB; case 0x0179: return 0xAC;
    case 0x017D: return 0xAE; case 0x017B: return 0xAF; case 0x0105: return 0xB1;
    case 0x02DB: return 0xB2; case 0x0142: return 0xB3; case 0x013E: return 0xB5;
    case 0x015B: return 0xB6; case 0x02C7: return 0xB7; case 0x0161: return 0xB9;
    case 0x015F: return 0xBA; case 0x0165: return 0xBB; case 0x017A: return 0xBC;
    case 0x02DD: return 0xBD; case 0x017E: return 0xBE; case 0x017C: return 0xBF;
    case 0x0154: return 0xC0; case 0x0102: return 0xC3; case 0x0139: return 0xC5;
    case 0x0106: return 0xC6; case 0x010C: return 0xC8; case 0x0118: return 0xCA;
    case 0x011A: return 0xCC; case 0x010E: return 0xCF; case 0x0110: return 0xD0;
    case 0x0143: return 0xD1; case 0x0147: return 0xD2; case 0x0150: return 0xD5;
    case 0x0158: return 0xD8; case 0x016E: return 0xD9; case 0x0170: return 0xDB;
    case 0x0162: return 0xDE; case 0x00DF: return 0xDF; case 0x0155: return 0xE0;
    case 0x0103: return 0xE3; case 0x013A: return 0xE5; case 0x0107: return 0xE6;
    case 0x010D: return 0xE8; case 0x0119: return 0xEA; case 0x011B: return 0xEC;
    case 0x010F: return 0xEF; case 0x0111: return 0xF0; case 0x0144: return 0xF1;
    case 0x0148: return 0xF2; case 0x0151: return 0xF5; case 0x0159: return 0xF8;
    case 0x016F: return 0xF9; case 0x0171: return 0xFB; case 0x0163: return 0xFE;
    case 0x02D9: return 0xFF;
    default: return (c >>> 0) & 0xFF;
  }
}

fan.sys.Charset.Iso8859Encoder.iso5_i2u = function(c)
{
  switch(c)
  {
    case 0xA1: return 0x0401; case 0xA2: return 0x0402; case 0xA3: return 0x0403;
    case 0xA4: return 0x0404; case 0xA5: return 0x0405; case 0xA6: return 0x0406;
    case 0xA7: return 0x0407; case 0xA8: return 0x0408; case 0xA9: return 0x0409;
    case 0xAA: return 0x040A; case 0xAB: return 0x040B; case 0xAC: return 0x040C;
    case 0xAE: return 0x040E; case 0xAF: return 0x040F; case 0xB0: return 0x0410;
    case 0xB1: return 0x0411; case 0xB2: return 0x0412; case 0xB3: return 0x0413;
    case 0xB4: return 0x0414; case 0xB5: return 0x0415; case 0xB6: return 0x0416;
    case 0xB7: return 0x0417; case 0xB8: return 0x0418; case 0xB9: return 0x0419;
    case 0xBA: return 0x041A; case 0xBB: return 0x041B; case 0xBC: return 0x041C;
    case 0xBD: return 0x041D; case 0xBE: return 0x041E; case 0xBF: return 0x041F;
    case 0xC0: return 0x0420; case 0xC1: return 0x0421; case 0xC2: return 0x0422;
    case 0xC3: return 0x0423; case 0xC4: return 0x0424; case 0xC5: return 0x0425;
    case 0xC6: return 0x0426; case 0xC7: return 0x0427; case 0xC8: return 0x0428;
    case 0xC9: return 0x0429; case 0xCA: return 0x042A; case 0xCB: return 0x042B;
    case 0xCC: return 0x042C; case 0xCD: return 0x042D; case 0xCE: return 0x042E;
    case 0xCF: return 0x042F; case 0xD0: return 0x0430; case 0xD1: return 0x0431;
    case 0xD2: return 0x0432; case 0xD3: return 0x0433; case 0xD4: return 0x0434;
    case 0xD5: return 0x0435; case 0xD6: return 0x0436; case 0xD7: return 0x0437;
    case 0xD8: return 0x0438; case 0xD9: return 0x0439; case 0xDA: return 0x043A;
    case 0xDB: return 0x043B; case 0xDC: return 0x043C; case 0xDD: return 0x043D;
    case 0xDE: return 0x043E; case 0xDF: return 0x043F; case 0xE0: return 0x0440;
    case 0xE1: return 0x0441; case 0xE2: return 0x0442; case 0xE3: return 0x0443;
    case 0xE4: return 0x0444; case 0xE5: return 0x0445; case 0xE6: return 0x0446;
    case 0xE7: return 0x0447; case 0xE8: return 0x0448; case 0xE9: return 0x0449;
    case 0xEA: return 0x044A; case 0xEB: return 0x044B; case 0xEC: return 0x044C;
    case 0xED: return 0x044D; case 0xEE: return 0x044E; case 0xEF: return 0x044F;
    case 0xF0: return 0x2116; case 0xF1: return 0x0451; case 0xF2: return 0x0452;
    case 0xF3: return 0x0453; case 0xF4: return 0x0454; case 0xF5: return 0x0455;
    case 0xF6: return 0x0456; case 0xF7: return 0x0457; case 0xF8: return 0x0458;
    case 0xF9: return 0x0459; case 0xFA: return 0x045A; case 0xFB: return 0x045B;
    case 0xFC: return 0x045C; case 0xFD: return 0x00A7; case 0xFE: return 0x045E;
    case 0xFF: return 0x045F;
    default: return c;
  }
}

fan.sys.Charset.Iso8859Encoder.iso5_u2i = function(c)
{
  switch(c)
  {
    case 0x0401: return 0xA1; case 0x0402: return 0xA2; case 0x0403: return 0xA3;
    case 0x0404: return 0xA4; case 0x0405: return 0xA5; case 0x0406: return 0xA6;
    case 0x0407: return 0xA7; case 0x0408: return 0xA8; case 0x0409: return 0xA9;
    case 0x040A: return 0xAA; case 0x040B: return 0xAB; case 0x040C: return 0xAC;
    case 0x040E: return 0xAE; case 0x040F: return 0xAF; case 0x0410: return 0xB0;
    case 0x0411: return 0xB1; case 0x0412: return 0xB2; case 0x0413: return 0xB3;
    case 0x0414: return 0xB4; case 0x0415: return 0xB5; case 0x0416: return 0xB6;
    case 0x0417: return 0xB7; case 0x0418: return 0xB8; case 0x0419: return 0xB9;
    case 0x041A: return 0xBA; case 0x041B: return 0xBB; case 0x041C: return 0xBC;
    case 0x041D: return 0xBD; case 0x041E: return 0xBE; case 0x041F: return 0xBF;
    case 0x0420: return 0xC0; case 0x0421: return 0xC1; case 0x0422: return 0xC2;
    case 0x0423: return 0xC3; case 0x0424: return 0xC4; case 0x0425: return 0xC5;
    case 0x0426: return 0xC6; case 0x0427: return 0xC7; case 0x0428: return 0xC8;
    case 0x0429: return 0xC9; case 0x042A: return 0xCA; case 0x042B: return 0xCB;
    case 0x042C: return 0xCC; case 0x042D: return 0xCD; case 0x042E: return 0xCE;
    case 0x042F: return 0xCF; case 0x0430: return 0xD0; case 0x0431: return 0xD1;
    case 0x0432: return 0xD2; case 0x0433: return 0xD3; case 0x0434: return 0xD4;
    case 0x0435: return 0xD5; case 0x0436: return 0xD6; case 0x0437: return 0xD7;
    case 0x0438: return 0xD8; case 0x0439: return 0xD9; case 0x043A: return 0xDA;
    case 0x043B: return 0xDB; case 0x043C: return 0xDC; case 0x043D: return 0xDD;
    case 0x043E: return 0xDE; case 0x043F: return 0xDF; case 0x0440: return 0xE0;
    case 0x0441: return 0xE1; case 0x0442: return 0xE2; case 0x0443: return 0xE3;
    case 0x0444: return 0xE4; case 0x0445: return 0xE5; case 0x0446: return 0xE6;
    case 0x0447: return 0xE7; case 0x0448: return 0xE8; case 0x0449: return 0xE9;
    case 0x044A: return 0xEA; case 0x044B: return 0xEB; case 0x044C: return 0xEC;
    case 0x044D: return 0xED; case 0x044E: return 0xEE; case 0x044F: return 0xEF;
    case 0x2116: return 0xF0; case 0x0451: return 0xF1; case 0x0452: return 0xF2;
    case 0x0453: return 0xF3; case 0x0454: return 0xF4; case 0x0455: return 0xF5;
    case 0x0456: return 0xF6; case 0x0457: return 0xF7; case 0x0458: return 0xF8;
    case 0x0459: return 0xF9; case 0x045A: return 0xFA; case 0x045B: return 0xFB;
    case 0x045C: return 0xFC; case 0x00A7: return 0xFD; case 0x045E: return 0xFE;
    case 0x045F: return 0xFF;
    default: return (c >>> 0) & 0xFF;
  }
}

fan.sys.Charset.Iso8859Encoder.iso8_i2u = function(c)
{
  switch(c)
  {
    case 0xAA: return 0x00D7; case 0xBA: return 0x00F7; case 0xDF: return 0x2017;
    case 0xE0: return 0x05D0; case 0xE1: return 0x05D1; case 0xE2: return 0x05D2;
    case 0xE3: return 0x05D3; case 0xE4: return 0x05D4; case 0xE5: return 0x05D5;
    case 0xE6: return 0x05D6; case 0xE7: return 0x05D7; case 0xE8: return 0x05D8;
    case 0xE9: return 0x05D9; case 0xEA: return 0x05DA; case 0xEB: return 0x05DB;
    case 0xEC: return 0x05DC; case 0xED: return 0x05DD; case 0xEE: return 0x05DE;
    case 0xEF: return 0x05DF; case 0xF0: return 0x05E0; case 0xF1: return 0x05E1;
    case 0xF2: return 0x05E2; case 0xF3: return 0x05E3; case 0xF4: return 0x05E4;
    case 0xF5: return 0x05E5; case 0xF6: return 0x05E6; case 0xF7: return 0x05E7;
    case 0xF8: return 0x05E8; case 0xF9: return 0x05E9; case 0xFA: return 0x05EA;
    case 0xFD: return 0x200E; case 0xFE: return 0x200F;
    default: return c;
  }
}

fan.sys.Charset.Iso8859Encoder.iso8_u2i = function(c)
{
  switch(c)
  {
    case 0x00D7: return 0xAA; case 0x00F7: return 0xBA; case 0x2017: return 0xDF;
    case 0x05D0: return 0xE0; case 0x05D1: return 0xE1; case 0x05D2: return 0xE2;
    case 0x05D3: return 0xE3; case 0x05D4: return 0xE4; case 0x05D5: return 0xE5;
    case 0x05D6: return 0xE6; case 0x05D7: return 0xE7; case 0x05D8: return 0xE8;
    case 0x05D9: return 0xE9; case 0x05DA: return 0xEA; case 0x05DB: return 0xEB;
    case 0x05DC: return 0xEC; case 0x05DD: return 0xED; case 0x05DE: return 0xEE;
    case 0x05DF: return 0xEF; case 0x05E0: return 0xF0; case 0x05E1: return 0xF1;
    case 0x05E2: return 0xF2; case 0x05E3: return 0xF3; case 0x05E4: return 0xF4;
    case 0x05E5: return 0xF5; case 0x05E6: return 0xF6; case 0x05E7: return 0xF7;
    case 0x05E8: return 0xF8; case 0x05E9: return 0xF9; case 0x05EA: return 0xFA;
    case 0x200E: return 0xFD; case 0x200F: return 0xFE;
    default: return (c >>> 0) & 0xFF;
  }
}