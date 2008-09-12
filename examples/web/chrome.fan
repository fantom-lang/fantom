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
  }

  override Void onPost()
  {
    view.onPost
  }

  TabPane tabs
  Widget view

}
