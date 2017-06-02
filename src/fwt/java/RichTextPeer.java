//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import java.lang.reflect.Field;
import java.util.ArrayList;
import fan.sys.*;
import fan.sys.List;
import fan.gfx.*;
import fanx.util.OpUtil;
import org.eclipse.swt.*;
import org.eclipse.swt.custom.*;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.events.*;

public class RichTextPeer
  extends TextWidgetPeer
  implements LineStyleListener, LineBackgroundListener,
             VerifyKeyListener, VerifyListener,
             SelectionListener, TraverseListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static RichTextPeer make(RichText self)
    throws Exception
  {
    RichTextPeer peer = new RichTextPeer();
    ((fan.fwt.TextWidget)self).peer = peer;
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    RichText self = (RichText)this.self;
    this.model = self.model();
    if (model == null) throw Err.make("RichText.model is null");

    int style = self.multiLine ? SWT.MULTI: SWT.SINGLE;
    if (!self.editable) style |= SWT.READ_ONLY;
    if (self.border)    style |= SWT.BORDER;
    if (self.wrap)      style |= SWT.WRAP;
    if (self.hscroll)   style |= SWT.H_SCROLL;
    if (self.vscroll)   style |= SWT.V_SCROLL;

    StyledText t = new StyledText((Composite)parent, style);
    control = t;
    t.setContent(content = new Content());
    t.addLineStyleListener(this);
    t.addLineBackgroundListener(this);
    t.addTraverseListener(this);
    t.addVerifyKeyListener(this);
    t.addVerifyListener(this);
    t.addSelectionListener(this);

    ScrollBar hbar = t.getHorizontalBar();
    ScrollBar vbar = t.getVerticalBar();
    if (hbar != null) ((ScrollBarPeer)self.hbar().peer).attachToScrollable(t, hbar);
    if (vbar != null) ((ScrollBarPeer)self.vbar().peer).attachToScrollable(t, vbar);

    // this is a hack, but seems to be the only way to set
    // the margins hidden away as private fields in StyledText
    setField(t, "leftMargin",   8);
    setField(t, "topMargin",    0);
    setField(t, "rightMargin",  8);
    setField(t, "bottomMargin", 8);

    // add myself as key/mouse listener for caret movement
    t.addKeyListener(new KeyAdapter()
    {
      public void keyPressed(KeyEvent e) { checkCaretPos(); }
      public void keyReleased(KeyEvent e) { checkCaretPos(); }
    });
    t.addMouseListener(new MouseAdapter()
    {
      public void mouseDown(MouseEvent e) { checkCaretPos(); }
      public void mouseUp(MouseEvent e) { checkCaretPos(); }
    });

    return t;
  }

  private void setField(StyledText t, String name, int val)
  {
    try
    {
      Field f = t.getClass().getDeclaredField(name);
      f.setAccessible(true);
      f.set(t, val);
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Prop.IntProp caretOffset() { return caretOffset; }
  public final Prop.IntProp caretOffset = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((StyledText)w).getCaretOffset(); }
    public void set(final Widget w, final int v)
    {
      // for whatever reason this call only works if used in an
      // async action; found this tip on the discussion group:
      // http://dev.eclipse.org/newslists/news.eclipse.platform.swt/msg26461.html
      // suppress exceptions, b/c something the widget gets disposed out under us
      Fwt.get().display.asyncExec(new Runnable()
      {
        public void run()
        {
          try
          {
            ((StyledText)w).setCaretOffset(v);
            checkCaretPos();
          }
          catch (SWTException e) {}
        }
      });
    }
  };

  Prop.FontProp font() { return font; }
  public final Prop.FontProp font = new Prop.FontProp(this)
  {
    public void set(Widget w, Font v) { ((StyledText)w).setFont(v); }
  };

  // Int topLine := 0
  public long topLine(RichText self) { return topLine.get(); }
  public void topLine(RichText self, long v) { topLine.set(v); }
  public final Prop.IntProp topLine = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((StyledText)w).getTopIndex(); }
    public void set(Widget w, int v) { ((StyledText)w).setTopIndex(v);  }
  };

  // Int tabSpacing := 2
  public long tabSpacing(RichText self) { return tabSpacing.get(); }
  public void tabSpacing(RichText self, long v) { tabSpacing.set(v); }
  public final Prop.IntProp tabSpacing = new Prop.IntProp(this, 2)
  {
    public int get(Widget w) { return ((StyledText)w).getTabs(); }
    public void set(Widget w, int v) { ((StyledText)w).setTabs(v);  }
  };

  public fan.gfx.Color fg(RichText self) { return fg.get(); }
  public void fg(RichText self, fan.gfx.Color v) { fg.set(v); }
  public final Prop.ColorProp fg = new Prop.ColorProp(this)
  {
    public void set(Widget w, org.eclipse.swt.graphics.Color v) { ((StyledText)w).setForeground(v); }
  };

  public fan.gfx.Color bg(RichText self) { return bg.get(); }
  public void bg(RichText self, fan.gfx.Color v) { bg.set(v); }
  public final Prop.ColorProp bg = new Prop.ColorProp(this)
  {
    public void set(Widget w, org.eclipse.swt.graphics.Color v) {
      ((StyledText)w).setBackground(v);
      ((StyledText)w).setMarginColor(v);
    }
  };

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  String selectText(Widget w) { return ((StyledText)w).getSelectionText(); }

  int selectStart(Widget w) { return ((StyledText)w).getSelection().x; }

  int selectSize(Widget w) { Point sel = ((StyledText)w).getSelection(); return sel.y - sel.x; }

  void select(Widget w, int start, int size) { ((StyledText)w).setSelection(start, start+size); }

  void selectAll(Widget w) { ((StyledText)w).selectAll(); }

  void selectClear(Widget w) { ((StyledText)w).setSelection( ((StyledText)w).getCaretOffset() ); }

//////////////////////////////////////////////////////////////////////////
// Clipboard
//////////////////////////////////////////////////////////////////////////

  void cut(Widget w)   { ((StyledText)w).cut(); }
  void copy(Widget w)  { ((StyledText)w).copy(); }
  void paste(Widget w) { ((StyledText)w).paste(); }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  public void repaintRange(RichText self, long start, long len)
  {
    if (control == null) return;
    ((StyledText)control).redrawRange((int)start, (int)len, false);
  }

  void repaintLineRect(int offset)
  {
    try
    {
      StyledText st = (StyledText)control;
      Point pt = st.getLocationAtOffset(offset);
      st.redraw(pt.x, pt.y, st.getSize().x, st.getLineHeight(offset), true);
    }
    catch (Exception e) {}
  }

  public void showLine(RichText self, long lineIndex)
  {
    StyledText st = (StyledText)control;
    if (st == null) return;

    // compute top and bottom line y coordinates
    Rectangle client = st.getClientArea();
    int topy = st.getTopPixel();
    int bottomy = topy + client.height - 4;

    // compute y coordinate of desired line
    int offset = (int)model.offsetAtLine(lineIndex);
    int targety = topy + st.getLocationAtOffset(offset).y;

    // if target line is visible bail
    if (topy <= targety && targety + st.getLineHeight(offset) < bottomy) return;

    // the SWT APIs for scrolling based on the text model leave
    // a lot to be desired, the safest thing is to use selection
    select(self, offset, 0);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public Long offsetAtPos(RichText self, long x, long y)
  {
    if (control == null) return null;
    try
    {
      int off = ((StyledText)control).getOffsetAtLocation(new Point((int)x, (int)y));
      if (off < 0) return null;
      return Long.valueOf(off);
    }
    catch (IllegalArgumentException e)
    {
      return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void keyTraversed(TraverseEvent se)
  {
    // suppress using tab as traversal
    if (se.character == '\t') se.doit = false;
  }

  public void verifyKey(VerifyEvent se)
  {
    fireKeyEvent(((RichText)self).onVerifyKey(), EventId.verifyKey, se);
    if (se.doit) checkHomeEnd(se);
  }

  public void verifyText(VerifyEvent se)
  {
    RichText self = (RichText)this.self;
    List cbs = self.onVerify().list();
    if (cbs.isEmpty()) return;

    TextChange tc = TextChange.make();
    tc.startOffset = se.start;
    tc.startLine   = model.lineAtOffset(tc.startOffset);
    tc.oldText     = model.textRange(tc.startOffset, se.end-se.start);
    tc.newText     = se.text;

    fan.fwt.Event fe = event(EventId.verify, tc);
    String origNewText = tc.newText;

    for (int i=0; i<cbs.sz(); ++i)
    {
      ((Func)cbs.get(i)).call(fe);
      if (tc.newText != origNewText && OpUtil.compareNE(tc.newText, origNewText))
      {
        if (tc.newText == null) se.doit = false;
        else se.text = tc.newText;
        return;
      }
    }
  }

  public void widgetDefaultSelected(SelectionEvent se) {}

  public void widgetSelected(SelectionEvent se)
  {
    fan.fwt.Event fe = event(EventId.select);
    fe.offset = Long.valueOf(se.x);
    fe.size   = Long.valueOf(se.y - se.x);
    ((RichText)self).onSelect().fire(fe);
  }

  public void checkCaretPos()
  {
    // short circuit if position has change
    int newCaretPos = ((StyledText)control).getCaretOffset();
    if (newCaretPos == oldCaretPos) return;

    // fire caret change event
    int oldPos = oldCaretPos;
    oldCaretPos = newCaretPos;
    fan.fwt.Event fe = event(EventId.caret);
    fe.offset = Long.valueOf(newCaretPos);
    ((RichText)self).onCaret().fire(fe);

    // automatically repaint last line and current line
    int oldLine = (int)model.lineAtOffset(oldPos);
    int newLine = (int)model.lineAtOffset(newCaretPos);
    if (oldLine == newLine) return;

    // repaint
    ((StyledText)control).redraw();
    repaintLineRect(oldPos);
    repaintLineRect(newCaretPos);
  }

  public void checkHomeEnd(KeyEvent event)
  {
    // make home/end work right by first going to home/end of
    // non-whitespace, then to actual beginning/end
    StyledText st = (StyledText)control;
    int lineStart = st.getKeyBinding(ST.LINE_START);
    int lineEnd   = st.getKeyBinding(ST.LINE_END);
    int mask = event.stateMask & ~SWT.SHIFT;
    boolean home = (event.keyCode | mask) == lineStart;
    boolean end  = (event.keyCode | mask) == lineEnd;
    if (!home && !end) return;

    // consume the event so StyledText doesn't process it
    event.doit = false;

    // gather all the crap we need
    int oldCaret   = st.getCaretOffset();
    int lineNum = content.getLineAtOffset(oldCaret);
    int lineOff = content.getOffsetAtLine(lineNum);
    int linePos = oldCaret - lineOff;  // offset inside this line
    String text = content.getLine(lineNum);

    // compute new offset inside this line based on non-whitespace
    int newPos;
    if (home)
    {
      int nonws = 0;
      while (nonws < text.length() && FanInt.isSpace(text.charAt(nonws))) nonws++;
      newPos = linePos <= nonws ? 0 : nonws;
    }
    else
    {
      int nonws = text.length();
      while (nonws-1 >= 0 && FanInt.isSpace(text.charAt(nonws-1))) nonws--;
      newPos = linePos >= nonws ? text.length() : nonws;
    }

    // include into selection if shift is down, otherwise just move caret
    int newCaret = lineOff + newPos;
    if ((event.stateMask & SWT.SHIFT) != 0)
    {
      Point sel = st.getSelection();
      st.setSelection(home ? sel.y : sel.x, newCaret);
    }
    else
    {
      st.setSelection(newCaret, newCaret);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Content
//////////////////////////////////////////////////////////////////////////

  public void onModelModify(RichText self, fan.fwt.Event fe)
  {
    StyledText styledText = (StyledText)RichTextPeer.this.control;
    TextChange tc = (TextChange)fe.data;

    // map Fan model event to SWT event
    TextChangingEvent te = new TextChangingEvent(content);
    te.start            = (int)tc.startOffset;
    te.replaceCharCount = tc.oldText.length();
    te.replaceLineCount = tc.oldNumNewlines().intValue();
    te.newText          = tc.newText;
    te.newCharCount     = tc.newText.length();
    te.newLineCount     = tc.newNumNewlines().intValue();

    // fire SWT changing event
    content.fireTextChanging(te);

    // fire modified event
    content.fireTextChanged(new TextChangedEvent(content));

    // if onModify callback register, fire event
    if (!self.onModify().isEmpty())
    {
      fan.fwt.Event modevt = event(EventId.modified, tc);
      self.onModify().fire(modevt);
    }

    // the styled text widget has a bug where it doesn't repaint
    // deleting lines at the end of the screen; so take a brute
    // force approach
    if (te.replaceLineCount != te.newLineCount)
    {
      styledText.redraw();
    }
    // if the style of the line immediately after the
    // inserted text has been modified, then do a repaint
    else if (tc.repaintLen != null)
    {
      int repaintStart = te.start;
      if (tc.repaintStart != null) repaintStart = tc.repaintStart.intValue();
      int repaintLen = tc.repaintLen.intValue();
      styledText.redrawRange(repaintStart, repaintLen, false);
    }
  }

  class Content implements StyledTextContent
  {
    // Return the number of characters in the content.
    public int getCharCount()
    {
      return (int)model.charCount();
    }

    // Return the number of lines.
    public int getLineCount()
    {
      return (int)model.lineCount();
    }

    // Return the line at the given line index without delimiters.
    public String getLine(int lineIndex)
    {
      try
      {
        return model.line(lineIndex);
      }
      catch (RuntimeException e)
      {
        System.out.println("WARNING: RichText.getLine " + lineIndex + " >= " + getLineCount());
        return "";
      }
    }

    // Return the line index at the given character offset.
    public int getLineAtOffset(int offset)
    {
      try
      {
        return (int)model.lineAtOffset(offset);
      }
      catch (RuntimeException e)
      {
        System.out.println("WARNING: RichText.getLineAtOffset " + offset + " >= " + getCharCount());
        return getLineCount()-1;
      }
    }

    // Return the character offset of the first character of the given line.
    public int getOffsetAtLine(int lineIndex)
    {
      try
      {
        return (int)model.offsetAtLine(lineIndex);
      }
      catch (RuntimeException e)
      {
        System.out.println("WARNING: RichText.getOffsetAtLine " + lineIndex + " >= " + getLineCount());
        return Math.max(getCharCount()-1, 0);
      }
    }

    // Return the line delimiter that should be used by the StyledText widget when inserting new lines.
    public String getLineDelimiter()
    {
      return model.lineDelimiter();
    }

    // Returns a string representing the content at the given range.
    public String getTextRange(int start, int len)
    {
      return model.textRange(start, len);
    }

    // Replace the text with "newText" starting at position "start" for a length of "len".
    public void replaceTextRange(int start, int len, String newText)
    {
      model.modify(start, len, newText);
    }

    // Set text to "text".
    public void setText(String text)
    {
      model.text(text);
    }

    // Called by StyledText to add itself as an Observer to content changes.
    public void addTextChangeListener(TextChangeListener listener)
    {
      listeners.add(listener);

      TextChangedEvent event = new TextChangedEvent(this);
      for (int i=0; i<listeners.size(); ++i)
        ((TextChangeListener)listeners.get(i)).textSet(event);
    }

    // Remove the specified text changed listener.
    public void removeTextChangeListener(TextChangeListener listener)
    {
      listeners.remove(listener);
    }

    private void fireTextChanging(TextChangingEvent e)
    {
      for (int i=0; i<listeners.size(); ++i)
        ((TextChangeListener)listeners.get(i)).textChanging(e);
    }

    private void fireTextChanged(TextChangedEvent e)
    {
      for (int i=0; i<listeners.size(); ++i)
        ((TextChangeListener)listeners.get(i)).textChanged(e);
    }

    ArrayList listeners = new ArrayList();
  }

//////////////////////////////////////////////////////////////////////////
// Styling
//////////////////////////////////////////////////////////////////////////

  public void lineGetStyle(LineStyleEvent event)
  {
    RichText self = (RichText )this.self;
    Fwt fwt = Fwt.get();
    int lineOffset = event.lineOffset;
    int lineLen = event.lineText.length();
    Font defFont = fwt.font(self.font());

    // get Int/RichTextStyle list where Int is offset in line
    List list = model.lineStyling(model.lineAtOffset(lineOffset));
    if (list == null) return;

    // map Int/RichTextStyle list to StyleRange array
    int num = list.sz()/2;
    StyleRange[] results = event.styles = new StyleRange[num];
    for (int i=0; i<num; ++i)
    {
      Long offsetInLine = (Long)list.get(i*2);
      RichTextStyle s = (RichTextStyle)list.get(i*2+1);
      results[i] = toStyleRange(fwt, s, lineOffset+offsetInLine.intValue(), defFont);
      if (i > 0) results[i-1].length = results[i].start - results[i-1].start;
    }
    if (num > 0)
      results[num-1].length = lineLen - (results[num-1].start - lineOffset);
  }

  StyleRange toStyleRange(Fwt fwt, RichTextStyle s, int start, Font defFont)
  {
    StyleRange r = new StyleRange();
    r.start          = start;
    r.foreground     = fwt.color(s.fg);
    r.background     = fwt.color(s.bg);
    r.font           = fwt.font(s.font);
    if (r.font == null) r.font = defFont;
    if (s.underline != null && s.underline != RichTextUnderline.none)
    {
      r.underline = true;
      r.underlineStyle = underlineStyle(s.underline);
      if (s.underlineColor == null)
        r.underlineColor = r.foreground;
      else
        r.underlineColor = fwt.color(s.underlineColor);
    }
    return r;
  }

  int underlineStyle(RichTextUnderline u)
  {
    if (u == RichTextUnderline.single)   return SWT.UNDERLINE_SINGLE;
    if (u == RichTextUnderline.squiggle) return SWT.UNDERLINE_SQUIGGLE;
    throw new IllegalStateException();
  }

  public void lineGetBackground(LineBackgroundEvent event)
  {
    Color bg = model.lineBackground(model.lineAtOffset(event.lineOffset));
    if (bg != null) event.lineBackground = Fwt.get().color(bg);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private StyledText styledText() { return (StyledText)control; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  RichTextModel model;
  Content content;
  int oldCaretPos;
}