#!/bin/bash

BOT_TOKEN="123456789:ABCdefGHIjkLmnoPQRstuVWxyZ"
CHAT_ID="123456789"
MESSAGE="$1"

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="$MESSAGE"
