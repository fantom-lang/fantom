//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

package fan.cryptoJava;

import fan.sys.*;

import java.security.KeyPairGenerator;

public class JKeyPairPeer
{

//////////////////////////////////////////////////////////////////////////
// Generate
//////////////////////////////////////////////////////////////////////////

  public static JKeyPair genKeyPair(final String algorithm, final long keysize)
  {
    try
    {
      // generate key pair
      KeyPairGenerator keyGen = KeyPairGenerator.getInstance(algorithm);
      keyGen.initialize((int)keysize);
      java.security.KeyPair keyPair = keyGen.generateKeyPair();

      return JKeyPair.make(new JPrivKey(keyPair.getPrivate()),
                           new JPubKey(keyPair.getPublic()));
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static JKeyPairPeer make(JKeyPair self)
  {
    return new JKeyPairPeer();
  }
}