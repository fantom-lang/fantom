using web
using webapp
using testWeb

class SerializationTest : Widget
{
  new make()
  {
    try
    {
      s := req.session["serial"] ?: serial
      add(content = InStream.makeForStr(s).readObj)
      serial = s
    }
    catch (Err e)
    {
      e.trace
      add(content = InStream.makeForStr(serial).readObj)
    }
    finally req.session["serial"] = null
  }

  override Void onGet()
  {
    head.title("Serialization")
    body.h1("Serialization")
    body.table("width='100%'")
    body.tr

    body.td("style='width: 60%; border-right: 1px solid #ccc;'")
    body.form("method='post' action='$req.uri'")
    body.p.textArea("name='serial' style='font: 9pt Monaco, \"Courier New\"' " +
      "cols='70' rows='20'").w(serial).textAreaEnd.pEnd
    body.p.submit("value='Serialize ->'").pEnd
    body.formEnd
    body.tdEnd

    body.td
    content.onGet
    body.tdEnd

    body.trEnd
    body.tableEnd
  }

  override Void onPost()
  {
    req.session["serial"] = req.form["serial"]
    res.redirect(req.uri)
  }

  Widget content
  Str serial :=
   "testWeb::GridPane
    {
      testWeb::Box { text=\"alpha\"; bg=\"#fcc\" }
      testWeb::Box { text=\"beta\";  bg=\"#cfc\" }
      testWeb::Box { text=\"gamma\"; bg=\"#ccf\" }
    }"

}
