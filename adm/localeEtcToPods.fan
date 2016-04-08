#! /usr/bin/env fan

//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 May 13  Brian Frank   Creation
//

**
** This script finds all the localization files under etc/*/locale/*.props
** and merges them directly into the lib/fan/*.pod files.  The pod files
** are replaced in-place!
**
class LocaleEtcToPods
{
  static Void main()
  {
    (Env.cur.workDir + `etc/`).listDirs.each |dir|
    {
      // check if locale/ sub-directory exists
      localeDir := dir + `locale/`
      if (!localeDir.exists) return

      // map etc/{pod} to lib/fan/{pod}.pod
      podName := dir.name
      podFile := Env.cur.workDir + `lib/fan/${podName}.pod`
      if (!podFile.exists || podName == "sys") return

      // find locale/*.props files
      props := localeDir.listFiles.findAll |f| { f.ext == "props" }
      if (props.isEmpty) return

      // we have files to merge!
      echo("Adding $props.size props files to $podFile ...")

      // unzip the pod file to a temp directory
      tempFilename := "temp-$podName" + DateTime.now.toLocale("YYMMDD-hhmmss")
      tempDir := Env.cur.tempDir + `${tempFilename}-dir/`
      zip := Zip.open(podFile)
      zip.contents.each |f| { f.copyTo(tempDir + f.pathStr[1..-1].toUri) }
      zip.close

      // copy props we found
      props.each |f| { f.copyTo(tempDir + `locale/$f.name`, ["overwrite":true]) }

      // re-zip up the pod file
      tempZipFile := Env.cur.tempDir+`${tempFilename}.pod`
      tempZip := Zip.write(tempZipFile .out)
      tempDir.walk |f|
      {
        if (f.isDir) return
        out := tempZip.writeNext(f.pathStr[tempDir.pathStr.size..-1].toUri, f.modified)
        f.in.pipe(out)
        out.close
      }
      tempZip.close

      // copy back to lib
      echo("  Replacing $podFile.name $podFile.size bytes with $tempZipFile.size bytes")
      tempZipFile.copyTo(podFile, ["overwrite":true])
    }
  }
}