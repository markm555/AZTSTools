# MIT License

Copyright (c) 2026 Mark Moore

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Purview Bulk Asset Loader (Excel + Python)

## Overview

This repository contains two Python scripts for demonstrating and enabling
bulk asset creation in Microsoft Purview using Excel or CSV input.

These scripts support:
- Customer scenarios (loading real metadata from spreadsheets)
- Demo scenarios (generating sample data quickly)

---

## Components

### createDemoExcel.py

Generates a sample Excel and CSV file with asset metadata for testing and demos.

What it does:
- Creates 100 sample assets
- Includes standard Purview fields and custom attributes
- Outputs two files:
  - assets.xlsx
  - assets_100.csv

Example columns:
- typeName  
- qualifiedName  
- name  
- description  
- owner  
- customAttributes.domain  
- customAttributes.priority  
- customAttributes.sensitive  
- customAttributes.costCenter  

---

### BulkLoadFromExcel.py

Reads the Excel file and performs bulk asset creation or updates in Purview.

What it does:
- Reads Excel or CSV input
- Maps columns to Purview entity attributes
- Calls the Purview REST API to create or update assets

Note:
Authentication and endpoint configuration must be provided in the script.

---

## End-to-End Workflow

Step 1 – Generate demo data (optional)

    python createDemoExcel.py

Outputs:
- assets.xlsx
- assets_100.csv


Step 2 – Modify spreadsheet (customer scenario)

Customers can:
- Replace rows with real data
- Add or remove columns
- Maintain required fields:
  - qualifiedName
  - name
  - typeName (optional if defaulted)


Step 3 – Load data into Purview

    python BulkLoadFromExcel.py

---

## Customization Guide

### Adding new attributes

Add a column in Excel:

    customAttributes.<attributeName>

Example:

    customAttributes.dataOwner
    customAttributes.retentionPolicy


Ensure your loading script maps them into the Purview payload.


---

### Changing asset type

Modify the typeName column:

    DataSet

Other examples:
- Table
- Column
- Custom Purview types


---

### Changing dataset size

Modify the loop in the script:

    for i in range(1, 101):

---

## Prerequisites

Python 3.x

Install required packages:

    pip install pandas openpyxl

You also need:
- Microsoft Purview account
- Azure AD authentication configured for API access

---

## Design Notes

- Excel-first design enables non-developers to participate
- Useful for:
  - Proof of Concepts
  - Workshops
  - Metadata onboarding
- CSV output provides a simple fallback for troubleshooting

---

## Known Limitations

- No schema validation against Purview types
- Limited error handling (demo/POC focused)
- Does not include:
  - Relationships
  - Lineage
  - Classifications

---

## Suggested Enhancements

- Add logging
- Add retry/error handling
- Add configuration file for API settings
- Extend to relationships and lineage

---

## Summary

This solution provides:
- A demo dataset generator
- A reusable Excel-driven ingestion pattern
- A flexible way to onboard metadata into Purview

---
