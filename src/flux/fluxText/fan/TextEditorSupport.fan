//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Sep 08  Brian Frank  Creation
//

using fwt
using flux

**
** TextEditorSupport provides a bunch of convience methods
**
internal mixin TextEditorSupport
{

  abstract TextEditor editor()

  Frame frame() { return editor.frame }

  TextEditorOptions options() { return editor.options }

  SyntaxOptions syntax() { return editor.syntax }

  SyntaxRules rules() { return editor.rules }

  TextEditorController controller() { return editor.controller }

  RichText richText() { return editor.richText }

  Doc doc() { return editor.doc }

}