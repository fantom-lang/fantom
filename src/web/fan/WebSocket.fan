//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 15  Brian Frank  Creation
//

using concurrent
using inet

**
** WebSocket is used for both client and server web socket messaging.
** Current implementation only supports basic non-fragmented text or
** binary messages.
**
class WebSocket
{

  **
  ** Open a client connection.  The URI must have a "ws" or "wss" scheme.
  ** The 'headers' parameter defines additional HTTP headers to include
  ** in the connection request.
  **
  static WebSocket openClient(Uri uri, [Str:Str]? headers := null)
  {
    // check scheme
    scheme := uri.scheme
    if (scheme != "ws" && scheme != "wss") throw ArgErr("Unsupported scheme: $scheme")

    // send handshake request
    httpUri := ("http" + uri.toStr[2..-1]).toUri
    key := Buf.random(16).toBase64
    c := WebClient(httpUri)
    c.reqMethod = "GET"
    c.reqHeaders["Upgrade"] = "websocket"
    c.reqHeaders["Connection"] = "Upgrade"
    c.reqHeaders["Sec-WebSocket-Key"] = key
    c.reqHeaders["Sec-WebSocket-Version"] = "13"
    if (headers != null) c.reqHeaders.addAll(headers)
    c.writeReq

    // read handshake response
    c.readRes
    if (c.resCode != 101) throw err("Bad HTTP response $c.resCode $c.resPhrase")
    checkHeader(c.resHeaders, "Upgrade", "websocket")
    checkHeader(c.resHeaders, "Connection", "upgrade")
    digest := checkHeader(c.resHeaders, "Sec-WebSocket-Accept", null)
    if (secDigest(key) != digest) throw err("Mismatch Sec-WebSocket-Accept")

    // we are connected!
    return make(c.socket, true)
  }

  **
  ** Upgrade a server request to a WebSocket.  Raise IOErr is there is any
  ** problems during the handshake in which case the calling WebMod should
  ** return a 400 response.
  **
  ** Note: once this method completes, the socket is now owned by the
  ** WebSocket instance and not the web server (wisp); it must be explicitly
  ** closed to prevent a file handle leak.
  **
  static WebSocket openServer(WebReq req, WebRes res)
  {
    // validate request
    if (req.method != "GET") throw err("Invalid method")
    checkHeader(req.headers, "Upgrade", "websocket")
    checkHeader(req.headers, "Connection", "upgrade")
    key := checkHeader(req.headers, "Sec-WebSocket-Key", null)

    // send upgrade response
    res.headers["Upgrade"] = "websocket"
    res.headers["Connection"] = "Upgrade"
    res.headers["Sec-WebSocket-Accept"] = secDigest(key)

    // take ownership of the underlying socket
    socket := res.upgrade(101)

    // connected, return WebSocket
    return make(socket, false)
  }

  private static Str checkHeader(Str:Str headers, Str name, Str? expected)
  {
    val := headers[name] ?: throw err("Missing $name header")
    if (expected != null && val.indexIgnoreCase(expected) == null)
      throw err("Invalid $name header: $val")
    return val
  }

  **
  ** Private constructor
  **
  private new make(TcpSocket socket, Bool maskOnSend)
  {
    this.socket = socket
    this.maskOnSend = maskOnSend
  }

  **
  ** Access to socket options for this request.
  **
  @Deprecated { msg = "Socket should be configured using SocketConfig" }
  SocketOptions socketOptions() { socket.options }

  **
  ** Return true if this socket has been closed
  **
  Bool isClosed() { closed }

  **
  ** Receive a message which is returned as either a Str or Buf.
  ** Raise IOErr if socket has error or is closed.
  **
  Obj? receive()
  {
    receiveBuf(null)
  }

  **
  ** Receive Buf message into given buffer.
  ** Raise IOErr if socket has error or is closed.
  **
  @NoDoc Obj? receiveBuf(Buf? buf)
  {
    while (true)
    {
      msg := doReceive(buf)
      if (msg === receiveAgain) continue
      return msg
    }
    throw Err()
  }

  private Obj? doReceive(Buf? payload)
  {
    // check if we have a frame or at end of stream
    in := socket.in
    firstByte := in.readU1

    // first byte indicates final frag, and opcode
    byte := firstByte
    fin := byte.and(0x80) > 0
    op := byte.and(0x0f)

    // second byte is mask, and length
    byte = in.readU1
    masked := byte.and(0x80) > 0
    len := byte.and(0x7F)

    // if len is 126 or 127, it len is next 2 or 8 bytes
    if (len == 126) len = in.readU2
    else if (len == 127) len = in.readS8

    // if payload is masked, get 32-bit masking key
    maskKey := masked ? in.readBufFully(null, 4) : null

    // read payload data
    payload = in.readBufFully(payload, len)

    // read fragmented message (not done yet!)
    if (!fin) throw Err("Fragmentation not supported yet!")

    // if masked, then unmask it
    if (masked)
      for (i := 0; i<len; ++i)
        payload[i] = payload[i].xor(maskKey[i.mod(4)])

    // handle control messages and receive again,
    // otherwise return the payload data
    switch (op)
    {
      case opClose:  close; throw IOErr("WebSocket closed")
      case opPing:   pong(payload); return receiveAgain
      case opPong:   return receiveAgain
      case opText:   return payload.readAllStr
      case opBinary: return payload
    }
    throw Err("Unsuppored opcode: $op")
  }

  **
  ** Send a message which must be either a Str of Buf.  Bufs are
  ** sent using their full contents irrelevant of their current position.
  **
  Void send(Obj msg)
  {
    // turn msg into payload Buf
    binary := msg is Buf
    op  := binary ? opBinary : opText
    payload := binary ? (Buf)msg : Buf().print((Str)msg)

    // route to common send implementation
    doSend(op, payload)
  }

  **
  ** Send a ping message
  **
  @NoDoc Void ping()
  {
    doSend(opPing, Buf().print("ping $Int.random.toHex"))
  }

  **
  ** Send a pong message
  **
  private Void pong(Buf echo)
  {
    doSend(opPong, echo)
  }

  private Void doSend(Int op, Buf payload)
  {
    // check closed flag
    if (closed) throw IOErr("WebSocket closed")

    // compute intermediate variables
    len := payload.size
    maskKey := Buf.random(4)
    out  := socket.out

    // finish + opcode byte
    out.write(0x80.or(op))

    // masked bit + len
    mask := maskOnSend ? 0x80 : 0x0
    if (len < 126)
      out.write(mask.or(len))
    else if (len < 0xffff)
      out.write(mask.or(126)).writeI2(len)
    else
      out.write(mask.or(127)).writeI8(len)

    if (maskOnSend)
    {
      // masked payload
      out.writeBuf(maskKey)
      for (i := 0; i<len; ++i)
        out.write(payload[i].xor(maskKey[i.mod(4)]))
    }
    else
    {
      // unmasked payload
      if (!payload.isImmutable) payload.seek(0)
      out.writeBuf(payload)
    }

    out.flush
  }

  **
  ** Close the web socket
  **
  Bool close()
  {
    if (closed) return false
    try
      doSend(opClose, Buf())
    catch (Err e)
      {}
    this.closed = true
    return socket.close
  }

  private static Err err(Str msg)
  {
    IOErr(msg)
  }

  private static Str secDigest(Str key)
  {
    Buf().print(key).print("258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toDigest("SHA-1").toBase64
  }

  private static const Int opContinue := 0x0
  private static const Int opText     := 0x1
  private static const Int opBinary   := 0x2
  private static const Int opClose    := 0x8
  private static const Int opPing     := 0x9
  private static const Int opPong     := 0xA

  private static const List receiveAgain := [ "receiveAgain" ]

  private TcpSocket socket
  private Bool maskOnSend
  private Bool closed
}

