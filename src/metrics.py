"""Ranking metrics for the recommender: recall@k and MAP@k."""
import numpy as np


def recall_at_k(actual_items, predicted, k=12):
    """Share of the items the customer bought that appear in our top k."""
    return len(actual_items & set(predicted[:k])) / len(actual_items)


def ap_at_k(actual_items, predicted, k=12):
    """Average precision: like recall, but rewards putting hits near the top."""
    hits, score = 0, 0.0
    for i, item in enumerate(predicted[:k]):
        if item in actual_items:
            hits += 1
            score += hits / (i + 1)
    return score / min(len(actual_items), k)


def evaluate(recommend, actual, k=12):
    """recommend = a function that takes a customer_id and returns a list of items."""
    recalls, aps = [], []
    for customer, items in actual.items():
        preds = recommend(customer)
        recalls.append(recall_at_k(items, preds, k))
        aps.append(ap_at_k(items, preds, k))
    return {"recall@12": round(np.mean(recalls), 4), "map@12": round(np.mean(aps), 4)}