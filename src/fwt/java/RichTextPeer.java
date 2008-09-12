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
import fanx.util.OpUtil;
import org.eclipse.swt.*;
import org.eclipse.swt.custom.*;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.events.*;

public class RichTextPeer
  extends TextWidgetPeer
  implements LineStyleListener, VerifyKeyListener, VerifyListener,
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
    if (model == null) throw Err.make("RichText.model is null").val;

    int style = self.multiLine.val ? SWT.MULTI: SWT.SINGLE;
    if (self.border.val)   style |= SWT.BORDER;
    if (self.wrap.val)     style |= SWT.WRAP;
    if (self.hscroll.val)  style |= SWT.H_SCROLL;
    if (self.vscroll.val)  style |= SWT.V_SCROLL;

    StyledText t = new StyledText((Composite)parent, style);
    control = t;
    t.setContent(content = new Content());
    t.addLineStyleListener(this);
    t.addTraverseListener(this);
    t.addVerifyKeyListener(this);
    t.addVerifyListener(this);
    t.addSelectionListener(this);

    // this is a hack, but seems to be the only way to set
    // the margins hidden away as private fields in StyledText
    setField(t, "leftMargin",   8);
    setField(t, "topMargin",    8);
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

  Prop.IntProp caretPos() { return caretPos; }
  public final Prop.IntProp caretPos = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((StyledText)w).getCaretOffset(); }
    public void set(final Widget w, final int v)
    {
      // for whatever reason this call only works if used in an
      // async action; found this tip on the discussion group:
      // http://dev.eclipse.org/newslists/news.eclipse.platform.swt/msg26461.html
      Env.get().display.asyncExec(new Runnable()
      {
        public void run() { ((StyledText)w).setCaretOffset(v); }
      });
    }
  };

  Prop.FontProp font() { return font; }
  public final Prop.FontProp font = new Prop.FontProp(this)
  {
    public void set(Widget w, Font v) { ((StyledText)w).setFont(v); }
  };

  // Int tabSpacing := 2
  public Int tabSpacing(RichText self) { return tabSpacing.get(); }
  public void tabSpacing(RichText self, Int v) { tabSpacing.set(v); }
  public final Prop.IntProp tabSpacing = new Prop.IntProp(this, 2)
  {
    public int get(Widget w) { return ((StyledText)w).getTabs(); }
    public void set(Widget w, int v) { ((StyledText)w).setTabs(v);  }
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

  public void repaintRange(RichText self, Int start, Int len)
  {
    if (control == null) return;
    ((StyledText)control).redrawRange((int)start.val, (int)len.val, false);
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
  }

  public void verifyText(VerifyEvent se)
  {
    RichText self = (RichText)this.self;
    List cbs = self.onVerify().list();
    if (cbs.isEmpty().val) return;

    TextChange tc = TextChange.make();
    tc.startOffset = Int.make(se.start);
    tc.startLine   = model.lineAtOffset(tc.startOffset);
    tc.oldText     = model.textRange(tc.startOffset, Int.make(se.end-se.start));
    tc.newText     = Str.make(se.text);

    fan.fwt.Event fe = event(EventId.verify, tc);
    Str origNewText = tc.newText;

    for (int i=0; i<cbs.sz(); ++i)
    {
      ((Func)cbs.get(i)).call1(fe);
      if (tc.newText != origNewText && OpUtil.compareNEz(tc.newText, origNewText))
      {
        if (tc.newText == null) se.doit = false;
        else se.text = tc.newText.val;
        return;
      }
    }
  }

  public void widgetDefaultSelected(SelectionEvent se) {}

  public void widgetSelected(SelectionEvent se)
  {
    fan.fwt.Event fe = event(EventId.select);
    fe.offset = Int.make(se.x);
    fe.size   = Int.make(se.y - se.x);
    ((RichText)self).onSelect().fire(fe);
  }

  public void checkCaretPos()
  {
    int newCaretPos = ((StyledText)control).getCaretOffset();
    if (newCaretPos == oldCaretPos) return;
    oldCaretPos = newCaretPos;
    fan.fwt.Event fe = event(EventId.caret);
    fe.offset = Int.make(newCaretPos);
    ((RichText)self).onCaret().fire(fe);
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
    te.start            = (int)tc.startOffset.val;
    te.replaceCharCount = (int)tc.oldText.size().val;
    te.replaceLineCount = (int)tc.oldNumNewlines.val;
    te.newText          = tc.newText.val;
    te.newCharCount     = (int)tc.newText.size().val;
    te.newLineCount     = (int)tc.newNumNewlines.val;

    // fire SWT changing event
    content.fireTextChanging(te);

    // if the style of the line immediately after the
    // inserted text has been modified, then do a repaint
    if (tc.repaintLen != null)
    {
      int repaintStart = te.start;
      if (tc.repaintStart != null) repaintStart = (int)tc.repaintStart.val;
      int repaintLen = (int)tc.repaintLen.val;
      styledText.redrawRange(repaintStart, repaintLen, false);
    }

    // fire modified event
    content.fireTextChanged(new TextChangedEvent(content));

    // if onModify callback register, fire event
    if (!self.onModify().isEmpty().val)
    {
      fan.fwt.Event modevt = event(EventId.modified, tc);
      self.onModify().fire(modevt);
    }
  }

  class Content implements StyledTextContent
  {
    // Return the number of characters in the content.
    public int getCharCount()
    {
      return (int)model.charCount().val;
    }

    // Return the number of lines.
    public int getLineCount()
    {
      return (int)model.lineCount().val;
    }

    // Return the line at the given line index without delimiters.
    public String getLine(int lineIndex)
    {
      return model.line(Int.pos(lineIndex)).val;
    }

    // Return the line index at the given character offset.
    public int getLineAtOffset(int offset)
    {
      return (int)model.lineAtOffset(Int.pos(offset)).val;
    }

    // Return the character offset of the first character of the given line.
    public int getOffsetAtLine(int lineIndex)
    {
      return (int)model.offsetAtLine(Int.pos(lineIndex)).val;
    }

    // Return the line delimiter that should be used by the StyledText widget when inserting new lines.
    public String getLineDelimiter()
    {
      return model.lineDelimiter().val;
    }

    // Returns a string representing the content at the given range.
    public String getTextRange(int start, int len)
    {
      return model.textRange(Int.pos(start), Int.pos(len)).val;
    }

    // Replace the text with "newText" starting at position "start" for a length of "len".
    public void replaceTextRange(int start, int len, String newText)
    {
      model.modify(Int.pos(start), Int.pos(len), Str.make(newText));
    }

    // Set text to "text".
    public void setText(String text)
    {
      model.text(Str.make(text));
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
    Env env = Env.get();
    int lineOffset = event.lineOffset;
    int lineLen = event.lineText.length();
    Font defFont = env.font(self.font());

    // get Int/RichTextStyle list where Int is offset in line
    List list = model.lineStyling(model.lineAtOffset(Int.pos(lineOffset)));
    if (list == null) return;

    // map Int/RichTextStyle list to StyleRange array
    int num = list.sz()/2;
    StyleRange[] results = event.styles = new StyleRange[num];
    for (int i=0; i<num; ++i)
    {
      Int offsetInLine = (Int)list.get(i*2);
      RichTextStyle s = (RichTextStyle)list.get(i*2+1);
      results[i] = toStyleRange(env, s, lineOffset+(int)offsetInLine.val, defFont);
      if (i > 0) results[i-1].length = results[i].start - results[i-1].start;
    }
    if (num > 0)
      results[num-1].length = lineLen - (results[num-1].start - lineOffset);
  }

  StyleRange toStyleRange(Env env, RichTextStyle s, int start, Font defFont)
  {
    StyleRange r = new StyleRange();
    r.start          = start;
    r.foreground     = env.color(s.fg);
    r.background     = env.color(s.bg);
    r.font           = env.font(s.font);
    if (r.font == null) r.font = defFont;

    /* waiting for Eclipse 3.4...
    if (s.underlineStyle != null && s.underlineStyle != Int.Zero)
    {
      switch (s.underlineStyle.val)
      {
        case 1: r.underlineStyle = SWT.UNDERLINE_SINGLE;   break;
        case 2: r.underlineStyle = SWT.UNDERLINE_DOUBLE;   break;
        case 3: r.underlineStyle = SWT.UNDERLINE_ERROR;    break;
        case 4: r.underlineStyle = SWT.UNDERLINE_SQUIGGLE; break;
      }
    }
    */

    return r;
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