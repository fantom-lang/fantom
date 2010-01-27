//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//  21 Dec 07  Brian Frank  Revamp
//

**
** Log provides a simple, but standardized mechanism for logging.
**
** See `docLang::Logging` for details and [examples]`examples::sys-logging`.
**
const class Log
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a list of all the active logs which
  ** have been registered since system startup.
  **
  static Log[] list()

  **
  ** Find a registered log by name.  If the log doesn't exist and
  ** checked is false then return null, otherwise throw Err.
  **
  static Log? find(Str name, Bool checked := true)

  **
  ** Find an existing registered log by name or if not found then
  ** create a new registered Log instance with the given name.
  ** Name must be valid according to `Uri.isName` otherwise
  ** NameErr is thrown.
  **
  static Log get(Str name)

  **
  ** Create a new log by name.  The log is added to the VM log registry
  ** only if 'register' is true.  If register is true and a log has already
  ** been created for the specified name then throw ArgErr.  Name must
  ** be valid according to `Uri.isName` otherwise NameErr is thrown.
  **
  new make(Str name, Bool register)

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return name of the log.
  **
  Str name()

  **
  ** Return name.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Severity Level
//////////////////////////////////////////////////////////////////////////

  **
  ** The log level field defines which log entries are reported
  ** versus ignored.  Anything which equals or is more severe than
  ** the log level is logged.  Anything less severe is ignored.
  ** If the level is set to silent, then logging is disabled.
  **
  LogLevel level

  **
  ** Return if this log is enabled for the specified level.
  **
  Bool isEnabled(LogLevel level)

  **
  ** Return if error level is enabled.
  **
  Bool isErr()

  **
  ** Return if warn level is enabled.
  **
  Bool isWarn()

  **
  ** Return if info level is enabled.
  **
  Bool isInfo()

  **
  ** Return if debug level is enabled.
  **
  Bool isDebug()

//////////////////////////////////////////////////////////////////////////
// Logging
//////////////////////////////////////////////////////////////////////////

  **
  ** Generate a `LogLevel.err` log entry.
  **
  Void err(Str msg, Err? err := null)

  **
  ** Generate a `LogLevel.warn` log entry.
  **
  Void warn(Str msg, Err? err := null)

  **
  ** Generate a `LogLevel.info` log entry.
  **
  Void info(Str msg, Err? err := null)

  **
  ** Generate a `LogLevel.debug` log entry.
  **
  Void debug(Str msg, Err? err := null)

  **
  ** Publish a log entry.  The convenience methods `err`, `warn`
  ** `info`, and `debug` all route to this method for centralized
  ** handling.  The standard implementation is to call each of the
  ** installed `handlers` if the specified level is enabled.
  **
  virtual Void log(LogRec rec)

//////////////////////////////////////////////////////////////////////////
// Handlers
//////////////////////////////////////////////////////////////////////////

  **
  ** List all the handler functions installed to process log events.
  **
  static |LogRec rec|[] handlers()

  **
  ** Install a handler to receive callbacks on logging events.
  ** If the handler func is not immutable, then throw NotImmutableErr.
  **
  static Void addHandler(|LogRec rec| handler)

  **
  ** Uninstall a log handler.
  **
  static Void removeHandler(|LogRec rec| handler)

}