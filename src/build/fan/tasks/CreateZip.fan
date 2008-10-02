//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Sep 08  Brian Frank  Creation
//

**
** CreateZip is used to create a zip file from a directory on the file system.
**
class CreateZip : Task
{

  new make(BuildScript script)
    : super(script)
  {
    this.filter  = |File f->Bool| { return true }
  }

  override Void run()
  {
    // basic sanity checking
    if (inDir == null) throw fatal("Not configured: CreateZip.inDir")
    if (outFile == null) throw fatal("Not configured: CreateZip.outFile")
    if (!inDir.isDir) throw fatal("Not a directory: $inDir")

    // ensure outFile is not under inDir (although we do allow
    // outFile to be placed directly under inDir as convenience)
    inPath := inDir.normalize.pathStr
    outPath := outFile.normalize.parent.pathStr
    if (outPath.startsWith(inPath) && inPath != outPath)
      throw fatal("Cannot set outFile under inDir: $outPath under $inPath")

    // zip it!
    log.info("CreateZip [$outFile]")
    out := Zip.write(outFile.out)
    try
    {
      inDir.list.each |File f|
      {
        if (f.name == outFile.name) return
        zip(out, f, f.name)
      }
    }
    catch (Err err)
    {
      throw fatal("Cannot create zip [$outFile]", err)
    }
    finally
    {
      if (out != null) out.close
    }
  }

  private Void zip(Zip out, File f, Str path)
  {
    if (!filter.call2(f, path)) return
    if (f.isDir)
    {
      f.list.each |File sub|
      {
        zip(out, sub, path + "/" + sub.name)
      }
    }
    else
    {
      o := out.writeNext(path.toUri, f.modified)
      f.in.pipe(o)
      o.close
    }
  }

  ** Output zip file to create
  File outFile

  ** Directory to zip up.  The contents of this dir are recursively
  ** zipped up with zip paths relative to this root directory.
  File inDir

  ** This function is called on each file under 'inDir'; if true
  ** returned it is included in the zip, if false then it is excluded.
  ** Returning false for a directory will skip recursing the entire
  ** directory.
  |File f, Str path->Bool| filter
}