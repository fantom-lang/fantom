//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 10  Andy Frank  Creation
//

/**
 * Env.
 */
fan.sys.Env = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.cur = function()
{
  if (fan.sys.Env.$cur == null) fan.sys.Env.$cur = new fan.sys.Env();
  return fan.sys.Env.$cur;
}

fan.sys.Env.prototype.$ctor = function()
{
  this.m_args = fan.sys.List.make(fan.sys.Str.$type).toImmutable();

  this.m_index = fan.sys.Map.make(fan.sys.Str.$type, new fan.sys.ListType(fan.sys.Str.$type));
  this.m_index = this.m_index.toImmutable();

  this.m_vars = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Str.$type)
  this.m_vars.caseInsensitive$(true);
  if (typeof fan$env !== 'undefined')
  {
    // fan$env is used to seed Env.var; it must be defined before sys.js
    var keys = Object.keys(fan$env);
    for (var i=0; i<keys.length; i++)
    {
      var k = keys[i];
      var v = fan$env[k]
      this.m_vars.set(k, v);
    }
  }

  this.m_vars = this.m_vars.toImmutable();

  // pod props map, keyed by pod.name
  this.m_props = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Map.$type);

  // user
  this.m_user = "unknown";

  // env.out
  this.m_out = new fan.sys.ConsoleOutStream();
}

fan.sys.Env.$invokeMain = function(qname)
{
  // resolve qname to method
  var dot = qname.indexOf('.');
  if (dot < 0) qname += '.main';
  var main = fan.sys.Slot.findMethod(qname);

  // invoke main
  if (main.isStatic()) main.call();
  else main.callOn(main.parent().make());
}

fan.sys.Env.prototype.$setIndex = function(index)
{
  if (index.$typeof().toStr() != "[sys::Str:sys::Str[]]") throw fan.sys.ArgErr.make("Invalid type");
  this.m_index = index.toImmutable();
}

fan.sys.Env.prototype.$setVars = function(vars)
{
  if (vars.$typeof().toStr() != "[sys::Str:sys::Str]") throw fan.sys.ArgErr.make("Invalid type");
  if (!vars.caseInsensitive()) throw fan.sys.ArgErr.make("Map must be caseInsensitive");
  this.m_vars = vars.toImmutable();
}

fan.sys.Env.noDef = "_Env_nodef_";

// used to display locale keys
fan.sys.Env.localeTestMode = false;

// true running under NodeJS
fan.sys.Env.$nodejs = this.window !== this;

// throw an unsupported error if not running in Node
fan.sys.Env.$requirenodejs = function()
{
  if (!fan.sys.Env.$nodejs)
  {
    throw fan.sys.UnsupportedErr.make("Not supported in this runtime");
  }
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.prototype.$typeof = function() { return fan.sys.Env.$type; }

fan.sys.Env.prototype.toStr = function() { return this.$typeof().toString(); }

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.prototype.runtime = function() { return "js"; }

fan.sys.Env.prototype.javaVersion = function() { return 0; }

fan.sys.Env.prototype.os = function()
{
  fan.sys.Env.$requirenodejs();
  return process.platform;
}

fan.sys.Env.prototype.arch = function()
{
  fan.sys.Env.$requirenodejs();
  return process.arch;
}

fan.sys.Env.prototype.platform = function()
{
  return this.os() + "-" + this.arch();
}

fan.sys.Env.prototype.parent = function()
{
  return null;
}

fan.sys.Env.prototype.idHash = function(obj)
{
  if (!obj) return 0;
  return fan.sys.ObjUtil.hash(obj);
}

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.prototype.args = function() { return this.m_args; }

fan.sys.Env.prototype.vars = function() { return this.m_vars; }

fan.sys.Env.prototype.diagnostics = function()
{
  var map = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Obj.$type);
  return map;
}

fan.sys.Env.prototype.user = function() { return this.m_user; }

fan.sys.Env.prototype.out = function() { return this.m_out; }

fan.sys.Env.prototype.prompt = function(msg)
{
  fan.sys.Env.$requirenodejs();
  if (msg === undefined) msg = "";

  if (process.platform == "win32") {
    return this.$win32prompt(msg);
  } else {
    return this.$unixprompt(msg);
  }
}

fan.sys.Env.prototype.$win32prompt = function(msg)
{
  // https://github.com/nodejs/node/issues/28243
  let fs = require('fs');
  fs.writeSync(1, String(msg));
  let s = '', buf = Buffer.alloc(1);
  while(buf[0] != 10 && buf[0] != 13)
  {
    s += buf;
    fs.readSync(0, buf, 0, 1, 0);
  }
  if (buf[0] == 13) { fs.readSync(0, buf, 0, 1, 0); }
  return s.slice(1);
}

fan.sys.Env.prototype.$unixprompt = function(msg)
{
  // https://stackoverflow.com/questions/61394928/get-user-input-through-node-js-console/74250003?noredirect=1#answer-75008198
  let stdin = fs.openSync("/dev/stdin","rs");

  fs.writeSync(process.stdout.fd, msg);
  let s = '';
  let buf = Buffer.alloc(1);
  fs.readSync(stdin,buf,0,1,null);
  while((buf[0] != 10) && (buf[0] != 13)) {
    s += buf;
    fs.readSync(stdin,buf,0,1,null);
  }
  // Not sure if we need this on unix?
  // if (buf[0] == 13) { fs.readSync(0, buf, 0, 1, 0); }
  return s;
}


fan.sys.Env.prototype.homeDir = function() { return this.m_homeDir; }

fan.sys.Env.prototype.workDir = function() { return this.m_workDir; }

fan.sys.Env.prototype.tempDir = function() { return this.m_tempDir; }

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.prototype.path = function()
{
  return fan.sys.List.make(fan.sys.File.$type, [this.workDir()]);
}

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.prototype.index = function(key)
{
  return this.m_index.get(key, fan.sys.Str.$type.emptyList());
}

fan.sys.Env.prototype.props = function(pod, uri, maxAge)
{
  var key = pod.$name() + ':' + uri.toStr();
  return this.$props(key);
}

fan.sys.Env.prototype.config = function(pod, key, def)
{
  if (def === undefined) def = null;
  return this.props(pod, fan.sys.Env.m_configProps, fan.sys.Duration.m_oneMin).get(key, def);
}

fan.sys.Env.prototype.locale = function(pod, key, def, locale)
{
  // if in test mode return pod::key
  if (fan.sys.Env.localeTestMode &&
      key.indexOf(".browser") == -1 &&
      key.indexOf(".icon") == -1 &&
      key.indexOf(".accelerator") == -1 &&
      pod.$name() != "sys")
    return pod + "::" + key;

  if (def === undefined) def = fan.sys.Env.noDef;
  if (locale === undefined) locale = fan.sys.Locale.cur();

  var val;
  var maxAge = fan.sys.Duration.m_maxVal;

  // 1. 'props(pod, `locale/{locale}.props`)'
  val = this.props(pod, locale.m_strProps, maxAge).get(key, null);
  if (val != null) return val;

  // 2. 'props(pod, `locale/{lang}.props`)'
  val = this.props(pod, locale.m_langProps, maxAge).get(key, null);
  if (val != null) return val;

  // 3. 'props(pod, `locale/en.props`)'
  val = this.props(pod, fan.sys.Env.m_localeEnProps, maxAge).get(key, null);
  if (val != null) return val;

  // 4. Fallback to 'pod::key' unless 'def' specified
  if (def === fan.sys.Env.noDef) return pod + "::" + key;
  return def;
}

fan.sys.Env.prototype.$props = function(key)
{
  var map = this.m_props.get(key);
  if (map == null)
  {
    map = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Str.$type)
    this.m_props.add(key, map);
  }
  return map;
}
