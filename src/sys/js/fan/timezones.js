//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// Auto-generated 2010-03-15T13:20:30.368-04:00 New_York
//

var tz,rule;

// Europe/Amsterdam
tz = new fan.sys.TimeZone();
tz.m_name = "Amsterdam";
tz.m_fullName = "Europe/Amsterdam";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1996;
 rule.offset = 3600;
 rule.stdAbbr = "CET";
 rule.dstOffset = 3600;
 rule.dstAbbr = "CEST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 3600;
 rule.stdAbbr = "CET";
 rule.dstOffset = 3600;
 rule.dstAbbr = "CEST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Amsterdam"] = tz;
fan.sys.TimeZone.cache["Europe/Amsterdam"] = tz;
fan.sys.TimeZone.names.push("Amsterdam");
fan.sys.TimeZone.fullNames.push("Europe/Amsterdam");

// America/Chicago
tz = new fan.sys.TimeZone();
tz.m_name = "Chicago";
tz.m_fullName = "America/Chicago";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = -21600;
 rule.stdAbbr = "CST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "CDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 0, 8, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(10, 62, 0, 1, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -21600;
 rule.stdAbbr = "CST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "CDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 62, 0, 1, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 119);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Chicago"] = tz;
fan.sys.TimeZone.cache["America/Chicago"] = tz;
fan.sys.TimeZone.names.push("Chicago");
fan.sys.TimeZone.fullNames.push("America/Chicago");

// America/Denver
tz = new fan.sys.TimeZone();
tz.m_name = "Denver";
tz.m_fullName = "America/Denver";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = -25200;
 rule.stdAbbr = "MST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "MDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 0, 8, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(10, 62, 0, 1, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -25200;
 rule.stdAbbr = "MST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "MDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 62, 0, 1, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 119);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Denver"] = tz;
fan.sys.TimeZone.cache["America/Denver"] = tz;
fan.sys.TimeZone.names.push("Denver");
fan.sys.TimeZone.fullNames.push("America/Denver");

// Etc/GMT
tz = new fan.sys.TimeZone();
tz.m_name = "GMT";
tz.m_fullName = "Etc/GMT";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 0;
 rule.stdAbbr = "GMT";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT"] = tz;
fan.sys.TimeZone.cache["Etc/GMT"] = tz;
fan.sys.TimeZone.names.push("GMT");
fan.sys.TimeZone.fullNames.push("Etc/GMT");

// Etc/GMT+1
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+1";
tz.m_fullName = "Etc/GMT+1";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -3600;
 rule.stdAbbr = "GMT+1";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+1"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+1"] = tz;
fan.sys.TimeZone.names.push("GMT+1");
fan.sys.TimeZone.fullNames.push("Etc/GMT+1");

// Etc/GMT+10
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+10";
tz.m_fullName = "Etc/GMT+10";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -36000;
 rule.stdAbbr = "GMT+10";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+10"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+10"] = tz;
fan.sys.TimeZone.names.push("GMT+10");
fan.sys.TimeZone.fullNames.push("Etc/GMT+10");

// Etc/GMT+11
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+11";
tz.m_fullName = "Etc/GMT+11";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -39600;
 rule.stdAbbr = "GMT+11";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+11"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+11"] = tz;
fan.sys.TimeZone.names.push("GMT+11");
fan.sys.TimeZone.fullNames.push("Etc/GMT+11");

// Etc/GMT+12
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+12";
tz.m_fullName = "Etc/GMT+12";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -43200;
 rule.stdAbbr = "GMT+12";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+12"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+12"] = tz;
fan.sys.TimeZone.names.push("GMT+12");
fan.sys.TimeZone.fullNames.push("Etc/GMT+12");

// Etc/GMT+2
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+2";
tz.m_fullName = "Etc/GMT+2";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -7200;
 rule.stdAbbr = "GMT+2";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+2"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+2"] = tz;
fan.sys.TimeZone.names.push("GMT+2");
fan.sys.TimeZone.fullNames.push("Etc/GMT+2");

// Etc/GMT+3
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+3";
tz.m_fullName = "Etc/GMT+3";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -10800;
 rule.stdAbbr = "GMT+3";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+3"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+3"] = tz;
fan.sys.TimeZone.names.push("GMT+3");
fan.sys.TimeZone.fullNames.push("Etc/GMT+3");

// Etc/GMT+4
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+4";
tz.m_fullName = "Etc/GMT+4";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -14400;
 rule.stdAbbr = "GMT+4";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+4"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+4"] = tz;
fan.sys.TimeZone.names.push("GMT+4");
fan.sys.TimeZone.fullNames.push("Etc/GMT+4");

// Etc/GMT+5
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+5";
tz.m_fullName = "Etc/GMT+5";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -18000;
 rule.stdAbbr = "GMT+5";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+5"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+5"] = tz;
fan.sys.TimeZone.names.push("GMT+5");
fan.sys.TimeZone.fullNames.push("Etc/GMT+5");

// Etc/GMT+6
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+6";
tz.m_fullName = "Etc/GMT+6";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -21600;
 rule.stdAbbr = "GMT+6";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+6"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+6"] = tz;
fan.sys.TimeZone.names.push("GMT+6");
fan.sys.TimeZone.fullNames.push("Etc/GMT+6");

// Etc/GMT+7
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+7";
tz.m_fullName = "Etc/GMT+7";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -25200;
 rule.stdAbbr = "GMT+7";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+7"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+7"] = tz;
fan.sys.TimeZone.names.push("GMT+7");
fan.sys.TimeZone.fullNames.push("Etc/GMT+7");

// Etc/GMT+8
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+8";
tz.m_fullName = "Etc/GMT+8";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -28800;
 rule.stdAbbr = "GMT+8";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+8"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+8"] = tz;
fan.sys.TimeZone.names.push("GMT+8");
fan.sys.TimeZone.fullNames.push("Etc/GMT+8");

// Etc/GMT+9
tz = new fan.sys.TimeZone();
tz.m_name = "GMT+9";
tz.m_fullName = "Etc/GMT+9";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -32400;
 rule.stdAbbr = "GMT+9";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT+9"] = tz;
fan.sys.TimeZone.cache["Etc/GMT+9"] = tz;
fan.sys.TimeZone.names.push("GMT+9");
fan.sys.TimeZone.fullNames.push("Etc/GMT+9");

// Etc/GMT-1
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-1";
tz.m_fullName = "Etc/GMT-1";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 3600;
 rule.stdAbbr = "GMT-1";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-1"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-1"] = tz;
fan.sys.TimeZone.names.push("GMT-1");
fan.sys.TimeZone.fullNames.push("Etc/GMT-1");

// Etc/GMT-10
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-10";
tz.m_fullName = "Etc/GMT-10";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 36000;
 rule.stdAbbr = "GMT-10";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-10"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-10"] = tz;
fan.sys.TimeZone.names.push("GMT-10");
fan.sys.TimeZone.fullNames.push("Etc/GMT-10");

// Etc/GMT-11
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-11";
tz.m_fullName = "Etc/GMT-11";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 39600;
 rule.stdAbbr = "GMT-11";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-11"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-11"] = tz;
fan.sys.TimeZone.names.push("GMT-11");
fan.sys.TimeZone.fullNames.push("Etc/GMT-11");

// Etc/GMT-12
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-12";
tz.m_fullName = "Etc/GMT-12";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 43200;
 rule.stdAbbr = "GMT-12";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-12"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-12"] = tz;
fan.sys.TimeZone.names.push("GMT-12");
fan.sys.TimeZone.fullNames.push("Etc/GMT-12");

// Etc/GMT-13
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-13";
tz.m_fullName = "Etc/GMT-13";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 46800;
 rule.stdAbbr = "GMT-13";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-13"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-13"] = tz;
fan.sys.TimeZone.names.push("GMT-13");
fan.sys.TimeZone.fullNames.push("Etc/GMT-13");

// Etc/GMT-14
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-14";
tz.m_fullName = "Etc/GMT-14";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 50400;
 rule.stdAbbr = "GMT-14";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-14"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-14"] = tz;
fan.sys.TimeZone.names.push("GMT-14");
fan.sys.TimeZone.fullNames.push("Etc/GMT-14");

// Etc/GMT-2
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-2";
tz.m_fullName = "Etc/GMT-2";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 7200;
 rule.stdAbbr = "GMT-2";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-2"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-2"] = tz;
fan.sys.TimeZone.names.push("GMT-2");
fan.sys.TimeZone.fullNames.push("Etc/GMT-2");

// Etc/GMT-3
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-3";
tz.m_fullName = "Etc/GMT-3";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 10800;
 rule.stdAbbr = "GMT-3";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-3"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-3"] = tz;
fan.sys.TimeZone.names.push("GMT-3");
fan.sys.TimeZone.fullNames.push("Etc/GMT-3");

// Etc/GMT-4
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-4";
tz.m_fullName = "Etc/GMT-4";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 14400;
 rule.stdAbbr = "GMT-4";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-4"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-4"] = tz;
fan.sys.TimeZone.names.push("GMT-4");
fan.sys.TimeZone.fullNames.push("Etc/GMT-4");

// Etc/GMT-5
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-5";
tz.m_fullName = "Etc/GMT-5";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 18000;
 rule.stdAbbr = "GMT-5";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-5"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-5"] = tz;
fan.sys.TimeZone.names.push("GMT-5");
fan.sys.TimeZone.fullNames.push("Etc/GMT-5");

// Etc/GMT-6
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-6";
tz.m_fullName = "Etc/GMT-6";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 21600;
 rule.stdAbbr = "GMT-6";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-6"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-6"] = tz;
fan.sys.TimeZone.names.push("GMT-6");
fan.sys.TimeZone.fullNames.push("Etc/GMT-6");

// Etc/GMT-7
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-7";
tz.m_fullName = "Etc/GMT-7";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 25200;
 rule.stdAbbr = "GMT-7";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-7"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-7"] = tz;
fan.sys.TimeZone.names.push("GMT-7");
fan.sys.TimeZone.fullNames.push("Etc/GMT-7");

// Etc/GMT-8
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-8";
tz.m_fullName = "Etc/GMT-8";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 28800;
 rule.stdAbbr = "GMT-8";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-8"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-8"] = tz;
fan.sys.TimeZone.names.push("GMT-8");
fan.sys.TimeZone.fullNames.push("Etc/GMT-8");

// Etc/GMT-9
tz = new fan.sys.TimeZone();
tz.m_name = "GMT-9";
tz.m_fullName = "Etc/GMT-9";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 32400;
 rule.stdAbbr = "GMT-9";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["GMT-9"] = tz;
fan.sys.TimeZone.cache["Etc/GMT-9"] = tz;
fan.sys.TimeZone.names.push("GMT-9");
fan.sys.TimeZone.fullNames.push("Etc/GMT-9");

// America/Godthab
tz = new fan.sys.TimeZone();
tz.m_name = "Godthab";
tz.m_fullName = "America/Godthab";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1996;
 rule.offset = -10800;
 rule.stdAbbr = "WGT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "WGST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -10800;
 rule.stdAbbr = "WGT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "WGST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Godthab"] = tz;
fan.sys.TimeZone.cache["America/Godthab"] = tz;
fan.sys.TimeZone.names.push("Godthab");
fan.sys.TimeZone.fullNames.push("America/Godthab");

// Asia/Jerusalem
tz = new fan.sys.TimeZone();
tz.m_name = "Jerusalem";
tz.m_fullName = "Asia/Jerusalem";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2020;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 27, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2019;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 6, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2018;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 16, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2017;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 24, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2016;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 100, 0, 1, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 9, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2015;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 20, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2014;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 28, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2013;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 8, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2012;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 23, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2011;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 100, 0, 1, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 2, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2010;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 12, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2009;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 27, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2008;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 5, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 16, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2006;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 5, 26, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 1, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2005;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 100, 0, 1, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 9, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2004;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 100, 0, 7, 3600, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 22, 3600, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2003;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 100, 0, 28, 3600, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 3, 3600, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2002;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 100, 0, 29, 3600, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 7, 3600, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2001;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 100, 0, 9, 3600, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 24, 3600, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2000;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 100, 0, 14, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 100, 0, 6, 3600, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1999;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 100, 0, 2, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 3, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1998;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 100, 0, 20, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 6, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1997;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 100, 0, 21, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 14, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1996;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 100, 0, 15, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 16, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 7200;
 rule.stdAbbr = "IST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "IDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 100, 0, 31, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 100, 0, 3, 0, 119);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Jerusalem"] = tz;
fan.sys.TimeZone.cache["Asia/Jerusalem"] = tz;
fan.sys.TimeZone.names.push("Jerusalem");
fan.sys.TimeZone.fullNames.push("Asia/Jerusalem");

// Europe/Kiev
tz = new fan.sys.TimeZone();
tz.m_name = "Kiev";
tz.m_fullName = "Europe/Kiev";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1996;
 rule.offset = 7200;
 rule.stdAbbr = "EET";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EEST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 7200;
 rule.stdAbbr = "EET";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EEST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Kiev"] = tz;
fan.sys.TimeZone.cache["Europe/Kiev"] = tz;
fan.sys.TimeZone.names.push("Kiev");
fan.sys.TimeZone.fullNames.push("Europe/Kiev");

// Europe/London
tz = new fan.sys.TimeZone();
tz.m_name = "London";
tz.m_fullName = "Europe/London";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1996;
 rule.offset = 0;
 rule.stdAbbr = "GMT/BST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "GMT/BST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 0;
 rule.stdAbbr = "G";
 rule.dstOffset = 3600;
 rule.dstAbbr = "B";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 62, 0, 22, 3600, 117);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["London"] = tz;
fan.sys.TimeZone.cache["Europe/London"] = tz;
fan.sys.TimeZone.names.push("London");
fan.sys.TimeZone.fullNames.push("Europe/London");

// America/Los_Angeles
tz = new fan.sys.TimeZone();
tz.m_name = "Los_Angeles";
tz.m_fullName = "America/Los_Angeles";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = -28800;
 rule.stdAbbr = "PST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "PDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 0, 8, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(10, 62, 0, 1, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -28800;
 rule.stdAbbr = "PST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "PDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 62, 0, 1, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 119);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Los_Angeles"] = tz;
fan.sys.TimeZone.cache["America/Los_Angeles"] = tz;
fan.sys.TimeZone.names.push("Los_Angeles");
fan.sys.TimeZone.fullNames.push("America/Los_Angeles");

// America/New_York
tz = new fan.sys.TimeZone();
tz.m_name = "New_York";
tz.m_fullName = "America/New_York";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = -18000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 0, 8, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(10, 62, 0, 1, 7200, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -18000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 62, 0, 1, 7200, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 119);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["New_York"] = tz;
fan.sys.TimeZone.cache["America/New_York"] = tz;
fan.sys.TimeZone.names.push("New_York");
fan.sys.TimeZone.fullNames.push("America/New_York");

// Europe/Riga
tz = new fan.sys.TimeZone();
tz.m_name = "Riga";
tz.m_fullName = "Europe/Riga";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2001;
 rule.offset = 7200;
 rule.stdAbbr = "EET";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EEST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2000;
 rule.offset = 7200;
 rule.stdAbbr = "EET";
 rule.dstOffset = 0;
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1997;
 rule.offset = 7200;
 rule.stdAbbr = "EET";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EEST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 3600, 117);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 3600, 117);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 7200;
 rule.stdAbbr = "EET";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EEST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(8, 108, 0, 0, 7200, 115);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Riga"] = tz;
fan.sys.TimeZone.cache["Europe/Riga"] = tz;
fan.sys.TimeZone.names.push("Riga");
fan.sys.TimeZone.fullNames.push("Europe/Riga");

// America/Sao_Paulo
tz = new fan.sys.TimeZone();
tz.m_name = "Sao_Paulo";
tz.m_fullName = "America/Sao_Paulo";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(10, 62, 0, 1, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 108, 0, 0, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2006;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(10, 62, 0, 1, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 62, 0, 15, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2005;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 100, 0, 16, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 62, 0, 15, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2004;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(10, 100, 0, 2, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 62, 0, 15, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2003;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 100, 0, 19, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 62, 0, 15, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2002;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(10, 100, 0, 3, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 62, 0, 15, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2001;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 62, 0, 8, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 62, 0, 15, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2000;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 62, 0, 8, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 100, 0, 27, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1999;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 100, 0, 3, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 100, 0, 21, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1998;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 100, 0, 11, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(2, 100, 0, 1, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1997;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 100, 0, 6, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 100, 0, 16, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1996;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 100, 0, 6, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 100, 0, 11, 0, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -10800;
 rule.stdAbbr = "BRT";
 rule.dstOffset = 3600;
 rule.dstAbbr = "BRST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 62, 0, 11, 0, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(1, 62, 0, 15, 0, 119);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Sao_Paulo"] = tz;
fan.sys.TimeZone.cache["America/Sao_Paulo"] = tz;
fan.sys.TimeZone.names.push("Sao_Paulo");
fan.sys.TimeZone.fullNames.push("America/Sao_Paulo");

// America/St_Johns
tz = new fan.sys.TimeZone();
tz.m_name = "St_Johns";
tz.m_fullName = "America/St_Johns";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = -12600;
 rule.stdAbbr = "NST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "NDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(2, 62, 0, 8, 60, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(10, 62, 0, 1, 60, 119);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = -12600;
 rule.stdAbbr = "NST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "NDT";
 rule.dstStart = new fan.sys.TimeZone$DstTime(3, 62, 0, 1, 60, 119);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 60, 119);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["St_Johns"] = tz;
fan.sys.TimeZone.cache["America/St_Johns"] = tz;
fan.sys.TimeZone.names.push("St_Johns");
fan.sys.TimeZone.fullNames.push("America/St_Johns");

// Australia/Sydney
tz = new fan.sys.TimeZone();
tz.m_name = "Sydney";
tz.m_fullName = "Australia/Sydney";
tz.m_rules = [];
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2008;
 rule.offset = 36000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 62, 0, 1, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(3, 62, 0, 1, 7200, 115);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2007;
 rule.offset = 36000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 7200, 115);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2006;
 rule.offset = 36000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(3, 62, 0, 1, 7200, 115);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2001;
 rule.offset = 36000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 7200, 115);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 2000;
 rule.offset = 36000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(7, 108, 0, 0, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 7200, 115);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1996;
 rule.offset = 36000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(2, 108, 0, 0, 7200, 115);
 tz.m_rules.push(rule);
rule = new fan.sys.TimeZone$Rule();
 rule.startYear = 1995;
 rule.offset = 36000;
 rule.stdAbbr = "EST";
 rule.dstOffset = 3600;
 rule.dstAbbr = "EST";
 rule.dstStart = new fan.sys.TimeZone$DstTime(9, 108, 0, 0, 7200, 115);
 rule.dstEnd = new fan.sys.TimeZone$DstTime(2, 62, 0, 1, 7200, 115);
 tz.m_rules.push(rule);
fan.sys.TimeZone.cache["Sydney"] = tz;
fan.sys.TimeZone.cache["Australia/Sydney"] = tz;
fan.sys.TimeZone.names.push("Sydney");
fan.sys.TimeZone.fullNames.push("Australia/Sydney");

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

// DateTime.defVal
fan.sys.DateTime.m_defVal = fan.sys.DateTime.make(2000, fan.sys.Month.m_jan, 1, 0, 0, 0, 0, fan.sys.TimeZone.utc());
fan.sys.DateTime.m_boot = fan.sys.DateTime.now();

