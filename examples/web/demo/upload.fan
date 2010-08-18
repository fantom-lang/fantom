using web

const class UploadMod : WebMod
{
  override Void onGet()
  {
    res.statusCode = 200
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.html.body
    out.w("<a href='/'>Index</a>").hr
    out.form("method='post' action='$req.uri.pathStr' enctype='multipart/form-data'")
    out.p.w("Chooose files to upload:").pEnd
    out.p.w("Upload File 1: ").input("type='file' name='file1'").br
    out.p.w("Upload File 2: ").input("type='file' name='file2'").br
    out.p.w("Upload File 3: ").input("type='file' name='file3'").br
    out.submit("value='Upload!'")
    out.formEnd
    out.bodyEnd.htmlEnd
  }

  override Void onPost()
  {
    // dump headers
    echo("###### UploadMod.onPost ######")
    req.headers.each |v, n| { echo("$n: $v") }
    echo("")

    // get boundary string
    mime := MimeType(req.headers["Content-Type"])
    boundary := mime.params["boundary"] ?: throw IOErr("Missing boundary param: $mime")

    // process each multi-part
    WebUtil.parseMultiPart(req.in, boundary) |headers, in|
    {
      // pick one of these (but not both!)
      //echoPart(headers, in)
      savePartToFile(headers, in)
    }

    // redisplay the html form to post again
    onGet
  }

  Void echoPart(Str:Str headers, InStream in)
  {
    echo("==========================")
    headers.each |v, n| { echo("$n: $v") }
    mime := MimeType(headers["Content-Type"] ?: "text/plain")
    echo("")
    if (mime.mediaType == "text")
      echo(in.readAllStr)
    else
      echo(in.readAllBuf.toBase64)
  }

  Void savePartToFile(Str:Str headers, InStream in)
  {
    disHeader := headers["Content-Disposition"]
    Str? name := null
    if (disHeader != null) name = MimeType.parseParams(disHeader)["filename"]
    if (name == null || name.size < 3)
    {
      echo("SKIP $disHeader")
      in.readAllBuf  // drain stream
      return
    }
    f := `./$name`.toFile.normalize
    echo("## savePart: $f")
    out := f.out
    try
      in.pipe(out)
    finally
      out.close
  }
}