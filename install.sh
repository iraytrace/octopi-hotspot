#!/bin/bash

if [ ! -x ./setup_hotspot.sh ] ; then
    echo "❌ Error: setup_hotspot.sh does not exist or is not executable"
    exit 1
fi
./setup_hotspot.sh

RC_LOCAL="/etc/rc.local"
setup_hotspot.sh*
SCRIPT_PATH="/usr/local/sbin/update-ip-issue.sh"

# install the script
sudo install -x update-ip-issue.sh $SCRIPT_PATH

# Ensure the script exists
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "❌ Error: $SCRIPT_PATH does not exist or is not executable"
    exit 1
fi

# If /etc/rc.local does not exist, create a basic one
if [ ! -f "$RC_LOCAL" ]; then
    echo "🛠️  Creating $RC_LOCAL"
    sudo tee "$RC_LOCAL" > /dev/null <<EOF
#!/bin/bash
$SCRIPT_PATH

exit 0
EOF
    sudo chmod +x "$RC_LOCAL"
    echo "✅ Created and configured $RC_LOCAL"
    exit 0
fi

# If the script is already in rc.local, do nothing
if grep -Fxq "$SCRIPT_PATH" "$RC_LOCAL"; then
    echo "✅ $SCRIPT_PATH already present in $RC_LOCAL"
    exit 0
fi

# Insert the script line before the 'exit 0'
echo "🛠️  Inserting $SCRIPT_PATH into $RC_LOCAL"
sudo sed -i "\|^exit 0\$|i $SCRIPT_PATH" "$RC_LOCAL"
sudo chmod +x "$RC_LOCAL"

echo "✅ Successfully added $SCRIPT_PATH to $RC_LOCAL"


