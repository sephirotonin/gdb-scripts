for i in {1..100}; do
    adb shell input tap 1000 200  
    sleep 1
    adb shell input tap 1000 200 
    sleep 2
done