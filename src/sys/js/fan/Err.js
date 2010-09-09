//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Err
 */
fan.sys.Err = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.prototype.$ctor = function(msg, cause)
{
  this.m_msg   = msg;
  this.m_cause = cause;
  this.m_stack = new Error().stack;
}

fan.sys.Err.make$ = function(self, msg, cause)
{
  self.m_msg   = msg;
  self.m_cause = cause;
  self.m_stack = new Error().stack;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.prototype.cause = function()
{
  return this.m_cause;
}

fan.sys.Err.prototype.$typeof = function()
{
  return fan.sys.Err.$type;
}

fan.sys.Err.prototype.toStr = function()
{
  return this.$typeof() + ": " + this.m_msg;
}

fan.sys.Err.prototype.msg = function()
{
  return this.m_msg;
}

fan.sys.Err.prototype.trace = function()
{
  fan.sys.ObjUtil.echo(this.traceToStr());
}

fan.sys.Err.prototype.traceToStr = function()
{
  var s = this.$typeof() + ": " + this.m_msg;
  if (this.m_stack != null) s += "\n" + fan.sys.Err.cleanTrace(this.m_stack);
  if (this.m_cause != null) s += "\n  Caused by: " + this.m_cause.traceToStr();
  return s;
}

fan.sys.Err.cleanTrace = function(orig)
{
  var stack = [];
  var lines = orig.split('\n');
  for (var i=0; i<lines.length; i++)
  {
    var line = lines[i];
    if (line.indexOf("@") != -1)
    {
      // firefox
      var about = line.lastIndexOf("@");
      var slash = line.lastIndexOf("/");
      if (slash != -1)
      {
        // TODO FIXIT
        var func = "Unknown"; // line.substring(0, about)
        var sub = "  at " + func + " (" + line.substr(slash+1) + ")";
        stack.push(sub);
      }
    }
    else if (line.charAt(line.length-1) == ')')
    {
      // chrome
      var paren = line.lastIndexOf("(");
      var slash = line.lastIndexOf("/");
      var sub   = line.substring(0, paren+1) + line.substr(slash+1);
      stack.push(sub);
    }
    else
    {
      // add orig
      stack.push(line)
    }
  }
  return stack.join("\n") + "\n";
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Err.make = function(err, cause)
{
  if (err instanceof fan.sys.Err) return err;
  if (err instanceof Error)
  {
    var m = err.message;
    if (m.indexOf(" from null") != -1) return fan.sys.NullErr.make(m, cause);

    // TODO
    //  EvalError
    //  RangeError
    //  ReferenceError
    //  SyntaxError
    //  TypeError
    //  URIError
    return new fan.sys.Err(err.message, cause);
  }
  return new fan.sys.Err("" + err, cause);
}

//////////////////////////////////////////////////////////////////////////
// Err subclasses
//////////////////////////////////////////////////////////////////////////

// ArgErr
fan.sys.ArgErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ArgErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.ArgErr.prototype.$typeof = function() { return fan.sys.ArgErr.$type; }
fan.sys.ArgErr.make = function(msg, cause) { return new fan.sys.ArgErr(msg, cause); }

// CancelledErr
fan.sys.CancelledErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.CancelledErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.CancelledErr.prototype.$typeof = function() { return fan.sys.CancelledErr.$type; }
fan.sys.CancelledErr.make = function(msg, cause) { return new fan.sys.CancelledErr(msg, cause); }

// CastErr
fan.sys.CastErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.CastErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.CastErr.prototype.$typeof = function() { return fan.sys.CastErr.$type; }
fan.sys.CastErr.make = function(msg, cause) { return new fan.sys.CastErr(msg, cause); }

// ConstErr
fan.sys.ConstErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ConstErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.ConstErr.prototype.$typeof = function() { return fan.sys.ConstErr.$type; }
fan.sys.ConstErr.make = function(msg, cause) { return new fan.sys.ConstErr(msg, cause); }

// FieldNotSetErr
fan.sys.FieldNotSetErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.FieldNotSetErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.FieldNotSetErr.prototype.$typeof = function() { return fan.sys.FieldNotSetErr.$type; }
fan.sys.FieldNotSetErr.make = function(msg, cause) { return new fan.sys.FieldNotSetErr(msg, cause); }

// IndexErr
fan.sys.IndexErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.IndexErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.IndexErr.prototype.$typeof = function() { return fan.sys.IndexErr.$type; }
fan.sys.IndexErr.make = function(msg, cause) { return new fan.sys.IndexErr(msg, cause); }

// InterruptedErr
fan.sys.InterruptedErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.InterruptedErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.InterruptedErr.prototype.$typeof = function() { return fan.sys.InterruptedErr.$type; }
fan.sys.InterruptedErr.make = function(msg, cause) { return new fan.sys.InterruptedErr(msg, cause); }

// IOErr
fan.sys.IOErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.IOErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.IOErr.prototype.$typeof = function() { return fan.sys.IOErr.$type; }
fan.sys.IOErr.make = function(msg, cause) { return new fan.sys.IOErr(msg, cause); }

// NameErr
fan.sys.NameErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.NameErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.NameErr.prototype.$typeof = function() { return fan.sys.NameErr.$type; }
fan.sys.NameErr.make = function(msg, cause) { return new fan.sys.NameErr(msg, cause); }

// NotImmutableErr
fan.sys.NotImmutableErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.NotImmutableErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.NotImmutableErr.prototype.$typeof = function() { return fan.sys.NotImmutableErr.$type; }
fan.sys.NotImmutableErr.make = function(msg, cause) { return new fan.sys.NotImmutableErr(msg, cause); }

// NullErr
fan.sys.NullErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.NullErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.NullErr.prototype.$typeof = function() { return fan.sys.NullErr.$type; }
fan.sys.NullErr.make = function(msg, cause) { return new fan.sys.NullErr(msg, cause); }

// ParseErr
fan.sys.ParseErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ParseErr.prototype.$ctor = function(type, val, more, cause)
{
  var msg = type;
  if (val != undefined)
  {
    msg = "Invalid " + type + ": '" + val + "'";
    if (more != undefined) msg += ": " + more;
  }
  fan.sys.Err.prototype.$ctor.call(this, msg, cause)
}
fan.sys.ParseErr.prototype.$typeof = function() { return fan.sys.ParseErr.$type; }
fan.sys.ParseErr.make = function(type, val, more, cause) { return new fan.sys.ParseErr(type,val,more,cause); }

// ReadonlyErr
fan.sys.ReadonlyErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.ReadonlyErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.ReadonlyErr.prototype.$typeof = function() { return fan.sys.ReadonlyErr.$type; }
fan.sys.ReadonlyErr.make = function(msg, cause) { return new fan.sys.ReadonlyErr(msg, cause); }

// TestErr
fan.sys.TestErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.TestErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.TestErr.prototype.$typeof = function() { return fan.sys.TestErr.$type; }
fan.sys.TestErr.make = function(msg, cause) { return new fan.sys.TestErr(msg, cause); }

// TimeoutErr
fan.sys.TimeoutErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.TimeoutErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.TimeoutErr.prototype.$typeof = function() { return fan.sys.TimeoutErr.$type; }
fan.sys.TimeoutErr.make = function(msg, cause) { return new fan.sys.TimeoutErr(msg, cause); }

// UnknownPodErr
fan.sys.UnknownPodErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownPodErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownPodErr.prototype.$typeof = function() { return fan.sys.UnknownPodErr.$type; }
fan.sys.UnknownPodErr.make = function(msg, cause) { return new fan.sys.UnknownPodErr(msg, cause); }

// UnknownServiceErr
fan.sys.UnknownServiceErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownServiceErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownServiceErr.prototype.$typeof = function() { return fan.sys.UnknownServiceErr.$type; }
fan.sys.UnknownServiceErr.make = function(msg, cause) { return new fan.sys.UnknownServiceErr(msg, cause); }

// UnknownSlotErr
fan.sys.UnknownSlotErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownSlotErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownSlotErr.prototype.$typeof = function() { return fan.sys.UnknownSlotErr.$type; }
fan.sys.UnknownSlotErr.make = function(msg, cause) { return new fan.sys.UnknownSlotErr(msg, cause); }

// UnknownFacetErr
fan.sys.UnknownFacetErr= fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownFacetErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownFacetErr.prototype.$typeof = function() { return fan.sys.UnknownFacetErr.$type; }
fan.sys.UnknownFacetErr.make = function(msg, cause) { return new fan.sys.UnknownFacetErr(msg, cause); }

// UnknownTypeErr
fan.sys.UnknownTypeErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnknownTypeErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnknownTypeErr.prototype.$typeof = function() { return fan.sys.UnknownTypeErr.$type; }
fan.sys.UnknownTypeErr.make = function(msg, cause) { return new fan.sys.UnknownTypeErr(msg, cause); }

// UnresolvedErr
fan.sys.UnresolvedErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnresolvedErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnresolvedErr.prototype.$typeof = function() { return fan.sys.UnresolvedErr.$type; }
fan.sys.UnresolvedErr.make = function(msg, cause) { return new fan.sys.UnresolvedErr(msg, cause); }

// UnsupportedErr
fan.sys.UnsupportedErr = fan.sys.Obj.$extend(fan.sys.Err);
fan.sys.UnsupportedErr.prototype.$ctor = function(msg, cause) { fan.sys.Err.prototype.$ctor.call(this, msg, cause); }
fan.sys.UnsupportedErr.prototype.$typeof = function() { return fan.sys.UnsupportedErr.$type; }
fan.sys.UnsupportedErr.make = function(msg, cause) { return new fan.sys.UnsupportedErr(msg, cause); }

