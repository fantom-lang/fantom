//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 2023  Brian Frank  Creation
//

/**
 * HttpSocket
 */

fan.dom.HttpSocket = fan.sys.Obj.$extend(fan.sys.Obj);
fan.dom.HttpSocket.prototype.$ctor = function() {}

fan.dom.HttpSocket.prototype.$typeof = function()
{
  return fan.dom.HttpSocket.$type;
}

// open
fan.dom.HttpSocket.open = function(uri, protocols)
{
  if (protocols !== undefined) protocols = protocols.m_values;
  console.log("~~ " + uri + " / " + protocols);
  var x = new fan.dom.HttpSocket();
  x.m_uri = uri;
  x.m_socket = new WebSocket(uri.encode(), protocols);
  x.m_socket.binaryType = "arraybuffer";
  return x;
}

// uri
fan.dom.HttpSocket.prototype.uri = function()
{
  return this.m_uri;
}

// send
fan.dom.HttpSocket.prototype.send = function(data)
{
  if (data instanceof fan.sys.MemBuf)
    data = new Uint8Array(data.getBytes(0, data.size())).buffer;
  this.m_socket.send(data);
}

// close
fan.dom.HttpSocket.prototype.close = function()
{
  this.m_socket.close();
}

// onOpen
fan.dom.HttpSocket.prototype.onOpen = function(cb)
{
  this.m_socket.onopen = (e) => {
    cb.call(fan.dom.EventPeer.make(e));
  }
}

// onReceive
fan.dom.HttpSocket.prototype.onReceive = function(cb)
{
  this.m_socket.onmessage = (e) => {
    cb.call(fan.dom.EventPeer.make(e));
  }
}

// onClose
fan.dom.HttpSocket.prototype.onClose = function(cb)
{
  this.m_socket.onclose = (e) => {
    cb.call(fan.dom.EventPeer.make(e));
  }
}

// onError
fan.dom.HttpSocket.prototype.onError = function(cb)
{
  this.m_socket.onerror = (e) => {
    cb.call(fan.dom.EventPeer.make(e));
  }
}

