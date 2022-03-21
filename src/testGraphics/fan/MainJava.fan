//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

using [java] java.lang::Runnable
using [java] java.awt.event
using [java] java.awt::BorderLayout
using [java] java.awt::EventQueue
using [java] java.awt::FlowLayout
using [java] java.awt::Frame
using [java] java.awt::Canvas
using [java] java.awt::Graphics as AwtGraphics
using [java] java.awt::GraphicsEnvironment
using [java] javax.swing::JComboBox
using [java] javax.swing::JFrame
using [java] javax.swing::JPanel
using concurrent
using graphics
using graphicsJava

class MainJava
{
  static Void run(Str? typeName)
  {
    GraphicsEnv.install(Java2DGraphicsEnv())
    EventQueue.invokeLater(JCanvas(typeName))
    Actor.sleep(Duration.maxVal)
  }

  static Void listFonts()
  {
    fonts := GraphicsEnvironment.getLocalGraphicsEnvironment.getAvailableFontFamilyNames
    fonts.sort
    echo(fonts.join("\n"))
  }
}


internal class JCanvas : Canvas, Runnable, WindowListener, ItemListener
{
  new make(Str? typeName)
  {
    this.typeName = typeName ?: BasicsTest#.name
  }

  override Void run()
  {
    typeNames := AbstractTest.list.map |t->Str| { t.name }
    typeNames.moveTo(BasicsTest#.name, 0)
    combo := JComboBox(typeNames)
    combo.addItemListener(this)

    toolbar := JPanel()
    toolbar.setLayout(FlowLayout(FlowLayout.LEADING))
    toolbar.add(combo)

    f := JFrame("Graphics Test")
    f.getContentPane().add(toolbar, BorderLayout.NORTH)
    f.setBounds(100, 100, 1000, 800+28)
    f.getContentPane().add(this, BorderLayout.CENTER)
    f.setVisible(true)
    f.addWindowListener(this)

    combo.setSelectedItem(typeName)
  }

  override Void itemStateChanged(ItemEvent? e)
  {
    type := typeof.pod.type(e.getItem)
    test = type.make
    repaint
  }

  override Void windowActivated(WindowEvent? e) {}
  override Void windowClosed(WindowEvent? e) {}
  override Void windowClosing(WindowEvent? e) { Env.cur.exit(0) }
  override Void windowDeactivated(WindowEvent? e) {}
  override Void windowDeiconified(WindowEvent? e) {}
  override Void windowIconified(WindowEvent? e) {}
  override Void windowOpened(WindowEvent? e) {}

  override Void paint(AwtGraphics? g)
  {
    test.paint(Size(getSize.width, getSize.height), Java2DGraphics(g))
  }

  private Str typeName
  AbstractTest test := BasicsTest()
}