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
  $at("Bool",      "sys::Obj").$af("defVal", 53250, "sys::Bool");
  $at("Duration",  "sys::Obj").$af("defVal", 53250, "sys::Duration");
  $at("Func",      "sys::Obj");
  $at("Int",       "sys::Num").$af("defVal", 53250, "sys::Int");
  $at("Decimal",   "sys::Num");
  $at("Float",     "sys::Num").$af("defVal", 53250, "sys::Float");
  $at("List",      "sys::Obj");
  $at("Map",       "sys::Obj");
  $at("Month",     "sys::Enum");
  $at("Pod",       "sys::Obj");
  $at("Range",     "sys::Obj");
  $at("Str",       "sys::Obj").$af("defVal", 53250, "sys::Str");
  $at("StrBuf",    "sys::Obj");
  // TODO: sys
  $at("Test",      "sys::Obj");
  $at("DateTime",  "sys::Obj").$af("defVal", 53250, "sys::DateTime");
  $at("Date",      "sys::Obj").$af("defVal", 53250, "sys::Date");
  $at("Time",      "sys::Obj").$af("defVal", 53250, "sys::Time");
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
  $at("Uri",       "sys::Obj").$af("defVal", 53250, "sys::Uri");
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
  $at("CastErr",   "sys::Obj");
  // TODO: ConstErr
  $at("IOErr",     "sys::Err");
  $at("IndexErr",  "sys::Err");
  // TODO: InterruptedErr
  $at("NameErr",   "sys::Err");
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

// TODO FIXIT
// cache sys types
fan.sys.Obj.$type  = fan.sys.Type.find("sys::Obj");
fan.sys.List.$type = fan.sys.Type.find("sys::List");
fan.sys.Map.$type  = fan.sys.Type.find("sys::Map");
fan.sys.Pod.$type  = fan.sys.Type.find("sys::Pod");

// TODO - temp
// fromStr
fan.sys.Type.find("sys::Bool").$am("fromStr", 20482);
fan.sys.Type.find("sys::Date").$am("fromStr", 20482);
fan.sys.Type.find("sys::DateTime").$am("fromStr", 20482);
fan.sys.Type.find("sys::Duration").$am("fromStr", 20482);
fan.sys.Type.find("sys::Float").$am("fromStr", 20482);
fan.sys.Type.find("sys::Int").$am("fromStr", 20482);
fan.sys.Type.find("sys::Str").$am("fromStr", 20482);
fan.sys.Type.find("sys::Time").$am("fromStr", 20482);
fan.sys.Type.find("sys::Uri").$am("fromStr", 20482);
// toLocale
fan.sys.Type.find("sys::Date").$am("toLocale", 4096);
fan.sys.Type.find("sys::DateTime").$am("toLocale", 4096);
fan.sys.Type.find("sys::DateTime").$am("date", 4096);
fan.sys.Type.find("sys::DateTime").$am("time", 4096);
fan.sys.Type.find("sys::Time").$am("toLocale", 4096);
// misc
fan.sys.Type.find("sys::Duration").$am("toMin", 4096);

// TODO - we really need to emit the type info *before*, but not
// sure quite how that should work yet.  So in the mean time, stick
// any static code requiring TypeInfo here

fan.sys.Float.m_posInf = fan.sys.Float.make(Number.POSITIVE_INFINITY);
fan.sys.Float.m_negInf = fan.sys.Float.make(Number.NEGATIVE_INFINITY);
fan.sys.Float.m_nan    = fan.sys.Float.make(Number.NaN);
fan.sys.Float.m_e      = fan.sys.Float.make(Math.E);
fan.sys.Float.m_pi     = fan.sys.Float.make(Math.PI);
fan.sys.Float.m_defVal = 0;

fan.sys.Int.m_maxVal = new Long(0x7fffffff, 0xffffffff);
fan.sys.Int.m_minVal = new Long(0x80000000, 0x00000000);
fan.sys.Int.m_defVal = 0;
fan.sys.Int.Chunk  = 4096;

fan.sys.Uri.parentRange = fan.sys.Range.make(0, -2, false);
fan.sys.Uri.m_defVal = fan.sys.Uri.fromStr("");

fan.sys.MimeType.m_imagePng  = fan.sys.MimeType.predefined("image", "png");
fan.sys.MimeType.m_imageGif  = fan.sys.MimeType.predefined("image", "gif");
fan.sys.MimeType.m_imageJpeg = fan.sys.MimeType.predefined("image", "jpeg");
fan.sys.MimeType.m_textPlain = fan.sys.MimeType.predefined("text", "plain");
fan.sys.MimeType.m_textHtml  = fan.sys.MimeType.predefined("text", "html");
fan.sys.MimeType.m_textXml   = fan.sys.MimeType.predefined("text", "xml");
fan.sys.MimeType.m_dir       = fan.sys.MimeType.predefined("x-directory", "normal");

fan.sys.UriPodBase = "/sys/pod/";

fan.sys.Month.m_vals = fan.sys.List.make(fan.sys.Type.find("sys::Month"),
[
  fan.sys.Month.m_jan,
  fan.sys.Month.m_feb,
  fan.sys.Month.m_mar,
  fan.sys.Month.m_apr,
  fan.sys.Month.m_may,
  fan.sys.Month.m_jun,
  fan.sys.Month.m_jul,
  fan.sys.Month.m_aug,
  fan.sys.Month.m_sep,
  fan.sys.Month.m_oct,
  fan.sys.Month.m_nov,
  fan.sys.Month.m_dec
]);

