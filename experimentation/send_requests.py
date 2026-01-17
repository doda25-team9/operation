import csv
import json
import requests

# Configuration
CSV_FILE = 'ExAIS_SMS_SPAM_DATA.csv'
URL = 'http://localhost:8080/sms/'

def send_sms():
    with open(CSV_FILE, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        counter = 0
        for row in reader:
            counter += 1
            # if counter % 100 == 0:
            #     print(f'{counter} messages sent')

            # message = row['Message']
            # payload = {"sms": message}
            
            # try:
            #     response = requests.post(
            #         URL, 
            #         json=payload, 
            #         headers={"Content-Type": "application/json"}
            #     )
            # except Exception as e:
            #     print(f"Failed to send: {e}")
        

        with open(CSV_FILE, newline="") as f:
            in_quote = False
            for i, line in enumerate(f, start=1):
                if line.count('"') % 2 == 1:
                    in_quote = not in_quote
                if in_quote:
                    print("INSIDE QUOTED FIELD:", i, line.rstrip())
        print(counter)

if __name__ == "__main__":
    send_sms()