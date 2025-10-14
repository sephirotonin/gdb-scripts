#!/bin/bash

export GDBCLIENT=gdb-multiarch

if [ -z "$GDBCLIENT" ]
then
    echo "Please set GDBCLIENT environment variable appropriately!"
    exit 1
fi

echo "Getting keymaster pid"
KEYMASTER_PID=$(adb wait-for-device && adb shell su -c "ps | grep android.hardware.keymaster" | awk '{print $2}')
echo "keymaster pid = $KEYMASTER_PID"

if [ -z "$KEYMASTER_PID" ]; then
    echo "Could not find keymaster PID!"
    exit 1
fi

echo "Cleaning up old gdbserver"
adb shell su -c pkill -9 gdbserver
adb forward --remove-all

echo "Starting gdbserver"
adb forward tcp:5040 tcp:5040
adb shell su -c "/data/local/tmp/gdbserver :5040 --attach $KEYMASTER_PID" &
sleep 2 

echo "Starting gdb"
$GDBCLIENT -ex "set confirm off" \
           -ex "set sysroot /home/user/Dokumente/Ray/files/volla2/sysroot" \
           -ex "set solib-search-path /home/user/Dokumente/Ray/files/volla2/sysroot/system/lib64:/home/user/Dokumente/Ray/files/volla2/sysroot/vendor/lib64:/home/user/Dokumente/Ray/files/volla2/sysroot/apex/com.android.runtime/lib64/bionic:/home/user/Dokumente/Ray/files/volla2/sysroot/apex/com.android.vndk.v32/lib64" \
           -ex "target remote :5040" \
           -ex "file /home/user/Dokumente/Ray/files/volla2/sysroot/vendor/bin/hw/android.hardware.keymaster@4.1-service.beanpod" \
           -ex "set architecture aarch64" \
           -ex "set complaints 0" \
           -ex "hbreak bp_keymaster_send" \
           -ex "hbreak bp_keymaster_call" \
           -ex "hbreak bp_keymaster_send_no_request" \
           -ex "continue"

echo "GDB session started"
exit 0