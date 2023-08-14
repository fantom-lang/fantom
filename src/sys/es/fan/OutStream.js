//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 2009  Andy Frank  Creation
//   25 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * OutStream
 */
class OutStream extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() {
    super();
    this.#out = null;
    this.#charset = Charset.utf8();
    this.#bigEndian = true;
  }

  #out;
  #charset;
  #bigEndian;

  static #xmlEscNewLines = 0x01;
  static xmlEscNewlines() { return OutStream.#xmlEscNewLines; }

  static #xmlEscQuotes = 0x02;
  static xmlEscQuotes() { return OutStream.#xmlEscQuotes; }

  static #xmlEscUnicode = 0x04;
  static xmlEscUnicode() { return OutStream.#xmlEscUnicode; }

  static make$(self, out) { 
    self.#out = out; 
    if (out != null) self.charset(out.charset());
  }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  __out() { return this.#out; }

  write(x) {
    if (!this.#out) throw UnsupportedErr.make(`${this.typeof$().qname()} wraps null OutStream`);
    this.#out.write(x);
    return this;
    // try
    // {
    //   this.out.write(x);
    //   return this;
    // }
    // catch (err)
    // {
    //   if (this.out == null)
    //     throw fan.sys.UnsupportedErr.make(this.$typeof().qname() + " wraps null OutStream");
    //   else
    //     throw err;
    // }
  }

  writeBuf(buf, n=buf.remaining()) {
    if (!this.#out) throw UnsupportedErr.make(`${this.typeof$().qname()} wraps null OutStream`);
    this.out.writeBuf(buf, n);
    return this;
    // try
    // {
    //   this.out.writeBuf(buf, n);
    //   return this;
    // }
    // catch (err)
    // {
    //   if (this.out == null)
    //     throw fan.sys.UnsupportedErr.make(this.typeof$().qname() + " wraps null OutStream");
    //   else
    //     throw err;
    // }
  }

  endian(it) {
    if (it === undefined) return this.#bigEndian ? Endian.big() : Endian.little();
    this.#bigEndian = (it == Endian.big());
  }

  writeI2(x) {
    if (this.#bigEndian)
      return this.write((x >>> 8) & 0xFF)
                 .write((x >>> 0) & 0xFF);
    else
      return this.write((x >>> 0) & 0xFF)
                 .write((x >>> 8) & 0xFF);
  }

  writeI4(x) {
    if (this.#bigEndian)
      return this.write((x >>> 24) & 0xFF)
                 .write((x >>> 16) & 0xFF)
                 .write((x >>> 8)  & 0xFF)
                 .write((x >>> 0)  & 0xFF);
    else
      return this.write((x >>> 0)  & 0xFF)
                 .write((x >>> 8)  & 0xFF)
                 .write((x >>> 16) & 0xFF)
                 .write((x >>> 24) & 0xFF);
  }

  writeI8(x) {
    if (this.#bigEndian)
      return this.write((x >>> 56) & 0xFF)
                 .write((x >>> 48) & 0xFF)
                 .write((x >>> 40) & 0xFF)
                 .write((x >>> 32) & 0xFF)
                 .write((x >>> 24) & 0xFF)
                 .write((x >>> 16) & 0xFF)
                 .write((x >>> 8)  & 0xFF)
                 .write((x >>> 0)  & 0xFF);
    else
      return this.write((x >>> 0)  & 0xFF)
                 .write((x >>> 8)  & 0xFF)
                 .write((x >>> 16) & 0xFF)
                 .write((x >>> 24) & 0xFF)
                 .write((x >>> 32) & 0xFF)
                 .write((x >>> 40) & 0xFF)
                 .write((x >>> 48) & 0xFF)
                 .write((x >>> 56) & 0xFF);
  }

  writeF4(x) { return this.writeI4(Float.bits32(x)); }

  writeF8(x) { throw make("OutStream.writeF8 not supported in JavaScript"); }

  writeDecimal(x) { return this.writeUtf(x.toString()); }

  writeBool(x) { return this.write(x ? 1 : 0); }

  writeUtf(s) {
    const slen = s.length;
    let utflen = 0;

    // first we have to figure out the utf length
    for (let i=0; i<slen; ++i)
    {
      const c = s.charCodeAt(i);
      if (c <= 0x007F)
        utflen +=1;
      else if (c > 0x07FF)
        utflen += 3;
      else
        utflen += 2;
    }

    // sanity check
    if (utflen > 65536) throw IOErr.make("String too big");

    // write length as 2 byte value
    this.write((utflen >>> 8) & 0xFF);
    this.write((utflen >>> 0) & 0xFF);

    // write characters
    for (let i=0; i<slen; ++i)
    {
      const c = s.charCodeAt(i);
      if (c <= 0x007F) {
        this.write(c);
      }
      else if (c > 0x07FF) {
        this.write(0xE0 | ((c >> 12) & 0x0F));
        this.write(0x80 | ((c >>  6) & 0x3F));
        this.write(0x80 | ((c >>  0) & 0x3F));
      }
      else {
        this.write(0xC0 | ((c >>  6) & 0x1F));
        this.write(0x80 | ((c >>  0) & 0x3F));
      }
    }
    return this;
  }

  charset(it) {
    if (it === undefined) return this.#charset;
    this.#charset = it;
  }

  writeChar(c) {
    if (this.#out != null) 
      this.#out.writeChar(c)
    else 
      this.#charset.__encoder().encodeOut(c, this);
    return this;
  }

  writeChars(s, off=0, len=s.length-off) {
    const end = off+len;
    for (let i=off; i<end; i++)
      this.writeChar(s.charCodeAt(i));
    return this;
  }

  print(obj) {
    const s = obj == null ? "null" : ObjUtil.toStr(obj);
    return this.writeChars(s, 0, s.length);
  }

  printLine(obj="") {
    const s = obj == null ? "null" : ObjUtil.toStr(obj);
    this.writeChars(s, 0, s.length);
    return this.writeChars('\n');
  }

  writeObj(obj, options=null) {
    new fanx_ObjEncoder(this, options).writeObj(obj);
    return this;
  }

  flush() {
    if (this.#out != null) this.#out.flush();
    return this;
  }

  writeProps(props, close=true) {
    const origCharset = this.charset();
    this.charset(Charset.utf8());
    try {
      const keys = props.keys().sort();
      const size = keys.size();
      for (let i=0; i<size; ++i) {
        const key = keys.get(i);
        const val = props.get(key);
        this.#writePropStr(key);
        this.writeChar(61);
        this.#writePropStr(val);
        this.writeChar(10);
      }
      return this;
    }
    finally {
      try { if (close) this.close(); } catch (err) { ObjUtil.echo(err); }
      this.charset(origCharset);
    }
  }

  #writePropStr(s) {
    const len = s.length;
    for (let i=0; i<len; ++i) {
      const ch = s.charCodeAt(i);
      const peek = i+1<len ? s.charCodeAt(i+1) : -1;

      // escape special chars
      switch (ch) {
        case 10: this.writeChar(92).writeChar(110); continue;
        case 13: this.writeChar(92).writeChar(114); continue;
        case  9: this.writeChar(92).writeChar(116); continue;
        case 92: this.writeChar(92).writeChar(92); continue;
      }

      // escape control chars, comments, and =
      if ((ch < 32) || (ch == 47 && (peek == 47 || peek == 42)) || (ch == 61))
      {
        const nib1 = Int.toDigit((ch >>> 4) & 0xf, 16);
        const nib2 = Int.toDigit((ch >>> 0) & 0xf, 16);

        this.writeChar(92).writeChar(117)
            .writeChar(48).writeChar(48)
            .writeChar(nib1).writeChar(nib2);
        continue;
      }

      // normal character
      this.writeChar(ch);
    }
  }

  writeXml(s, mask=0) {
    const escNewlines  = (mask & OutStream.xmlEscNewlines()) != 0;
    const escQuotes    = (mask & OutStream.xmlEscQuotes()) != 0;
    const escUnicode   = (mask & OutStream.xmlEscUnicode()) != 0;

    for (let i=0; i<s.length; ++i) {
      const ch = s.charCodeAt(i);
      switch (ch) {
        // table switch on control chars
        case  0: case  1: case  2: case  3: case  4: case  5: case  6:
        case  7: case  8: case 11: case 12:
        case 14: case 15: case 16: case 17: case 18: case 19: case 20:
        case 21: case 22: case 23: case 24: case 25: case 26: case 27:
        case 28: case 29: case 30: case 31:
          this.#writeXmlEsc(ch);
          break;

        // newlines
        case 10: case 13:
          if (!escNewlines)
            this.writeChar(ch);
          else
            this.#writeXmlEsc(ch);
          break;

        // space
        case 32:
          this.writeChar(32);
          break;

        // table switch on common ASCII chars
        case 33: case 35: case 36: case 37: case 40: case 41: case 42:
        case 43: case 44: case 45: case 46: case 47: case 48: case 49:
        case 50: case 51: case 52: case 53: case 54: case 55: case 56:
        case 57: case 58: case 59: case 61: case 63: case 64: case 65:
        case 66: case 67: case 68: case 69: case 70: case 71: case 72:
        case 73: case 74: case 75: case 76: case 77: case 78: case 79:
        case 80: case 81: case 82: case 83: case 84: case 85: case 86:
        case 87: case 88: case 89: case 90: case 91: case 92: case 93:
        case 94: case 95: case 96: case 97: case 98: case 99: case 100:
        case 101: case 102: case 103: case 104: case 105: case 106: case 107:
        case 108: case 109: case 110: case 111: case 112: case 113: case 114:
        case 115: case 116: case 117: case 118: case 119: case 120: case 121:
        case 122: case 123: case 124: case 125: case 126:
          this.writeChar(ch);
          break;

        // XML control characters
        case 60:
          this.writeChar(38);
          this.writeChar(108);
          this.writeChar(116);
          this.writeChar(59);
          break;
        case 62:
          if (i > 0 && s.charCodeAt(i-1) != 93)
            this.writeChar(62);
          else
          {
            this.writeChar(38);
            this.writeChar(103);
            this.writeChar(116);
            this.writeChar(59);
          }
          break;
        case 38:
          this.writeChar(38);
          this.writeChar(97);
          this.writeChar(109);
          this.writeChar(112);
          this.writeChar(59);
          break;
        case 34:
          if (!escQuotes)
            this.writeChar(34);
          else
          {
            this.writeChar(38);
            this.writeChar(113);
            this.writeChar(117);
            this.writeChar(111);
            this.writeChar(116);
            this.writeChar(59);
          }
          break;
        case 39:
          if (!escQuotes)
            this.writeChar(39);
          else
          {
            // &#39;
            this.writeChar(38);
            this.writeChar(35);
            this.writeChar(51);
            this.writeChar(57);
            this.writeChar(59);
          }
          break;

        // default
        default:
          if (ch <= 0xf7 || !escUnicode)
            this.writeChar(ch);
          else
            this.#writeXmlEsc(ch);
      }
    }
    return this;
  }

  #writeXmlEsc(ch) {
    // const enc = this.#charset.__encoder();
    const hex = "0123456789abcdef";

    this.writeChar(38);
    this.writeChar(35);
    this.writeChar(120);
    if (ch > 0xff) {
      this.writeChar(hex.charCodeAt((ch >>> 12) & 0xf));
      this.writeChar(hex.charCodeAt((ch >>> 8)  & 0xf));
    }
    this.writeChar(hex.charCodeAt((ch >>> 4) & 0xf));
    this.writeChar(hex.charCodeAt((ch >>> 0) & 0xf));
    this.writeChar(59);
  }

  sync() {
    if (this.#out != null) this.#out.sync();
    return this;
  }

  close() {
    if (this.#out != null) return this.#out.close();
    return true;
  }
}