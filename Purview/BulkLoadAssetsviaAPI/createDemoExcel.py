import pandas as pd
from datetime import datetime
import openpyxl

rows=[]
for i in range(1,101):
    rows.append({
        "typeName": "DataSet" if i % 3 == 0 else None,  # exercise defaulting logic
        "qualifiedName": f"asset_{i:03d}@excel_poc",
        "name": f"asset_{i:03d}",
        "description": f"PoC asset created from Excel row {i:03d}",
        "owner": f"owner{i:03d}@contoso.com",
        "customAttributes.domain": ["Finance","HR","Sales","IT"][i % 4],
        "customAttributes.priority": ["High","Medium","Low"][i % 3],
        "customAttributes.sensitive": "Yes" if i % 5 == 0 else "No",
        "customAttributes.costCenter": f"CC{1000 + (i % 20):04d}"
    })

df=pd.DataFrame(rows)

# Write Excel
xlsx_path='assets.xlsx'
df.to_excel(xlsx_path, index=False, engine='openpyxl')

# Also write CSV for copy/paste fallback
csv_path='assets_100.csv'
df.to_csv(csv_path, index=False)

(xlsx_path, csv_path, df.head(3).to_dict(orient='records') )


