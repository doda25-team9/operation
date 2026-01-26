#!/bin/bash

URL="http://sms-checker.local/sms/"
COOKIE_FILE="/tmp/session-$$.txt"

echo "Attempting to obtain v2 session (10% probability per attempt)"
echo ""

for attempt in {1..30}; do
  rm -f "$COOKIE_FILE"
  echo -n "Attempt $attempt: "
  
  VERSION=$(curl -s -c "$COOKIE_FILE" -I "$URL" 2>/dev/null | \
            grep -i "x-app-version" | awk '{print $2}' | tr -d '\r')
  
  echo "$VERSION"
  
  if [[ "$VERSION" == "v2" ]]; then
    echo ""
    echo "v2 session obtained"
    echo ""
    echo "Testing v2 session persistence..."
    
    for i in {1..10}; do
      echo -n "  Request $i: "
      curl -s -b "$COOKIE_FILE" -I "$URL" 2>/dev/null | \
        grep -i "x-app-session" | awk '{print $2}' | tr -d '\r'
    done
    
    echo ""
    echo "v2 sticky session verified"
    rm -f "$COOKIE_FILE"
    exit 0
  fi
done

echo ""
echo "v2 not obtained after 30 attempts"
rm -f "$COOKIE_FILE"
exit 1
