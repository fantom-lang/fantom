//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Nov 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.DirectoryDialog;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.custom.SashForm;

public class FileDialogPeer
{

  public static FileDialogPeer make(fan.fwt.FileDialog self)
    throws Exception
  {
   return new FileDialogPeer();
  }

  public Object open(fan.fwt.FileDialog self, Window parent)
  {
    Shell parentShell = parent == null ? null : (Shell)parent.peer.control;

    FileDialog fd = null;
    DirectoryDialog dd = null;
    if (self.mode == FileDialogMode.openFile) fd = new FileDialog(parentShell, SWT.OPEN);
    else if (self.mode == FileDialogMode.openFiles) fd = new FileDialog(parentShell, SWT.OPEN|SWT.MULTI);
    else if (self.mode == FileDialogMode.saveFile) fd = new FileDialog(parentShell, SWT.SAVE);
    else if (self.mode == FileDialogMode.openDir) dd = new DirectoryDialog(parentShell);
    else throw new IllegalStateException(""+self.mode);

    if (fd != null)
    {
      if (self.name != null) fd.setFileName(self.name);
      if (self.dir != null) fd.setFilterPath(self.dir.osPath());
      if (self.filterExts != null) fd.setFilterExtensions(self.filterExts.toStrings());
      String r = fd.open();
      if (r == null) return null;
      if (self.mode != FileDialogMode.openFiles)
        return toFile(r);
      else
        return toFiles(fd.getFilterPath(), fd.getFileNames());
    }
    else
    {
      if (self.dir != null) dd.setFilterPath(self.dir.osPath());
      String r = dd.open();
      if (r == null) return null;
      return toFile(r);
    }
  }

  static File toFile(String path)
  {
    return File.os(path);
  }

  static List toFiles(String base, String[] paths)
  {
    File baseFile = toFile(base);
    List list = new List(Sys.FileType, paths.length);
    for (int i=0; i<paths.length; ++i)
      list.add(baseFile.plus(Uri.fromStr(paths[i])));
    return list;
  }


}