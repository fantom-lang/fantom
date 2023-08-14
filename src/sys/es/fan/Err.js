//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   31 Mar 2023  Matthew Giannini  Refactor to ES
//


/**
 * Err
 */
class Err extends Obj {
  constructor(msg = "", cause = null) {
    super();
    this.#err = new Error();
    this.#msg = msg;
    this.#cause = cause;
  }

  #err;
  #msg;
  #cause;

  static make(err, cause) {
    if (err instanceof Err) return err;
    if (err instanceof Error) {
      let m = err.message;
      if (m.indexOf(" from null") != -1)
        return NullErr.make(m, cause).assign$(err);
      if (m.indexOf(" of null") != -1)
        return NullErr.make(m, cause).assign$(err);

      // TODO
      //  EvalError
      //  RangeError
      //  ReferenceError
      //  SyntaxError
      //  TypeError
      //  URIError

      // TODO: do we need to wrap `cause` too?

      return new Err(err.message, cause).assign$(err);
    }
    return new Err("" + err, cause);
  }

  static make$(self, msg, cause) {
    self.#err = new Error();
    self.#msg = msg;
    self.#cause = cause;
  }

  // TODO: hack to workaround how we get root errors
  // mapped into the Err wrapper instance; really need
  // to probably rework alot of this class to work better
  assign$(jsErr) {
    this.#err = jsErr;
    return this;
  }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

  msg() {
    return this.#msg;
  }

  cause() {
    return this.#cause;
  }

  toStr() {
    return `${this.typeof$()}: ${this.#msg}`;
  }

  trace() {
    ObjUtil.echo(this.traceToStr());
  }

  traceToStr() {
    let s = this.typeof$() + ": " + this.#msg;
    if (this.#err.stack) s += "\n" + Err.cleanTrace(this.#err.stack);
    if (this.#cause) 
    {
      if (this.#cause.stack) s += "\n  Caused by: " + Err.cleanTrace(this.#cause.stack);
      else if (this.#cause) 
      {
        if (this.#cause.traceToStr) s += "\n Caused by: " + this.#cause.traceToStr();
        else s += `\n Caused by ${this.#cause}`;
      }
      // else s += this.#cause.traceToStr();
    }
    return s;
  }

  static cleanTrace(orig) {
    let stack = [];
    let lines = orig.split("\n");
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i];
      if (line.indexOf("@") != -1) {
        // firefox
        let about = line.lastIndexOf("@");
        let slash = line.lastIndexOf("/");
        if (slash != -1) {
          // TODO FIXIT
          let func = "Unknown"; // line.substring(0, about)
          let sub = "  at " + func + " (" + line.substr(slash + 1) + ")";
          stack.push(sub);
        }
      } else if (line.charAt(line.length - 1) == ")") {
        // chrome
        let paren = line.lastIndexOf("(");
        let slash = line.lastIndexOf("/");
        let sub = line.substring(0, paren + 1) + line.substr(slash + 1);
        stack.push(sub);
      } else {
        // add orig
        stack.push(line);
      }
    }
    return stack.join("\n") + "\n";
  }
}

/** ArgErr */
class ArgErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new ArgErr(msg, cause); }
}

/** CancelledErr */
class CancelledErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new CancelledErr(msg, cause); }
}

/** CastErr */
class CastErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new CastErr(msg, cause); }
}

/** ConstErr */
class ConstErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new ConstErr(msg, cause); }
}

/** FieldNotSetErr */
class FieldNotSetErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new FieldNotSetErr(msg, cause); }
}

/** IndexErr */
class IndexErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new IndexErr(msg, cause); }
}

/** InterruptedErr */
class InterruptedErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new InterruptedErr(msg, cause); }
}

/** IOErr */
class IOErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new IOErr(msg, cause); }
}

/** NameErr */
class NameErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new NameErr(msg, cause); }
}

/** NotImmutableErr */
class NotImmutableErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new NotImmutableErr(msg, cause); }
}

/** NullErr */
class NullErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new NullErr(msg, cause); }
}

/** ParseErr */
class ParseErr extends Err {
  constructor(type, val, more, cause) {
    let msg = type;
    if (val != undefined) {
      msg = `Invalid ${type}: '${val}'`;
      if (more != undefined) msg += ": " + more;
    }
    super(msg, cause);
  }
  
  static make(msg="", cause=null) { return new ParseErr(msg, null, null, cause); }
  static makeStr(type, val, more, cause) { return new ParseErr(type, val, more, cause); }
}

/** ReadonlyErr */
class ReadonlyErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new ReadonlyErr(msg, cause); }
}

/** TestErr */
class TestErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new TestErr(msg, cause); }
}

/** TimeoutErr */
class TimeoutErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new TimeoutErr(msg, cause); }
}

/** UnknownKeyErr */
class UnknownKeyErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnknownKeyErr(msg, cause); }
}

/** UnknownPodErr */
class UnknownPodErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnknownPodErr(msg, cause); }
}

/** UnknownServiceErr */
class UnknownServiceErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnknownServiceErr(msg, cause); }
}

/** UnknownSlotErr */
class UnknownSlotErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnknownSlotErr(msg, cause); }
}

/** UnknownFacetErr */
class UnknownFacetErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnknownFacetErr(msg, cause); }
}

/** UnknownTypeErr */
class UnknownTypeErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnknownTypeErr(msg, cause); }
}

/** UnresolvedErr */
class UnresolvedErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnresolvedErr(msg, cause); }
}

/** UnsupportedErr */
class UnsupportedErr extends Err {
  constructor(msg = "", cause = null) { super(msg, cause); }
  
  static make(msg="", cause=null) { return new UnsupportedErr(msg, cause); }
}
