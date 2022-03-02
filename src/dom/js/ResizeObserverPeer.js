//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2022  Andy Frank  Creation
//

fan.dom.ResizeObserverPeer = fan.sys.Obj.$extend(fan.sys.Obj);

fan.dom.ResizeObserverPeer.prototype.$ctor = function(self)
{
  this.observer = new ResizeObserver(function(entries)
  {
    if (self.m_callback != null)
    {
      var list = fan.dom.ResizeObserverPeer.$makeEntryList(entries);
      var args = fan.sys.List.make(fan.sys.Obj.$type, [list]);
      self.m_callback.callOn(self, args);
    }
  });
}

fan.dom.ResizeObserverPeer.prototype.observe = function(self, target)
{
  this.observer.observe(target.peer.elem);
  return self;
}

fan.dom.ResizeObserverPeer.prototype.unobserve = function(self, target)
{
  this.observer.unobserve(target.peer.elem);
  return self;
}

fan.dom.ResizeObserverPeer.prototype.disconnect = function(self)
{
  this.observer.disconnect();
}

fan.dom.ResizeObserverPeer.$makeEntryList = function(entries)
{
  var list = new Array();
  for (var i=0; i<entries.length; i++)
    list.push(fan.dom.ResizeObserverPeer.$makeEntry(entries[i]));
  return fan.sys.List.make(fan.dom.ResizeObserver.$type, list);
}

fan.dom.ResizeObserverPeer.$makeEntry = function(entry)
{
  var w  = entry.contentRect.width;
  var h  = entry.contentRect.height;
  var re = fan.dom.ResizeObserverEntry.make();
  re.m_target = fan.dom.ElemPeer.wrap(entry.target);
  re.m_size   = fan.graphics.Size.make(w, h);
  return re;
}