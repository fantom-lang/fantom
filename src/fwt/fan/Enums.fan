//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//

**************************************************************************
** Halign
**************************************************************************

**
** Horizontal alignment: left, center, right, or fill.
**
@javascript
enum Halign
{
  left,
  center,
  right,
  fill
}

**************************************************************************
** Valign
**************************************************************************

**
** Vertical alignment: top, center, bottom, or fill.
**
@javascript
enum Valign
{
  top,
  center,
  bottom,
  fill
}

**************************************************************************
** Orientation.
**************************************************************************

**
** Horizontal or vertical.
**
@javascript
enum Orientation
{
  horizontal,
  vertical
}

**************************************************************************
** CommandMode.
**************************************************************************

**
** Enum for `Command.mode`.
**
@javascript
enum CommandMode
{
  push,
  toggle

  ButtonMode toButtonMode()
  {
    return this == push ? ButtonMode.push : ButtonMode.toggle
  }

  MenuItemMode toMenuItemMode()
  {
    return this == push ? MenuItemMode.push : MenuItemMode.check
  }
}

**************************************************************************
** ButtonMode.
**************************************************************************

**
** Enum for `Button.mode`.
**
@javascript
enum ButtonMode
{
  check,
  push,
  radio,
  toggle,
  sep
}

**************************************************************************
** MenuMode.
**************************************************************************

**
** Enum for `MenuItem.mode`.
**
@javascript
enum MenuItemMode
{
  check,
  push,
  radio,
  sep,
  menu
}

**************************************************************************
** WindowMode.
**************************************************************************

**
** Enum for `Window.mode`.
**
@javascript
enum WindowMode
{
  modeless,
  windowModal,
  appModal,
  sysModal
}

**************************************************************************
** FileDialogMode.
**************************************************************************

**
** Enum for `FileDialog.mode`.
**
@javascript
enum FileDialogMode
{
  ** Display open dialog for single file
  openFile,
  ** Display open dialog for multiple files
  openFiles,
  ** Display save dialog for single file
  saveFile,
  ** Display open directory dialog
  openDir
}