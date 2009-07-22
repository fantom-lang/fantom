//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 06  Brian Frank  Creation
//

**
** ProcessTest
**
class ProcessTest : Test
{

  Void testDefaults()
  {
    p := Process()
    verify(p.mergeErr)
    verify(p.env.size > 0)
    verifySame(p.out, Sys.out)
    verifySame(p.err, Sys.err)
    verifySame(p.in, null)
  }

  Void testStdMerged()
  {
    proc := makeProc
    proc.run
    verifyEq(proc.join, 7)
    verifyErr(Err#) |,| { proc.run }
  }

  Void testStdSeparate()
  {
    proc := makeProc { mergeErr=false }
    proc.run
    verifyEq(proc.join, 7)
    verifyErr(Err#) |,| { proc.dir=null }
    verifyErr(Err#) |,| { proc.out=null }
    verifyErr(Err#) |,| { proc.err=null }
    verifyErr(Err#) |,| { proc.in=null }
    verifyErr(Err#) |,| { proc.run }
  }

  Void testStrMerged()
  {
    bufOut := Buf()
    proc := makeProc(["a", "b"]) { out = bufOut.out }
    verifyEq(proc.run.join, 7)
    lines := bufOut.flip.readAllLines
    verifyEq(lines.size, 2)
    verifyEq(lines[0].split, ["ProcessTest.out", "a", "b"])
    verifyEq(lines[1].split, ["ProcessTest.err", "a", "b"])
  }

  Void testStrSeparate()
  {
    bufOut := Buf()
    bufErr := Buf()
    proc := makeProc(["a", "b"]) { mergeErr=false; out = bufOut.out; err=bufErr.out }
    verifyEq(proc.run.join, 7)
    outLines := bufOut.flip.readAllLines
    errLines := bufErr.flip.readAllLines
    verifyEq(outLines.size, 1)
    verifyEq(errLines.size, 1)
    verifyEq(outLines[0].split, ["ProcessTest.out", "a", "b"])
    verifyEq(errLines[0].split, ["ProcessTest.err", "a", "b"])
  }

  Void testNullOut()
  {
    proc := makeProc { out = null }
    verifyEq(proc.run.join, 7)
  }

  Void testIn()
  {
    buf := Buf()
    proc := makeProc(["echoStdIn"])
    {
      out = buf.out
      in = Buf().printLine("Test stdin").flip.in
    }
    proc.run.join
    str := buf.flip.readAllStr.trim
    verifyEq(str, "Test stdin")
  }

  Void testEnv()
  {
    buf := Buf()
    proc := makeProc(["printEnv", "fan_process_test"])
    {
      out = buf.out
      env["fan_process_test"] = "Test env"
    }
    proc.run.join
    verifyEq(buf.flip.readAllStr.trim, "Test env")
  }

  Process makeProc(Str[] args := Str[,])
  {
    cmd := (Repo.boot.home + (isWindows ? `bin/fan.exe` : `bin/fan`)).osPath
    return Process([cmd, type.qname].addAll(args))
  }

  Bool isWindows() { return Sys.env["os.name"].lower.contains("win") }

//////////////////////////////////////////////////////////////////////////
// Process Spawned
//////////////////////////////////////////////////////////////////////////

  static Int main(Str[] args)
  {
    if (args.size > 0)
    {
      m := ProcessTest#.method(args.first, false)
      if (m != null) return m.call(args[1..-1])
    }
    Sys.out.printLine("     ProcessTest.out " + args.join(" ")).flush
    Sys.err.printLine("     ProcessTest.err " + args.join(" ")).flush
    return 7
  }

  static Int printEnv(Str[] args)
  {
    Sys.out.printLine("     " + Sys.env[args.first]).flush
    return 0
  }

  static Int echoStdIn(Str[] args)
  {
    line := Sys.in.readLine
    Sys.out.printLine("     $line").flush
    return 0
  }

}