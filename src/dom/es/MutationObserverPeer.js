//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 2016  Andy Frank  Creation
//   10 Jun 2023 Kiera O'Flynn  Refactor to ES
//

class MutationObserverPeer extends sys.Obj {

  constructor(self)
  {
    super();
    this.observer = new js.MutationObserver(function(recs)
    {
      const list = MutationObserverPeer.$makeRecList(recs);
      self.callback()(list);
    });
  }

  observe(self, target, opts)
  {
    const config = {
      childList:             opts.get("childList")      == true,
      attributes:            opts.get("attrs")          == true,
      characterData:         opts.get("charData")       == true,
      subtree:               opts.get("subtree")        == true,
      attributeOldValue:     opts.get("attrOldVal")     == true,
      characterDataOldValue: opts.get("charDataOldVal") == true,
    };
    const filter = opts.get("attrFilter")
    if (filter != null) config.attributeFilter = filter.values();
    this.observer.observe(target.peer.elem, config);
    return self;
  }

  takeRecs = function(self)
  {
    const recs = this.observer.takeRecords();
    return MutationObserverPeer.$makeRecList(recs);
  }

  disconnect = function(self)
  {
    this.observer.disconnect();
  }

  static $makeRec = function(rec)
  {
    const fanRec = MutationRec.make();

    if (rec.type == "attributes")         fanRec.type ("attrs");
    else if (rec.type == "characterData") fanRec.type ("charData");
    else                                  fanRec.type (rec.type);

    fanRec.target (ElemPeer.wrap(rec.target));
    fanRec.attr   (rec.attributeName);
    fanRec.attrNs (rec.attributeNamespace);
    fanRec.oldVal (rec.oldValue);

    if (rec.previousSibling) fanRec.prevSibling (ElemPeer.wrap(rec.previousSibling));
    if (rec.nextSibling)     fanRec.nextSibling (ElemPeer.wrap(rec.nextSibling));

    const added = new Array();
    for (let i=0; i<rec.addedNodes.length; i++)
      added.push(ElemPeer.wrap(rec.addedNodes[i]));
    fanRec.added (sys.List.make(Elem.type$, added));

    const removed = new Array();
    for (let i=0; i<rec.removedNodes.length; i++)
      removed.push(ElemPeer.wrap(rec.removedNodes[i]));
    fanRec.removed (sys.List.make(Elem.type$, removed));

    return fanRec;
  }

  static $makeRecList = function(recs)
  {
    const list = new Array();
    for (let i=0; i<recs.length; i++)
      list.push(MutationObserverPeer.$makeRec(recs[i]));
    return sys.List.make(MutationRec.type$, list);
  }
}