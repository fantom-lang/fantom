using web

const class DumpMod : WebMod
{
  override Void onGet()
  {
    s := req.session
    res.cookies.add(Cookie("foo", "a,b,c"))
    res.cookies.add(Cookie("bar", "some \"quoted\" text!"))
    res.cookies.add(Cookie("baz", "xy;zfoo;".toBuf.toBase64))
    if (s["testcounter"] == 10) s.delete

    res.statusCode = 200
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    res.out.printLine("<a href='/'>Index</a> |")
    res.out.printLine("<a href='/dump'>/dump</a> |")
    res.out.printLine("<a href='/dump/'>/dump/</a> |")
    res.out.printLine("<a href='/dump/a'>/dump/a</a> |")
    res.out.printLine("<a href='/dump/a/b'>/dump/a/b</a> |")
    res.out.printLine("<pre>")
    res.out.printLine("remoteAddr: $req.remoteAddr:$req.remotePort")
    res.out.printLine("uri:        $req.uri")
    res.out.printLine("absUri:     $req.absUri")
    res.out.printLine("mod:        $req.mod")
    res.out.printLine("modBase:    $req.modBase")
    res.out.printLine("modRel:     $req.modRel")
    res.out.printLine("version:    $req.version")
    res.out.printLine("method:     $req.method")
    res.out.printLine("stash:      $req.stash")
    res.out.printLine("cookies:    $req.cookies")
    res.out.printLine("  foo:      " + req.cookies["foo"])
    res.out.printLine("  bar:      " + req.cookies["bar"])
    res.out.printLine("  baz:      " + Buf.fromBase64(req.cookies.get("baz", "")).readAllStr)
    res.out.printLine("headers:")
    req.headers.each |Str v, Str k| { res.out.printLine("  $k: $v") }
    res.out.printLine("session:    $req.session.id")
    req.session.map.each |Obj? v, Str k| { res.out.printLine("  $k: $v") }
    res.out.printLine("</pre>")

    s["testcounter"] = (Int)s.map.get("testcounter", 0) + 1
    s["foobar"] = "hi there"
  }
}