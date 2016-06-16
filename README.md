OpenSSL is deprecated
=====================

Android no longer uses OpenSSL and instead has moved to BoringSSL. Most
applications can move to using BoringSSL as well as long as it is not
making use of deprecated APIs.

Please see these locations for more information:

  * [BoringSSL repository](https://boringssl.googlesource.com/boringssl/): The
    official BoringSSL repository.
  * [Android's BoringSSL project](https://android.googlesource.com/platform/external/boringssl/):
    Android's copy of BoringSSL.
