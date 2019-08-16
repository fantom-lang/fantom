//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Feb 2015  Brian Frank  Creation
//

using dom

**
** Selection manages the selected items and/or indexes
**
@Js abstract class Selection
{
  ** Enable or disable selection.
  Bool enabled := true

  ** True to enable multiple selection, false for single selection.
  Bool multi := false
  {
    set { &multi=it; refresh }
  }

  ** Is the selection currently empty
  abstract Bool isEmpty()

  ** Number of selected items
  abstract Int size()

  ** Get or set a single item
  abstract Obj? item

  ** Selected items.
  abstract Obj[] items

  ** Get or set a single index
  abstract Int? index

  ** Selected zero based indexes
  abstract Int[] indexes

  ** Clear the selection
  Void clear() { items = Obj[,] }

  ** Validate selection.
  internal virtual Void refresh() {}
}

**************************************************************************
** IndexSelection
**************************************************************************

** Internal implementation for supporting index-based Selection widgets.
@NoDoc @Js abstract class IndexSelection : Selection
{

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  override Bool isEmpty() { indexes.isEmpty }

  override Int size() { indexes.size }

  override Obj? item
  {
    get { items.first }
    set { items = (it == null) ? Obj[,] : [it] }
  }

  override Obj[] items
  {
    get { toItems(indexes) }
    set { indexes = toIndexes(it) }
  }

  override Int? index
  {
    get { indexes.first }
    set { indexes = (it == null) ? Int[,] : [it] }
  }

  override Int[] indexes := [,]
  {
    set
    {
      if (!enabled) return
      oldIndexes := &indexes
      newIndexes := checkIndexes(it).sort.ro
      &indexes = newIndexes
      onUpdate(oldIndexes, newIndexes)
    }
  }

  internal override Void refresh()
  {
    temp := indexes
    indexes = temp
  }

//////////////////////////////////////////////////////////////////////////
// Subclass Hooks
//////////////////////////////////////////////////////////////////////////

  ** Max number of items
  protected abstract Int max()

  ** Lookup item at given index
  protected abstract Obj toItem(Int index)

  ** Lookup index for given item
  protected abstract Int? toIndex(Obj item)

  ** Callback when selection is modified
  protected abstract Void onUpdate(Int[] oldIndexes, Int[] newIndexes)

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Verify that all indexes are less than max and enforce multi
  private Int[] checkIndexes(Int[] indexes)
  {
    checked := indexes.findAll |index| { 0 <= index && index < max }
    if (!multi && checked.size > 1) checked = [checked.first]
    return checked
  }

  ** List of indexes to items
  private Obj[] toItems(Int[] indexes)
  {
    max := this.max
    acc := Obj[,]
    acc.capacity = indexes.size
    indexes.each |index|
    {
      if (index < max)
      {
        item := toItem(index)
        acc.add(item)
      }
    }
    return acc
  }

  ** List of items to indexes
  private Int[] toIndexes(Obj[] items)
  {
    acc := Int[,]
    acc.capacity = items.size
    items.each |item|
    {
      index := toIndex(item)
      if (index != null) acc.add(index)
    }
    return acc
  }
}