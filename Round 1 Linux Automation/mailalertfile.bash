#!/bin/bash

THRESHOLD=3
LOG_FILE="/var/log/sudo-access.log"
ADMIN_EMAIL="ekambaramjanesh@gmail.com"

# Find all users with UID greater than or equal to 1000 and not system users (UID != 65534)
LOW_PRIV_USERS=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd)

echo "$LOW_PRIV_USERS"

for USER in $LOW_PRIV_USERS; do
  # Check if username contains only lowercase letters (no uppercase)
  if [[ $USER =~ ^[a-z]+$ ]]; then
    THRESHOLD=1  # Limit to 1 sudo attempt for users with lowercase letters only
    echo "User $USER is limited to $THRESHOLD sudo attempt."
    
  # Check if username ends with 'SH'
  elif [[ $USER =~ SH$ ]]; then
    echo "User $USER has unlimited sudo attempts."
    continue  # Allow unlimited attempts and skip the rest of the script for this user
  else
    THRESHOLD=3  # Default threshold for all other users
  fi

  SUDO_COUNT=$(grep -c "$USER : user not in sudoers" $LOG_FILE)

  if [[ $SUDO_COUNT -gt $THRESHOLD ]]; then
    echo "Threshold Reached. Mailing about $USER"
    SUBJECT="Excessive sudo attempts by $USER"
    BODY="The user $USER has attempted to use sudo commands $SUDO_COUNT times."
    echo "$BODY" | mail -s "$SUBJECT" "$ADMIN_EMAIL"
  fi
done
