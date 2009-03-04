using web
using webapp
using testWeb

class Index : Widget
{

  override Void onGet()
  {
    head.title.w("Fan Web Demo").titleEnd
    body.h1.w("Fan Web Demo").h1End
  }

}