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
      function test(uri)
      {
        var xhr = window.ActiveXObject
          ? new ActiveXObject(\"Microsoft.XMLHTTP\") : new XMLHttpRequest();
        xhr.open(\"POST\", uri, false);
        xhr.send(null);
        alert(xhr.responseText);
      }
      </script>")

    uriAlpha := toInvoke(&onAlpha)
    uriBeta  := toInvoke(&onBeta)
    uriGamma := toInvoke("onGamma")

    body.h1("Actions")
    body.p.a(`#`, "onclick='test(\"$uriAlpha\"); return false;'").w("Alpha").aEnd.pEnd
    body.p.a(`#`, "onclick='test(\"$uriBeta\");  return false;'").w("Beta").aEnd.pEnd
    body.p.a(`#`, "onclick='test(\"$uriGamma\"); return false;'").w("Gamma").aEnd.pEnd
  }

  Void onAlpha() { echo("Alpha!"); body.w("Alpha!") }
  Void onBeta()  { echo("Beta!");  body.w("Beta!")  }
  Void onGamma() { echo("Gamma!"); body.w("Gamma!") }

}