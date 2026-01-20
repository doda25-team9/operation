import csv
import json
import requests

CSV_FILE = 'ExAIS_SMS_SPAM_DATA.csv'
URL = 'http://localhost:8080/sms/'


def send_sms():
    with open(CSV_FILE, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        counter = 0
        for row in reader:

            counter += 1
            if counter % 200 == 0:
                print(f'{counter} messages sent')

            message = row['Message']
            payload = {"sms": message}
            
            try:
                response = requests.post(
                    URL, 
                    json=payload, 
                    headers={"Content-Type": "application/json", "Host": "sms-checker.local"}
                )
            except Exception as e:
                print(f"Failed to send: {e}")
        
        print(f'{counter} requests sent')

if __name__ == "__main__":
    send_sms()