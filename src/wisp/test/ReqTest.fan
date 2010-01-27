//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 07  Brian Frank  Creation
//

using inet

**
** ReqTest
**
class ReqTest : Test
{

  Void testBasic()
  {
    verifyReq(
      "GET / HTTP/1.0\r\n" +
      "Host: foobar\r\n" +
      "Extra1:  space\r\n" +
      "Extra2: space  \r\n" +
      "Cont: one two \r\n" +
      "  three\r\n" +
      "\tfour\r\n" +
      "Coalesce: a,b\r\n" +
      "Coalesce: c\r\n" +
      "Coalesce:  d\r\n" +
      "\r\n",

      "GET", `/`,
      [
        "Host":     "foobar",
        "Extra1":   "space",
        "Extra2":   "space",
        "Cont":     "one two three four",
        "Coalesce": "a,b,c,d",
      ])
  }

  Void verifyReq(Str s, Str method, Uri uri, Str:Str headers)
  {
  /*
    req := WispReq.makeTest(s.in)
    WispThread.parseReq(req)
    verifyEq(req.method,  method)
    verifyEq(req.uri,     uri)
    verifyEq(req.headers, headers)
    // echo(req.headers)
  */
  }

  static Void main(Str[] args := Env.cur.args)
  {
    uri := args.first.toUri
    socket := TcpSocket.make
    socket.connect(IpAddr(uri.host), uri.port)
    socket.out.print("GET $uri.pathStr HTTP/1.1\r\n")
    socket.out.print("Host: $uri.host\r\n")
    socket.out.print("\r\n")
    socket.out.flush
    while (true)
    {
      line := socket.in.readLine
      if (line.isEmpty) break
      echo(line)
    }
    socket.close
  }

}