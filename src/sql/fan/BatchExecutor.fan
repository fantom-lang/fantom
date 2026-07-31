//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 July 2026  Mike Jarmy  Creation
//

**
** BatchExecutor creates a queue of commands that are executed in batches via
** calls to Statement.executeBatch().  The batches are executed in chunks that
** are no greater than a given maximum chunk size.
**
@NoDoc
class BatchExecutor
{
  ** Create a BatchExecutor.  The Statement must already be prepared.
  new make(Statement stmt, Int maxChunkSize := 1000)
  {
    this.stmt = stmt
    this.maxChunkSize = maxChunkSize
  }

  ** Add a command to the queue. Call Statement.executeBatch() if the queue
  ** size is greater than maxChunkSize.
  Void add(Str:Obj params)
  {
    queued.add(params)
    if (queued.size > maxChunkSize)
    {
      r := stmt.executeBatch(queued)
      result.updateCounts.addAll(r.updateCounts)
      result.keys.addAll(r.keys)
      queued.clear
    }
  }

  ** Finish execution, and return the collated results from each call
  ** to Statement.executeBatch().
  BatchResult finish()
  {
    if (queued.size > 0)
    {
      r := stmt.executeBatch(queued)
      result.updateCounts.addAll(r.updateCounts)
      result.keys.addAll(r.keys)
      queued.clear
    }
    return result
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Statement stmt
  private Int maxChunkSize

  private [Str:Obj][] queued := [Str:Obj][,]
  private BatchResult result := BatchResult(Int?[,], Obj?[,])
}

