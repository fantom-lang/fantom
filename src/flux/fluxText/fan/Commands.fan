//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Sep 08  Brian Frank  Creation
//

using fwt
using flux

internal class TextEditorCommand : FluxCommand
{
  new make(TextEditor editor, Str id)
    : super(id, type.pod)
  {
    this.editor = editor
  }

  TextEditorController controller() { return editor.controller }

  RichText richText() { return editor.richText }

  Doc doc() { return editor.doc }

  readonly TextEditor editor
}

**************************************************************************
** TextChangeCommand
**************************************************************************

internal class TextChangeCommand : TextEditorCommand
{
  new make(TextEditor editor, TextChange change)
    : super(editor, "textChange")
  {
    this.change = change
  }

  override Void redo()
  {
    controller.inUndo = true
    try
      change.redo(richText)
    finally
      controller.inUndo = false
  }

  override Void undo()
  {
    controller.inUndo = true
    try
      change.undo(richText)
    finally
      controller.inUndo = false
  }

  TextChange change
}
