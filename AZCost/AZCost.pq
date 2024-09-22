// Power Query M code to query the database and pull all rows back, then parst the tags which are stored in Json and create a new column for each unique Tag name and place the Tag value in that column for each row that has that tag.

let
    // Step 1: Load the data from the database
    Source = Sql.Database("db", "AZCost", [Query="Select * from History"]),
    
    // Step 2: Buffer the table
    BufferedTable = Table.Buffer(Source),
    
    // Step 3: Add a conditional column to parse JSON only if Tags is not null or empty
    AddParsedJson = Table.AddColumn(BufferedTable, "ParsedTags", each if [Tags] <> null and [Tags] <> "" then Json.Document([Tags]) else null),
    
    // Step 4: Remove rows where ParsedTags is null
    RemoveNulls = Table.SelectRows(AddParsedJson, each [ParsedTags] <> null),
    
    // Step 5: Extract unique keys from the JSON
    ExtractKeys = List.Distinct(List.Combine(List.Transform(RemoveNulls[ParsedTags], each Record.FieldNames(_)))),
    
    // Step 6: Add new columns for each unique key to the original table
    AddColumns = List.Accumulate(ExtractKeys, RemoveNulls, (state, current) => Table.AddColumn(state, current, each if [ParsedTags] <> null and Record.HasFields([ParsedTags], current) then Record.Field([ParsedTags], current) else null)),
    
    // Step 7: Remove the ParsedTags column as it's no longer needed
    FinalTable = Table.RemoveColumns(AddColumns, {"ParsedTags"})
in
    FinalTable
