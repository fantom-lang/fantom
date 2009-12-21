//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Nov 07  Andy Frank  Ported to .NET
//

using System;
using System.Net;
using System.Net.Sockets;
using Fan.Sys;

namespace Fan.Inet
{
  public class TcpSocketPeer
  {

  //////////////////////////////////////////////////////////////////////////
  // Peer Factory
  //////////////////////////////////////////////////////////////////////////

    public static TcpSocketPeer make(TcpSocket fan)
    {
      return new TcpSocketPeer();
    }

    // TODO - hardcoded to IPv4!
    public TcpSocketPeer()
      : this(new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp))
    {
    }

    public TcpSocketPeer(Socket socket)
    {
      this.m_dotnet = socket;

      // turn off Nagle's algorithm since we should
      // always be doing buffering in the virtual machine
      try { m_dotnet.NoDelay = true; } catch {}
    }

  //////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////

    public bool isBound(TcpSocket fan)
    {
      return m_dotnet.IsBound;
    }

    public bool isConnected(TcpSocket fan)
    {
      return m_dotnet.Connected;
    }

    public bool isClosed(TcpSocket fan)
    {
      return m_closed;
    }

  //////////////////////////////////////////////////////////////////////////
  // End Points
  //////////////////////////////////////////////////////////////////////////

    public IpAddr localAddr(TcpSocket fan)
    {
      if (!m_dotnet.IsBound) return null;
      IPEndPoint pt = m_dotnet.LocalEndPoint as IPEndPoint;
      if (pt == null) return null;
      return IpAddrPeer.make(pt.Address);
    }

    public Long localPort(TcpSocket fan)
    {
      if (!m_dotnet.IsBound) return null;
      IPEndPoint pt = m_dotnet.LocalEndPoint as IPEndPoint;
      if (pt == null) return null;
      // TODO - default port?
      return Long.valueOf(pt.Port);
    }

    public IpAddr remoteAddr(TcpSocket fan)
    {
      if (!m_dotnet.Connected) return null;
      return m_remoteAddr;
    }

    public Long remotePort(TcpSocket fan)
    {
      if (!m_dotnet.Connected) return null;
      return Long.valueOf(m_remotePort);
    }

  //////////////////////////////////////////////////////////////////////////
  // Communication
  //////////////////////////////////////////////////////////////////////////

    public TcpSocket bind(TcpSocket fan, IpAddr addr, Long port)
    {
      try
      {
        IPAddress dotnetAddr = (addr == null) ? IPAddress.Any : addr.m_peer.m_dotnet;
        int dotnetPort = (port == null) ? 0 : port.intValue();
        m_dotnet.Bind(new IPEndPoint(dotnetAddr, dotnetPort));
        return fan;
      }
      catch (SocketException e)
      {
        throw IOErr.make(e).val;
      }
    }

    public TcpSocket connect(TcpSocket fan, IpAddr addr, long port, Duration timeout)
    {
      if (timeout != null)
      {
        IAsyncResult result = m_dotnet.BeginConnect(addr.m_peer.m_dotnet, (int)port, null, null);
        bool success = result.AsyncWaitHandle.WaitOne((int)timeout.millis(), true);
        if (!success)
        {
          m_dotnet.Close();
          throw new System.IO.IOException("Connection timed out.");
        }
      }
      else
      {
        m_dotnet.Connect(addr.m_peer.m_dotnet, (int)port);
      }
      connected(fan);
      return fan;
    }

    internal void connected(TcpSocket fan)
    {
      IPEndPoint endPoint = m_dotnet.RemoteEndPoint as IPEndPoint;
      m_remoteAddr = IpAddrPeer.make(endPoint.Address);
      m_remotePort = endPoint.Port;
      m_in  = SysInStream.make(new NetworkStream(m_dotnet), getInBufferSize(fan));
      m_out = SysOutStream.make(new NetworkStream(m_dotnet), getOutBufferSize(fan));
    }

    public InStream @in(TcpSocket fan)
    {
      if (m_in == null) throw IOErr.make("not connected").val;
      return m_in;
    }

    public OutStream @out(TcpSocket fan)
    {
      if (m_out == null) throw IOErr.make("not connected").val;
      return m_out;
    }

    public bool close(TcpSocket fan)
    {
      try
      {
        close();
        return true;
      }
      catch
      {
        return false;
      }
    }

    public void close()
    {
      m_dotnet.Close();
      m_in  = null;
      m_out = null;
      m_closed = true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Threading
  //////////////////////////////////////////////////////////////////////////

  /* TODO - remove when I make final decision to keep TcpSocket const

    **
    ** Fork this socket onto another thread.  A new thread is automatically
    ** created with the given name (pass null to auto-generate a name).
    ** The new thread is started using the specified run method and this
    ** socket as the argument.  The run method must be a const method (it
    ** cannot capture state from the calling thread), otherwise NotImmutableErr
    ** is thrown.  Once a socket is forked onto a new thread,  it is detached
    ** from the calling thread and all methods will throw UnsupportedErr.
    **
    native Thread fork(string threadName, |TcpSocket s->Obj| run)

    public Thread fork(TcpSocket oldSock, string name, final Method run)
    {
      // error checking
      checkDetached();
      if (!run.isConst().val)
        throw NotImmutableErr.make("Run method not const: " + run).val;

      // increment fork counter
      int n = -1;
      synchronized (topLock) { n = forkCount++; }

      // generate name if null
      if (name == null) name = string.make("inet.TcpSocket" + n);

      // create new detached thread-safe socket
      final TcpSocket newSock = detach(oldSock);

      // create new thread
      Thread thread = new Thread(name)
      {
        public Obj run()
        {
          return run.call(newSock);
        }
      };

      // start thread
      return thread.start();
    }

    private TcpSocket detach(TcpSocket oldSock)
    {
      // detach old TcpSocket from this peer
      oldSock.peer = new TcpSocketPeer();
      oldSock.peer.detached = true;

      // create new thread safe TcpSocket
      final TcpSocket newSock = new TcpSocket();
      newSock.peer = this;
      return newSock;
    }

    private void checkDetached()
    {
      if (detached)
        throw UnsupportedErr.make("TcpSocket forked onto new thread").val;
    }
  */

  //////////////////////////////////////////////////////////////////////////
  // Streaming Options
  //////////////////////////////////////////////////////////////////////////

    public Long getInBufferSize(TcpSocket fan)
    {
      return (m_inBufSize <= 0) ? null : Long.valueOf(m_inBufSize);
    }

    public void setInBufferSize(TcpSocket fan, Long v)
    {
      if (m_in != null) throw Err.make("Must set inBufferSize before connection").val;
      m_inBufSize = (v == null) ? 0 : v.intValue();
    }

    public Long getOutBufferSize(TcpSocket fan)
    {
      return (m_outBufSize <= 0) ? null : Long.valueOf(m_outBufSize);
    }

    public void setOutBufferSize(TcpSocket fan, Long v)
    {
      if (m_in != null) throw Err.make("Must set outBufSize before connection").val;
      m_outBufSize = (v == null) ? 0 : v.intValue();
    }

  //////////////////////////////////////////////////////////////////////////
  // Socket Options
  //////////////////////////////////////////////////////////////////////////

    public SocketOptions options(TcpSocket fan)
    {
      if (m_options == null) m_options = SocketOptions.make(fan);
      return m_options;
    }

    public bool getKeepAlive(TcpSocket fan)
    {
      return Convert.ToBoolean(m_dotnet.GetSocketOption(
        SocketOptionLevel.Socket, SocketOptionName.KeepAlive));
    }

    public void setKeepAlive(TcpSocket fan, bool v)
    {
      m_dotnet.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.KeepAlive, v);
    }

    public long getReceiveBufferSize(TcpSocket fan)
    {
      return m_dotnet.ReceiveBufferSize;
    }

    public void setReceiveBufferSize(TcpSocket fan, long v)
    {
      m_dotnet.ReceiveBufferSize = (int)v;
    }

    public long getSendBufferSize(TcpSocket fan)
    {
      return m_dotnet.SendBufferSize;
    }

    public void setSendBufferSize(TcpSocket fan, long v)
    {
      m_dotnet.SendBufferSize = (int)v;
    }

    public bool getReuseAddr(TcpSocket fan)
    {
      return Convert.ToBoolean(m_dotnet.GetSocketOption(
       SocketOptionLevel.Socket, SocketOptionName.ReuseAddress));
    }

    public void setReuseAddr(TcpSocket fan, bool v)
    {
      m_dotnet.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, v);
    }

    public Duration getLinger(TcpSocket fan)
    {
      if (!m_dotnet.LingerState.Enabled) return null;
      return Duration.makeSec(m_dotnet.LingerState.LingerTime);
    }

    public void setLinger(TcpSocket fan, Duration v)
    {
      if (v == null)
      {
        m_dotnet.LingerState = new LingerOption(false, 0);
      }
      else
      {
        m_dotnet.LingerState = new LingerOption(true, (int)(v.sec()));
      }
    }

    public Duration getReceiveTimeout(TcpSocket fan)
    {
      if (m_dotnet.ReceiveTimeout <= 0) return null;
      return Duration.makeMillis(m_dotnet.ReceiveTimeout);
    }

    public void setReceiveTimeout(TcpSocket fan, Duration v)
    {
      if (v == null)
        m_dotnet.ReceiveTimeout = 0;
      else
        m_dotnet.ReceiveTimeout = (int)(v.millis());
    }

    public bool getNoDelay(TcpSocket fan)
    {
      return m_dotnet.NoDelay;
    }

    public void setNoDelay(TcpSocket fan, bool v)
    {
      m_dotnet.NoDelay = v;
    }

    public long getTrafficClass(TcpSocket fan)
    {
      return Convert.ToInt32(m_dotnet.GetSocketOption(
        SocketOptionLevel.IP, SocketOptionName.TypeOfService));
    }

    public void setTrafficClass(TcpSocket fan, long v)
    {
      m_dotnet.SetSocketOption(SocketOptionLevel.IP, SocketOptionName.TypeOfService, (int)v);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Socket m_dotnet;

    private int m_inBufSize = 4096;
    private int m_outBufSize = 4096;
    private IpAddr m_remoteAddr;
    private int m_remotePort;
    private SysInStream m_in;
    private SysOutStream m_out;
    private SocketOptions m_options;
    private bool m_closed;

  }
}