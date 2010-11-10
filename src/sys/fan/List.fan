//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//

**
** List represents an liner sequence of Objects indexed by an Int.
**
** See [examples]`examples::sys-lists`.
**
@Serializable
final class List
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor with of type and initial capacity.
  **
  new make(Type of, Int capacity)

  **
  ** Constructor for Obj?[] with initial capacity.
  **
  new makeObj(Int capacity)

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Two Lists are equal if they have the same type, the same
  ** number of items, and all the items at each index return
  ** true for 'equals'.
  **
  ** Examples:
  **   [2, 3] == [2, 3]     =>  true
  **   [2, 3] == [3, 2]     =>  false
  **   [2, 3] == Num[2, 3]  =>  false
  **   Str[,] == [,]        =>  false
  **   Str[,] == Str?[,]    =>  false
  **
  override Bool equals(Obj? that)

  **
  ** Return platform dependent hashcode based a hash of the items
  ** of the list.
  **
  override Int hash()

  **
  ** Get the item Type of this List.
  **
  ** Examples:
  **   ["hi"].of    =>  Str#
  **   [[2, 3]].of  =>  Int[]#
  **
  Type of()

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if size == 0.  This method is readonly safe.
  **
  Bool isEmpty()

  **
  ** The number of items in the list.  Getting size is readonly safe,
  ** setting size throws ReadonlyErr if readonly.
  **
  ** If the size is set greater than the current size then the list is
  ** automatically grown to be a sparse list with new items defaulting
  ** to null.  However if this is a non-nullable list, then growing a
  ** list will throw ArgErr.
  **
  ** If the size is set less than the current size then any items with
  ** indices past the new size are automatically removed.  Changing size
  ** automatically allocates new storage so that capacity exactly matches
  ** the new size.
  **
  Int size

  **
  ** The number of items this list can hold without allocating more memory.
  ** Capacity is always greater or equal to size.  If adding a large
  ** number of items, it may be more efficient to manually set capacity.
  ** See the `trim` method to automatically set capacity to size.  Throw
  ** ArgErr if attempting to set capacity less than size.  Getting capacity
  ** is readonly safe, setting capacity throws ReadonlyErr if readonly.
  **
  Int capacity

  **
  ** Get is used to return the item at the specified the index.  A
  ** negative index may be used to access an index from the end of the
  ** list.  For example get(-1) is translated into get(size()-1).  The
  ** get method is accessed via the [] shortcut operator.  Throw
  ** IndexErr if index is out of range.  This method is readonly safe.
  **
  @Operator V get(Int index)

  **
  ** Get the item at the specified index, but if index is out of
  ** range, then return 'def' parameter.  A negative index may be
  ** used according to the same semantics as `get`.  This method
  ** is readonly safe.
  **
  V? getSafe(Int index, V? def := null)

  **
  ** Return a sub-list based on the specified range.  Negative indexes
  ** may be used to access from the end of the list.  This method
  ** is accessed via the '[]' operator.  This method is readonly safe.
  ** Throw IndexErr if range illegal.
  **
  ** Examples:
  **   list := [0, 1, 2, 3]
  **   list[0..2]   => [0, 1, 2]
  **   list[3..3]   => [3]
  **   list[-2..-1] => [2, 3]
  **   list[0..<2]  => [0, 1]
  **   list[1..-2]  => [1, 2]
  **
  @Operator L getRange(Range range)

  ** TODO: use `getRange`
  @Deprecated L slice(Range range)

  **
  ** Return if this list contains the specified item.
  ** Equality is determined by `Obj.equals`.  This method is readonly safe.
  **
  Bool contains(V item)

  **
  ** Return if this list contains every item in the specified list.
  ** Equality is determined by `Obj.equals`.  This method is readonly safe.
  **
  Bool containsAll(L list)

  **
  ** Return if this list contains any one of the items in the specified list.
  ** Equality is determined by `Obj.equals`.  This method is readonly safe.
  **
  Bool containsAny(L list)

  **
  ** Return the integer index of the specified item using
  ** the '==' operator (shortcut for equals method) to check
  ** for equality.  Use `indexSame` to find with '===' operator.
  ** The search starts at the specified offset and returns
  ** the first match.  The offset may be negative to access
  ** from end of list.  Throw IndexErr if offset is out of
  ** range.  If the item is not found return null.  This method
  ** is readonly safe.
  **
  Int? index(V item, Int offset := 0)

  **
  ** Return integer index just like `List.index` except
  ** use '===' same operator instead of the '==' equals operator.
  **
  Int? indexSame(V item, Int offset := 0)

  **
  ** Return the item at index 0, or if empty return null.
  ** This method is readonly safe.
  **
  V? first()

  **
  ** Return the item at index-1, or if empty return null.
  ** This method is readonly safe.
  **
  V? last()

  **
  ** Create a shallow duplicate copy of this List.  The items
  ** themselves are not duplicated.  This method is readonly safe.
  **
  L dup()

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

  **
  ** Set is used to overwrite the item at the specified the index.  A
  ** negative index may be used to access an index from the end of the
  ** list.  The set method is accessed via the []= shortcut operator.
  ** If you wish to use List as a sparse array and set values greater
  ** then size, then manually set size larger.  Return this.  Throw
  ** IndexErr if index is out of range.  Throw ReadonlyErr if readonly.
  **
  @Operator L set(Int index, V item)

  **
  ** Add the specified item to the end of the list.  The item will have
  ** an index of size.  Size is incremented by 1.  Return this.  Throw
  ** ReadonlyErr if readonly.
  **
  L add(V item)

  **
  ** Add all the items in the specified list to the end of this list.
  ** Size is incremented by list.size.  Return this.  Throw ReadonlyErr
  ** if readonly.
  **
  L addAll(L list)

  **
  ** Insert the item at the specified index.  A negative index may be
  ** used to access an index from the end of the list.  Size is incremented
  ** by 1.  Return this.  Throw IndexErr if index is out of range.  Throw
  ** ReadonlyErr if readonly.
  **
  L insert(Int index, V item)

  **
  ** Insert all the items in the specified list into this list at the
  ** specified index.  A negative index may be used to access an index
  ** from the end of the list.  Size is incremented by list.size.  Return
  ** this.  Throw IndexErr if index is out of range.  Throw ReadonlyErr
  ** if readonly.
  **
  L insertAll(Int index, L list)

  **
  ** Remove the specified value from the list.  The value is compared
  ** using the == operator (shortcut for equals method).  Use `removeSame`
  ** to remove with the === operator.  Return the removed value and
  ** decrement size by 1.  If the value is not found, then return null.
  ** Throw ReadonlyErr if readonly.
  **
  V? remove(V item)

  **
  ** Remove the item just like `remove` except use
  ** the === operator instead of the == equals operator.
  **
  V? removeSame(V item)

  **
  ** Remove the object at the specified index.  A negative index may be
  ** used to access an index from the end of the list.  Size is decremented
  ** by 1.  Return the item removed.  Throw IndexErr if index is out of
  ** range.  Throw ReadonlyErr if readonly.
  **
  V removeAt(Int index)

  **
  ** Remove a range of indices from this list.  Negative indexes
  ** may be used to access from the end of the list.  Throw
  ** ReadonlyErr if readonly.  Throw IndexErr if range illegal.
  ** Return this (*not* the removed items).
  **
  L removeRange(Range r)

  **
  ** Remove all items from the list and set size to 0.  Return this.
  ** Throw ReadonlyErr if readonly.
  **
  L clear()

  **
  ** Trim the capacity such that the underlying storage is optimized
  ** for the current size.  Return this.  Throw ReadonlyErr if readonly.
  **
  L trim()

  **
  ** Append a value to the end of the list the given number of times.
  ** Return this. Throw ReadonlyErr if readonly.
  **
  ** Example:
  **   Int[,].fill(0, 3)  =>  [0, 0, 0]
  **
  L fill(V val, Int times)

//////////////////////////////////////////////////////////////////////////
// Stack
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the item at index-1, or if empty return null.
  ** This method has the same semantics as last().  This method
  ** is readonly safe.
  **
  V? peek()

  **
  ** Remove the last item and return it, or return null if the list
  ** is empty.  This method as the same semantics as remove(-1), with
  ** the exception of has an empty list is handled.  Throw ReadonlyErr
  ** if readonly.
  **
  V? pop()

  **
  ** Add the specified item to the end of the list.  Return this.
  ** This method has the same semantics as add(item).  Throw ReadonlyErr
  ** if readonly.
  **
  L push(V item)

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  **
  ** Call the specified function for every item in the list starting
  ** with index 0 and incrementing up to size-1.  This method is
  ** readonly safe.
  **
  ** Example:
  **   ["a", "b", "c"].each |Str s| { echo(s) }
  **
  Void each(|V item, Int index| c)

  **
  ** Reverse each - call the specified function for every item in
  ** the list starting with index size-1 and decrementing down
  ** to 0.  This method is readonly safe.
  **
  ** Example:
  **   ["a", "b", "c"].eachr |Str s| { echo(s) }
  **
  Void eachr(|V item, Int index| c)

  **
  ** Iterate the list usnig the specified range.   Negative indexes
  ** may be used to access from the end of the list.  This method is
  ** readonly safe.  Throw IndexErr if range is invalid.
  **
  Void eachRange(Range r, |V item, Int index| c)

  **
  ** Iterate every item in the list starting with index 0 up to
  ** size-1 until the function returns non-null.  If function
  ** returns non-null, then break the iteration and return the
  ** resulting object.  Return null if the function returns
  ** null for every item.  This method is readonly safe.
  **
  Obj? eachWhile(|V item, Int index->Obj?| c)

  **
  ** Reverse `eachWhile`.  Iterate every item in the list starting
  ** with size-1 down to 0.  If the function returns non-null, then
  ** break the iteration and return the resulting object.  Return
  ** null if the function returns null for every item.  This method
  ** is readonly safe.
  **
  Obj? eachrWhile(|V item, Int index->Obj?| c)

  **
  ** Return the first item in the list for which c returns true.
  ** If c returns false for every item, then return null.  This
  ** method is readonly safe.
  **
  ** Example:
  **   list := [0, 1, 2, 3, 4]
  **   list.find |Int v->Bool| { return v.toStr == "3" } => 3
  **   list.find |Int v->Bool| { return v.toStr == "7" } => null
  **
  V? find(|V item, Int index->Bool| c)

  **
  ** Return the first item in the list for which c returns true
  ** and return the item's index.  If c returns false for every
  ** item, then return null.  This method is readonly safe.
  **
  ** Example:
  **   list := [5, 6, 7]
  **   list.findIndex |Int v->Bool| { return v.toStr == "7" } => 2
  **   list.findIndex |Int v->Bool| { return v.toStr == "9" } => null
  **
  Int? findIndex(|V item, Int index->Bool| c)

  **
  ** Return a new list containing the items for which c returns
  ** true.  If c returns false for every item, then return an
  ** empty list.  The inverse of this method is exclude().  This
  ** method is readonly safe.
  **
  ** Example:
  **   list := [0, 1, 2, 3, 4]
  **   list.findAll |Int v->Bool| { return v%2==0 } => [0, 2, 4]
  **
  L findAll(|V item, Int index->Bool| c)

  **
  ** Return a new list containing all the items which are an instance
  ** of the specified type such that item.type.fits(t) is true.  Any null
  ** items are automatically excluded.  If none of the items are instance
  ** of the specified type, then an empty list is returned.  The returned
  ** list will be a list of t.  This method is readonly safe.
  **
  ** Example:
  **   list := ["a", 3, "foo", 5sec, null]
  **   list.findType(Str#) => Str["a", "foo"]
  **
  L findType(Type t)

  **
  ** Return a new list containing the items for which c returns
  ** false.  If c returns true for every item, then return an
  ** empty list.  The inverse of this method is findAll().  This
  ** method is readonly safe.
  **
  ** Example:
  **   list := [0, 1, 2, 3, 4]
  **   list.exclude |Int v->Bool| { return v%2==0 } => [1, 3]
  **
  L exclude(|V item, Int index->Bool| c)

  **
  ** Return true if c returns true for any of the items in
  ** the list.  If the list is empty, return false.  This method
  ** is readonly safe.
  **
  ** Example:
  **   list := ["ant", "bear"]
  **   list.any |Str v->Bool| { return v.size >= 4 } => true
  **   list.any |Str v->Bool| { return v.size >= 5 } => false
  **
  Bool any(|V item, Int index->Bool| c)

  **
  ** Return true if c returns true for all of the items in
  ** the list.  If the list is empty, return true.  This method
  ** is readonly safe.
  **
  ** Example:
  **   list := ["ant", "bear"]
  **   list.all |Str v->Bool| { return v.size >= 3 } => true
  **   list.all |Str v->Bool| { return v.size >= 4 } => false
  **
  Bool all(|V item, Int index->Bool| c)

  **
  ** Create a new list which is the result of calling c for
  ** every item in this list.  The new list is typed based on
  ** the return type of c.  This method is readonly safe.
  **
  ** Example:
  **   list := [3, 4, 5]
  **   list.map |Int v->Int| { return v*2 } => [6, 8, 10]
  **
  Obj?[] map(|V item, Int index->Obj?| c)

  **
  ** Reduce is used to iterate through every item in the list
  ** to reduce the list into a single value called the reduction.
  ** The initial value of the reduction is passed in as the init
  ** parameter, then passed back to the closure along with each
  ** item.  This method is readonly safe.
  **
  ** Example:
  **   list := [1, 2, 3]
  **   list.reduce(0) |Obj r, Int v->Obj| { return (Int)r + v } => 6
  **
  Obj? reduce(Obj? init, |Obj? reduction, V item, Int index->Obj?| c)

  **
  ** Return the minimum value of the list.  If c is provided, then it
  ** implements the comparator returning -1, 0, or 1.  If c is null
  ** then the <=> operator is used (shortcut for compare method).  If
  ** the list is empty, return null.  This method is readonly safe.
  **
  ** Example:
  **   list := ["albatross", "dog", "horse"]
  **   list.min => "albatross"
  **   list.min |Str a, Str b->Int| { return a.size <=> b.size } => "dog"
  **
  V? min(|V a, V b->Int|? c := null)

  **
  ** Return the maximum value of the list.  If c is provided, then it
  ** implements the comparator returning -1, 0, or 1.  If c is null
  ** then the <=> operator is used (shortcut for compare method).  If
  ** the list is empty, return null.  This method is readonly safe.
  **
  ** Example:
  **   list := ["albatross", "dog", "horse"]
  **   list.max => "horse"
  **   list.max |Str a, Str b->Int| { return a.size <=> b.size } => "albatross"
  **
  V? max(|V a, V b->Int|? c := null)

  **
  ** Returns a new list with all duplicate items removed such that the
  ** resulting list is a proper set.  Duplicates are detected using hash()
  ** and the == operator (shortcut for equals method).  This method is
  ** readonly safe.
  **
  ** Example:
  **   ["a", "a", "b", "c", "b", "b"].unique => ["a", "b", "c"]
  **
  L unique()

  **
  ** Return a new list which is the union of this list and the given list.
  ** The union is defined as the unique items which are in *either* list.
  ** The resulting list is ordered first by this list's order, and secondarily
  ** by that's order.  The new list is guaranteed to be unique with no duplicate
  ** values.  Equality is determined using hash() and the == operator
  ** (shortcut for equals method).  This method is readonly safe.
  **
  ** Example:
  **   [1, 2].union([3, 2]) => [1, 2, 3]
  **
  L union(L that)

  **
  ** Return a new list which is the intersection of this list and the
  ** given list.  The intersection is defined as the unique items which
  ** are in *both* lists.  The new list will be ordered according to this
  ** list's order.  The new list is guaranteed to be unique with no duplicate
  ** values.  Equality is determined using hash() and the == operator
  ** (shortcut for equals method).  This method is readonly safe.
  **
  ** Example:
  **   [0, 1, 2, 3].intersection([5, 3, 1]) => [1, 3]
  **   [0, null, 2].intersection([null, 0, 1, 2, 3]) => [0, null, 2]
  **
  L intersection(L that)

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Perform an in-place sort on this list.  If a method is provided
  ** it implements the comparator returning -1, 0, or 1.  If the
  ** comparator method is null then sorting is based on the
  ** value's <=> operator (shortcut for 'compare' method).  Return this.
  ** Throw ReadonlyErr if readonly.
  **
  ** Example:
  **   s := ["candy", "ate", "he"]
  **
  **   s.sort
  **   // s now evaluates to [ate, candy, he]
  **
  **   s.sort |Str a, Str b->Int| { return a.size <=> b.size }
  **   // s now evaluates to ["he", "ate", "candy"]
  **
  L sort(|V a, V b->Int|? c := null)

  **
  ** Reverse sort - perform an in-place reverse sort on this list.  If
  ** a method is provided it implements the comparator returning -1,
  ** 0, or 1.  If the comparator method is null then sorting is based
  ** on the items <=> operator (shortcut for 'compare' method).  Return
  ** this.  Throw ReadonlyErr if readonly.
  **
  ** Example:
  **   [3, 2, 4, 1].sortr =>  [4, 3, 2, 1]
  **
  L sortr(|V a, V b->Int|? c := null)

  **
  ** Search the list for the index of the specified key using a binary
  ** search algorithm.  The list must be sorted in ascending order according
  ** to the specified comparator function.  If the list contains multiple
  ** matches for key, no guarantee is made to which one is returned.  If
  ** the comparator is null then then it is assumed to be the '<=>'
  ** operator (shortcut for the 'compare' method).  If the key is not found,
  ** then return a negative value which is '-(insertation point) - 1'.
  **
  Int binarySearch(V key, |V a, V b->Int|? c := null)

  **
  ** Reverse the order of the items of this list in-place.  Return this.
  ** Throw ReadonlyErr if readonly.
  **
  ** Example:
  **   [1, 2, 3, 4].reverse  =>  [4, 3, 2, 1]
  **
  L reverse()

  **
  ** Swap the items at the two specified indexes.  Negative indexes may
  ** used to access an index from the end of the list.  Return this.
  ** Throw ReadonlyErr if readonly.
  **
  L swap(Int indexA, Int indexB)

  **
  ** Find the given item, and move it to the given index.  All the
  ** other items are shifted accordingly.  Negative indexes may
  ** used to access an index from the end of the list.  If the item is
  ** not found then this is a no op.  Return this.  Throw ReadonlyErr
  ** if readonly.
  **
  ** Examples:
  **   [10, 11, 12].moveTo(11, 0)  =>  [11, 10, 12]
  **   [10, 11, 12].moveTo(11, -1) =>  [10, 12, 11]
  **
  L moveTo(V item, Int toIndex)

  **
  ** Return a new list which recursively flattens any list items into
  ** a one-dimensional result.  This method is readonly safe.
  **
  ** Examples:
  **   [1,2,3].flatten        =>  [1,2,3]
  **   [[1,2],[3]].flatten    =>  [1,2,3]
  **   [1,[2,[3]],4].flatten  =>  [1,2,3,4]
  **
  Obj?[] flatten()

  **
  ** Return a random item from the list.  If the list is empty
  ** return null.  This method is readonly safe.  See `Int.random`.
  **
  V? random()

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a string representation the list.  This method is readonly safe.
  **
  override Str toStr()

  **
  ** Return a string by concatenating each item's toStr result
  ** using the specified separator string.  If c is non-null
  ** then it is used to format each item into a string, otherwise
  ** Obj.toStr is used.  This method is readonly safe.
  **
  ** Example:
  **   ["a", "b", "c"].join => "abc"
  **   ["a", "b", "c"].join("-") => "a-b-c"
  **   ["a", "b", "c"].join("-") |Str s->Str| { return "($s)" } => "(a)-(b)-(c)"
  **
  Str join(Str separator := "", |V item, Int index->Str|? c := null)

  **
  ** Get this list as a Fantom expression suitable for code generation.
  ** The individual items must all respond to the 'toCode' method.
  **
  Str toCode()

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this List is readonly.  A readonly List is guaranteed to
  ** be immutable (although its items may be mutable themselves).  Any
  ** attempt to  modify a readonly List will result in ReadonlyErr.  Use
  ** `rw` to get a read-write List from a readonly List.  Methods
  ** documented as "readonly safe" may be used safely with a readonly List.
  ** This method is readonly safe.
  **
  Bool isRO()

  **
  ** Return if this List is read-write.  A read-write List is mutable
  ** and may be modified.  Use `ro` to get a readonly List from a
  ** read-write List.  This method is readonly safe.
  **
  Bool isRW()

  **
  ** Get a readonly List instance with the same contents as this
  ** List (although the items may be mutable themselves).  If this
  ** List is already readonly, then return this.  Only methods
  ** documented as "readonly safe" may be used safely with a readonly
  ** List, all others will throw ReadonlyErr.  This method is readonly
  ** safe.  See `isImmutable` and `toImmutable` for deep immutability.
  **
  L ro()

  **
  ** Get a read-write, mutable List instance with the same contents
  ** as this List.  If this List is already read-write, then return this.
  ** This method is readonly safe.
  **
  L rw()

}