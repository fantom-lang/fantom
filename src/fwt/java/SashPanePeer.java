//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.custom.SashForm;

public class SashPanePeer extends WidgetPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static SashPanePeer make(SashPane self)
    throws Exception
  {
    SashPanePeer peer = new SashPanePeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    SashPane self = (SashPane)this.self;
    control = new SashForm((Composite)parent, orientation(self.orientation));
    return control;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Int[] weights := null
  // Note: SWT will throw IllegalArg if we set weights with wrong number
  // of children; just ignore that, we'll try again on childAdded callback
  public List weights(SashPane self) { return weights.get(); }
  public void weights(SashPane self, List v) { weights.set(v); }
  public final Prop.IntsProp weights = new Prop.IntsProp(this)
  {
    public int[] get(Widget w) { return ((SashForm)w).getWeights(); }
    public void set(Widget w, int[] v)
    {
      try { ((SashForm)w).setWeights(v); } catch (IllegalArgumentException e) {}
    }
  };

  void childAdded(fan.fwt.Widget child)
  {
    // retry weights
    weights((SashPane)this.self, weights.val);
  }

}
