#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 08  Brian Frank  Creation
//   08 Sep 09  Brian Frank  Rework fandoc -> example
//

using web

**
** Working with WebClient
**
class Client
{

  Void main()
  {
    gets
    pipelining
    // need to have a server which accepts posts for this test
    // posts
  }

  Void gets()
  {
    // simple string get
    echo("\n--- getStr ---")
    str := WebClient(`http://fantom.org/`).getStr
    echo(str.in.readLine + "...")

    // simple binary get
    echo("\n--- getBuf ---")
    buf := WebClient(`http://fantom.org/`).getBuf
    echo(buf.readLine + "...")

    // get as input stream
    echo("\n--- getIn ---")
    c := WebClient(`http://fantom.org/doc/`)
    try
    {
      in := c.getIn
      echo("getIn:  " + in.readLine)
    }
    finally c.close

    // dump get response headers and string body
    echo("\n--- response headers ---")
    c = WebClient(`http://google.com/`).writeReq.readRes
    echo("$c.reqUri => $c.resCode $c.resPhrase")
    echo(c.resHeaders.join("\n"))
    echo(c.resStr[0..30] + "...")
    c.close
  }

  Void posts()
  {
    // post form
    c := WebClient(`http://foo/post.cgi`)
    c.postForm(["firstName":"Bob", "lastName":"Smith"])
    echo(c.resStr) // process response
    c.close

    // post content with fixed length
    c = WebClient(`http://foo/post.cgi`)
    c.reqMethod = "POST"
    c.reqHeaders["Content-Type"] = "text/plain; charset=utf-8"
    c.reqHeaders["Content-Length"] = "5"
    c.writeReq
    c.reqOut.print("hello").close
    c.readRes
    echo(c.resStr) // process response
    c.close
  }

  Void pipelining()
  {
    echo("\n--- pipelining ---")
    // pipelining: write 2 requests, then read 2 responses
    c := WebClient()
    c.reqUri = `http://fantom.org/`
    c.writeReq
    c.reqUri = `http://fantom.org/doc/`
    c.writeReq
    c.readRes
    echo(c.resStr[0..30] + "...") // process path1 response
    c.readRes
    echo(c.resStr[0..30] + "...") // process path2 response
  }

}




