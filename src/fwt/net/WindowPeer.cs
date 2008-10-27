//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 08  Andy Frank  Creation
//

using Fan.Sys;
using System.Windows.Forms;

namespace Fan.Fwt
{
  public class WindowPeer : WidgetPeer
  {

    public override Control create(Control parent)
    {
      // window uses open, not normal attach process
      throw new System.InvalidOperationException();
    }

    public override void sync(string id)
    {
      Window self = (Window)this.m_self;
      Form form = (Form)this.m_control;
      if (id == null || id == Window.m_titleId) form.Text = self.title().val;
    }

    public override object send(string id)
    {
      if (id == Window.m_openId) { open(); return null; }
      if (id == Window.m_closeId) { close(); return null; }
      return base.send(id);
    }

  //////////////////////////////////////////////////////////////////////////
  // Window
  //////////////////////////////////////////////////////////////////////////

  // TODO

    public void open()
    {
      if (m_control != null) return;

      Form form = new Form();
      attachTo(form);
      m_control.Controls[0].Location = new System.Drawing.Point(0, 0);
      m_control.Controls[0].Size = m_control.ClientSize;
      Application.Run(form);
    }

    public void close()
    {
      if (m_control == null) return;
      Application.Exit();
      detach(m_self);
    }

  }
}
