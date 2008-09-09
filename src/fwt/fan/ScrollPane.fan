//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jul 08  Brian Frank  Creation
//

**
** ScrollPane displays a scrollbars to scroll its content child.
**
class ScrollPane : ContentPane
{
  // TODO: I haven't quite figured out how the ScrollComposite
  // pane works, but I don't think it works like how I want FWT
  // to work.  The way it should work is that the scrollpane
  // sets its scrolling based on prefSize of content.  The way
  // SWT works is that I have to explictly set the size (which
  // seems weird)

  // to force native peer
  private native Void dummyScrollPane()

}