using web
using webapp
using testWeb

class Chrome : Widget
{

  override Void onGet()
  {
    // nav
    body.p("style='background: #eee; border:1px solid #ccc; padding: 10px'")
    body.a(`/`).w("Home").aEnd
    body.w(" | ")
    body.a(`/examples/mounting`).w("Mounting").aEnd
    /*
    body.w(" | ")
    body.a(`/examples/flash`).w("Flash").aEnd
    body.w(" | ")
    body.a(`/examples/actions`).w("Actions").aEnd
    body.w(" | ")
    body.a(`/examples/serialization`).w("Serialization").aEnd
    */
    body.pEnd

    // view
    body.div("style='padding: 0 20px 20px 20px'")
    req.stash["webapp.chromeView"]->onGet
    body.divEnd

    /*
    // Test root widget actions
    head.w(
     "<script type='text/javascript'>
      function chromeTest(uri)
      {
        var xhr = window.ActiveXObject
          ? new ActiveXObject(\"Microsoft.XMLHTTP\") : new XMLHttpRequest();
        xhr.open(\"POST\", uri, false);
        xhr.send(null);
        alert(xhr.responseText);
      }
      </script>")
    uri := toInvoke(&onAction)
    body.div("style='border-top: 1px solid #ccc; padding: 1em'")
    body.a(`#`, "onclick='chromeTest(\"$uri\"); return false;'").w("Chrome Action").aEnd
    body.divEnd
    */
  }

  override Void onPost()
  {
    req.stash["webapp.chromeView"]->onPost
  }

  //Void onAction() { echo("Chrome Action!"); body.w("Chrome Action!") }

}