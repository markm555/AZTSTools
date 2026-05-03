
Markdown# Purview Bulk Asset Loader (Excel + Python)## OverviewThis repository contains two Python utilities designed to demonstrate and enable **bulk asset creation in Microsoft Purview using Excel or CSV input**.These scripts are intended for:- ✅ Customer scenarios (bulk loading real metadata from spreadsheets)- ✅ Demo scenarios (quickly generating sample data for testing)---## Components### 1. `createDemoExcel.py`Generates a sample Excel (`.xlsx`) and CSV (`.csv`) file for testing or demonstration purposes.#### What it does- Creates 100 sample assets with realistic metadata- Includes required Purview fields and custom attributes- Provides a ready-to-use spreadsheet for ingestion#### Output Files- `assets.xlsx` → Primary input for ingestion- `assets_100.csv` → Fallback / troubleshooting format#### Sample Columns| Column                          | Description                          ||---------------------------------|--------------------------------------|| typeName                        | Purview asset type                   || qualifiedName                   | Unique identifier in the catalog     || name                            | Asset display name                   || description                     | Asset description                    || owner                           | Owner email                          || customAttributes.domain         | Business domain                      || customAttributes.priority       | Priority classification              || customAttributes.sensitive      | Sensitivity indicator                || customAttributes.costCenter     | Cost center value                    |---### 2. `BulkLoadFromExcel.py`Reads the Excel file and performs bulk asset creation (or update) in Microsoft Purview using the API.#### What it does- Reads structured data from Excel or CSV- Maps columns to Purview entity attributes- Creates or updates assets in Purview- Supports custom attributes dynamically> NOTE: This script assumes API authentication and endpoint configuration are handled (e.g., Azure AD token).---## End-to-End Workflow### Step 1 – Generate Sample Data (Optional)```bashpython createDemoExcel.pyShow more lines

License (MIT)
Plain TextMIT LicenseCopyright (c) 2026 Mark MoorePermission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the “Software”), 
to dealin the Software without restriction, including without limitation the rightsto use, copy, modify, merge, publish, distribute, sublicense, and/or sellcopies of the Software, and to permit 
persons to whom the Software isfurnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in allcopies or substantial portions 
of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS ORIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THEAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHERLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,OUT OF OR IN CONNECTION WITH 
THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THESOFTWARE.Show more lines

Creates:

assets.xlsx
assets_100.csv


Step 2 – Modify Spreadsheet (Customer Scenario)
Customers can:

Replace rows with real data
Add/remove columns
Maintain required fields:

qualifiedName
name
typeName (optional if defaulted)




Step 3 – Bulk Load into Purview
Shellpython BulkLoadFromExcel.pyShow more lines
This will:

Read the spreadsheet
Construct API payloads
Create or update assets in Purview


Customization Guide
Adding Custom Attributes
To add new attributes:


Add a column in Excel:
customAttributes.<attributeName>



Ensure mapping logic in ingestion script handles it, for example:
Pythonentity["attributes"]["customAttributes"][attr] = valueShow more lines



Changing Asset Type
Modify the typeName column:
Python"typeName": "DataSet"Show more lines
Supported examples:

DataSet
Table
Column
Custom types defined in Purview


Scaling Data Volume
Update row generation logic:
Pythonfor i in range(1, 101):Show more lines

Design Considerations

Excel-first approach simplifies customer adoption
Works well for:

Proof of Concepts (POCs)
Data catalog onboarding
Migration use cases


CSV fallback supports quick troubleshooting
Custom attribute pattern aligns with flexible metadata modeling in Purview


Prerequisites
Python Dependencies
Shellpip install pandas openpyxlShow more lines
Environment Requirements

Python 3.x
Microsoft Purview account
Azure AD authentication set up for API access


Known Limitations

No schema validation against Purview types
Limited error handling (intended for demo/POC usage)
Assumes attributes exist or are accepted dynamically
Does not currently support:

Relationships
Lineage
Classification assignments




Suggested Enhancements

Add retry logic / error handling
Add logging output for ingestion results
Add support for relationships and lineage
Introduce config file for API endpoint and auth

Summary
This solution provides:

✅ A reusable Excel-based ingestion pattern
✅ A demo data generator for rapid setup
✅ A customer-ready workflow for bulk asset onboarding in Purview
