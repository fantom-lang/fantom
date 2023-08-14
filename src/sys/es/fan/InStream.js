//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   25 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * InStream
 */
class InStream extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() {
    super();
    this.#in = null;
    this.#charset = Charset.utf8();
    this.#bigEndian = true;
  }

  #in;
  #inChar;
  #charset;
  #bigEndian;

  static make(in$=null) {
    const s = new InStream();
    InStream.make$(s, in$);
    return s;
  }

  static __makeForStr(s) { return new StrInStream(s); }

  static make$(self, in$) { 
    self.#in = in$; 
    if (in$ != null) {
      self.#inChar = in$.__toCharInStream();
      self.charset(in$.charset());
    }
  }

  /**
   * If this input stream is optimized to read chars, then return
   * this. Otherwise return null so that wrapped InStreams always
   * do charset decoding themselves from the raw bytes.
   */
  __toCharInStream() { return null; }

//////////////////////////////////////////////////////////////////////////
// InputStream
//////////////////////////////////////////////////////////////////////////

  /**
   * Read char as primitive int.
   */
  __rChar() {
    if (this.#inChar) 
      return this.#inChar.__rChar();
    else 
      return this.#charset.__encoder().decode(this);
  }

  avail() { return 0; }

  read() {
    if (!this.#in) throw UnsupportedErr.make(`${this.typeof$().qname()} wraps null InStream`);
    return this.#in.read();
  }

  readBuf(buf, n) {
    if (!this.#in) throw UnsupportedErr.make(`${this.typeof$().qname()} wraps null InStream`);
    return this.#in.readBuf(buf, n);
  }

  unread(n) {
    if (!this.#in) throw UnsupportedErr.make(`${this.typeof$().qname()} wraps null InStream`);
    return this.#in.unread(n);
  }

  skip(n) {
    if (this.#in) return this.#in.skip(n);

    // TODO:TEST - this doesn't seem right. why comparing to 0? instead of
    // testing null
    for (let i=0; i<n; ++i)
      if (this.read() == 0) return i;
    return n;
  }

  readAllBuf() {
    try {
      const size = Int.__chunk;
      const buf = Buf.make(size);
      while (this.readBuf(buf, size) != null);
      buf.flip();
      return buf;
    }
    finally {
      try { this.close(); } catch (e) { ObjUtil.echo("InStream.readAllBuf: " + e); }
    }
  }

  readBufFully(buf, n) {
    if (buf == null) buf = Buf.make(n);

    let total = n;
    let got = 0;
    while (got < total) {
      const r = this.readBuf(buf, total-got);
      if (r == null || r == 0) throw IOErr.make("Unexpected end of stream");
      got += r;
    }

    buf.flip();
    return buf;
  }

  endian(it) { 
    if (it === undefined) return this.#bigEndian ? Endian.big() : Endian.little(); 
    this.#bigEndian = (it == Endian.big());
  }


  peek() {
    const x = this.read();
    if (x != null) this.unread(x);
    return x;
  }

  readU1() {
    const c = this.read();
    if (c == null) throw IOErr.make("Unexpected end of stream");
    return c;
  }

  readS1() {
    const c = this.read();
    if (c == null) throw IOErr.make("Unexpected end of stream");
    return c <= 0x7F ? c : (0xFFFFFF00 | c);
  }

  readU2() {
    const c1 = this.read();
    const c2 = this.read();
    if (c1 == null || c2 == null) throw IOErr.make("Unexpected end of stream");
    if (this.#bigEndian)
      return c1 << 8 | c2;
    else
      return c2 << 8 | c1;
  }

  readS2() {
    const c1 = this.read();
    const c2 = this.read();
    if (c1 == null || c2 == null) throw IOErr.make("Unexpected end of stream");
    let c;
    if (this.#bigEndian)
      c = c1 << 8 | c2;
    else
      c = c2 << 8 | c1;
    return c <= 0x7FFF ? c : (0xFFFF0000 | c);
  }

  readU4() {
    const c1 = this.read();
    const c2 = this.read();
    const c3 = this.read();
    const c4 = this.read();
    if (c1 == null || c2 == null || c3 == null || c4 == null) throw IOErr.make("Unexpected end of stream");
    let c;
    if (this.#bigEndian)
      c = (c1 << 24) + (c2 << 16) + (c3 << 8) + c4;
    else
      c = (c4 << 24) + (c3 << 16) + (c2 << 8) + c1;
    if (c >= 0)
      return c;
    else
      return (c & 0x7FFFFFFF) + Math.pow(2, 31);
  }

  readS4() {
    const c1 = this.read();
    const c2 = this.read();
    const c3 = this.read();
    const c4 = this.read();
    if (c1 == null || c2 == null || c3 == null || c4 == null) throw IOErr.make("Unexpected end of stream");
    if (this.#bigEndian)
      return (c1 << 24) + (c2 << 16) + (c3 << 8) + c4;
    else
      return (c4 << 24) + (c3 << 16) + (c2 << 8) + c1;
  }

  readS8() {
    const c1 = this.read();
    const c2 = this.read();
    const c3 = this.read();
    const c4 = this.read();
    const c5 = this.read();
    const c6 = this.read();
    const c7 = this.read();
    const c8 = this.read();
    if ((c1 | c2 | c3 | c4 | c5 | c6 | c7 | c8) < 0) throw IOErr.make("Unexpected end of stream");
    if (this.#bigEndian)
      return ((c1 << 56) + (c2 << 48) + (c3 << 40) + (c4 << 32) +
              (c5 << 24) + (c6 << 16) + (c7 << 8) + c8);
    else
      return ((c8 << 56) + (c7 << 48) + (c6 << 40) + (c5 << 32) +
              (c4 << 24) + (c3 << 16) + (c2 << 8) + c1);
  }

  readF4() { return Float.makeBits32(this.readS4()); }

  readF8() { throw Err.make("InStream.readF8 not supported in JavaScript"); }

  readDecimal() {
    const inp = this.readUtf()
    return Decimal.fromStr(inp);
  }

  readBool() {
    const c = this.read();
    if (c == null) throw IOErr.make("Unexpected end of stream");
    return c != 0;
  }

  readUtf() {
    // read two-byte length
    const len1 = this.read();
    const len2 = this.read();
    if (len1 == null || len2 == null) throw IOErr.make("Unexpected end of stream");
    const utflen = len1 << 8 | len2;

    let buf = ""; // char buffer we read into
    let bnum = 0; // byte count

    // read the chars
    let c1, c2, c3;
    while (bnum < utflen) {
      c1 = this.read(); bnum++;
      if (c1 == null) throw IOErr.make("Unexpected end of stream");
      switch (c1 >> 4) {
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
          // 0xxxxxxx
          buf += String.fromCharCode(c1);
          break;
        case 12: case 13:
          // 110x xxxx   10xx xxxx
          if (bnum >= utflen) throw IOErr.make("UTF encoding error");
          c2 = this.read(); bnum++;
          if (c2 == null) throw IOErr.make("Unexpected end of stream");
          if ((c2 & 0xC0) != 0x80) throw IOErr.make("UTF encoding error");
          buf += String.fromCharCode(((c1 & 0x1F) << 6) | (c2 & 0x3F));
          break;
        case 14:
          // 1110 xxxx  10xx xxxx  10xx xxxx 
          if (bnum+1 >= utflen) throw IOErr.make("UTF encoding error");
          c2 = this.read(); bnum++;
          c3 = this.read(); bnum++;
          if (c2 == null || c3 == null) throw IOErr.make("Unexpected end of stream");
          if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80)) throw IOErr.make("UTF encoding error");
          buf += String.fromCharCode(((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
          break;
        default:
          // 10xx xxxx,  1111 xxxx 
          throw IOErr.make("UTF encoding error");
      }
    }
    return buf;
  }

  charset(it) { 
    if (it === undefined) return this.#charset;
    this.#charset = it;
  }

  readChar() {
    const ch = this.__rChar();
    return ch < 0 ? null : ch;
  }

  unreadChar(c) {
    const ch = this.#charset.__encoder().encodeIn(c, this);
    // return ch < 0 ? null : ch;
    return this;
  }

  peekChar() {
    const x = this.readChar();
    if (x != null) this.unreadChar(x);
    return x;
  }

  readChars(n) {
    if (n === undefined || n < 0) throw ArgErr.make("readChars n < 0: " + n);
    if (n == 0) return "";
    let buf = "";
    for (let i=n; i>0; --i) {
      const ch = this.__rChar();
      if (ch < 0) throw IOErr.make("Unexpected end of stream");
      buf += String.fromCharCode(ch);
    }
    return buf;
  }

  readLine(max=null) {
    // max limit
    const maxChars = (max != null) ? max.valueOf() : Int.maxVal();
    if (maxChars <= 0) return "";

    // read first char, if at end of file bail
    let c = this.__rChar();
    if (c < 0) return null;

    // loop reading char until we hit newline
    // combo or end of stream
    let buf = "";
    while (true) {
      // check for \n, \r\n, or \r
      if (c == 10) break;
      if (c == 13) {
        c = this.__rChar();
        if (c >= 0 && c != 10) this.unreadChar(c);
        break;
      }

      // append to working buffer
      buf += String.fromCharCode(c);
      if (buf.length >= maxChars) break;

      // read next char
      c = this.__rChar();
      if (c < 0) break;
    }
    return buf;
  }

  readNullTerminatedStr(max=null) {
    // max limit
    const maxChars = (max != null) ? max.valueOf() : Int.maxVal();
    if (maxChars <= 0) return "";

    // read first char, if at end of file bail
    let c = this.__rChar();
    if (c < 0) return null;

    // loop readin chars until we hit '\0' or max chars
    let buf = "";
    while (true) {
      if (c == 0) break;

      // append to working buffer
      buf += String.fromCharCode(c);
      if (buf.length >= maxChars) break;

      // read next char
      c = this.__rChar();
      if (c < 0) break;
    }
    return buf;
  }

  readStrToken(max=null, f=null) {
    if (max == null) max = Int.__chunk;

    // max limit
    const maxChars = (max != null) ? max.valueOf() : Int.maxVal();
    if (maxChars <= 0) return "";

    // read first char, if at end of file bail
    let c = this.__rChar();
    if (c < 0) return null;

    // loop reading chars until our closure returns false
    let buf = "";
    while (true) {
      // check for \n, \r\n, or \r
      let terminate;
      if (f == null)
        terminate = Int.isSpace(c);
      else
        terminate = f(c);
      if (terminate) {
        this.unreadChar(c);
        break;
      }

      // append to working buffer
      buf += String.fromCharCode(c);
      if (buf.length >= maxChars) break;

      // read next char
      c = this.__rChar();
      if (c < 0) break;
    }
    return buf;
  }

  readAllLines() {
    try {
      const list = List.make(Str.type$, []);
      let line = "";
      while ((line = this.readLine()) != null)
        list.push(line);
      return list;
    }
    finally {
      try { this.close(); } catch (err) { Err.make(err).trace(); }
    }
  }

  eachLine(f) {
    try {
      let line;
      while ((line = this.readLine()) != null)
        f(line);
    }
    finally {
      try { this.close(); } catch (err) { Err.make(err).trace(); }
    }
  }

  readAllStr(normalizeNewlines=true) {
    try {
      let s = "";
      const normalize = normalizeNewlines;

      // read characters
      let last = -1;
      while (true) {
        const c = this.__rChar();
        if (c < 0) break;

        // normalize newlines and add to buffer
        if (normalize) {
          if (c == 13) s += String.fromCharCode(10);
          else if (last == 13 && c == 10) {}
          else s += String.fromCharCode(c);
          last = c;
        }
        else {
          s += String.fromCharCode(c);
        }
      }
      return s;
    }
    finally {
      try { this.close(); } catch (err) { Err.make(err).trace(); }
    }
  }

  readObj(options=null) {
    return new fanx_ObjDecoder(this, options).readObj();
  }

  readProps() {
    const origCharset = this.charset();
    this.charset(Charset.utf8());
    try {
      const props = Map.make(Str.type$, Str.type$);

      let name = "";
      let v = null;
      let inBlockComment = 0;
      let inEndOfLineComment = false;
      let c = 32, last = 32;
      let lineNum = 1;
      let colNum = 0;

      while (true) {
        last = c;
        c = this.__rChar();
        ++colNum;
        if (c < 0) break;

        // end of line
        if (c == 10 || c == 13) {
          colNum = 0;
          inEndOfLineComment = false;
          if (last == 13 && c == 10) continue;
          const n = Str.trim(name);
          if (v !== null) {
            props.add(n, Str.trim(v));
            name = "";
            v = null;
          }
          else if (n.length > 0)
            throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]");
          lineNum++;
          continue;
        }

        // if in comment
        if (inEndOfLineComment) continue;

        // block comment
        if (inBlockComment > 0) {
          if (last == 47 && c == 42) inBlockComment++;
          if (last == 42 && c == 47) inBlockComment--;
          continue;
        }

        // equal
        if (c == 61 && v === null) {
          v = "";
          continue;
        }

        // line comment
        // if (c == 35 && (last == 10 || last == 13)) {
        if (c == 35 && colNum == 1) {
          inEndOfLineComment = true;
          continue;
        }

        // end of line comment
        if (c == 47 && Int.isSpace(last)) {
          const peek = this.__rChar();
          if (peek < 0) break;
          if (peek == 47) { inEndOfLineComment = true; continue; }
          if (peek == 42) { inBlockComment++; continue; }
          this.unreadChar(peek);
        }

        // escape or line continuation
        if (c == 92) {
          let peek = this.__rChar();
          if (peek < 0) break;
          else if (peek == 110) c = 10;
          else if (peek == 114) c = 13;
          else if (peek == 116) c = 9;
          else if (peek == 92)  c = 92;
          else if (peek == 13 || peek == 10)
          {
            // line continuation
            lineNum++;
            if (peek == 13)
            {
              peek = this.__rChar();
              if (peek != 10) this.unreadChar(peek);
            }
            while (true) {
              peek = this.__rChar();
              if (peek == 32 || peek == 9) continue;
              this.unreadChar(peek);
              break;
            }
            continue;
          }
          else if (peek == 117)
          {
            const n3 = InStream.#hex(this.__rChar());
            const n2 = InStream.#hex(this.__rChar());
            const n1 = InStream.#hex(this.__rChar());
            const n0 = InStream.#hex(this.__rChar());
            if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0) throw IOErr.make("Invalid hex value for \\uxxxx [Line " +  lineNum + "]");
            c = ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
          }
          else throw IOErr.make("Invalid escape sequence [Line " + lineNum + "]");
        }

        // normal character
        if (v === null)
          name += String.fromCharCode(c);
        else
          v += String.fromCharCode(c);
      }

      const n = Str.trim(name);
      if (v !== null)
        props.add(n, Str.trim(v));
      else if (n.length > 0)
        throw IOErr.make("Invalid name/value pair [Line " + lineNum + "]");

      return props;
    }
    finally {
      try { this.close(); } catch (err) { Err.make(err).trace(); }
      this.charset(origCharset);
    }
  }

  static #hex(c) {
    if (48 <= c && c <= 57)  return c - 48;
    if (97 <= c && c <= 102) return c - 97 + 10;
    if (65 <= c && c <= 70)  return c - 65 + 10;
    return -1;
  }

  pipe(out, toPipe=null, close=true)
  {
    try {
      let bufSize = Int.__chunk;
      const buf = Buf.make(bufSize);
      let total = 0;
      if (toPipe == null) {
        while (true) {
          const n = this.readBuf(buf.clear(), bufSize);
          if (n == null) break;
          out.writeBuf(buf.flip(), buf.remaining());
          total += n;
        }
      }
      else {
        const toPipeVal = toPipe;
        while (total < toPipeVal) {
          if (toPipeVal - total < bufSize) bufSize = toPipeVal - total;
          const n = this.readBuf(buf.clear(), bufSize);
          if (n == null) throw IOErr.make("Unexpected end of stream");
          out.writeBuf(buf.flip(), buf.remaining());
          total += n;
        }
      }
      return total;
    }
    finally {
      if (close) this.close();
    }
  }

  close() {
    if (this.#in) return this.#in.close();
    return true;
  }
}