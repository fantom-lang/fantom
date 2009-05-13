//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 09  Andy Frank  Creation
//

with (sys_Pod.$add("sys"))
{
  $addType("Obj",       null);

  // basic primitives
  $addType("Num",       "sys::Obj");
  $addType("Enum",      "sys::Obj");
  $addType("Bool",      "sys::Obj");
  $addType("Duration",  "sys::Obj");
  $addType("Func",      "sys::Obj");
  $addType("Int",       "sys::Num");
  // TODO: decimal
  $addType("Float",     "sys::Obj");
  $addType("List",      "sys::Obj");
  $addType("Map",       "sys::Obj");
  $addType("Month",     "sys::Enum");
  $addType("Pod",       "sys::Obj");
  $addType("Range",     "sys::Obj");
  $addType("Str",       "sys::Obj");
  $addType("StrBuf",    "sys::Obj");
  // TODO: sys
  $addType("Test",      "sys::Obj");
  $addType("DateTime",  "sys::Obj");
  $addType("Date",      "sys::Obj");
  // TODO: time
  // TODO: timezone
  $addType("Type",      "sys::Obj");
  $addType("Weekday",   "sys::Obj");
  // TODO: this
  // TODO: void

  // reflection
  $addType("Slot",      "sys::Obj");
  $addType("Field",     "sys::Slot");
  $addType("Method",    "sys::Obj");
  // TODO: param

  // resources
  $addType("Namespace", "sys::Obj");
  // TODO: rootNamespace
  // TODO: sysNamespace
  // TODO: dirNamespace

  // IO
  $addType("Charset",   "sys::Obj");
  $addType("InStream",  "sys::Obj");
  // TODO: SysInStream
  // TODO: OutStream
  // TODO: SysOutStream
  // TODO: File
  // TODO: LocalFile
  // TODO: ZipEntryFile
  $addType("Buf",       "sys::Obj");
  // TODO: MemBuf
  // TODO: FileBuf
  // TODO: MmapBuf
  $addType("Uri",       "sys::Obj");
  // TODO: Zip

  // actors
  // TODO: Actor
  // TODO: ActorPool
  // TODO: Context
  // TODO: Future

  // utils
  // TODO: Depend
  $addType("Log",       "sys::Obj");
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
  $addType("Err",       "sys::Obj");
  $addType("ArgErr",    "sys::Err");
  // TODO: CancelledErr
  // TODO: CastErr
  // TODO: ConstErr
  $addType("IOErr",     "sys::Err");
  $addType("IndexErr",  "sys::Err");
  // TODO: InterruptedErr
  // TODO: NameErr
  // TODO: NotImmutableErr
  $addType("NullErr",   "sys::Err");
  $addType("ParseErr",  "sys::Err");
  // TODO: ReadonlyErr
  // TODO: TestErr
  // TODO: TimeoutErr
  $addType("UnknownPodErr", "sys::Err")
  // TODO: UnknownServiceErr
  // TODO: UnknownSlotErr
  $addType("UnknownTypeErr", "sys::Err")
  // TODO: UnresolvedErr
  // TODO: UnsupportedErr
};