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
  // TODO: timezone
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
  // TODO: Locale
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

sys_Float.posInf = sys_Float.make(Number.POSITIVE_INFINITY);
sys_Float.negInf = sys_Float.make(Number.NEGATIVE_INFINITY);
sys_Float.nan    = sys_Float.make(Number.NaN);
sys_Float.e      = sys_Float.make(Math.E);
sys_Float.pi     = sys_Float.make(Math.PI);

sys_Int.maxVal = new Long(0x7fffffff, 0xffffffff);
sys_Int.minVal = new Long(0x80000000, 0x00000000);
sys_Int.defVal = 0;
sys_Int.Chunk  = 4096;

sys_MimeType.imagePng  = sys_MimeType.predefined("image", "png");
sys_MimeType.imageGif  = sys_MimeType.predefined("image", "gif");
sys_MimeType.imageJpeg = sys_MimeType.predefined("image", "jpeg");
sys_MimeType.textPlain = sys_MimeType.predefined("text", "plain");
sys_MimeType.textHtml  = sys_MimeType.predefined("text", "html");
sys_MimeType.textXml   = sys_MimeType.predefined("text", "xml");
sys_MimeType.dir       = sys_MimeType.predefined("x-directory", "normal");

sys_UriPodBase = "/sys/pod/";

sys_Month.values = sys_List.make(sys_Type.find("sys::Month"),
[
  sys_Month.jan, sys_Month.feb, sys_Month.mar, sys_Month.apr, sys_Month.may, sys_Month.jun,
  sys_Month.jul, sys_Month.aug, sys_Month.sep, sys_Month.oct, sys_Month.nov, sys_Month.dec
]);