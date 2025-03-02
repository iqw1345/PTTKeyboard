#!/usr/bin/env bash

# Configuration
TELNET_HOST="127.0.0.1"   # Replace with your Telnet server IP
TELNET_PORT="4532"          # Replace with your Telnet port

stty -echo

# Open the telnet session using a file descriptor
exec 3<>/dev/tcp/$TELNET_HOST/$TELNET_PORT
if [[ $? -ne 0 ]]; then
    echo "Failed to connect to $TELNET_HOST on port $TELNET_PORT"
    exit 1
fi

echo "Connected to $TELNET_HOST:$TELNET_PORT"
echo "Monitoring /dev/input/event6 for spacebar events..."

echo "f" >&3
read -r frequency <&3
if [[ ${#frequency} -le 6 ]]; then
    frequency="0$frequency"
fi
formatted_frequency=$(echo "$frequency" | rev | sed 's/\([0-9]\{3\}\)/\1./g' | rev | sed 's/\.$//')
status="\r\033[2K$formatted_frequency Hz | RX"
echo -ne $status
# State variable to track if "T 1" has been sent
spacebar_held=false

# Start monitoring /dev/input/event9 for key events
sudo evtest /dev/input/event7 | while read -r line; do
    # Spacebar hold (value 2), send "T 1" only once
    if echo "$line" | grep -q "type 1 (EV_KEY), code 57 (KEY_SPACE), value 2"; then
        if ! $spacebar_held; then
            echo "T 1" >&3
	    echo "f" >&3
	    read -r rprt <&3
	    read -r frequency <&3
	    if [[ ${#frequency} -le 6 ]]; then
		frequency="0$frequency"
	    fi
	    formatted_frequency=$(echo "$frequency" | rev | sed 's/\([0-9]\{3\}\)/\1./g' | rev | sed 's/\.$//')
	    echo -ne "\r\033[2K$formatted_frequency Hz | TX"
	    spacebar_held=true  # Update state to indicate "T 1" has been sent
        fi
    fi

    # Spacebar release (value 0), send "T 0" every time it's released
    if echo "$line" | grep -q "type 1 (EV_KEY), code 57 (KEY_SPACE), value 0"; then
        if $spacebar_held; then
            echo "T 0" >&3
	    echo "f" >&3
	    read -r rprt <&3
            read -r frequency <&3
	    if [[ ${#frequency} -le 6 ]]; then
                frequency="0$frequency"
            fi  
            formatted_frequency=$(echo "$frequency" | rev | sed 's/\([0-9]\{3\}\)/\1./g' | rev | sed 's/\.$//')
	    echo -ne "\r\033[2K$formatted_frequency Hz | RX"
            spacebar_held=false  # Reset state to allow "T 1" to be sent again
        fi
    fi

done

