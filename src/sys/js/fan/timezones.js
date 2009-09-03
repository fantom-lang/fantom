//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// Auto-generated 2009-07-13T21:28:59.254-04:00 New_York
//

var tz,rule;

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

// DateTime.defVal
fan.sys.DateTime.m_defVal = fan.sys.DateTime.make(2000, fan.sys.Month.m_jan, 1, 0, 0, 0, 0, fan.sys.TimeZone.utc());

