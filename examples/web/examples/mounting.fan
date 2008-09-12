using web
using webapp
using testWeb

class Mounting : Widget
{

  override Void onGet()
  {
    head.title("Demo Index")
    body.h1("Mounting directories into Namespace")

    body.h2("FindResourceStep Directory")
    body.ul
    body.li.a(`../dir`).w("/dir").aEnd.liEnd
    body.li.a(`../dir/`).w("/dir/").aEnd.liEnd
    body.li.a(`../dir/index`).w("/dir/index").aEnd.liEnd
    body.li.a(`../dir/index.html`).w("/dir/index.html").aEnd.liEnd
    body.ulEnd

    body.h2("Mounting a tree of HTML")

    body.ul
    body.li.a(`/doc`).w("/doc").aEnd.liEnd
    body.li.a(`/doc/docIntro`).w("/doc/docIntro").aEnd.liEnd
    body.li.a(`/doc/docIntro/`).w("/doc/docIntro/").aEnd.liEnd
    body.li.a(`/doc/docIntro/index`).w("/doc/docIntro/index").aEnd.liEnd
    body.li.a(`/doc/docIntro/index.html`).w("/doc/docIntro/index.html").aEnd.liEnd
    body.ulEnd
  }

}
