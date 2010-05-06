//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jun 07  Brian Frank  Creation
//

**
** WebUtil encapsulates several useful utility web methods.
** Also see `sys::MimeType` and its utility methods.
**
@Js
class WebUtil
{

//////////////////////////////////////////////////////////////////////////
// Chars
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if the specified string is a valid HTTP token production
  ** which is any ASCII character which is not a control char or a
  ** separator.  The separators characters are:
  **   "(" | ")" | "<" | ">" | "@" |
  **   "," | ";" | ":" | "\" | <"> |
  **   "/" | "[" | "]" | "?" | "=" |
  **   "{" | "}" | SP | HT
  **
  static Bool isToken(Str s)
  {
    if (s.isEmpty) return false
    return s.all |Int c->Bool| { return c < 127 && tokenChars[c] }
  }

  private static const Bool[] tokenChars
  static
  {
    m := Bool[,]
    for (i:=0; i<127; ++i) m.add(i > 0x20)
    m['(']  = false;  m[')'] = false;  m['<']  = false;  m['>'] = false
    m['@']  = false;  m[','] = false;  m[';']  = false;  m[':'] = false
    m['\\'] = false;  m['"'] = false;  m['/']  = false;  m['['] = false
    m[']']  = false;  m['?'] = false;  m['=']  = false;  m['{'] = false
    m['}']  = false;  m[' '] = false;  m['\t'] = false;
    tokenChars = m
  }

  **
  ** Return the specified string as a HTTP quoted string according
  ** to RFC 2616 Section 2.2.  The result is wrapped in quotes.  Throw
  ** ArgErr if any character is outside of the ASCII range of 0x20
  ** to 0x7e.  The quote char itself is backslash escaped.
  ** See `fromQuotedStr`.
  **
  static Str toQuotedStr(Str s)
  {
    buf := StrBuf()
    buf.addChar('"')
    s.each |Int c|
    {
      if (c < 0x20 || c > 0x7e) throw ArgErr("Invalid quoted str chars: $s")
      if (c == '"') buf.addChar('\\')
      buf.addChar(c)
    }
    buf.addChar('"')
    return buf.toStr
  }

  **
  ** Decode a HTTP quoted string according to RFC 2616 Section 2.2.
  ** The given string must be wrapped in quotes.  See `toQuotedStr`.
  **
  static Str fromQuotedStr(Str s)
  {
    if (s.size < 2 || s[0] != '"' || s[-1] != '"')
      throw ArgErr("Not quoted str: $s")
    return s[1..-2].replace("\\\"", "\"")
  }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a list of comma separated tokens.  Any leading
  ** or trailing whitespace is trimmed from the list of tokens.
  **
  static Str[] parseList(Str s)
  {
    return s.split(',')
  }

  **
  ** Parse a series of HTTP headers according to RFC 2616 section
  ** 4.2.  The final CRLF which terminates headers is consumed with
  ** the stream positioned immediately following.  The headers are
  ** returned as a [case insensitive]`sys::Map.caseInsensitive` map.
  ** Throw ParseErr if headers are malformed.
  **
  static Str:Str parseHeaders(InStream in)
  {
    headers := Str:Str[:]
    headers.caseInsensitive = true
    Str? last := null

    // read headers into map
    while (true)
    {
      peek := in.peek

      // CRLF is end of headers
      if (peek == CR) break

      // if line starts with space it is
      // continuation of last header field
      if (peek.isSpace && last != null)
      {
        headers[last] += " " + in.readLine.trim
        continue
      }

      // key/value pair
      key := token(in, ':').trim
      val := token(in, CR).trim
      if (in.read != LF)
        throw ParseErr("Invalid CRLF line ending")

      // check if key already defined in which case
      // this is an append, otherwise its a new pair
      dup := headers[key]
      if (dup == null)
        headers[key] = val
      else
        headers[key] = dup + "," + val
      last = key
    }

    // consume final CRLF
    if (in.read != CR || in.read != LF)
      throw ParseErr("Invalid CRLF headers ending")

    return headers
  }

  **
  ** Read the next token from the stream up to the specified
  ** separator. We place a limit of 512 bytes on a single token.
  ** Consume the separate char too.
  **
  private static Str token(InStream in, Int sep)
  {
    // read up to separator
    tok := in.readStrToken(maxTokenSize) |Int ch->Bool| { return ch == sep }

    // sanity checking
    if (tok == null) throw IOErr("Unexpected end of stream")
    if (tok.size >= maxTokenSize) throw ParseErr("Token too big")

    // read separator
    in.read

    return tok
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  **
  ** Given a set of headers, wrap the specified input stream
  ** to read the content body:
  **   1. If Content-Length then `makeFixedInStream`
  **   2. If Transfer-Encoding is chunked then `makeChunkedInStream`
  **   3. If Content-Type assume non-pipelined connection and
  **      return 'in' directly
  **   4. Assume no content and return null
  **
  ** If a stream is returned, then it is automatically configured
  ** with the correct content encoding based on the Content-Type.
  **
  static InStream? makeContentInStream(Str:Str headers, InStream in)
  {
    // map the "Content-Type" response header to the
    // appropiate charset or default to UTF-8.
    Charset cs := Charset.utf8
    ct := headers["Content-Type"]
    if (ct != null) cs = MimeType(ct).charset

    // check for fixed content length
    len := headers["Content-Length"]
    if (len != null)
      return makeFixedInStream(in, len.toInt) { charset = cs }

    // check for chunked transfer encoding
    if (headers.get("Transfer-Encoding", "").lower.contains("chunked"))
      return makeChunkedInStream(in) { charset = cs }

    // if content-type is specified assume open ended content until close
    if (ct != null) return in

    // no content in response
    return null
  }

  **
  ** Given a set of headers, wrap the specified output stream
  ** to write the content body:
  **   1. If Content-Length then `makeFixedOutStream`
  **   2. If Content-Type then set Transfer-Encoding header to
  **      chunked and return `makeChunkedOutStream`
  **   3. Assume no content and return null
  **
  ** If a stream is returned, then it is automatically configured
  ** with the correct content encoding based on the Content-Type.
  **
  static OutStream? makeContentOutStream(Str:Str headers, OutStream out)
  {
    // map the "Content-Type" response header to the
    // appropiate charset or default to UTF-8.
    Charset cs := Charset.utf8
    ct := headers["Content-Type"]
    if (ct != null) cs = MimeType(ct).charset

    // check for fixed content length
    len := headers["Content-Length"]
    if (len != null)
      return makeFixedOutStream(out, len.toInt) { charset = cs }

    // if content-type then assumed chunked output
    if (ct != null)
    {
      headers["Transfer-Encoding"] = "chunked"
      return makeChunkedOutStream(out) { charset = cs }
    }

    // no content
    return null
  }

  **
  ** Wrap the given input stream to read a fixed number of bytes.
  ** Once 'fixed' bytes have been read from the underlying input
  ** stream, the wrapped stream will return end-of-stream.  Closing
  ** the wrapper stream does not close the underlying stream.
  **
  static InStream makeFixedInStream(InStream in, Int fixed)
  {
    return ChunkInStream(in, fixed)
  }

  **
  ** Wrap the given input stream to read bytes using a HTTP
  ** chunked transfer encoding.  The wrapped streams provides
  ** a contiguous stream of bytes until the last chunk is read.
  ** Closing the wrapper stream does not close the underlying stream.
  **
  static InStream makeChunkedInStream(InStream in)
  {
    return ChunkInStream(in, null)
  }

  **
  ** Wrap the given output stream to write a fixed number of bytes.
  ** Once 'fixed' bytes have been written, attempting to further
  ** bytes will throw IOErr.  Closing the wrapper stream does not
  ** close the underlying stream.
  **
  static OutStream makeFixedOutStream(OutStream out, Int fixed)
  {
    return FixedOutStream(out, fixed)
  }

  **
  ** Wrap the given output stream to write bytes using a HTTP
  ** chunked transfer encoding.  Closing the wrapper stream
  ** terminates the chunking, but does not close the underlying
  ** stream.
  **
  static OutStream makeChunkedOutStream(OutStream out)
  {
    return ChunkOutStream(out)
  }

//////////////////////////////////////////////////////////////////////////
// Multi-Part Forms
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a multipart/form-data input stream.  For each part in the
  ** stream call the given callback function with the part's headers
  ** and an input stream used to read the part's body.  Each callback
  ** must completely drain the input stream to prepare for the next
  ** part.
  **
  static Void parseMultiPart(InStream in, Str boundary, |Str:Str headers, InStream in| cb)
  {
    boundary = "--" + boundary
    line := in.readLine
    if (line == boundary + "--") return
    if (line != boundary) throw IOErr("Expecting boundry line $boundary.toCode")
    while (true)
    {
      headers := parseHeaders(in)
      partIn := MultiPartInStream(in, boundary)
      cb(headers, partIn)
      if (partIn.endOfParts) break
    }
  }

//////////////////////////////////////////////////////////////////////////
// JsMain
//////////////////////////////////////////////////////////////////////////

  **
  ** Generate the method invocation code used to boostrap into
  ** JavaScript from a webpage.  This *must* be called inside the
  ** '<head>' tag for the page.  The main method will be invoked
  ** using the 'onLoad' DOM event.
  **
  ** The 'main' argument can be either a type or method.  If no
  ** method is specified, 'main' is used.  If the method is not
  ** static, a new instance of type is created:
  **
  **   "foo::Instance"     =>  Instance().main()
  **   "foo::Instance.bar" =>  Instance().bar()
  **   "foo::Static"       =>  Static.main()
  **   "foo::Static.bar"   =>  Static.bar()
  **
  ** If 'env' is specified, then vars will be added to and available
  ** from `sys::Env.vars` on client-side.
  **
  static Void jsMain(OutStream out, Str main, [Str:Str]? env := null)
  {
    envStr := StrBuf()
    if (env?.size > 0)
    {
      envStr.add("var env = fan.sys.Map.make(fan.sys.Str.\$type, fan.sys.Str.\$type);\n")
      envStr.add("env.caseInsensitive\$(true);\n")
      env.each |v,k|
      {
        envStr.add("  ")
        if (k == "sys.uriPodBase")
          envStr.add("fan.sys.UriPodBase = '$v';\n")
        else
          envStr.add("env.set('$k', '$v');\n")
      }
      envStr.add("fan.sys.Env.cur().\$setVars(env);\n")
    }

    out.printLine(
     "<script type='text/javascript'>
      //<![CDATA[
      var webJsMain_hasRun = false;
      var doLoad = function()
      {
        // safari appears to have a problem calling this event
        // twice, so make sure we short-circuit if already run
        if (webJsMain_hasRun) return;
        webJsMain_hasRun = true;

        // inject env vars
        $envStr.toStr

        // find main
        var qname = '$main';
        var dot = qname.indexOf('.');
        if (dot < 0) qname += '.main';
        var main = fan.sys.Slot.findMethod(qname);

        // invoke main
        if (main.isStatic()) main.call();
        else main.callOn(main.parent().make());
      }
      if (window.addEventListener)
        window.addEventListener('load', doLoad, false);
      else
        window.attachEvent('onload', doLoad);
      //]]>
      </script>")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const static Int CR  := '\r'
  internal const static Int LF  := '\n'
  internal const static Int HT  := '\t'
  internal const static Int SP  := ' '
  internal const static Int maxTokenSize := 4096

}

**************************************************************************
** ChunkInStream
**************************************************************************

internal class ChunkInStream : InStream
{
  new make(InStream in, Int? fixed := null) : super(null)
  {
    this.in = in
    this.isFixed  = (fixed != null)
    this.chunkRem = (fixed != null) ? fixed : -1
  }

  override Int? read()
  {
    if (pushback != null && !pushback.isEmpty) return pushback.pop
    if (!checkChunk) return null
    chunkRem -= 1
    return in.read
  }

  override Int? readBuf(Buf buf, Int n)
  {
    if (pushback != null && !pushback.isEmpty && n > 0)
    {
      buf.write(pushback.pop)
      return 1
    }
    if (!checkChunk) return null
    numRead := in.readBuf(buf, chunkRem.min(n))
    chunkRem -= numRead
    return numRead
  }

  override This unread(Int b)
  {
    if (pushback == null) pushback = Int[,]
    pushback.push(b)
    return this
  }

  private Bool checkChunk()
  {
    try
    {
      // if we have bytes remaining in this chunk return true
      if (chunkRem > 0) return true

      // if this is a single fixed "chunk" we are at end of stream
      if (isFixed) return false

      // we expect \r\n unless this is first chunk
      if (chunkRem != -1 && !in.readLine.isEmpty) throw Err()

      // read the next chunk status line
      line := in.readLine
      semi := line.index(";")
      if (semi != null) line = line[0..semi]
      chunkRem = line.toInt(16)

      // if we have more chunks keep chugging,
      // otherwise read any trailing headers
      if (chunkRem > 0) return true
      WebUtil.parseHeaders(in)
      return false
    }
    catch throw IOErr("Invalid format for HTTP chunked transfer encoding")
  }

  override Str toStr() { "${Type.of(this).qname} { isFixed=$isFixed chunkRem=$chunkRem pushback=$pushback }" }

  InStream in         // underlying input stream
  Bool isFixed        // if non-null, then we're using as one fixed chunk
  Int chunkRem        // remaining bytes in current chunk (-1 for first chunk)
  Int[]? pushback     // stack for unread
}

**************************************************************************
** FixedOutStream
**************************************************************************

internal class FixedOutStream : OutStream
{
  new make(OutStream out, Int fixed) : super(null)
  {
    this.out = out
    this.fixed = fixed
  }

  override This write(Int b)
  {
    checkChunk(1)
    out.write(b)
    return this
  }

  override This writeBuf(Buf buf, Int n := buf.remaining)
  {
    checkChunk(n)
    out.writeBuf(buf, n)
    return this
  }

  override This flush()
  {
    out.flush
    return this
  }

  override Bool close()
  {
    try
    {
      this.flush
      return true
    }
    catch (Err e) return false
  }

  private Void checkChunk(Int n)
  {
    written += n
    if (written > fixed) throw IOErr("Attempt to write more than Content-Length: $fixed")
  }

  OutStream out      // underlying output stream
  Int? fixed         // if non-null, then we're using as one fixed chunk
  Int written        // number of bytes written in this chunk
}

**************************************************************************
** ChunkOutStream
**************************************************************************

internal class ChunkOutStream : OutStream
{
  new make(OutStream out) : super(null)
  {
    this.out = out
    this.buffer = Buf(chunkSize + 256)
  }

  override This write(Int b)
  {
    buffer.write(b)
    checkChunk
    return this
  }

  override This writeBuf(Buf buf, Int n := buf.remaining)
  {
    buffer.writeBuf(buf, n)
    checkChunk
    return this
  }

  override This flush()
  {
    if (closed) throw IOErr("ChunkOutStream is closed")
    if (buffer.size > 0)
    {
      out.print(buffer.size.toHex).print("\r\n")
      out.writeBuf(buffer.flip, buffer.remaining)
      out.print("\r\n").flush
      buffer.clear
    }
    return this
  }

  override Bool close()
  {
    // never write end of chunk more than once
    if (closed) return true

    try
    {
      this.flush
      closed = true
      out.print("0\r\n\r\n").flush
      return true
    }
    catch return false
  }

  private Void checkChunk()
  {
    if (buffer.size >= chunkSize) flush
  }

  const static Int chunkSize := 1024

  OutStream out    // underlying output stream
  Buf? buffer      // buffer for bytes
  Bool closed      // have we written final close chunk?
}

**************************************************************************
** MultiPartInStream
**************************************************************************

internal class MultiPartInStream : InStream
{
  new make(InStream in, Str boundary) : super(null)
  {
    this.in = in
    this.boundary = boundary
    this.curLine = Buf(1024)
  }

  override Int? read()
  {
    if (pushback != null && !pushback.isEmpty) return pushback.pop
    if (!checkLine) return null
    numRead += 1
    return curLine.read
  }

  override Int? readBuf(Buf buf, Int n)
  {
    if (pushback != null && !pushback.isEmpty && n > 0)
    {
      buf.write(pushback.pop)
      numRead += 1
      return 1
    }
    if (!checkLine) return null
    actualRead := curLine.readBuf(buf, n)
    numRead += actualRead
    return actualRead
  }

  override This unread(Int b)
  {
    if (pushback == null) pushback = Int[,]
    pushback.push(b)
    numRead -= 1
    return this
  }

  private Bool checkLine()
  {
    // if we have bytes remaining in this line return true
    if (curLine.remaining > 0) return true

    // if we have read boundary, then this part is complete
    if (endOfPart) return false

    // read the next line or 1000 bytes into curLine buf
    curLine.clear
    for (i:=0; i<1024; ++i)
    {
      c := in.readU1
      curLine.write(c)
      if (c == '\n') break
    }

    // if not a property \r\n newline then keep chugging
    if (curLine.size < 2 || curLine[-2] != '\r') { curLine.seek(0); return true }

    // go ahead and keep reading as long as we have boundary match
    for (i:=0; i<boundary.size; ++i)
    {
      c := in.readU1
      if (c != boundary[i])
      {
        if (c == '\r') in.unread(c)
        else curLine.write(c)
        curLine.seek(0)
        return true
      }
      curLine.write(c)
    }

    // we have boundary match, so now figure out if end of parts
    curLine.size = curLine.size - boundary.size - 2
    c1 := in.readU1
    c2 := in.readU1
    if (c1 == '-' && c2 == '-')
    {
      endOfParts = true
      c1 = in.readU1
      c2 = in.readU1
    }
    if (c1 != '\r' || c2 != '\n') throw IOErr("Fishy boundary " + (c1.toChar + c2.toChar).toCode('"', true))
    endOfPart = true
    curLine.seek(0)
    return curLine.size > 0
  }

  InStream in
  Str boundary
  Buf curLine
  Int[]? pushback     // stack for unread
  Bool endOfPart
  Bool endOfParts
  Int numRead
}

