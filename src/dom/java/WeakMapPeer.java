//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import java.lang.ref.ReferenceQueue;
import java.lang.ref.WeakReference;
import java.util.HashMap;

/**
 * WeakMapPeer maps a key to a value for as long as the key is
 * reachable.  A key is the object itself, as in JavaScript, whatever
 * its equals says.
 */
public class WeakMapPeer
{
  public static WeakMapPeer make(WeakMap fan) { return new WeakMapPeer(); }

  public boolean has(WeakMap self, Object key) { purge(); return map.containsKey(new Key(key, null)); }

  public Object get(WeakMap self, Object key) { purge(); return map.get(new Key(key, null)); }

  public WeakMap set(WeakMap self, Object key, Object val)
  {
    purge();
    map.put(new Key(key, queue), val);
    return self;
  }

  public boolean delete(WeakMap self, Object key)
  {
    purge();
    Key k = new Key(key, null);
    boolean had = map.containsKey(k);
    map.remove(k);
    return had;
  }

  // drop the entries whose key was collected
  private void purge()
  {
    for (Object k = queue.poll(); k != null; k = queue.poll()) map.remove(k);
  }

  // A key by identity, which still equals itself once its object is
  // collected so that it can be dropped
  static class Key extends WeakReference
  {
    Key(Object key, ReferenceQueue queue) { super(key, queue); this.hash = System.identityHashCode(key); }
    public int hashCode() { return hash; }
    public boolean equals(Object that)
    {
      if (this == that) return true;
      Object key = get();
      return key != null && that instanceof Key && ((Key)that).get() == key;
    }
    final int hash;
  }

  private final HashMap map = new HashMap();   // Key:Obj
  private final ReferenceQueue queue = new ReferenceQueue();
}
