#
# NOTE: Rename /usr/include to insure no accidental inclusion
#
SAVEPWD=$PWD

# Set up a local place for binaries we will need from the host systsem
mkdir -p /tmp/mybin
cd /tmp/mybin
rm -f *

ln -s `which awk`
ln -s `which basename`
ln -s `which chmod`
ln -s `which chown`
ln -s `which cp`
ln -s `which date`
ln -s `which echo`
ln -s `which fgrep`
ln -s `which find`
ln -s `which grep`
ln -s `which ln`
ln -s `which make`
ln -s `which makedepend`
ln -s `which mv`
ln -s `which perl`
ln -s `which pod2man`
ln -s `which rm`
ln -s `which sed`
ln -s `which sh`
ln -s `which touch`
ln -s `which uniq`

# Reset the path to home dir and cross-compile
cd $SAVEPWD

PATH=/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin:/tmp/mybin
#echo $PATH

#CFLAGS="-DOPENSSL_SYSNAME_MACOSX -DOPENSSL_THREADS -D__IPHONE_OS_VERSION_MIN_REQUIRED=20000 -Os -fasm-blocks -fmessage-length=0 -fpascal-strings -gdwarf-2 -isysroot /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator2.0.sdk -mmacosx-version-min=10.5 -pipe"

#echo $CFLAGS

#./Configure no-shared no-hw no-asm no-idea no-krb5 enable-camellia no-cms no-gmp enable-mdc2 enable-rc5 enable-rfc3779 enable-seed enable-tlsext --prefix=$PWD/iPhoneSimulator $CFLAGS darwin-i386-cc
./Configure no-shared no-hw zlib no-asm no-krb5 --prefix=$PWD/iPhoneSimulator iphone-i386-cc

make clean
find . -name "*.o" -exec rm {} \;
find . -name "*.a" -exec rm {} \;

make depend > /dev/null 2>&1

make && make install


