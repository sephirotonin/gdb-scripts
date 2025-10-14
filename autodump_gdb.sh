#!/bin/bash

export GDBCLIENT=gdb-multiarch

if [ -z "$GDBCLIENT" ]; then
    echo "Please set GDBCLIENT environment variable!"
    exit 1
fi

echo "Getting keymaster pid"
KEYMASTER_PID=$(adb wait-for-device && adb shell su -c "ps -A | grep android.hardware.keymaster" | awk '{print $2}')
if [ -z "$KEYMASTER_PID" ]; then
    echo "Could not find keymaster PID!"
    exit 1
fi
echo "keymaster pid = $KEYMASTER_PID"

echo "Cleaning up old gdbserver"
adb shell su -c pkill -9 gdbserver
adb forward --remove-all

echo "Starting gdbserver"
adb forward tcp:5040 tcp:5040
adb shell su -c "/data/local/tmp/gdbserver :5040 --attach $KEYMASTER_PID" &
sleep 5

DUMP_DIR="/home/user/Dokumente/Ray/files/keyTriggerScript/newdumps"
mkdir -p "$DUMP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create temporary GDB init file
GDB_INIT_TEMP="/tmp/gdb_init_temp.gdb"
cat <<EOF > $GDB_INIT_TEMP
set \$counter = 0
delete breakpoints
break bp_keymaster_call
commands
    silent
    set \$counter = \$counter + 1
    printf "Hit bp_keymaster_call (%d) at %p, x0=%p, x1=%p, x2=%p, x3=%p\\n", \$counter, \$pc, \$x0, \$x1, \$x2, \$x3
    eval "dump binary memory $DUMP_DIR/input_dump_${TIMESTAMP}_%d.bin \$x1 \$x1+0x11800", \$counter
    eval "dump binary memory $DUMP_DIR/output_dump_${TIMESTAMP}_%d.bin \$x3 \$x3+0x11800", \$counter
    continue
end
continue
EOF

echo "Starting gdb with auto-dumps"
$GDBCLIENT -ex "set confirm off" \
           -ex "set sysroot /home/user/Dokumente/Ray/files/volla2/sysroot" \
           -ex "set solib-search-path /home/user/Dokumente/Ray/files/volla2/sysroot/system/lib64:/home/user/Dokumente/Ray/files/volla2/sysroot/vendor/lib64:/home/user/Dokumente/Ray/files/volla2/sysroot/apex/com.android.runtime/lib64/bionic:/home/user/Dokumente/Ray/files/volla2/sysroot/apex/com.android.vndk.v32/lib64" \
           -ex "set architecture aarch64" \
           -ex "set complaints 0" \
           -ex "set logging file $DUMP_DIR/gdb_log_$TIMESTAMP.txt" \
           -ex "set logging enabled on" \
           -ex "target remote :5040" \
           -x "$GDB_INIT_TEMP"

echo "GDB session started with auto-dumps to $DUMP_DIR"
rm "$GDB_INIT_TEMP"
exit 0