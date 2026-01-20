#!/bin/bash

URL="http://localhost:8080/sms/"

echo "Starting SMS traffic simulation..."
echo "Target: $URL"
echo "Press [CTRL+C] to stop."
echo "-------------------------------------"

while true; do

  # Phase 1: Spam Burst
  echo "Sending spam burst..."
  for i in {1..15}; do
    curl -s -o /dev/null -X POST "$URL" \
      -H "Content-Type: application/json" \
      -d '{"sms":"WINNER!! As a valued network customer you have been selected to receivea £900 prize reward! To claim call 09061701461. Claim code KL341. Valid 12 hours only."}'
    sleep 0.1
  done

  # Phase 2: Normal Traffic
  echo "Sending normal traffic..."
  for i in {1..20}; do
    curl -s -o /dev/null -X POST "$URL" \
      -H "Content-Type: application/json" \
      -d '{"sms":"Hey, are we still on for lunch tomorrow? Let me know."}'
    sleep 0.5
  done

  # Phase 3: Long Messages
  echo "Sending long messages..."
  for i in {1..5}; do
    curl -s -o /dev/null -X POST "$URL" \
      -H "Content-Type: application/json" \
      -d '{"sms":"This is a significantly longer message that is intended to test the character length histogram buckets in Prometheus. It contains many words and sentences to ensure it exceeds the typical length of a standard SMS message, pushing the data into the higher buckets on your Grafana dashboard."}'
    sleep 0.2
  done

  # Phase 4: Pause
  echo "Pausing for 5 seconds..."
  sleep 5
  echo "-------------------------------------"

done