using web
using webapp

class TestWidget: Widget
{
  override Void onGet()
  {
    head.title.w("Title It Up!").titleEnd
    body.h1.w("Does this thing work?").h1End

    body.table("border='1' cellpadding='5'")
    body.tr.td.w("uri").tdEnd.td.w(req.uri).tdEnd.trEnd
    body.tr.td.w("type").tdEnd.td.w(type.qname).tdEnd.trEnd
    body.tableEnd

    body.form("method='post' action='${call(#onFoo).encode.toXml}'")
    body.p
    body.submit
    body.pEnd
    body.formEnd
    body.p.w("Back up to").a(`/dir/index.html`).w("/dir/index.html").aEnd.w(".").pEnd
  }

  Void onFoo()
  {
    echo("TestWidget.onFoo uri=$req.uri")
    res.redirect(`/dir/widget.fan`)
  }

}