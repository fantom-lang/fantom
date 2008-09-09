using web

class TestWeblet : Weblet
{
  override Void onGet()
  {
   s := req.session
    res.cookies.add(Cookie { name="foo"; value="alpha" })
    res.cookies.add(Cookie { name="bar"; value="beta" })
    if (s["testcounter"] == 10) s.delete

    res.statusCode = 200
    res.headers["Content-Type"] = "text/html"
    res.out.printLine("<pre>")
    res.out.printLine("uri:       $req.uri")
    res.out.printLine("absUri:    $req.absUri")
    res.out.printLine("version:   $req.version")
    res.out.printLine("method:    $req.method")
    res.out.printLine("stash:     $req.stash")
    res.out.printLine("userAgent: $req.userAgent")
    res.out.printLine("cookies:   $req.cookies")
    res.out.printLine("headers:")
    req.headers.each |Str v, Str k| { res.out.printLine("  $k: $v") }
    res.out.printLine("session:   $req.session.id")
    req.session.map.each |Obj v, Str k| { res.out.printLine("  $k: $v") }
    res.out.printLine("</pre>")
    res.out.printLine("Back up to <a href='/dir/index.html'>/dir/index.html</a>.</p>")

    s["testcounter"] = (Int)s.map.get("testcounter", 0) + 1

    s["foobar"] = "hi there"
  }
}
