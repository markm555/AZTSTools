/*
 * This is a sample program that will randomly generate transactions as you would see in a checkbook along with categories for each transaction and a running balance.
 * If the balance falls below the next transaction amount + $500, it will make a random deposit amount to bring the balance back up.
 * 
 * In this specific example, I am writing the transactions to an Azure Event Hub, however, it would be very easy to write these transactions to a database.
 * 
 * 08/12/2024
 * Mark Moore
 */

using System;
using System.Text;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Newtonsoft.Json.Linq;

public class Program
{
    // Modify the next four lines of code to include values for your Eventhub Namespace, Name, Keyname, and key value.
    private static readonly string EHNamespace = "<YourEHNamespace>";
    private static readonly string EHName = "<YourEHName>";
    private static readonly string EHKeyname = "<YourKeyName>";
    private static readonly string EHKey = "<YourKeyValue>";

    private static readonly string connectionString = $"Endpoint=sb://{EHNamespace}.servicebus.windows.net/;SharedAccessKeyName={EHKeyname};SharedAccessKey={EHKey};EntityPath={EHName}";
    private static readonly string eventHubName = "transactions";

    private static readonly string[] Departments = {
        "Mortgage", "Utilities", "Internet", "Phone", "Groceries", "Eating Out", "Transportation", "Healthcare",
        "Insurance", "Personal Care", "Clothing", "Entertainment", "Fitness", "Education", "Gifts", "Travel",
        "Home Maintenance", "Furnishings", "Savings", "Misc"
    };

    private static string GetDepartment()
    {
        Random random = new Random();
        int deptNum = random.Next(Departments.Length);
        return Departments[deptNum];
    }

    public static async Task Main()
    {
        double balance = 10000;  // Initial balance of $10,000.00
        await using var producerClient = new EventHubProducerClient(connectionString, eventHubName);
        Random random = new Random();

        while (true)
        {
            DateTime dt = DateTime.Now;
            double price = Math.Round(random.NextDouble() * 1000, 2);
            string priceStr = price.ToString("F2");

            using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();
            string category = GetDepartment();

            JObject ehrec = new JObject();

            if (balance < (price + 500))
            {
                double deposit = Math.Round(random.NextDouble() * 10000, 2);
                balance += deposit;
                ehrec.Add("DateTime", dt);
                ehrec.Add("Category", "Deposit");
                ehrec.Add("Deposit", deposit);
                ehrec.Add("Withdrawal", "");
                ehrec.Add("Balance", balance.ToString("F2"));
            }
            else
            {
                balance -= price;
                ehrec.Add("DateTime", dt);
                ehrec.Add("Category", category);
                ehrec.Add("Deposit", "");
                ehrec.Add("Withdrawal", priceStr);
                ehrec.Add("Balance", balance.ToString("F2"));
            }

            eventBatch.TryAdd(new EventData(Encoding.UTF8.GetBytes(ehrec.ToString())));
            await producerClient.SendAsync(eventBatch);
            Console.WriteLine(ehrec.ToString());
            Thread.Sleep(1000);
        }
    }
}
