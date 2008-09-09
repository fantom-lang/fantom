using web
using webapp
using testWeb

class FlashTest : Widget
{

  new make()
  {
    add(Flash { label="Red";    text="This should be red!";    bg="#f88" })
    add(Flash { label="Yellow"; text="This should be yellow!"; bg="#ff8" })
    add(Flash { label="Green";  text="This should be green!";  bg="#8f8" })
  }

  override Void onGet()
  {
    head.title("Flash")
    body.h1("Flash")
    children.each |Widget w| { w.onGet }
    body.hr
    body.p
    body.button("value='Refresh' onclick='window.location.reload(true);'")
    body.pEnd
  }

}
