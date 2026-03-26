//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Andy Frank  Creation
//   10 Jun 2023 Kiera O'Flynn  Refactor to ES
//

class ResizeObserverPeer extends sys.Obj {

  constructor(self)
  {
    super();
    this.observer = new js.ResizeObserver(function(entries)
    {
      if (self.callback() != null)
      {
        const list = ResizeObserverPeer.$makeEntryList(entries);
        const args = sys.List.make(sys.Obj.type$, [list]);
        self.callback()(args);
      }
    });
  }

  observe(self, target)
  {
    this.observer.observe(target.peer.elem);
    return self;
  }

  unobserve(self, target)
  {
    this.observer.unobserve(target.peer.elem);
    return self;
  }

  disconnect(self)
  {
    this.observer.disconnect();
  }

  static $makeEntryList(entries)
  {
    const list = new Array();
    for (let i=0; i<entries.length; i++)
      list.push(ResizeObserverPeer.$makeEntry(entries[i]));
    return sys.List.make(ResizeObserver.type$, list);
  }

  static $makeEntry(entry)
  {
    const w   = entry.contentRect.width;
    const h   = entry.contentRect.height;
    const re  = ResizeObserverEntry.make();
    re.target (ElemPeer.wrap(entry.target));
    re.size   (graphics.Size.make(w, h));
    return re;
  }
}