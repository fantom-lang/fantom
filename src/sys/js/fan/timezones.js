//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// Auto-generated 2009-07-08T14:18:51.807-04:00 New_York
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

