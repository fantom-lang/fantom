using web
using webapp
using testWeb

class Actions : Widget
{

  override Void onGet()
  {
    head.title("Actions")
    head.w(
     "<script type='text/javascript'>
      function test(func)
      {
        var xhr = window.ActiveXObject
          ? new ActiveXObject(\"Microsoft.XMLHTTP\") : new XMLHttpRequest();
        xhr.open(\"POST\", window.location + \"?invoke=/w0/\" + func, false);
        xhr.send(null);
        alert(xhr.responseText);
      }
      </script>")
    body.h1("Actions")
    body.p.a(`#`, "onclick='test(\"onAlpha\"); return false;'").w("Alpha").aEnd.pEnd
    body.p.a(`#`, "onclick='test(\"onBeta\");  return false;'").w("Beta").aEnd.pEnd
    body.p.a(`#`, "onclick='test(\"onGamma\"); return false;'").w("Gamma").aEnd.pEnd
  }

  Void onAlpha() { echo("Alpha!"); body.w("Alpha!") }
  Void onBeta()  { echo("Beta!");  body.w("Beta!")  }
  Void onGamma() { echo("Gamma!"); body.w("Gamma!") }

}
