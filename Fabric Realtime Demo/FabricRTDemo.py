#
# This is a sample program that will randomly generate transactions as you would see in a checkbook along with categories for each transaction and a running balance.
# If the balance falls below the next transaction amount + $500, it will make a random deposit amount to bring the balance back up.
# 
# In this specific example, I am writing the transactions to an Azure Event Hub, however, it would be very easy to write these transactions to a database.
# 
# 08/12/2024
# Mark Moore
#

import json
import random
import time
from datetime import datetime
from azure.eventhub import EventHubProducerClient, EventData

# Modify the next four lines of code to include values for your Eventhub Namespace, Name, Keyname, and key value.
EHNamespace = "<YourNamespaceName>"
EHName = "<YourEventHubName>"
EHKeyname = "<YourEHKeyname>"
EHKey = "<YourKeyValue>"

connection_string = f"Endpoint=sb://{EHNamespace}.servicebus.windows.net/;SharedAccessKeyName={EHKeyname};SharedAccessKey={EHKey};EntityPath={EHName}"
event_hub_name = "transactions"

Departments = [
    "Mortgage", "Utilities", "Internet", "Phone", "Groceries", "Eating Out", "Transportation", "Healthcare",
    "Insurance", "Personal Care", "Clothing", "Entertainment", "Fitness", "Education", "Gifts", "Travel",
    "Home Maintenance", "Furnishings", "Savings", "Misc"
]

def get_department():
    return random.choice(Departments)

async def main():
    balance = 10000  # Initial balance of $10,000.00
    producer_client = EventHubProducerClient.from_connection_string(connection_string, event_hub_name=event_hub_name)

    try:
        while True:
            dt = datetime.now()
            price = round(random.uniform(0, 1000), 2)
            price_str = f"{price:.2f}"

            try:
                event_batch = producer_client.create_batch()
            except Exception as e:
                print(f"Error creating batch: {e}")
                break

            category = get_department()

            ehrec = {}

            if balance < (price + 500):
                deposit = round(random.uniform(0, 10000), 2)
                balance += deposit
                ehrec["DateTime"] = dt.isoformat()
                ehrec["Category"] = "Deposit"
                ehrec["Deposit"] = deposit
                ehrec["Withdrawal"] = ""
                ehrec["Balance"] = f"{balance:.2f}"
            else:
                balance -= price
                ehrec["DateTime"] = dt.isoformat()
                ehrec["Category"] = category
                ehrec["Deposit"] = ""
                ehrec["Withdrawal"] = price_str
                ehrec["Balance"] = f"{balance:.2f}"

            event_batch.add(EventData(json.dumps(ehrec)))
            producer_client.send_batch(event_batch)
            print(json.dumps(ehrec, indent=4))
            time.sleep(1)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        producer_client.close()

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())