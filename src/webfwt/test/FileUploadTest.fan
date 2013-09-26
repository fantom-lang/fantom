//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 2011  Andy Frank  Creation
//

using fwt
using gfx
using web

**
** FileUploadTest
**
@Js
internal class FileUploadTest : ContentPane
{
  new make()
  {
    content = InsetPane(24)
    {
      GridPane
      {
        vgap = 24
        GridPane { numCols=2; hgap=24; makeDef, makeDlg },
        makeReset,
        makeMulti,
        makeMultiPart,
      },
    }
  }

  private Widget makeDef()
  {
    BorderPane
    {
      bg = Color("#eee")
      insets = Insets(6)
      GridPane
      {
        f := FileUploader
        {
          uri = `/upload`
          onComplete.add |e| { echo("# $e.data") }
        };
        Label { text="Def" }, f, buttons(f),
      },
    }
  }

  private Widget makeDlg()
  {
    GridPane
    {
      numCols = 3
      Button
      {
        text = "Dialog : Def"
        onAction.add
        {
          FileUploader.dialog(this.window, FileUploader
          {
            uri = `/upload`
            onComplete.add |e| { echo("# $e.data") }
          }).open
        }
      },
      Button
      {
        text = "Dialog : Multi"
        onAction.add
        {
          FileUploader.dialog(this.window, FileUploader
          {
            uri = `/upload`
            multi = true
            onComplete.add |e| { echo("# $e.data") }
          }).open
        }
      },
      Button
      {
        text = "Dialog : Headers"
        onAction.add
        {
          FileUploader.dialog(this.window, FileUploader
          {
            uri = `/upload`
            headers = ["Test-Header-A": "foo", "Test-Header-B": "bar", "Content-Type": "foo/bar"]
            onComplete.add |e| { echo("# $e.data") }
          }).open
        }
      },
    }
  }

  private Widget makeReset()
  {
    BorderPane
    {
      bg = Color("#eee")
      insets = Insets(6)
      GridPane
      {
        f := FileUploader
        {
          uri = `/upload`
          onComplete.add |e|
          {
            try {
            Dialog(window)
            {
              it.title = ""
              it.body  = Label { text="Done!" }
              it.commands = [Dialog.ok]
              it.onClose.add { e.widget->reset }
            }.open
            }
            catch (Err x) { x.trace }
          }
        };
        Label { text="Reset" }, f, buttons(f),
      },
    }
  }

  private Widget makeMulti()
  {
    BorderPane
    {
      bg = Color("#eee")
      insets = Insets(6)
       GridPane
       {
        f := FileUploader
        {
          uri = `/upload`
          multi = true
          onComplete.add |e| { echo("# $e.data") }
        }
        Label { text="Multi" }, f, buttons(f),
      },
    }
  }

  private Widget makeMultiPart()
  {
    BorderPane
    {
      bg = Color("#eee")
      insets = Insets(6)
      GridPane
      {
        f := FileUploader
        {
          uri = `/upload`
          useMultiPart = true
          onComplete.add |e| { echo("# $e.data") }
        };
        Label { text="Form Multi-Part" }, f, buttons(f),
      },
    }
  }

  private Widget buttons(FileUploader f)
  {
    InsetPane(0,0,0,270)
    {
      GridPane
      {
        halignPane = Halign.right
        numCols = 2
        Button { text="Upload"; onAction.add { f.upload }},
        Button { text="Reset";  onAction.add { f.reset }},
      },
    }
  }
}