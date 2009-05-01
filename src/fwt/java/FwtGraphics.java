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
import fan.gfx.*;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Pattern;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.graphics.Transform;
import org.eclipse.swt.widgets.Display;

public class FwtGraphics implements Graphics
{
  public FwtGraphics(GC gc)
  {
    this.gc = gc;
  }

  public Brush brush()
  {
    return brush;
  }

  public void brush(Brush brush)
  {
    this.brush = brush;
    Env env = Env.get();
    Pattern oldfg = gc.getForegroundPattern();
    Pattern oldbg = gc.getBackgroundPattern();
    try
    {
      if (brush instanceof Color)
      {
        int ca = (int)((Color)brush).alpha();
        gc.setAlpha((alpha == 255) ? ca : (int)((alpha * ca) / 255));
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
    int a1 = (int)g.c1.alpha();
    int a2 = (int)g.c2.alpha();
    if (alpha != 255)
    {
      a1 = (int)((alpha * a1) / 255);
      a2 = (int)((alpha * a2) / 255);
    }
    return new Pattern(env.display,
        (float)g.p1.x, (float)g.p1.y,
        (float)g.p2.x, (float)g.p2.y,
        env.color(g.c1), a1,
        env.color(g.c2), a2);
  }

  public Pen pen()
  {
    return pen;
  }

  public void pen(Pen pen)
  {
    this.pen = pen;
    gc.setLineWidth((int)pen.width);
    gc.setLineCap(penCap(pen.cap));
    gc.setLineJoin(penJoin(pen.join));
    gc.setLineDash(pen.dash != null ? pen.dash.toInts() : null);
  }

  private static int penCap(long cap)
  {
    if (cap == Pen.capSquare) return SWT.CAP_SQUARE;
    if (cap == Pen.capButt)   return SWT.CAP_FLAT;
    if (cap == Pen.capRound)  return SWT.CAP_ROUND;
    throw new IllegalStateException("Invalid pen.cap " + cap);
  }

  private static int penJoin(long join)
  {
    if (join == Pen.joinMiter) return SWT.JOIN_MITER;
    if (join == Pen.joinBevel) return SWT.JOIN_BEVEL;
    if (join == Pen.joinRound) return SWT.JOIN_ROUND;
    throw new IllegalStateException("Invalid pen.join " + join);
  }

  public Font font()
  {
    return font;
  }

  public void font(Font font)
  {
    this.font = font;
    this.gc.setFont(Env.get().font(font));
  }

  public boolean antialias()
  {
    return gc.getAntialias() == SWT.ON;
  }

  public void antialias(boolean on)
  {
    int val = on ? SWT.ON : SWT.OFF;
    gc.setAntialias(val);
    gc.setTextAntialias(val);
  }

  public long alpha()
  {
    return alpha;
  }

  public void alpha(long alpha)
  {
    this.alpha = (int)alpha;
    brush(this.brush);
  }

  public Graphics drawPoint(long x, long y)
  {
    gc.drawPoint((int)x, (int)y);
    return this;
  }

  public Graphics drawLine(long x1, long y1, long x2, long y2)
  {
    gc.drawLine((int)x1, (int)y1, (int)x2, (int)y2);
    return this;
  }

  public Graphics drawRect(long x, long y, long w, long h)
  {
    gc.drawRectangle((int)x, (int)y, (int)w, (int)h);
    return this;
  }

  public Graphics fillRect(long x, long y, long w, long h)
  {
    gc.fillRectangle((int)x, (int)y, (int)w, (int)h);
    return this;
  }

  public Graphics drawOval(long x, long y, long w, long h)
  {
    gc.drawOval((int)x, (int)y, (int)w, (int)h);
    return this;
  }

  public Graphics fillOval(long x, long y, long w, long h)
  {
    gc.fillOval((int)x, (int)y, (int)w, (int)h);
    return this;
  }

  public Graphics drawArc(long x, long y, long w, long h, long s, long a)
  {
    gc.drawArc((int)x, (int)y, (int)w, (int)h, (int)s, (int)a);
    return this;
  }

  public Graphics fillArc(long x, long y, long w, long h, long s, long a)
  {
    gc.fillArc((int)x, (int)y, (int)w, (int)h, (int)s, (int)a);
    return this;
  }

  public Graphics drawText(String text, long x, long y)
  {
    int flags = SWT.DRAW_DELIMITER | SWT.DRAW_TAB | SWT.DRAW_TRANSPARENT;
    gc.drawText(text, (int)x, (int)y, flags);
    return this;
  }

  public Graphics drawImage(Image img, long x, long y)
  {
    gc.drawImage(Env.get().image(img), (int)x, (int)y);
    return this;
  }

  public Graphics copyImage(Image img, Rect s, Rect d)
  {
    gc.drawImage(Env.get().image(img),
      (int)s.x, (int)s.y, (int)s.w, (int)s.h,
      (int)d.x, (int)d.y, (int)d.w, (int)d.h);
    return this;
  }

  public Graphics translate(long x, long y)
  {
    Transform t = new Transform(gc.getDevice());
    gc.getTransform(t);
    t.translate((int)x, (int)y);
    gc.setTransform(t);
    t.dispose();
    return this;
  }

  public Rect clipRect()
  {
    return WidgetPeer.rect(gc.getClipping());
  }

  public void clipRect(Rect r)
  {
    gc.setClipping(WidgetPeer.rect(r));
  }

  public Graphics clip(Rect r)
  {
    Rectangle a = gc.getClipping();
    Rectangle b = WidgetPeer.rect(r);
    gc.setClipping(a.intersection(b));
    return this;
  }

  public void dispose()
  {
    gc.dispose();
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public void push()
  {
    State s = new State();
    s.pen   = pen;
    s.brush = brush;
    s.font  = font;
    s.antialias = gc.getAntialias();
    s.textAntialias = gc.getTextAntialias();
    s.alpha = alpha;
    s.transform = new Transform(gc.getDevice());
    gc.getTransform(s.transform);
    s.clip = gc.getClipping();
    stack.push(s);
  }

  public void pop()
  {
    State s = (State)stack.pop();
    alpha = s.alpha;
    pen(s.pen);
    brush(s.brush);
    font(s.font);
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
    int alpha;
    Transform transform;
    Rectangle clip;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  GC gc;
  Pen pen = Pen.defVal;
  Brush brush = Color.black;
  Font font;
  int alpha = 255;
  Stack stack = new Stack();

}