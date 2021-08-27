//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2021 Matthew Giannini   Creation
//

**
** Common base class with utilities for crypto tests
**
@NoDoc
abstract class CryptoTest : Test
{
  virtual Crypto crypto() { Crypto.cur }

  Cert? selfSign

  override Void setup()
  {
    contents :=  Str<|-----BEGIN CERTIFICATE-----
                      MIIC7jCCAdYCCQC4yTJEzwbB+zANBgkqhkiG9w0BAQUFADA5MQswCQYDVQQGEwJV
                      UzERMA8GA1UECBMIVmlyZ2luaWExFzAVBgNVBAoTDlNreUZvdW5kcnkgTExDMB4X
                      DTE2MDIxMjE2MzI1M1oXDTE3MDIxMTE2MzI1M1owOTELMAkGA1UEBhMCVVMxETAP
                      BgNVBAgTCFZpcmdpbmlhMRcwFQYDVQQKEw5Ta3lGb3VuZHJ5IExMQzCCASIwDQYJ
                      KoZIhvcNAQEBBQADggEPADCCAQoCggEBAKa7GQ3BKdvyzB6y8xNqNPJRqZ+2MAdI
                      1nED+9cNFFZjggUgPHV88ccnz8WAdvfT+SRhNR68aYu6z5O7E+He4Wy0puY/t9v2
                      bZWHMnJWJKL/yvqc6KcH1qkXaybATZ8RHqqdtOwJkG7Xv84uITYt2Nfx531xDu/4
                      8mR/C0+iRwYJdRLCPacDJjy6sG70ziAgrhg+AigWYOvSNK8TWNpaz4FAuZTLGgHu
                      QQ6SjZZ+OF/kv7GvrDe2nstHviA9mWowJPAfHGu6ee3vXhVAVGvivkvnlC1kTcUa
                      sABZ+IhXOzho43AIiY78TvBsNTSbuHkGgc2ItxVpWaRdvYPCaSWYVS0CAwEAATAN
                      BgkqhkiG9w0BAQUFAAOCAQEAb+ud7iP51/VpfW9w8bEaEXtspLjyarKrr/6PvOjM
                      3N9Moqzs1lG9XbkiO6QTVroZhbMz+nCqI9nOMOyHpLtyozG2bleV7pyddDFEtlW+
                      ruj4q3E3mpP7vcNnylEzMexph6ROh9xKtCAil0orOdYEpGGatmkDK7RVFIRplvqj
                      +0A0ptuEFyC4aVubb8wWpsxhExFJOvY97D7U19Q5wp5bPVyhtJli1s/hrs5Sb9CT
                      DUhL6fhf0j7awWbKkI404msot/1QB0PpcJwqn5ed+4GU1tml6E+ogLWbmKt3lgNN
                      lM04MmrQP6Pow3AfrLFQr2oMrNwib3co9x23GoknwGG4Sw==
                      -----END CERTIFICATE-----|>
    crt := contents.toBuf.toFile(`self-signed.crt`)
    this.selfSign = crypto.loadX509(crt.in).first
  }
}