"""H&M recommender API: serves the batch-computed recommendations.

Run from the project root:   uvicorn src.api.main:app --reload
Then open:                   http://127.0.0.1:8000/docs
"""
import json
from pathlib import Path

import pandas as pd
import pyarrow.compute as pc
import pyarrow.parquet as pq
from fastapi import FastAPI, Query

ART = Path(__file__).resolve().parents[2] / "data" / "artifacts"

# Load once at startup, in a compact form: customer IDs as an index, items as a grid of numbers
_table = pq.read_table(ART / "recommendations.parquet")
CUSTOMERS = pd.Index(_table["customer_id"].to_pylist())
ITEMS = (pc.cast(pc.list_flatten(_table["article_ids"]), "int64")   # all lists end to end, as numbers
           .to_numpy().reshape(len(CUSTOMERS), 12))                  # one row per customer, 12 columns
del _table
COLD = json.loads((ART / "cold_start.json").read_text())

app = FastAPI(title="H&M Recommender API", version="1.0")


@app.get("/health")
def health():
    """Is the service up, and how fresh are the recommendations?"""
    return {"status": "ok", "customers": len(CUSTOMERS), "history_end": COLD["history_end"]}


@app.get("/sample")
def sample():
    """A few real customer IDs to try the /recommend endpoint with."""
    return {"customer_ids": CUSTOMERS[:3].tolist()}


@app.get("/recommend/{customer_id}")
def recommend(customer_id: str, k: int = Query(12, ge=1, le=12)):
    """Top-k items for a customer: personalised if we know them, otherwise last week's best-sellers."""
    pos = CUSTOMERS.get_indexer([customer_id])[0]          # -1 means "not in the table"
    if pos == -1:
        return {"customer_id": customer_id, "source": "cold_start", "recommendations": COLD["trending"][:k]}
    items = [str(x).zfill(10) for x in ITEMS[pos, :k]]
    return {"customer_id": customer_id, "source": "personalised", "recommendations": items}