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
import org.eclipse.swt.program.Program;

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

  public static void appName(String name)
  {
    Display.setAppName(name);
  }

  public static String platform()
  {
    if (Fwt.isWindows()) return "windows";
    if (Fwt.isMac()) return "mac";
    return SWT.getPlatform();
  }

  public static boolean isWindows()
  {
    return Fwt.isWindows();
  }

  public static boolean isMac()
  {
    return Fwt.isMac();
  }

  public static Rect bounds()
  {
    return WidgetPeer.rect(Fwt.get().display.getBounds());
  }

  public static Clipboard clipboard()
  {
    if (clipboard == null) clipboard = new Clipboard();
    return clipboard;
  }
  private static Clipboard clipboard;

  public static fan.fwt.Widget focus()
  {
    return WidgetPeer.toFanWidget(Fwt.get().display.getFocusControl());
  }

  public static void callAsync(Func func)
  {
    callLater(Duration.defVal, func);
  }

  public static void callLater(Duration delay, Func func)
  {
    // check if running on UI thread
    Fwt fwt = Fwt.main();
    if (java.lang.Thread.currentThread() != fwt.display.getThread())
      func = (Func)func.toImmutable();

    // enqueue on main UI thread's display
    final Func finalFunc = func;
    final Runnable runnable = new Runnable()
    {
      public void run()
      {
        try
        {
          finalFunc.call();
        }
        catch (Throwable e)
        {
          e.printStackTrace();
        }
      }
    };

    if (delay.ticks > 0)
      fwt.display.timerExec((int)delay.millis(), runnable);
    else
      fwt.display.asyncExec(runnable);
  }

  public static boolean launchProgram(Uri uri)
  {
    return Program.launch(uri.toString());
  }

//////////////////////////////////////////////////////////////////////////
// System Fonts
//////////////////////////////////////////////////////////////////////////

  public static fan.gfx.Font sysFont()
  {
    if (sysFont == null)
    {
      FontData data = Fwt.get().display.getSystemFont().getFontData()[0];
      sysFont = fan.gfx.Font.makeFields(data.getName(), data.getHeight());
    }
    return sysFont;
  }

  public static fan.gfx.Font sysFontSmall()
  {
    if (sysFontSmall == null)
    {
      fan.gfx.Font sys = fan.fwt.Desktop.sysFont();
      sysFontSmall = sys.toSize(sys.size-2);
    }
    return sysFontSmall;
  }

  public static fan.gfx.Font sysFontView()
  {
    if (sysFontView == null)
    {
      fan.gfx.Font sys = fan.fwt.Desktop.sysFont();
      sysFontView = Fwt.isMac() ? sys.toSize(sys.size-1) : sys;
    }
    return sysFontView;
  }

  public static fan.gfx.Font sysFontMonospace()
  {
    if (sysFontMonospace == null)
    {
      String name = "Courier New"; int size = 9;
      if (Fwt.isMac()) { name = "Monaco"; size = 12; }
      sysFontMonospace = fan.gfx.Font.makeFields(name, size);
    }
    return sysFontMonospace;
  }

  private static fan.gfx.Font sysFont;
  private static fan.gfx.Font sysFontSmall;
  private static fan.gfx.Font sysFontView;
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
  public static fan.gfx.Color sysListSelFg() { return sysColor(sysListSelFg, SWT.COLOR_LIST_SELECTION_TEXT); }
  public static fan.gfx.Color sysListSelBg() { return sysColor(sysListSelBg, SWT.COLOR_LIST_SELECTION); }

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
      Color sys = Fwt.get().display.getSystemColor(swtId);
      int rgb = (sys.getRed() << 16) | (sys.getGreen() << 8) | sys.getBlue();
      c = sysColors[index] = fan.gfx.Color.make(rgb, false);
    }
    return c;
  }
}