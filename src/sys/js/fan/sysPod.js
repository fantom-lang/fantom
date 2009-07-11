//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 09  Andy Frank  Creation
//

with (fan.sys.Pod.$add("sys"))
{
  $at("Obj",       null);

  // basic primitives
  $at("Num",       "sys::Obj");
  $at("Enum",      "sys::Obj");
  $at("Bool",      "sys::Obj");
  $at("Duration",  "sys::Obj");
  $at("Func",      "sys::Obj");
  $at("Int",       "sys::Num");
  $at("Decimal",   "sys::Num");
  $at("Float",     "sys::Num");
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
  $at("Time",      "sys::Obj");
  $at("TimeZone",  "sys::Obj");
  $at("Type",      "sys::Obj");
  $at("Weekday",   "sys::Enum");
  // TODO: this
  $at("Void",      "sys::Obj"); // TODO - STUB

  // reflection
  $at("Slot",      "sys::Obj");
  $at("Field",     "sys::Slot");
  $at("Method",    "sys::Slot");
  $at("Param",     "sys::Obj");

  // resources
  $at("Namespace", "sys::Obj");
  // TODO: rootNamespace
  // TODO: sysNamespace
  // TODO: dirNamespace

  // IO
  $at("Charset",   "sys::Obj");
  $at("InStream",  "sys::Obj");
  // TODO: SysInStream
  $at("OutStream", "sys::Obj");
  // TODO: SysOutStream
  $at("File",      "sys::Obj");  // TODO - STUB
  // TODO: LocalFile
  // TODO: ZipEntryFile
  $at("Buf",       "sys::Obj");
  //$at("MemBuf",    "sys::Buf"); // TODO - when we fix Buf
  // TODO: FileBuf
  // TODO: MmapBuf
  $at("Uri",       "sys::Obj");
  // TODO: Zip

  // actors
  $at("Actor",     "sys::Obj");
  // TODO: ActorPool
  // TODO: Context
  // TODO: Future

  // utils
  // TODO: Depend
  $at("Log",       "sys::Obj");
  // TODO: LogLevel
  // TODO: LogRecord
  $at("Locale",    "sys::Obj");
  $at("MimeType",  "sys::Obj");
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
  $at("UnresolvedErr",  "sys::Err");
  $at("UnsupportedErr", "sys::Err");
};

// TODO - we really need to emit the type info *before*, but not
// sure quite how that should work yet.  So in the mean time, stick
// any static code requiring TypeInfo here

fan.sys.Float.posInf = fan.sys.Float.make(Number.POSITIVE_INFINITY);
fan.sys.Float.negInf = fan.sys.Float.make(Number.NEGATIVE_INFINITY);
fan.sys.Float.nan    = fan.sys.Float.make(Number.NaN);
fan.sys.Float.e      = fan.sys.Float.make(Math.E);
fan.sys.Float.pi     = fan.sys.Float.make(Math.PI);

fan.sys.Int.maxVal = new Long(0x7fffffff, 0xffffffff);
fan.sys.Int.minVal = new Long(0x80000000, 0x00000000);
fan.sys.Int.defVal = 0;
fan.sys.Int.Chunk  = 4096;

fan.sys.MimeType.imagePng  = fan.sys.MimeType.predefined("image", "png");
fan.sys.MimeType.imageGif  = fan.sys.MimeType.predefined("image", "gif");
fan.sys.MimeType.imageJpeg = fan.sys.MimeType.predefined("image", "jpeg");
fan.sys.MimeType.textPlain = fan.sys.MimeType.predefined("text", "plain");
fan.sys.MimeType.textHtml  = fan.sys.MimeType.predefined("text", "html");
fan.sys.MimeType.textXml   = fan.sys.MimeType.predefined("text", "xml");
fan.sys.MimeType.dir       = fan.sys.MimeType.predefined("x-directory", "normal");

fan.sys.UriPodBase = "/sys/pod/";

fan.sys.Month.values = fan.sys.List.make(fan.sys.Type.find("sys::Month"),
[
  fan.sys.Month.jan, fan.sys.Month.feb, fan.sys.Month.mar, fan.sys.Month.apr, fan.sys.Month.may, fan.sys.Month.jun,
  fan.sys.Month.jul, fan.sys.Month.aug, fan.sys.Month.sep, fan.sys.Month.oct, fan.sys.Month.nov, fan.sys.Month.dec
]);