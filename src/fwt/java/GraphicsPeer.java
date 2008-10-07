//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import java.util.Stack;
import fan.sys.FanObj;
import fan.sys.ArgErr;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Pattern;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.graphics.Transform;
import org.eclipse.swt.widgets.Display;

public class GraphicsPeer
{

  public static GraphicsPeer make(Graphics self)
  {
    return new GraphicsPeer();
  }

  public Brush brush(Graphics self)
  {
    return brush;
  }

  public void brush(Graphics self, Brush brush)
  {
    this.brush = brush;
    Env env = Env.get();
    Pattern oldfg = gc.getForegroundPattern();
    Pattern oldbg = gc.getBackgroundPattern();
    try
    {
      if (brush instanceof Color)
      {
        org.eclipse.swt.graphics.Color c = env.color((Color)brush);
        gc.setForeground(c);
        gc.setBackground(c);
        gc.setForegroundPattern(null);
        gc.setBackgroundPattern(null);
      }
      else if (brush instanceof Gradient)
      {
        Pattern p = gradient(env, (Gradient)brush);
        gc.setForegroundPattern(p);
        gc.setBackgroundPattern(p);
      }
      else
      {
        throw ArgErr.make("Unsupported brush type: " + FanObj.type(brush)).val;
      }
    }
    finally
    {
      if (oldfg != null) oldfg.dispose();
      if (oldbg != null) oldbg.dispose();
    }
  }

  private Pattern gradient(Env env, Gradient g)
  {
    return new Pattern(env.display,
        (float)g.p1.x.longValue(), (float)g.p1.y.longValue(),
        (float)g.p2.x.longValue(), (float)g.p2.y.longValue(),
        env.color(g.c1), g.c1.alpha().intValue(),
        env.color(g.c2), g.c2.alpha().intValue());
  }

  public Pen pen(Graphics self)
  {
    return pen;
  }

  public void pen(Graphics self, Pen pen)
  {
    this.pen = pen;
    gc.setLineWidth(pen.width.intValue());
    gc.setLineCap(penCap(pen.cap));
    gc.setLineJoin(penJoin(pen.join));
    gc.setLineDash(pen.dash != null ? pen.dash.toInts() : null);
  }

  private static int penCap(Long cap)
  {
    if (cap == Pen.capSquare) return SWT.CAP_SQUARE;
    if (cap == Pen.capButt)   return SWT.CAP_FLAT;
    if (cap == Pen.capRound)  return SWT.CAP_ROUND;
    throw new IllegalStateException("Invalid pen.cap " + cap);
  }

  private static int penJoin(Long join)
  {
    if (join == Pen.joinMiter) return SWT.JOIN_MITER;
    if (join == Pen.joinBevel) return SWT.JOIN_BEVEL;
    if (join == Pen.joinRound) return SWT.JOIN_ROUND;
    throw new IllegalStateException("Invalid pen.join " + join);
  }

  public Font font(Graphics self)
  {
    return font;
  }

  public void font(Graphics self, Font font)
  {
    this.font = font;
    this.gc.setFont(Env.get().font(font));
  }

  public Boolean antialias(Graphics self)
  {
    return gc.getAntialias() == SWT.ON;
  }

  public void antialias(Graphics self, Boolean on)
  {
    int val = on ? SWT.ON : SWT.OFF;
    gc.setAntialias(val);
    gc.setTextAntialias(val);
  }

  public Graphics drawPoint(Graphics self, Long x, Long y)
  {
    gc.drawPoint(x.intValue(), y.intValue());
    return self;
  }

  public Graphics drawLine(Graphics self, Long x1, Long y1, Long x2, Long y2)
  {
    gc.drawLine(x1.intValue(), y1.intValue(), x2.intValue(), y2.intValue());
    return self;
  }

  public Graphics drawRect(Graphics self, Long x, Long y, Long w, Long h)
  {
    gc.drawRectangle(x.intValue(), y.intValue(), w.intValue(), h.intValue());
    return self;
  }

  public Graphics fillRect(Graphics self, Long x, Long y, Long w, Long h)
  {
    gc.fillRectangle(x.intValue(), y.intValue(), w.intValue(), h.intValue());
    return self;
  }

  public Graphics drawOval(Graphics self, Long x, Long y, Long w, Long h)
  {
    gc.drawOval(x.intValue(), y.intValue(), w.intValue(), h.intValue());
    return self;
  }

  public Graphics fillOval(Graphics self, Long x, Long y, Long w, Long h)
  {
    gc.fillOval(x.intValue(), y.intValue(), w.intValue(), h.intValue());
    return self;
  }

  public Graphics drawArc(Graphics self, Long x, Long y, Long w, Long h, Long s, Long a)
  {
    gc.drawArc(x.intValue(), y.intValue(), w.intValue(), h.intValue(), s.intValue(), a.intValue());
    return self;
  }

  public Graphics fillArc(Graphics self, Long x, Long y, Long w, Long h, Long s, Long a)
  {
    gc.fillArc(x.intValue(), y.intValue(), w.intValue(), h.intValue(), s.intValue(), a.intValue());
    return self;
  }

  public Graphics drawText(Graphics self, String text, Long x, Long y)
  {
    int flags = SWT.DRAW_DELIMITER | SWT.DRAW_TAB | SWT.DRAW_TRANSPARENT;
    gc.drawText(text, x.intValue(), y.intValue(), flags);
    return self;
  }

  public Graphics drawImage(Graphics self, Image img, Long x, Long y)
  {
    gc.drawImage(Env.get().image(img), x.intValue(), y.intValue());
    return self;
  }

  public Graphics copyImage(Graphics self, Image img, Rect s, Rect d)
  {
    gc.drawImage(Env.get().image(img),
      s.x.intValue(), s.y.intValue(), s.w.intValue(), s.h.intValue(),
      d.x.intValue(), d.y.intValue(), d.w.intValue(), d.h.intValue());
    return self;
  }

  public Graphics translate(Graphics self, Long x, Long y)
  {
    Transform t = new Transform(gc.getDevice());
    gc.getTransform(t);
    t.translate(x.intValue(), y.intValue());
    gc.setTransform(t);
    t.dispose();
    return self;
  }

  public Rect clipRect(Graphics self)
  {
    return WidgetPeer.rect(gc.getClipping());
  }

  public void clipRect(Graphics self, Rect r)
  {
    gc.setClipping(WidgetPeer.rect(r));
  }

  public Graphics clip(Graphics self, Rect r)
  {
    Rectangle a = gc.getClipping();
    Rectangle b = WidgetPeer.rect(r);
    gc.setClipping(a.intersection(b));
    return self;
  }

  public void dispose(Graphics self)
  {
    gc.dispose();
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public void push(Graphics self)
  {
    State s = new State();
    s.pen   = pen;
    s.brush = brush;
    s.font  = font;
    s.antialias = gc.getAntialias();
    s.textAntialias = gc.getTextAntialias();
    s.transform = new Transform(gc.getDevice());
    gc.getTransform(s.transform);
    s.clip = gc.getClipping();
    stack.push(s);
  }

  public void pop(Graphics self)
  {
    State s = (State)stack.pop();
    pen(self, s.pen);
    brush(self, s.brush);
    font(self, s.font);
    gc.setAntialias(s.antialias);
    gc.setTextAntialias(s.textAntialias);
    gc.setTransform(s.transform);
    s.transform.dispose();
    gc.setClipping(s.clip);
  }

  static class State
  {
    Pen pen;
    Brush brush;
    Font font;
    int antialias;
    int textAntialias;
    Transform transform;
    Rectangle clip;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  GC gc;
  Pen pen = Pen.def;
  Brush brush = Color.black;
  Font font;
  Stack stack = new Stack();

}