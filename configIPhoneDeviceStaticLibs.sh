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

PATH=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin:/tmp/mybin

### NOTE: In ./crypto/ui/ui_openssl.c sig_atomic_t is undefined, replace by int in order to compile
./Configure no-shared no-hw zlib no-asm no-krb5 --prefix=$PWD/iPhoneDevice iphone-arm-cc

make clean
find . -name "*.o" -exec rm {} \;
find . -name "*.a" -exec rm {} \;

make depend > /dev/null 2>&1

make && make install

