using web
using webapp
using testWeb

class Chrome : Widget
{

  new make()
  {
    tabs = TabPane
    {
      addTab(`/`, "Home")
      addTab(`/examples/mounting`, "Mounting")
      addTab(`/examples/flash`, "Flash")
      addTab(`/examples/actions`, "Actions")
      addTab(`/examples/serialization`, "Serialization")
    }
    add(view = req.stash["webapp.view"])
  }

  override Void onGet()
  {
    tabs.onGet
    body.div("style='padding: 0 20px 20px 20px'")
    view.onGet
    body.divEnd

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
  }

  override Void onPost() { view.onPost }

  Void onAction() { echo("Chrome Action!"); body.w("Chrome Action!") }

  TabPane tabs
  Widget view

}