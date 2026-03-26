//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Aug 2023  Brian Frank  Creation
//

/**
 * HttpSocket
 */

class HttpSocket extends sys.Obj {

  constructor() { super(); }
  typeof() { return HttpSocket.type$; }

  // open
  static open(uri, protocols)
  {
    if (protocols !== undefined) protocols = protocols.__values();
    console.log("~~ " + uri + " / " + protocols);
    var x = new HttpSocket();
    x.#uri = uri;
    x.#socket = new WebSocket(uri.encode(), protocols);
    x.#socket.binaryType = "arraybuffer";
    return x;
  }

  // WebSocket instance
  #socket;

  // uri
  uri() { return this.#uri; }
  #uri;

  // send
  send(data)
  {
    if (data instanceof sys.MemBuf)
      data = new Uint8Array(data.__getBytes(0, data.size())).buffer;
    this.#socket.send(data);
  }

  // close
  close()
  {
    this.#socket.close();
  }

  // onOpen
  onOpen(cb)
  {
    this.#socket.onopen = (e) => {
      cb(EventPeer.make(e));
    }
  }

  // onReceive
  onReceive(cb)
  {
    this.#socket.onmessage = (e) => {
      cb(EventPeer.make(e));
    }
  }

  // onClose
  onClose(cb)
  {
    this.#socket.onclose = (e) => {
      cb(EventPeer.make(e));
    }
  }

  // onError
  onError(cb)
  {
    this.#socket.onerror = (e) => {
      cb(EventPeer.make(e));
    }
  }
}

