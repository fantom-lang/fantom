using web
using webapp
using testWeb

class Index : Widget
{

  override Void onGet()
  {
    head.title.w("Fantom Web Demo").titleEnd
    body.h1.w("Fantom Web Demo").h1End
    body.ul
    body.li.a(`dir/test.html`).w("Straight up HTML page").aEnd.liEnd
    body.li.a(`dir/weblet.fan`).w("Weblet script example").aEnd.liEnd
    body.li.a(`dir/widget.fan`).w("Widget script example").aEnd.liEnd
    body.ulEnd
  }

}