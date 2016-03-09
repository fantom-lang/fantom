//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 2016  Andy Frank  Creation
//

fan.dom.MutationObserverPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.MutationObserverPeer.prototype.$ctor = function(self)
{
  this.observer = new MutationObserver(function(recs)
  {
    var list = fan.dom.MutationObserverPeer.$makeRecList(recs);
    var args = fan.sys.List.make(fan.sys.Obj.$type, [list]);
    self.m_callback.callOn(self, args);
  });
}

fan.dom.MutationObserverPeer.prototype.observe = function(self, target, opts)
{
  var config = {
    childList:             opts.get("childList")      == true ? true : false,
    attributes:            opts.get("attrs")          == true ? true : false,
    characterData:         opts.get("charData")       == true ? true : false,
    subtree:               opts.get("subtree")        == true ? true : false,
    attributeOldValue:     opts.get("attrOldVal")     == true ? true : false,
    characterDataOldValue: opts.get("charDataOldVal") == true ? true : false,
  };
  var filter = opts.get("attrFilter")
  if (filter != null) config.attributeFilter = filter.m_values;
  this.observer.observe(target.peer.elem, config);
  return self;
}

fan.dom.MutationObserverPeer.prototype.takeRecs = function(self)
{
  var recs = this.observer.takeRecords();
  return fan.dom.MutationObserverPeer.$makeRecList(recs);
}

fan.dom.MutationObserverPeer.prototype.disconnect = function(self)
{
  this.observer.disconnect();
}

fan.dom.MutationObserverPeer.$makeRec = function(rec)
{
  var fanRec = fan.dom.MutationRec.make();

  if (rec.type == "attributes") fanRec.m_type = "attrs";
  else if (rec.type == "characterData") fanRec.m_type = "charData";
  else fanRec.m_type = rec.type;

  fanRec.m_target = fan.dom.ElemPeer.wrap(rec.target);
  fanRec.m_attr   = rec.attributeName;
  fanRec.m_attrNs = rec.attributeNamespace;
  fanRec.m_oldVal = rec.oldValue;

  if (rec.previousSibling) fanRec.m_prevSibling = fan.dom.ElemPeer.wrap(rec.previousSibling);
  if (rec.nextSibling) fanRec.m_nextSibling = fan.dom.ElemPeer.wrap(rec.nextSibling);

  var added = new Array();
  for (var i=0; i<rec.addedNodes.length; i++)
    added.push(fan.dom.ElemPeer.wrap(rec.addedNodes[i]));
  fanRec.m_added = fan.sys.List.make(fan.dom.Elem.$type, added);

  var removed = new Array();
  for (var i=0; i<rec.removedNodes.length; i++)
    removed.push(fan.dom.ElemPeer.wrap(rec.removedNodes[i]));
  fanRec.m_removed = fan.sys.List.make(fan.dom.Elem.$type, removed);

  return fanRec;
}

fan.dom.MutationObserverPeer.$makeRecList = function(recs)
{
  var list = new Array();
  for (var i=0; i<recs.length; i++)
    list.push(fan.dom.MutationObserverPeer.$makeRec(recs[i]));
  return fan.sys.List.make(fan.dom.MutationRec.$type, list);
}