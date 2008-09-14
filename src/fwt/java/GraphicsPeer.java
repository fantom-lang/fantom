//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import java.util.Stack;
import fan.sys.Bool;
import fan.sys.Int;
import fan.sys.Str;
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
        throw ArgErr.make("Unsupported brush type: " + brush.type()).val;
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
        (float)g.p1.x.val, (float)g.p1.y.val,
        (float)g.p2.x.val, (float)g.p2.y.val,
        env.color(g.c1), (int)g.c1.alpha().val,
        env.color(g.c2), (int)g.c2.alpha().val);
  }

  public Pen pen(Graphics self)
  {
    return pen;
  }

  public void pen(Graphics self, Pen pen)
  {
    this.pen = pen;
    gc.setLineWidth((int)pen.width.val);
    gc.setLineCap(penCap(pen.cap));
    gc.setLineJoin(penJoin(pen.join));
    gc.setLineDash(pen.dash != null ? pen.dash.toInts() : null);
  }

  private static int penCap(Int cap)
  {
    if (cap == Pen.capSquare) return SWT.CAP_SQUARE;
    if (cap == Pen.capButt)   return SWT.CAP_FLAT;
    if (cap == Pen.capRound)  return SWT.CAP_ROUND;
    throw new IllegalStateException("Invalid pen.cap " + cap);
  }

  private static int penJoin(Int join)
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

  public Bool antialias(Graphics self)
  {
    return Bool.make(gc.getAntialias() == SWT.ON);
  }

  public void antialias(Graphics self, Bool on)
  {
    int val = on.val ? SWT.ON : SWT.OFF;
    gc.setAntialias(val);
    gc.setTextAntialias(val);
  }

  public Graphics drawPoint(Graphics self, Int x, Int y)
  {
    gc.drawPoint((int)x.val, (int)y.val);
    return self;
  }

  public Graphics drawLine(Graphics self, Int x1, Int y1, Int x2, Int y2)
  {
    gc.drawLine((int)x1.val, (int)y1.val, (int)x2.val, (int)y2.val);
    return self;
  }

  public Graphics drawRect(Graphics self, Int x, Int y, Int w, Int h)
  {
    gc.drawRectangle((int)x.val, (int)y.val, (int)w.val, (int)h.val);
    return self;
  }

  public Graphics fillRect(Graphics self, Int x, Int y, Int w, Int h)
  {
    gc.fillRectangle((int)x.val, (int)y.val, (int)w.val, (int)h.val);
    return self;
  }

  public Graphics drawOval(Graphics self, Int x, Int y, Int w, Int h)
  {
    gc.drawOval((int)x.val, (int)y.val, (int)w.val, (int)h.val);
    return self;
  }

  public Graphics fillOval(Graphics self, Int x, Int y, Int w, Int h)
  {
    gc.fillOval((int)x.val, (int)y.val, (int)w.val, (int)h.val);
    return self;
  }

  public Graphics drawArc(Graphics self, Int x, Int y, Int w, Int h, Int s, Int a)
  {
    gc.drawArc((int)x.val, (int)y.val, (int)w.val, (int)h.val, (int)s.val, (int)a.val);
    return self;
  }

  public Graphics fillArc(Graphics self, Int x, Int y, Int w, Int h, Int s, Int a)
  {
    gc.fillArc((int)x.val, (int)y.val, (int)w.val, (int)h.val, (int)s.val, (int)a.val);
    return self;
  }

  public Graphics drawText(Graphics self, Str text, Int x, Int y)
  {
    int flags = SWT.DRAW_DELIMITER | SWT.DRAW_TAB | SWT.DRAW_TRANSPARENT;
    gc.drawText(text.val, (int)x.val, (int)y.val, flags);
    return self;
  }

  public Graphics drawImage(Graphics self, Image img, Int x, Int y)
  {
    gc.drawImage(Env.get().image(img), (int)x.val, (int)y.val);
    return self;
  }

  public Graphics copyImage(Graphics self, Image img, Rect s, Rect d)
  {
    gc.drawImage(Env.get().image(img),
      (int)s.x.val, (int)s.y.val, (int)s.w.val, (int)s.h.val,
      (int)d.x.val, (int)d.y.val, (int)d.w.val, (int)d.h.val);
    return self;
  }

  public Graphics translate(Graphics self, Int x, Int y)
  {
    Transform t = new Transform(gc.getDevice());
    gc.getTransform(t);
    t.translate((int)x.val, (int)y.val);
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