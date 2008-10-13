//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Apr 08  Brian Frank  Creation
//

using inet

**
** SmtpClient implements the client side of SMTP (Simple
** Mail Transport Protocol) as specified by RFC 2821.
**
** See [docLib]`docLib::Email` for details.
** See [docCookbook]`docCookbook::Email` for coding examples.
**
class SmtpClient
{

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  **
  ** DNS hostname of server.
  **
  Str host

  **
  ** TCP port number of server, defaults to 25.
  **
  Int port := 25

  **
  ** Username to use for authentication, or null to skip
  ** authentication.
  **
  Str? username

  **
  ** Password to use for authentication, or null to skip
  ** authentication.
  **
  Str? password

//////////////////////////////////////////////////////////////////////////
// Send
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if there is no open session.
  **
  Bool isClosed()
  {
    return sock == null
  }

  **
  ** Open a session to the SMTP server.  If username and
  ** password are configured, then SMTP authentication is
  ** attempted.  Throw SmtpErr if there is a protocol error.
  ** Throw IOErr is there is a network problem.
  **
  Void open()
  {
    // do sanity checking before opening the socket
    if ((Obj?)host == null) throw NullErr("host is null")
    if ((Obj?)port == null) throw NullErr("port is null")

    // open the socket connection
    sock = TcpSocket().connect(IpAddress(host), port)
    try
    {
      // read server hello
      res := readRes
      if (res.code != 220) throw SmtpErr.makeRes(res)

      // EHLO query the extensions supported
      writeReq("EHLO [$IpAddress.local.numeric]")
      res = readRes
      if (res.code != 250) throw SmtpErr.makeRes(res)
      readExts(res)

      // authenticate if configured
      if (username != null && password != null && auths != null)
        authenticate
    }
    catch (Err e)
    {
      close
      throw e
    }
  }

  **
  ** Close the session to the SMTP server.  Do nothing if
  ** session already closed.
  **
  Void close()
  {
    if (sock != null)
    {
      try { writeReq("QUIT") } catch {}
      try { sock.close } catch {}
      sock = null
    }
  }

  **
  ** Send the email to the SMTP server.  Throw SmtpErr if
  ** there is a protocol error.  Throw IOErr if there is
  ** a networking problem.  If the session is closed, then
  ** this call automatically opens the session and guarantees
  ** a close after it is complete.
  **
  Void send(Email email)
  {
    email.validate
    autoOpen := isClosed
    if (autoOpen) open
    try
    {
      // MAIL command
      writeReq("MAIL From:$email.from")
      res := readRes
      if (res.code != 250) throw SmtpErr.makeRes(res)

      // RCPT for each to address
      email.recipients.each |Str to|
      {
        writeReq("RCPT To:$to")
        res = readRes
        if (res.code != 250) throw SmtpErr.makeRes(res)
      }

      // DATA command
      writeReq("DATA")
      res = readRes
      if (res.code != 354) throw SmtpErr.makeRes(res)

      // encode email message
      email.encode(sock.out)
      sock.out.flush
      res = readRes
      if (res.code != 250) throw SmtpErr.makeRes(res)
    }
    finally
    {
      if (autoOpen) close
    }
  }

  **
  ** Write a request line to the server.
  **
  private Void writeReq(Str req)
  {
    sock.out.print(req).print("\r\n").flush
    if (log.isDebug) log.debug("c: $req")
  }

  **
  ** Read a single or multi-line reply from the server.
  **
  private SmtpRes readRes()
  {
    res := SmtpRes()

    while (true)
    {
      line := sock.in.readLine
      try
      {
        res.code = line[0..2].toInt
        if (line.size <= 4) { res.lines.add(""); break }
        res.lines.add(line[4..-1])
        if (line[3] != '-') break
      }
      catch (Err e)
      {
        throw IOErr("Invalid SMTP reply '$line'")
      }
    }

    if (log.isDebug)
    {
      res.lines.each |Str line, Int i|
      {
        sep := i < res.lines.size-1 ? "-" : " "
        log.debug("s: $res.code$sep$line")
      }
    }

    return res
  }

  **
  ** Query the reply lines to figure out which extensions
  ** the server supports that we might use.
  **
  Void readExts(SmtpRes res)
  {
    res.lines.each |Str line|
    {
      toks := line.upper.split
      switch (toks[0])
      {
        case "AUTH":
          auths = toks[1..-1]
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Authentication
//////////////////////////////////////////////////////////////////////////

  **
  ** Authenticate using the strongest mechanism
  ** which both the server and myself support.
  **
  Void authenticate()
  {
    if (auths.contains("CRAM-MD5")) { authCramMd5; return }
    if (auths.contains("LOGIN"))    { authLogin;   return }
    if (auths.contains("PLAIN"))    { authPlain;   return }
    throw Err("No AUTH mechanism available: $auths")
  }

  **
  ** Authenticate using CRAM-MD5 mechanism.
  **
  Void authCramMd5()
  {
    // submit auth request which returns nonce
    writeReq("AUTH CRAM-MD5")
    res := readRes
    if (res.code != 334) throw SmtpErr.makeRes(res)
    nonce := Buf.fromBase64(res.line.trim).readAllStr

    // digest = MD5((password XOR opad), MD5((password XOR ipad), nonce))
    // ipad = the byte 0x36 repeated B times
    // opad = the byte 0x5C repeated B times.
    // B = 64
    ipad := xorPad(password, 0x36, 64)
    opad := xorPad(password, 0x5C, 64)
    digest := Buf.make
      .writeBuf(opad)
      .writeBuf(Buf.make.writeBuf(ipad).print(nonce).toDigest("MD5"))
      .toDigest("MD5")
    cred := "$username $digest.toHex.lower"

    // submit username space digest
    writeReq(Buf.make.print(cred).toBase64)
    res = readRes
    if (res.code != 235) throw SmtpErr.makeRes(res)
  }

  private Buf xorPad(Str text, Int pad, Int blockSize)
  {
    buf := Buf.make.print(text)
    if (buf.size > blockSize) throw Err("CRAM-MD5 password too big")
    while (buf.size < blockSize) buf.write(0)
    blockSize.times |Int i| { buf[i] = buf[i] ^ pad }
    buf.seek(0)
    return buf
  }

  **
  ** Authenticate using LOGIN mechanism.
  **
  Void authLogin()
  {
    // auth
    writeReq("AUTH LOGIN")
    res := readRes
    if (res.code != 334 || res.line != "VXNlcm5hbWU6") throw SmtpErr.makeRes(res)

    // username
    writeReq(Buf.make.print(username).toBase64)
    res = readRes
    if (res.code != 334 || res.line != "UGFzc3dvcmQ6") throw SmtpErr.makeRes(res)

    // password
    writeReq(Buf.make.print(password).toBase64)
    res = readRes
    if (res.code != 235) throw SmtpErr.makeRes(res)
  }

  **
  ** Authenticate using PLAIN mechanism.
  **
  Void authPlain()
  {
    // not tested against real SMTP server
    creds := Buf.make.write(0).print(username).write(0).print(password)
    writeReq("AUTH PLAIN $creds.toBase64")
    res := readRes
    if (res.code != 235) throw SmtpErr.makeRes(res)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Log for tracing
  Log log := Log.get("smtp")

  private TcpSocket? sock  // Socket if open or null if closed
  private Str[]? auths     // SASL auth mechanisms supported by server
}

**************************************************************************
** SmtpRes
**************************************************************************

internal class SmtpRes
{
  Void dump(OutStream out := Sys.out)
  {
    lines.each |Str line, Int i|
    {
      sep := i < lines.size-1 ? "-" : " "
      out.print(code).print(sep).printLine(line)
    }
  }

  override Str toStr() { return "$code $lines.last" }

  Str line() { return lines.last }

  Int code
  Str[] lines := Str[,]
}