//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Sep 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;

public class DialogPeer extends WindowPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static DialogPeer make(fan.fwt.Dialog self)
    throws Exception
  {
    DialogPeer peer = new DialogPeer();
    ((fan.fwt.Window)self).peer = peer;
    ((fan.fwt.Pane)self).peer = peer;
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

//////////////////////////////////////////////////////////////////////////
// MessageBox
//////////////////////////////////////////////////////////////////////////

  public static Obj openInfo(Window parent, Str msg, List commands)
  {
    return openMsgBox(parent, msg, commands, SWT.ICON_INFORMATION);
  }

  public static Obj openWarn(Window parent, Str msg, List commands)
  {
    return openMsgBox(parent, msg, commands, SWT.ICON_WARNING);
  }

  public static Obj openErr(Window parent, Str msg, List commands)
  {
    return openMsgBox(parent, msg, commands, SWT.ICON_ERROR);
  }

  public static Obj openQuestion(Window parent, Str msg, List commands)
  {
    return openMsgBox(parent, msg, commands, SWT.ICON_QUESTION);
  }

  public static Obj openMsgBox(Window parent, Str msg, List commands, int style)
  {
    // map commands to SWT style
    int[] swtCommands = new int[commands.sz()];
    for (int i=0; i<commands.sz(); ++i)
    {
      try
      {
        DialogCommand cmd = (DialogCommand)commands.get(i);
        swtCommands[i] = style(cmd.id);
        style |= swtCommands[i];
      }
      catch (ClassCastException e)
      {
        throw ArgErr.make("Commands not from predefined set").val;
      }
    }

    Shell parentShell = (Shell)parent.peer.control;
    MessageBox mb = new MessageBox(parentShell, style);
    mb.setMessage(msg.val);
    int result = mb.open();

    // map swt result id back to command
    for (int i=0; i<swtCommands.length; ++i)
      if (swtCommands[i] == result) return commands.get(i);
    return null;
  }

  static int style(DialogCommandId id)
  {
    if (id == DialogCommandId.ok)     return SWT.OK;
    if (id == DialogCommandId.cancel) return SWT.CANCEL;
    if (id == DialogCommandId.yes)    return SWT.YES;
    if (id == DialogCommandId.no)     return SWT.NO;
    throw new IllegalStateException();
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  int defaultStyle() { return SWT.CLOSE | SWT.TITLE; }

}