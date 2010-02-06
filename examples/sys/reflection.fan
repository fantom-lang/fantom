#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 08  Brian Frank  Creation
//   08 Sep 09  Brian Frank  Rework fandoc -> example
//

using fwt

**
** Working with Pod, Type, Slot, Field, Method, and Symbol
** reflection APIs.
**
class Reflection
{
  Void main()
  {
    pods
    types
    slots
    methods
    fields
  }

  Void pods()
  {
    echo("\n--- pods ---")
    p := Pod.find("compiler")
    show(Pod.list,                     "list the pods installed")
    show(Pod.find("compiler"),         "find a pod (throws err if not found)")
    show(Pod.find("bad", false),       "find a pod (returns null if not found)")
    show(p.name,                       "pod name")
    show(p.version,                    "pod version")
    show(p.meta,                       "all pod meta name/value metadata pairs")
    show(p.meta["build.time"],         "lookup a pod metadata key")
    show(p.file(`/img/icon.png`, false), "lookup a resource file in myPod")
  }

  Void types()
  {
    echo("\n--- types ---")
    pod := Pod.find("fwt")
    t := pod.type("Button")
    show("foo".typeof,                   "get the type of the an object")
    show(pod.types,                      "list the types in myPod")
    show(pod.type("Button"),             "find a type in pod by simple name")
    show(pod.type("Foo", false),         "returns null if type not found")
    show(Type.find("fwt::Label"),        "lookup a type by its qualified name")
    show(Type.find("fwt::Foo", false),   "returns null if type not found")
    show(Int#,                           "type literal for sys::Int")
    show(Int?[]#,                        "type literal for sys::Int?[]")
    show(t.fits(Num#),                   "reflective is/instanceof operator")
    show(t.pod,                          "get the pod of a type")
    show(t.qname,                        "qualified name of type")
    show(t.name,                         "simple unqualified name of type")
    show(t.base,                         "type's base class")
    show(t.mixins,                       "type's mixins or empty list")
    show(t.inheritance,                  "all the types inherited")
    show(t.signature,                    "formal type signature")
    show(t.make,                         "make an obj of type t")
    show(t.facets,                       "list of all declared facets")
    show(t.facet(Serializable#, false),  "lookup facet")
    show(t.hasFacet(Serializable#),      "check if facet defined")
  }

  Void slots()
  {
    echo("\n--- slots ---")
    t := Type.find("fwt::Widget")
    s := t.slot("onFocus")
    show(t.slot("relayout"),           "lookup the slot called xyz on someType")
    show(t.slots,                      "list all the slots on someType")
    show(Slot.find("fwt::Widget.enabled"),    "looukp a slot by its qualified name")
    show(Slot.find("fwt::Widget.foo", false), "returns null if slot not found")
    show(Widget#enabled,               "slot literal")
    show(#main,                        "slot literal (in enclosing class)")
    show(s.qname,                      "qualified name")
    show(s.name,                       "unqualified simple name")
    show(s.parent,                     "declaring type")
    show(s.signature,                  "full signature of field or method")
    show(s.facets,                     "map of all facets")
    show(s.facet(Transient#, false),   "lookup facet")
    show(s.hasFacet(Transient#),       "check if facet defined")
  }

  Void methods()
  {
    echo("\n--- methods ---")
    t  := Str#
    m  := Str#toInt
    ms := Str#spaces
    show(t.method("split"),            "lookup the method called xyz on someType")
    show(t.method("foo", false),       "returns null if method not found")
    show(t.methods,                    "list all the methods on someType")
    show(Slot.findMethod("sys::Str.split"),      "looukp a method by its qualified name")
    show(Slot.findMethod("sys::Str.foo", false), "returns null if method not found")
    show(m.returns,                    "return type of method")
    show(m.params,                     "list of parameters")
    show(ms.callList([3])->toCode,     "invoke static method using reflection")
    show(ms.call(3)->toCode,           "same as above")
    show(m.callOn("100", [16]),        "invoke instance method using reflection")
    show(m.call("100", 16),            "same as above")
    show(m.func,                       "the function which implements the method")
  }

  Void fields()
  {
    echo("\n--- fields ---")
    t   := Type.find("fwt::Label")
    obj := t.make
    f   := t.field("text")
    show(t.field("onBlur"),            "lookup the field called xyz on someType")
    show(t.field("x", false),          "returns null if field not found")
    show(t.fields,                     "list all the fields on someType")
    show(Slot.findField("fwt::Label.text"),       "looukp a field by its qualified name")
    show(Slot.findField("fwt::Label.foo", false),  "returns null if field not found")
    show(f.type,                       "type of field")
    f.set(obj, "hi")                   // set instance field
    show(f.get(obj),                   "get instance field")
    show(Float#pi.get,                 "get static field")
  }

  Void show(Obj? result, Str what)
  {
    resultStr := "" + result
    if (resultStr.size > 40) resultStr = resultStr[0..40] + "..."
    echo(what.padr(40) + " => " + resultStr)
  }
}




