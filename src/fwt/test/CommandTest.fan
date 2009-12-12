//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 08  Brian Frank  Creation
//

**
** CommandTest
**
class CommandTest : Test
{

  Void testBinding()
  {
    count := 0
    c := Command("Foo", null) |->| { count++ }
    m := MenuItem { command = c }
    verifyEq(m.text, "Foo")
    verifyEq(m.enabled, true)
    verifyEq(c.widgets, Widget[m])

    c.enabled = false
    verifyEq(m.enabled, false)

    b := Button { command = c }
    verifyEq(b.text, "Foo")
    verifyEq(b.enabled, false)
    verifyEq(c.widgets, Widget[m, b])

    c.enabled = true
    verifyEq(m.enabled, true)
    verifyEq(b.enabled, true)

    m.command = null
    verifyEq(c.widgets, Widget[b])
  }

  Void testStack()
  {
    Command a := TestCommand("a")
    Command b := TestCommand("b")
    Command c := TestCommand("c")
    Command d := TestCommand("d")

    s := CommandStack()
    verifyEq(s.hasUndo, false); verifyEq(s.hasRedo, false)

    s.push(a)
    verifyEq(s.hasUndo, true); verifyEq(s.hasRedo, false)
    verifyEq(s.listUndo, [a]); verifyEq(s.listUndo.isRO, true)

    s.push(b)
    verifyEq(s.hasUndo, true); verifyEq(s.hasRedo, false)
    verifyEq(s.listUndo, [a, b])

    s.push(c).push(d)
    verifyEq(s.hasUndo, true); verifyEq(s.hasRedo, false)
    verifyEq(s.listUndo, [a, b, c, d])

    verifySame(s.undo, d); verifyEq(d->undone, 1)
    verifyEq(s.hasUndo, true); verifyEq(s.hasRedo, true)
    verifyEq(s.listUndo, [a, b, c]); verifyEq(s.listRedo, [d])

    verifySame(s.undo, c); verifyEq(c->undone, 1)
    verifyEq(s.hasUndo, true); verifyEq(s.hasRedo, true)
    verifyEq(s.listUndo, [a, b]); verifyEq(s.listRedo, [d, c])

    verifySame(s.redo, c); verifyEq(c->invokedCount, 1)
    verifyEq(s.hasUndo, true); verifyEq(s.hasRedo, true)
    verifyEq(s.listUndo, [a, b, c]); verifyEq(s.listRedo, [d])

    verifySame(s.redo, d); verifyEq(d->invokedCount, 1)
    verifyEq(s.hasUndo, true); verifyEq(s.hasRedo, false)
    verifyEq(s.listUndo, [a, b, c, d]); verifyEq(s.listRedo, Command[,])

    s.clear
    verifyEq(s.hasUndo, false); verifyEq(s.hasRedo, false)
    verifyEq(s.undo, null)
    verifyEq(s.redo, null)
  }

}

internal class TestCommand : Command
{
  new make(Str name) : super(name) {}

  override Void invoked(Event? e) { invokedCount++ }
  override Void undo() { undone++ }

  Int invokedCount := 0
  Int undone := 0
}