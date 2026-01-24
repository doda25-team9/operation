import csv
import json
import requests
import random

CSV_FILE = 'ExAIS_SMS_SPAM_DATA.csv'
STABLE_URL = 'http://stable.sms-checker.local:8080/sms/'
CANARY_URL = 'http://canary.sms-checker.local:8080/sms/'

def send_sms():
    with open(CSV_FILE, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        counter = 0
        for row in reader:
            if random.random() < 0.10:
                url = CANARY_URL
            else:
                url = STABLE_URL

            message = row['Message']
            payload = {"sms": message}
            
            try:
                response = requests.post(
                    url, 
                    json=payload, 
                    headers={"Content-Type": "application/json"}
                )
            except Exception as e:
                print(f"Failed to send: {e}")

            counter += 1
            if counter % 200 == 0:
                print(f'{counter} messages sent')
        
        print(f'{counter} requests sent')

if __name__ == "__main__":
    send_sms()