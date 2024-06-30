//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  03 Dec 2009  Andy Frank  Creation
//  04 Apr 2023  Matthew Giannini Refactor for ES
//

//
// Pod
//
Pod.sysPod$ = Pod.find("sys");

//
// DateTime
//
DateTime.__boot = DateTime.now();

//
// Num
//
NumPattern.cache$("00");    NumPattern.cache$("000");       NumPattern.cache$("0000");
NumPattern.cache$("0.0");   NumPattern.cache$("0.00");      NumPattern.cache$("0.000");
NumPattern.cache$("0.#");   NumPattern.cache$("#,###.0");   NumPattern.cache$("#,###.#");
NumPattern.cache$("0.##");  NumPattern.cache$("#,###.00");  NumPattern.cache$("#,###.##");
NumPattern.cache$("0.###"); NumPattern.cache$("#,###.000"); NumPattern.cache$("#,###.###");
NumPattern.cache$("0.0#");  NumPattern.cache$("#,###.0#");  NumPattern.cache$("#,###.0#");
NumPattern.cache$("0.0##"); NumPattern.cache$("#,###.0##"); NumPattern.cache$("#,###.0##");
