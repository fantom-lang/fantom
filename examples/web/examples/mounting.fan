using web
using webapp
using testWeb

class Mounting : Widget
{

  override Void onGet()
  {
    head.title.w("Demo Index").titleEnd
    body.h1.w("Mounting directories into Namespace").h1End

    body.h2.w("FindResourceStep Directory").h2End
    body.ul
    body.li.a(`../dir`).w("/dir").aEnd.liEnd
    body.li.a(`../dir/`).w("/dir/").aEnd.liEnd
    body.li.a(`../dir/index`).w("/dir/index").aEnd.liEnd
    body.li.a(`../dir/index.html`).w("/dir/index.html").aEnd.liEnd
    body.ulEnd

    body.h2.w("Mounting a tree of HTML").h2End

    body.ul
    body.li.a(`/doc`).w("/doc").aEnd.liEnd
    body.li.a(`/doc/docIntro`).w("/doc/docIntro").aEnd.liEnd
    body.li.a(`/doc/docIntro/`).w("/doc/docIntro/").aEnd.liEnd
    body.li.a(`/doc/docIntro/index`).w("/doc/docIntro/index").aEnd.liEnd
    body.li.a(`/doc/docIntro/index.html`).w("/doc/docIntro/index.html").aEnd.liEnd
    body.ulEnd
  }

}