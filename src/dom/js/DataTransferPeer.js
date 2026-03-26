//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 2015  Andy Frank  Creation
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class DataTransferPeer extends sys.Obj {

  constructor(self) { super(); }

  dataTx;
  data;

  dropEffect(self, it)
  {
    if (it===undefined) return this.dataTx.dropEffect;
    else this.dataTx.dropEffect = it;
  }

  effectAllowed(self, it)
  {
    if (it===undefined) return this.dataTx.effectAllowed;
    else this.dataTx.effectAllowed = it;
  }

  types(self)
  {
    const list = sys.List.make(sys.Str.type$);
    for (let i=0; i<this.dataTx.types.length; i++) list.add(this.dataTx.types[i]);
    return list;
  }

  getData(self, type)
  {
    let val = this.dataTx.getData(type);
    if (val === "") val = this.data[type] || "";
    return val;
  }

  setData(self, type, val)
  {
    // we keep a backup of data for WebKit workaround - see EventPeer.dataTransfer
    this.data[type] = val;
    return this.dataTx.setData(type, val);
  }

  setDragImage(self, image, x, y)
  {
    this.dataTx.setDragImage(image.peer.elem, x, y);
    return self;
  }

  files(self)
  {
    if (this.dataTx.files.length == 0)
      return DomFile.type$.emptyList();

    const list = sys.List.make(DomFile.type$);
    for (let i=0; i<this.dataTx.files.length; i++)
        list.add(DomFilePeer.wrap(this.dataTx.files[i]));
    return list;
  }

  static make(dataTx)
  {
    const x = DataTransfer.make();
    x.peer.dataTx = dataTx;
    x.peer.data = {};
    return x;
  }
}