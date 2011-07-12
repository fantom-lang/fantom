//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** Command implements a top-level command in the fanr command line tool.
**
** Commands declare their options using the `CommandOpt` facet which
** works similiar to `util::AbstractMain`.  If the field is a Bool, then
** the option is treated as a flag option.  Otherwise it must be one of
** these types: Str, Uri.
**
abstract class Command
{

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  ** Name of command
  abstract Str name()

  ** Short summary of command for usage screen
  abstract Str summary()

  ** Execute command.  If there is a failure then throw `err`,
  ** otherwise the command is assumed to be successful.
  abstract Void run()

//////////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////////

  ** Stdout for printing command output
  OutStream out := Env.cur.out

  ** Log a warning to `out`
  Void warn(Str msg)
  {
    out.printLine("WARN: $msg")
  }

  ** Throw an exception which may be used to unwind the stack
  ** back to main to indicate command failed and return non-zero
  Err err(Str msg, Err? cause := null)
  {
    return CommandErr(msg, cause)
  }

  ** Ask for y/n confirmation or skip if '-y' option specified.
  Bool confirm(Str msg)
  {
    if (skipConfirm) return true
    out.printLine
    out.print("$msg [y/n]: ").flush
    r := Env.cur.in.readLine
    return r.lower.startsWith("y")
  }

  ** Pretty print a pod versions to output stream
  internal Void printPodVersion(PodSpec version)
  {
    printPodVersions([version])
  }

  ** Pretty print a list of pod versions (of same pod) to output stream
  internal Void printPodVersions(PodSpec[] versions)
  {
    top := versions.sortr.first

    // ensure summary isn't too long
    summary := top.summary
    if (summary.size > 100) summary = summary[0..100] + "..."

    // figure out alignment padding for versions
    verPad := 6
    versions.each |x| { verPad = verPad.max(x.version.toStr.size) }

    // print it
    out.printLine(top.name)
    out.printLine("  $summary")
    versions.each |x|
    {
      // build details as "ts, size"
      details := StrBuf()
      if (x.ts != null) details.join(x.ts.date.toLocale("DD-MMM-YYYY"), ", ")
      if (x.size != null) details.join(x.size.toLocale("B"), ", ")

      // print version info line
      verStr := x.version.toStr.padr(verPad)
      out.printLine("  $verStr ($details)")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Global Options
//////////////////////////////////////////////////////////////////////////

  ** Repository URI -r option
  @CommandOpt
  {
    name   = "r"
    help   = "Repository URI for command"
    config = "repo"
  }
  Uri? repoUri

  ** Get the repo to use for this command:
  **   - default is config prop "repo"
  **   - override with "-r" option
  once Repo repo()
  {
    if (repoUri == null)
      throw err("No repoUri available: use -r or set 'repo' in etc/fanr/config.props")

    try
      return Repo.makeForUri(repoUri, username, password)
    catch (Err e)
      throw err("Cannot init repo: $repoUri", e)
  }

  ** Get the local environment to use this command
  once FanrEnv env() { FanrEnv() }

  ** Option to dump full stack trace on errors
  @CommandOpt
  {
    name   = "errTrace"
    help   = "Dump error stack traces"
  }
  Bool errTrace

  ** Option to skip confirmation (auto yes)
  @CommandOpt
  {
    name   = "y"
    help   = "Skip confirmation"
  }
  Bool skipConfirm

  ** Username for authentication
  @CommandOpt
  {
    name   = "u"
    help   = "Username for authentication"
    config = "username"
  }
  Str? username

  ** Password for authentication
  @CommandOpt
  {
    name   = "p"
    help   = "Password for authentication"
    config = "password"
  }
  Str? password

//////////////////////////////////////////////////////////////////////////
// Initialization
//////////////////////////////////////////////////////////////////////////

  internal Bool init(Str[] args)
  {
    initOptsFromConfig
    if (!parseArgs(args)) return false
    promptPassword
    return true
  }

  private Void initOptsFromConfig()
  {
    optFields.each |field|
    {
      val := optDefault(field)
      field.set(this, val)
    }
  }

  private Obj? optDefault(Field field)
  {
    def := field.get(this)
    CommandOpt facet := field.facet(CommandOpt#)
    if (facet.config != null)
    {
      config := Command#.pod.config(facet.config)
      if (config != null)
      {
        try
          def = parseVal(field.type, config)
        catch (Err e)
        err("Invalid config value for '$facet.config': $config")
      }
    }
    return def
  }

  private Bool parseArgs(Str[] toks)
  {
    args := argFields
    opts := optFields
    varArgs := !args.isEmpty && args.last.type.fits(List#)
    argi := 0
    for (i:=0; i<toks.size; ++i)
    {
      tok := toks[i]
      Str? next := i+1 < toks.size ? toks[i+1] : null
      if (tok.startsWith("-"))
      {
        if (parseOpt(opts, tok, next)) ++i
      }
      else if (argi < args.size)
      {
        if (parseArg(args[argi], tok)) ++argi
      }
      else
      {
        warn("Unexpected arg: $tok")
      }
    }
    if (argi == args.size) return true
    if (argi == args.size-1 && varArgs) return true

    // // missing args
    usage
    out.printLine
    out.printLine("Missing arguments")
    return false
  }

  private Field[] argFields()
  {
    Type.of(this).fields.findAll |f| { f.hasFacet(CommandArg#) }
  }

  private Field[] optFields()
  {
    Type.of(this).fields.findAll |f| { f.hasFacet(CommandOpt#) }
  }

  private Bool parseOpt(Field[] opts, Str tok, Str? next)
  {
    n := tok[1..-1]
    for (i:=0; i<opts.size; ++i)
    {
      // if name doesn't match opt or any of its aliases then continue
      field := opts[i]
      facet := (CommandOpt)field.facet(CommandOpt#)
      if (facet.name != n) continue

      // if field is a bool we always assume the true value
      if (field.type == Bool#)
      {
        field.set(this, true)
        return false // did not consume next
      }

      // check that we have a next value to parse
      if (next == null || next.startsWith("-"))
      {
        err("Missing value for -$n")
        return false // did not consume next
      }

      try
      {
        // parse the value to proper type and set field
        field.set(this, parseVal(field.type, next))
      }
      catch (Err e) err("Cannot parse -$n as $field.type.name: $next")
      return true // we *did* consume next
    }

    warn("Unknown option -$n")
    return false // did not consume next
  }

  private Bool parseArg(Field field, Str tok)
  {
    isList := field.type.fits(List#)
    try
    {
      // if not a list, this is easy
      if (!isList)
      {
        field.set(this, parseVal(field.type, tok))
        return true // increment argi
      }

      // if list, then parse list item and add to end of list
      of := field.type.params["V"]
      val :=  parseVal(of, tok)
      list := field.get(this) as Obj?[]
      if (list == null) field.set(this, list = List.make(of, 8))
      list.add(val)
    }
    catch (Err e) err("Cannot parse argument as $field.type.name: $tok")
    return !isList // increment argi if not list
  }

  private static Obj? parseVal(Type of, Str tok)
  {
    of = of.toNonNullable
    if (of == Str#) return tok
    if (of == File#) return parsePath(tok)
    return of.method("fromStr").call(tok)
  }

  internal static File parsePath(Str path)
  {
    if (path.contains("\\"))
      return File.os(path).normalize
    else
      return File.make(path.toUri, false)
  }

  private Void promptPassword()
  {
    // if we have a username, but no password then prompt for it
    if (username != null && password == null)
      password = Env.cur.promptPassword("Password for '$username'>")
  }

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  ** Print usage to given output stream
  virtual Void usage(OutStream out := this.out)
  {
    // get list of argument and option fields
    args := argFields
    opts := optFields

    // format args/opts into columns
    argRows := usagePad(args.map |f| { usageArg(f) })
    optRows := usagePad(opts.map |f| { usageOpt(f) })

    // format summary line
    argSummary := args.join(" ") |field|
    {
      CommandArg facet := field.facet(CommandArg#)
      s := "<" + facet.name + ">"
      if (field.type.fits(List#)) s += "*"
      return s
    }

    out.printLine("Summary:")
    out.printLine("  $summary")
    out.printLine("Usage:")
    out.printLine("  fanr $name [options] $argSummary")
    usagePrint(out, "Arguments:", argRows)
    usagePrint(out, "Options:", optRows)
  }

  private Str[] usageArg(Field field)
  {
    CommandArg facet := field.facet(CommandArg#)
    return [facet.name, facet.help]
  }

  private Str[] usageOpt(Field field)
  {
    CommandOpt facet := field.facet(CommandOpt#)
    name := facet.name
    def  := optDefault(field)
    help := facet.help

    col1 := "-$name"
    if (def != false) col1 += " <$field.type.name>"

    col2 := help
    if (def != false && def != null) col2 += " (default $def)"

    return [col1, col2]
  }

  private Str[][] usagePad(Str[][] rows)
  {
    if (rows.isEmpty) return rows
    Int max := rows.map |row| { row[0].size }.max
    pad := 20.min(2 + max)
    rows.each |row| { row[0] = row[0].padr(pad) }
    return rows
  }

  private Void usagePrint(OutStream out, Str title, Str[][] rows)
  {
    if (rows.isEmpty) return
    out.printLine(title)
    rows.each |row| { out.printLine("  ${row[0]}  ${row[1]}") }
  }

}

**************************************************************************
** CommandErr
**************************************************************************

**
** CommandErr is used to unwind the stack back to main
**
internal const class CommandErr : Err
{
  new make(Str msg, Err? cause) : super(msg, cause) {}
}

**************************************************************************
** CommandArg
**************************************************************************

**
** Facet for annotating an `Command` argument field.
**
facet class CommandArg
{
  ** Name of the argument
  const Str name

  ** Usage help, should be a single short line summary
  const Str help
}

**************************************************************************
** CommandOpt
**************************************************************************

**
** Facet for annotating an `Command` option field.
**
facet class CommandOpt
{
  ** Name of option to use on command line
  const Str name

  ** Usage help, should be a single short line summary
  const Str help

  ** Property name to use to initialize from fanr config
  const Str? config
}

