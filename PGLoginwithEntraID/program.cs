using Azure.Identity;
using Npgsql;
using System;
using System.Threading.Tasks;
using static System.Net.WebRequestMethods;

class Program
{
    static async Task Main(string[] args)
    {
        // Your PostgreSQL Flexible Server details
        string host = "<yourpgserver>.postgres.database.azure.com";
        string database = "postgres";
        string user = "<your user id>";
        // Example: user = alice@contoso.com;

        // 1. Acquire an Entra ID access token for PostgreSQL
        var credential = new InteractiveBrowserCredential();

    // PostgreSQL Flexible Server uses this scope
    string[] scopes = new[] { "https://ossrdbms-aad.database.windows.net/.default"};

        var token = await credential.GetTokenAsync(
            new Azure.Core.TokenRequestContext(scopes)
        );

        // 2. Build the Npgsql connection string
        var connString = new NpgsqlConnectionStringBuilder
        {
            Host = host,
            Database = database,
            Username = user,
            Port = 5432,
            SslMode = SslMode.Require,
            TrustServerCertificate = true
        };

        // 3. Open the connection using the token
        await using var conn = new NpgsqlConnection(connString.ConnectionString)
        {
            // Npgsql uses this delegate to fetch the token
            ProvidePasswordCallback = (host, port, database, username) => token.Token
        };
        Console.WriteLine(token.Token);

        await conn.OpenAsync();

        Console.WriteLine("Connected successfully using Entra ID authentication.");

        // 4. Run a simple query
        string sql = "SELECT version();";

        await using var cmd = new NpgsqlCommand(sql, conn);
        await using var reader = await cmd.ExecuteReaderAsync();

        // 5. Write results to console
        while (await reader.ReadAsync())
        {
            Console.WriteLine($"PostgreSQL Version: {reader.GetString(0)}");
        }

        Console.WriteLine("Query complete.");
    }
}

