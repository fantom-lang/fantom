//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;

public class ColorPeer
{
  static final ColorPeer singleton = new ColorPeer();

  public static ColorPeer make(fan.fwt.Color self)
  {
    return singleton;
  }

  public void dispose(fan.fwt.Color f)
  {
    Env.get().dispose(f);
  }

//////////////////////////////////////////////////////////////////////////
// System Colors
//////////////////////////////////////////////////////////////////////////

  public static fan.fwt.Color sysDarkShadow() { return sysColor(sysDarkShadow, SWT.COLOR_WIDGET_DARK_SHADOW); }
  public static fan.fwt.Color sysNormShadow() { return sysColor(sysNormShadow, SWT.COLOR_WIDGET_NORMAL_SHADOW); }
  public static fan.fwt.Color sysLightShadow() { return sysColor(sysLightShadow, SWT.COLOR_WIDGET_LIGHT_SHADOW); }
  public static fan.fwt.Color sysHighlightShadow() { return sysColor(sysHighlightShadow, SWT.COLOR_WIDGET_HIGHLIGHT_SHADOW); }
  public static fan.fwt.Color sysFg() { return sysColor(sysFg, SWT.COLOR_WIDGET_FOREGROUND); }
  public static fan.fwt.Color sysBg() { return sysColor(sysBg, SWT.COLOR_WIDGET_BACKGROUND); }
  public static fan.fwt.Color sysBorder() { return sysColor(sysBorder, SWT.COLOR_WIDGET_BORDER); }
  public static fan.fwt.Color sysListFg() { return sysColor(sysListFg, SWT.COLOR_LIST_FOREGROUND); }
  public static fan.fwt.Color sysListBg() { return sysColor(sysListBg, SWT.COLOR_LIST_BACKGROUND); }
  public static fan.fwt.Color sysListSelFg() { return sysColor(sysListSelFg, SWT.COLOR_LIST_SELECTION); }
  public static fan.fwt.Color sysListSelBg() { return sysColor(sysListSelBg, SWT.COLOR_LIST_SELECTION_TEXT); }

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
  static fan.fwt.Color[] sysColors = new fan.fwt.Color[11];

  private static fan.fwt.Color sysColor(int index, int swtId)
  {
    fan.fwt.Color c = sysColors[index];
    if (c == null)
    {
      Color sys = Env.get().display.getSystemColor(swtId);
      int rgb = (sys.getRed() << 16) | (sys.getGreen() << 8) | sys.getBlue();
      c = sysColors[index] = fan.fwt.Color.make(Int.make(rgb), Bool.False);
    }
    return c;
  }

}
