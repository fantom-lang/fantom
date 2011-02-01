#! /usr/bin/env fan

using gfx
using fwt

**
** Display a label which updates every second using Desktop.callLater
**
class Timer : Window
{

  new make() : super(null, null)
  {
    content = label
    //onActive works only on java side
    onActive.add |->| { timer() }
  }

  Void main()
  {
    open()
    //this works only for JS, while in java open method is blocked
    timer()
  }

  private |->| timer := |->|
  {
    count++
    label.text = "$count"
    content.repaint
    Desktop.callLater(1sec, timer)
  }

  private Label label := Label { text = "0"; halign = Halign.center }
  private Int count := 0
}