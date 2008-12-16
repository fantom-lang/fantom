#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Dec 08  Brian Frank  Creation
//

using [java] javax.swing
using [java] java.awt.event

**
** Simple Swing app using Java FFI
**
class SwingDemo
{

  Void main()
  {
    frame := JFrame("Hello Swing")

    button := JButton("Click Me")
    button.addActionListener(Handler.make |ActionEvent e|
    {
      JOptionPane.showMessageDialog(null,
            "<html>Hello from <b>Java</b><br/>" +
            "Button $e.getActionCommand pressed")
    })

    frame.getContentPane.add(button)
    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE)
    frame.setBounds(100, 100, 200, 200)
    frame.setVisible(true)

    Thread.sleep(9999day) // Fan launcher exits if this thread exists
  }

}

class Handler : ActionListener
{
  new make(|ActionEvent| cb) { this.cb = cb }
  override Void actionPerformed(ActionEvent? e) { cb.call1(e) }
  |ActionEvent| cb
}