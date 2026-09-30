# ARCore is a compileOnly dependency (see UAr.kt): apps that don't add
# com.google.ar:core must still pass R8. UArCoreSession is only reached after
# UArCoreSession.sdkPresent() confirms the classes exist at runtime.
-dontwarn com.google.ar.core.**
