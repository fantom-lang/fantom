//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Dec 09  Andy Frank  Creation
//

//
// Bool
//
fan.sys.Bool.m_defVal = false;

//
// Int
//
fan.sys.Int.m_maxVal = Math.pow(2, 53)
fan.sys.Int.m_minVal = -Math.pow(2, 53)
fan.sys.Int.m_defVal = 0;
fan.sys.Int.Chunk  = 4096;

// Float
fan.sys.Float.m_posInf = fan.sys.Float.make(Number.POSITIVE_INFINITY);
fan.sys.Float.m_negInf = fan.sys.Float.make(Number.NEGATIVE_INFINITY);
fan.sys.Float.m_nan    = fan.sys.Float.make(Number.NaN);
fan.sys.Float.m_e      = fan.sys.Float.make(Math.E);
fan.sys.Float.m_pi     = fan.sys.Float.make(Math.PI);
fan.sys.Float.m_defVal = fan.sys.Float.make(0);

//
// Num
//
fan.sys.NumPattern.cache("00");    fan.sys.NumPattern.cache("000");       fan.sys.NumPattern.cache("0000");
fan.sys.NumPattern.cache("0.0");   fan.sys.NumPattern.cache("0.00");      fan.sys.NumPattern.cache("0.000");
fan.sys.NumPattern.cache("0.#");   fan.sys.NumPattern.cache("#,###.0");   fan.sys.NumPattern.cache("#,###.#");
fan.sys.NumPattern.cache("0.##");  fan.sys.NumPattern.cache("#,###.00");  fan.sys.NumPattern.cache("#,###.##");
fan.sys.NumPattern.cache("0.###"); fan.sys.NumPattern.cache("#,###.000"); fan.sys.NumPattern.cache("#,###.###");
fan.sys.NumPattern.cache("0.0#");  fan.sys.NumPattern.cache("#,###.0#");  fan.sys.NumPattern.cache("#,###.0#");
fan.sys.NumPattern.cache("0.0##"); fan.sys.NumPattern.cache("#,###.0##"); fan.sys.NumPattern.cache("#,###.0##");

//
// Str
//
fan.sys.Str.m_defVal = "";

//
// Duration
//
fan.sys.Duration.nsPerDay   = 86400000000000;
fan.sys.Duration.nsPerHr    = 3600000000000;
fan.sys.Duration.nsPerMin   = 60000000000;
fan.sys.Duration.nsPerSec   = 1000000000;
fan.sys.Duration.nsPerMilli = 1000000;
fan.sys.Duration.secPerDay  = 86400;
fan.sys.Duration.secPerHr   = 3600;
fan.sys.Duration.secPerMin  = 60;

fan.sys.Duration.m_defVal    = fan.sys.Duration.make(0);
fan.sys.Duration.m_minVal    = fan.sys.Duration.make(fan.sys.Int.m_minVal);
fan.sys.Duration.m_maxVal    = fan.sys.Duration.make(fan.sys.Int.m_maxVal);
fan.sys.Duration.m_oneDay    = fan.sys.Duration.make(fan.sys.Duration.nsPerDay);
fan.sys.Duration.m_oneMin    = fan.sys.Duration.make(fan.sys.Duration.nsPerMin);
fan.sys.Duration.m_oneSec    = fan.sys.Duration.make(fan.sys.Duration.nsPerSec);
fan.sys.Duration.m_negOneDay = fan.sys.Duration.make(-fan.sys.Duration.nsPerDay);
fan.sys.Duration.m_boot      = fan.sys.Duration.now();

//
// Endian
//
fan.sys.Endian.m_big    = new fan.sys.Endian(0,  "big");
fan.sys.Endian.m_little = new fan.sys.Endian(1,  "little");

fan.sys.Endian.m_vals = fan.sys.List.make(fan.sys.Endian.$type,
[
  fan.sys.Endian.m_big,
  fan.sys.Endian.m_little
]);

//
// OutStream
//
fan.sys.OutStream.m_xmlEscNewlines = 0x01;
fan.sys.OutStream.m_xmlEscQuotes   = 0x02;
fan.sys.OutStream.m_xmlEscUnicode  = 0x04;

//
// Uri
//
fan.sys.Uri.parentRange = fan.sys.Range.make(0, -2, false);
fan.sys.Uri.m_defVal = fan.sys.Uri.fromStr("");
fan.sys.UriPodBase = "/pod/"; // TODO

//
// MimeType
//
fan.sys.MimeType.m_imagePng  = fan.sys.MimeType.predefined("image", "png");
fan.sys.MimeType.m_imageGif  = fan.sys.MimeType.predefined("image", "gif");
fan.sys.MimeType.m_imageJpeg = fan.sys.MimeType.predefined("image", "jpeg");
fan.sys.MimeType.m_textPlain = fan.sys.MimeType.predefined("text", "plain");
fan.sys.MimeType.m_textHtml  = fan.sys.MimeType.predefined("text", "html");
fan.sys.MimeType.m_textXml   = fan.sys.MimeType.predefined("text", "xml");
fan.sys.MimeType.m_dir       = fan.sys.MimeType.predefined("x-directory", "normal");

//
// LogLevel
//
fan.sys.LogLevel.m_debug  = new fan.sys.LogLevel(0, "debug");
fan.sys.LogLevel.m_info   = new fan.sys.LogLevel(1, "info");
fan.sys.LogLevel.m_warn   = new fan.sys.LogLevel(2, "warn");
fan.sys.LogLevel.m_err    = new fan.sys.LogLevel(3, "err");
fan.sys.LogLevel.m_silent = new fan.sys.LogLevel(4, "silent");

fan.sys.LogLevel.m_vals = fan.sys.List.make(fan.sys.LogLevel.$type,
[
  fan.sys.LogLevel.m_debug,
  fan.sys.LogLevel.m_info,
  fan.sys.LogLevel.m_warn,
  fan.sys.LogLevel.m_err,
  fan.sys.LogLevel.m_silent
]).toImmutable();

//
// Log
//
// TODO FIXTI
//fan.sys.Log.m_handlers.push(fan.sys.LogRec.$type.method("print", true).func());
fan.sys.Log.m_handlers.push(fan.sys.Func.make(
  fan.sys.List.make(fan.sys.Param.$type, new fan.sys.Param("rec", fan.sys.LogRec.$type, false)),
  fan.sys.Void.$type,
  function(rec) { rec.print(); }
));

//
// Month
//
fan.sys.Month.m_jan = new fan.sys.Month(0,  "jan");
fan.sys.Month.m_feb = new fan.sys.Month(1,  "feb");
fan.sys.Month.m_mar = new fan.sys.Month(2,  "mar");
fan.sys.Month.m_apr = new fan.sys.Month(3,  "apr");
fan.sys.Month.m_may = new fan.sys.Month(4,  "may");
fan.sys.Month.m_jun = new fan.sys.Month(5,  "jun");
fan.sys.Month.m_jul = new fan.sys.Month(6,  "jul");
fan.sys.Month.m_aug = new fan.sys.Month(7,  "aug");
fan.sys.Month.m_sep = new fan.sys.Month(8,  "sep");
fan.sys.Month.m_oct = new fan.sys.Month(9,  "oct");
fan.sys.Month.m_nov = new fan.sys.Month(10, "nov");
fan.sys.Month.m_dec = new fan.sys.Month(11, "dec");

fan.sys.Month.m_vals = fan.sys.List.make(fan.sys.Month.$type,
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
]).toImmutable();

//
// Weekday
//
fan.sys.Weekday.m_sun = new fan.sys.Weekday(0,  "sun");
fan.sys.Weekday.m_mon = new fan.sys.Weekday(1,  "mon");
fan.sys.Weekday.m_tue = new fan.sys.Weekday(2,  "tue");
fan.sys.Weekday.m_wed = new fan.sys.Weekday(3,  "wed");
fan.sys.Weekday.m_thu = new fan.sys.Weekday(4,  "thu");
fan.sys.Weekday.m_fri = new fan.sys.Weekday(5,  "fri");
fan.sys.Weekday.m_sat = new fan.sys.Weekday(6,  "sat");

fan.sys.Weekday.m_vals = fan.sys.List.make(fan.sys.Weekday.$type,
[
  fan.sys.Weekday.m_sun,
  fan.sys.Weekday.m_mon,
  fan.sys.Weekday.m_tue,
  fan.sys.Weekday.m_wed,
  fan.sys.Weekday.m_thu,
  fan.sys.Weekday.m_fri,
  fan.sys.Weekday.m_sat
]).toImmutable();

//
// TimeZone
//
// Etc/UTC
tz = new fan.sys.TimeZone();
tz.m_name = "UTC";
tz.m_fullName = "Etc/UTC";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 0;
 rule.stdAbbr = "UTC";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["UTC"] = tz;
fan.sys.TimeZone.cache["Etc/UTC"] = tz;
fan.sys.TimeZone.names.push("UTC");
fan.sys.TimeZone.fullNames.push("Etc/UTC");
fan.sys.TimeZone.m_utc = tz;

// Etc/Rel
tz = new fan.sys.TimeZone();
tz.m_name = "Rel";
tz.m_fullName = "Etc/Rel";
tz.m_rules = [new fan.sys.TimeZone$Rule()];
fan.sys.TimeZone.cache["Rel"] = tz;
fan.sys.TimeZone.cache["Etc/Rel"] = tz;
fan.sys.TimeZone.names.push("Rel");
fan.sys.TimeZone.fullNames.push("Etc/Rel");
fan.sys.TimeZone.m_rel = tz;

//
// DateTime
//
fan.sys.Time.m_defVal = new fan.sys.Time(0, 0, 0, 0);
fan.sys.Date.m_defVal = new fan.sys.Date(2000, 0, 1);
fan.sys.DateTime.m_defVal = fan.sys.DateTime.make(
  2000, fan.sys.Month.m_jan, 1, 0, 0, 0, 0, fan.sys.TimeZone.utc());

//
// Version
//
fan.sys.Version.m_defVal = fan.sys.Version.fromStr("0");

//
// Unit
//
fan.sys.Unit.m_quantityNames = fan.sys.List.make(fan.sys.Str.$type, []);

//
// Env
//
fan.sys.Env.m_configProps   = fan.sys.Uri.fromStr("config.props");
fan.sys.Env.m_localeEnProps = fan.sys.Uri.fromStr("locale/en.props");



