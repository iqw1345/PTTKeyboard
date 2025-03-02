# PTTKeyboard
Hold down your Space Bar to TX

Bash script for Linux

Needs Hamlib to be configured for your rig and evtest to be installed.

Script needs to be modified to use your keyboard.

Run:

```sudo evtest```

Find your keyboard, and update within the script:

```sudo evtest /dev/input/eventX```

with your keyboard.

Tested on Arch Linux and ICOM 7300.
