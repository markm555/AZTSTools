import math
import requests
import pandas as pd
from azure.identity import ClientSecretCredential

# =========================
# CONFIGURATION
# =========================
TENANT_ID = "<TENANT_ID>"
CLIENT_ID = "<APP_CLIENT_ID>"
CLIENT_SECRET = "<APP_CLIENT_SECRET>"
PURVIEW_ACCOUNT_NAME = "markm-purview"

# NOTE:
# The REST doc uses a generic {endpoint}. In most tenants this is:
#   https://{account}.purview.azure.com
# If your existing https://{account}.purview.azure.net works, keep it.
PURVIEW_ENDPOINT = f"https://markm-purview.purview.azure.com"

API_VERSION = "2023-09-01"
EXCEL_FILE = "assets.xlsx"
DEFAULT_TYPE_NAME = "DataSet"   # override per-row with a 'typeName' column if you want
BATCH_SIZE = 50                 # set 1 for true row-by-row, or 50/100 for faster PoC loads

# =========================
# AUTHENTICATION
# =========================
credential = ClientSecretCredential(
    tenant_id=TENANT_ID,
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET
)

token = credential.get_token("https://purview.azure.net/.default").token  # per REST ref
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

# =========================
# LOAD EXCEL
# =========================
df = pd.read_excel(EXCEL_FILE, engine="openpyxl")
df = df.where(pd.notna(df), None)  # convert NaN -> None

print(f"Loaded {len(df)} rows from Excel: {EXCEL_FILE}")

# =========================
# HELPERS
# =========================
def row_to_entity(row_dict, row_index):
    """
    Build an Atlas Entity object with:
      - attributes
      - customAttributes
      - businessAttributes (nested)
    """
    # Determine typeName (allow override from Excel)
    type_name = row_dict.get("typeName") or DEFAULT_TYPE_NAME

    # Split columns by prefix
    attributes = {}
    custom_attributes = {}
    business_attributes = {}

    for k, v in row_dict.items():
        if v is None:
            continue

        if k.startswith("customAttributes."):
            ca_key = k.split(".", 1)[1]
            custom_attributes[ca_key] = v

        elif k.startswith("businessAttributes."):
            # businessAttributes.<BMName>.<attrName>
            parts = k.split(".")
            if len(parts) >= 3:
                bm_name = parts[1]
                bm_attr = ".".join(parts[2:])  # allow dot names after BMName
                business_attributes.setdefault(bm_name, {})
                business_attributes[bm_name][bm_attr] = v
            else:
                # malformed column name; ignore or raise depending on preference
                pass

        else:
            # normal attributes (includes qualifiedName, name, description, owner, etc.)
            attributes[k] = v

    # REQUIRED: qualifiedName must exist for upsert matching (unless guid is provided)
    if "qualifiedName" not in attributes:
        raise ValueError("Missing required column 'qualifiedName'")

    entity = {
        "typeName": type_name,
        "attributes": attributes,
        # Optional but useful: temporary negative guid for correlation in response
        "guid": f"-{row_index + 1}"
    }

    if custom_attributes:
        entity["customAttributes"] = custom_attributes

    if business_attributes:
        entity["businessAttributes"] = business_attributes
    return entity

def post_entities(entities):
    url = f"{PURVIEW_ENDPOINT}/datamap/api/atlas/v2/entity/bulk?api-version={API_VERSION}"
    resp = requests.post(url, headers=headers, json={"entities": entities, "referredEntities": {}})
    return resp

# =========================
# BUILD ENTITIES
# =========================
entities = []
errors = 0

for idx, row in df.iterrows():
    try:
        row_dict = row.to_dict()
        entities.append(row_to_entity(row_dict, idx))
    except Exception as e:
        print(f"❌ Row {idx} build error: {e}")
        errors += 1

print(f"Prepared {len(entities)} entities. Build errors: {errors}")

# =========================
# UPLOAD (BATCHED)
# =========================
success_batches = 0
failed_batches = 0

total_batches = max(1, math.ceil(len(entities) / BATCH_SIZE))

for b in range(total_batches):
    batch = entities[b * BATCH_SIZE : (b + 1) * BATCH_SIZE]
    if not batch:
        continue

    resp = post_entities(batch)

    # REST reference shows 200 OK for success
    # Some guidance/examples mention 201 Created can appear on create paths
    if resp.status_code in (200, 201):
        success_batches += 1
        data = resp.json()
        creates = len((data.get("mutatedEntities", {}) or {}).get("CREATE", []) or [])
        updates = len((data.get("mutatedEntities", {}) or {}).get("UPDATE", []) or [])
        print(f"✅ Batch {b+1}/{total_batches} OK (CREATE={creates}, UPDATE={updates})")
    else:
        failed_batches += 1
        print(f"❌ Batch {b+1}/{total_batches} FAILED: {resp.status_code}")
        print(resp.text)

print("\n==== Summary ====")
print(f"Batches OK    : {success_batches}")
print(f"Batches Failed: {failed_batches}")
print(f"Row build errs: {errors}")
