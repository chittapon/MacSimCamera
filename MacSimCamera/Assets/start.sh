#!/bin/sh

# work directory
cd "$(dirname "$0")"

# Install python dependency
pip3 install -r requirements.txt

# Kill last background process
kill $(< pid.text)

# Run the mock server and send it to background
nohup python3 server.py &

# Record the PID of the last background process
echo $! > pid.text