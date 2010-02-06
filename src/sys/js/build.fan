#! /usr/bin/env fansubstitute
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

using build

class Build : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Compile javascript for sys pod" }
  Void compile()
  {
    log.info("compile [js]")

    sys   = scriptFile.parent + `fan/`
    fanx  = scriptFile.parent + `fanx/`
    types = Pod.find("sys").types

    tempDir := scriptFile.parent + `temp-js/`
    tempDir.delete
    tempDir.create

    lib := tempDir.createFile("sys.js")
    out := lib.out
    writeSys(out)
    writeFanx(out)
    writeTypeInfo(out)
    writeSysSupport(out)
    out.close

    // add into pod file
    jar := JdkTask.make(this).jarExe
    pod := devHomeDir + `lib/fan/sys.pod`
    Exec.make(this, [jar, "fu", pod.osPath, "-C", tempDir.osPath, "."], tempDir).run

    tempDir.delete
  }

  private Void writeSys(OutStream out)
  {
    log.debug("  fan/")
    types.each |t|
    {
      f := sys + `${t.name}.js`
      if (f.exists) append(f, out)
    }
  }

  private Void writeTypeInfo(OutStream out)
  {
    log.debug("  TypeInfo")

    out.printLine("with (fan.sys.Pod.\$add('sys'))")
    out.printLine("{")

    // filter out synthetic types from reflection
    reflect := types.findAll |t|
    {
      if (t.isSynthetic) return false
      if (t.fits(Err#)) return true
      return (sys+`${t.name}.js`).exists
    }

    // Obj and Type must be defined first
    i := reflect.index(Type#)
    reflect.insert(1, reflect.removeAt(i))

    // write all types first
    reflect.each |t|
    {
      adder  := t.isMixin ? "\$am" : "\$at"
      base   := t.base == null ? "null" : "'$t.base.qname'"
      mixins := t.mixins.join(",") |m| { "'$m.pod::$m.name'" }
      flags  := t->flags
      out.printLine("  fan.sys.${t.name}.\$type = $adder('$t.name',$base,[$mixins],$flags);")
    }

    // then write slot info
    reflect.each |t|
    {
      if (t.fields.isEmpty && t.methods.isEmpty) return
      out.print("  fan.sys.${t.name}.\$type")
      t.fields.each |f| { out.print(".\$af('$f.name',${f->flags},'$f.type.signature')") }
      t.methods.each |m| { out.print(".\$am('$m.name',${m->flags})") }
      out.printLine(";")
    }

    out.printLine("}")
  }

  private Void writeSysSupport(OutStream out)
  {
    log.debug("  fan/ [support]")
    append(sys + `FConst.js`, out)
    append(sys + `MemBufStream.js`, out)
    append(sys + `Md5.js`, out)
    append(sys + `ObjUtil.js`, out)
    append(sys + `Sha1.js`, out)
    append(sys + `StrInStream.js`, out)
    append(sys + `staticInit.js`, out)
    append(sys + `timezones.js`, out)
  }

  private Void writeFanx(OutStream out)
  {
    log.debug("  fanx/")
    fanx.listFiles.each |f| { append(f, out) }
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Delete all intermediate and target files" }
  Void clean()
  {
    log.info("clean [js]")
    Delete.make(this, scriptFile.parent + `temp-js/`).run
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Run clean, compile" }
  Void full()
  {
    clean
    compile
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  Void append(File f, OutStream out)
  {
    log.debug("    $f.name")

    inBlock := false
    f.readAllLines.each |Str line|
    {
      s := line
      // line comments
      i := s.index("//")
      if (i != null)
      {
        // skip uris
        if (i==0 || s[i-1] != ':') s = s[0..<i]
      }
      // block comments
      temp := s
      a := temp.index("/*")
      if (a != null)
      {
        s = temp[0..<a]
        inBlock = true
      }
      if (inBlock)
      {
        b := temp.index("*/")
        if (b != null)
        {
          s = (a == null) ? temp[b+2..-1] : s + temp[b+2..-1]
          inBlock = false
        }
      }
      // trim and print
      s = s.trim
      if (inBlock) return
      if (s.size == 0) return
      out.printLine(s)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  File? sys      // sys/fan/ dir
  File? fanx     // sys/fanx/ dir
  Type[]? types  // types to emit

}