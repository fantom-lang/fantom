//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2010  Andy Frank  Creation
//   20 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * LogRec.
 */
class LogRec extends Obj {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(time, level, logName, msg, err=null) {
    super();
    this.time$ = time;
    this.level$ = level;
    this.logName$ = logName;
    this.msg$ = msg;
    this.err$ = err;
  }

  time$;
  level$;
  logName$;
  msg$;
  err$;

  static make(time, level, logName, msg, err=null) {
    return new LogRec(time, level, logName, msg, err);
  }

  

  time() { return this.time$; }

  level() { return this.level$; }

  logName() { return this.logName$; }

  msg() { return this.msg$; }

  err() { return this.err$; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  toStr() {
    const ts = this.time$.toLocale("hh:mm:ss DD-MMM-YY");
    return '[' + ts + '] [' + this.level$ + '] [' + this.logName$ + '] ' + this.msg$;
  }

  print(out) {
    // TODO FIXIT
    //if (out === undefined) out = ???
    //out.printLine(toStr());
    //if (err != null) err.trace(out, 2, true);

    ObjUtil.echo(this.toStr());
    if (this.err$ != null) this.err$.trace(); // echo routes to console too
  }

}
