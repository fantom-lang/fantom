<!--
title:      Slots
author:     Brian Frank
created:    8 Dec 07
copyright:  Copyright (c) 2007, Brian Frank and Andy Frank
license:    Licensed under the Academic Free License version 3.0
-->

# Overview
Types are composed of uniquely named [slots](Structure#slots).
Slots define the state and behavior of the object oriented type.
There are two types of slots:
  - [Fields] define state
  - [Methods] define behavior

# Slot Modifiers
Slots may be annotated with one of the following modifiers:
  - `abstract`: see [fields](Fields#abstract-fields) and [methods](Methods#abstract-methods)
  - `const`: see [fields](Fields#const-fields)
  - `new`: see [methods](Methods#constructors)
  - `internal`: see [protection](#protection)
  - `native`: see [fields](Fields#native-fields) and [methods](Methods#native-methods)
  - `override`: see [fields](Fields#virtual-fields) and [methods](Methods#virtual-methods)
  - `private`: see [protection](#protection)
  - `protected`: see [protection](#protection)
  - `public`: see [protection](#protection)
  - `static`: see [fields](Fields#static-fields) and [methods](Methods#overview)
  - `virtual`: see [fields](Fields#virtual-fields) and [methods](Methods#virtual-methods)

## Protection
A slot can be annotated with one of the following modifiers
to define its visibility:

  - `public`: everyone can access the slot
  - `protected`: only subclasses and types within declaring pod can access the slot
  - `internal`: only types within the declaring pod can access the slot
  - `private`: only declaring type can access the slot

If no protection keyword is specified, the slot defaults to public.
