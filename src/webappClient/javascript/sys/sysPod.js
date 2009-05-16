//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 09  Andy Frank  Creation
//

with (sys_Pod.$add("sys"))
{
  $at("Obj",       null);

  // basic primitives
  $at("Num",       "sys::Obj");
  $at("Enum",      "sys::Obj");
  $at("Bool",      "sys::Obj");
  $at("Duration",  "sys::Obj");
  $at("Func",      "sys::Obj");
  $at("Int",       "sys::Num");
  // TODO: decimal
  $at("Float",     "sys::Obj");
  $at("List",      "sys::Obj");
  $at("Map",       "sys::Obj");
  $at("Month",     "sys::Enum");
  $at("Pod",       "sys::Obj");
  $at("Range",     "sys::Obj");
  $at("Str",       "sys::Obj");
  $at("StrBuf",    "sys::Obj");
  // TODO: sys
  $at("Test",      "sys::Obj");
  $at("DateTime",  "sys::Obj");
  $at("Date",      "sys::Obj");
  // TODO: time
  // TODO: timezone
  $at("Type",      "sys::Obj");
  $at("Weekday",   "sys::Obj");
  // TODO: this
  $at("Void",      "Sys::Obj"); // TODO - STUB

  // reflection
  $at("Slot",      "sys::Obj");
  $at("Field",     "sys::Slot");
  $at("Method",    "sys::Obj");
  // TODO: param

  // resources
  $at("Namespace", "sys::Obj");
  // TODO: rootNamespace
  // TODO: sysNamespace
  // TODO: dirNamespace

  // IO
  $at("Charset",   "sys::Obj");
  $at("InStream",  "sys::Obj");
  // TODO: SysInStream
  // TODO: OutStream
  // TODO: SysOutStream
  $at("File",      "sys::Obj");  // TODO - STUB
  // TODO: LocalFile
  // TODO: ZipEntryFile
  $at("Buf",       "sys::Obj");
  // TODO: MemBuf
  // TODO: FileBuf
  // TODO: MmapBuf
  $at("Uri",       "sys::Obj");
  // TODO: Zip

  // actors
  // TODO: Actor
  // TODO: ActorPool
  // TODO: Context
  // TODO: Future

  // utils
  // TODO: Depend
  $at("Log",       "sys::Obj");
  // TODO: LogLevel
  // TODO: LogRecord
  // TODO: Locale
  // TODO: MimeType
  // TODO: Process
  // TODO: Regex
  // TODO: RegexMatcher
  // TODO: Service
  // TODO: Version
  // TODO: Unit
  // TODO: Unsafe
  // TODO: Uuid

  // uri schemes
  // TODO: UriScheme
  // TODO: FanScheme
  // TODO: FileScheme

  // exceptions
  $at("Err",       "sys::Obj");
  $at("ArgErr",    "sys::Err");
  // TODO: CancelledErr
  // TODO: CastErr
  // TODO: ConstErr
  $at("IOErr",     "sys::Err");
  $at("IndexErr",  "sys::Err");
  // TODO: InterruptedErr
  // TODO: NameErr
  // TODO: NotImmutableErr
  $at("NullErr",        "sys::Err");
  $at("ParseErr",       "sys::Err");
  $at("ReadonlyErr",    "sys::Err");
  // TODO: TestErr
  // TODO: TimeoutErr
  $at("UnknownPodErr",  "sys::Err");
  // TODO: UnknownServiceErr
  $at("UnknownSlotErr", "sys::Err");
  $at("UnknownTypeErr", "sys::Err");
  // TODO: UnresolvedErr
  // TODO: UnsupportedErr
};

