//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 08  Andy Frank  Creation
//

using Fan.Sys;
using System.Drawing;
using System.Windows.Forms;

namespace Fan.Fwt
{
  public class LabelPeer : WidgetPeer
  {
    public override Control create(Control parent)
    {
      Control c = new System.Windows.Forms.Label();
      parent.Controls.Add(c);
      return c;
    }

    public override void sync(string f)
    {
      Fan.Fwt.Label self = (Fan.Fwt.Label)this.m_self;
      System.Windows.Forms.Label c = (System.Windows.Forms.Label)this.m_control;

      if (f == null || f == Fan.Fwt.Label.m_textId) c.Text = self.text().val;
      if (f == null || f == Fan.Fwt.Label.m_halignId) c.TextAlign = halign(self.halign());
    }

    ContentAlignment halign(Halign f)
    {
      if (f == Halign.m_left)   return ContentAlignment.MiddleLeft;
      if (f == Halign.m_center) return ContentAlignment.MiddleCenter;
      if (f == Halign.m_right)  return ContentAlignment.MiddleRight;
      throw new System.InvalidOperationException();
    }
  }
}
