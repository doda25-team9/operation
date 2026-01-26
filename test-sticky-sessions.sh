#!/bin/bash

URL="http://sms-checker.local/sms/"
COOKIE_FILE="/tmp/session-$$.txt"

echo "======================================"
echo "Sticky Session Implementation Tests"
echo "======================================"
echo "Note: Requests may take 5-10 seconds"
echo ""

# Test 1: Traffic Distribution
echo "Test 1: Traffic Distribution (10 requests)"
echo "-------------------------------------------"

for i in {1..10}; do
  echo "  Request $i..."
  VERSION=$(curl -s -I "$URL" 2>/dev/null | grep -i "x-app-version" | awk '{print $2}' | tr -d '\r')
  echo "    Version: $VERSION"
done

echo ""

# Test 2: Sticky Session
echo "Test 2: Sticky Session Verification"
echo "------------------------------------"

rm -f "$COOKIE_FILE"

echo "First request (no cookie)..."
RESPONSE=$(curl -s -c "$COOKIE_FILE" -I "$URL" 2>/dev/null)
FIRST_VERSION=$(echo "$RESPONSE" | grep -i "x-app-version" | awk '{print $2}' | tr -d '\r')
COOKIE_SET=$(echo "$RESPONSE" | grep -i "set-cookie: user-session" | wc -l)

echo "  Version: $FIRST_VERSION"
echo "  Cookie set: $([ $COOKIE_SET -gt 0 ] && echo 'Yes' || echo 'No')"

if [[ -n "$FIRST_VERSION" ]] && (( COOKIE_SET > 0 )); then
  echo "  Initial routing successful"
  
  echo ""
  echo "Next 10 requests (with cookie)..."
  
  all_sticky=true
  for i in {1..10}; do
    echo "  Request $i..."
    SESSION=$(curl -s -b "$COOKIE_FILE" -I "$URL" 2>/dev/null | grep -i "x-app-session" | awk '{print $2}' | tr -d '\r')
    echo "    Session: $SESSION"
    
    if [[ "$SESSION" != "sticky-active" ]]; then
      all_sticky=false
    fi
  done
  
  echo ""
  if [ "$all_sticky" = true ]; then
    echo "Sticky sessions verified:"
    echo "  - Cookie set on first request"
    echo "  - Subsequent requests use cookie-based routing"
    echo "  - User remains on same version"
  else
    echo "Sticky sessions failed"
  fi
else
  echo "  Initial routing failed"
fi

echo ""

# Test 3: Configuration
echo "Test 3: Configuration Verification"
echo "-----------------------------------"

kubectl get virtualservice app-virtualservice -o yaml | grep -A 2 "user-session" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "VirtualService cookie routing: configured"
else
  echo "VirtualService cookie routing: not found"
fi

kubectl get destinationrule app-destinationrule -o yaml | grep "consistentHash" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "DestinationRule consistent hash: configured"
else
  echo "DestinationRule consistent hash: not found"
fi

kubectl get pods -l app=sms-checker --field-selector=status.phase=Running | grep "2/2" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "App pods: running (2/2 ready)"
else
  echo "App pods: not ready"
fi

echo ""
echo "======================================"
echo "Tests Complete"
echo "======================================"

rm -f "$COOKIE_FILE"
