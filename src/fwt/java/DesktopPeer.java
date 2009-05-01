//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import fan.gfx.Rect;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Widget;

public class DesktopPeer
{

//////////////////////////////////////////////////////////////////////////
// Peer
//////////////////////////////////////////////////////////////////////////

  public static DesktopPeer make(Desktop self)
  {
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Native methods
//////////////////////////////////////////////////////////////////////////

  public static String platform()
  {
    if (Env.isWindows()) return "windows";
    if (Env.isMac()) return "mac";
    return SWT.getPlatform();
  }

  public static boolean isWindows()
  {
    return Env.isWindows();
  }

  public static boolean isMac()
  {
    return Env.isMac();
  }

  public static Rect bounds()
  {
    return WidgetPeer.rect(Env.get().display.getBounds());
  }

  public static fan.fwt.Widget focus()
  {
    return WidgetPeer.toFanWidget(Env.get().display.getFocusControl());
  }

  public static void callAsync(final Func func)
  {
    // check if running on UI thread
    Env env = Env.main();
    if (java.lang.Thread.currentThread() != env.display.getThread())
    {
      if (!func.isImmutable())
        throw NotImmutableErr.make("callAsync func must be immutable if not on UI thread").val;
    }

    // enqueue on main UI thread's display
    env.display.asyncExec(new Runnable()
    {
      public void run()
      {
        try
        {
          func.call0();
        }
        catch (Throwable e)
        {
          e.printStackTrace();
        }
      }
    });
  }

//////////////////////////////////////////////////////////////////////////
// Dispose
//////////////////////////////////////////////////////////////////////////

  public static void disposeColor(fan.gfx.Color f)
  {
    Env.get().dispose(f);
  }

  public static void disposeFont(fan.gfx.Font f)
  {
    Env.get().dispose(f);
  }

  public static void disposeImage(fan.gfx.Image f)
  {
    Env.get().dispose(f);
  }

//////////////////////////////////////////////////////////////////////////
// System Fonts
//////////////////////////////////////////////////////////////////////////

  public static fan.gfx.Font sysFont()
  {
    if (sysFont == null)
    {
      FontData data = Env.get().display.getSystemFont().getFontData()[0];
      sysFont = fan.gfx.Font.makeFields(data.getName(), data.getHeight());
    }
    return sysFont;
  }
  private static fan.gfx.Font sysFont;

  public static fan.gfx.Font sysFontMonospace()
  {
    if (sysFontMonospace == null)
    {
      String name = "Courier New"; int size = 9;
      if (Env.isMac()) { name = "Monaco"; size = 12; }
      sysFontMonospace = fan.gfx.Font.makeFields(name, size);
    }
    return sysFontMonospace;
  }
  private static fan.gfx.Font sysFontMonospace;

//////////////////////////////////////////////////////////////////////////
// System Colors
//////////////////////////////////////////////////////////////////////////

  public static fan.gfx.Color sysDarkShadow() { return sysColor(sysDarkShadow, SWT.COLOR_WIDGET_DARK_SHADOW); }
  public static fan.gfx.Color sysNormShadow() { return sysColor(sysNormShadow, SWT.COLOR_WIDGET_NORMAL_SHADOW); }
  public static fan.gfx.Color sysLightShadow() { return sysColor(sysLightShadow, SWT.COLOR_WIDGET_LIGHT_SHADOW); }
  public static fan.gfx.Color sysHighlightShadow() { return sysColor(sysHighlightShadow, SWT.COLOR_WIDGET_HIGHLIGHT_SHADOW); }
  public static fan.gfx.Color sysFg() { return sysColor(sysFg, SWT.COLOR_WIDGET_FOREGROUND); }
  public static fan.gfx.Color sysBg() { return sysColor(sysBg, SWT.COLOR_WIDGET_BACKGROUND); }
  public static fan.gfx.Color sysBorder() { return sysColor(sysBorder, SWT.COLOR_WIDGET_BORDER); }
  public static fan.gfx.Color sysListFg() { return sysColor(sysListFg, SWT.COLOR_LIST_FOREGROUND); }
  public static fan.gfx.Color sysListBg() { return sysColor(sysListBg, SWT.COLOR_LIST_BACKGROUND); }
  public static fan.gfx.Color sysListSelFg() { return sysColor(sysListSelFg, SWT.COLOR_LIST_SELECTION); }
  public static fan.gfx.Color sysListSelBg() { return sysColor(sysListSelBg, SWT.COLOR_LIST_SELECTION_TEXT); }

  static final int sysDarkShadow      = 0;
  static final int sysNormShadow      = 1;
  static final int sysLightShadow     = 2;
  static final int sysHighlightShadow = 3;
  static final int sysFg              = 4;
  static final int sysBg              = 5;
  static final int sysBorder          = 6;
  static final int sysListFg          = 7;
  static final int sysListBg          = 8;
  static final int sysListSelFg       = 9;
  static final int sysListSelBg       = 10;
  static fan.gfx.Color[] sysColors = new fan.gfx.Color[11];

  private static fan.gfx.Color sysColor(int index, int swtId)
  {
    fan.gfx.Color c = sysColors[index];
    if (c == null)
    {
      Color sys = Env.get().display.getSystemColor(swtId);
      int rgb = (sys.getRed() << 16) | (sys.getGreen() << 8) | sys.getBlue();
      c = sysColors[index] = fan.gfx.Color.make(rgb, false);
    }
    return c;
  }
}