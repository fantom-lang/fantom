using web
using webapp
using testWeb

class Index : Widget
{

  override Void onGet()
  {
    head.title("Fan Web Demo")
    body.h1("Fan Web Demo")
  }

}
