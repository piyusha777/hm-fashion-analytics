"""Build the two Tableau extracts that need transaction-level data.

Reads the processed CSVs written by notebooks/01_data_exploration.ipynb and
writes small, aggregated files to dashboard/data/. No customer IDs leave this
script: the outputs are counts and article-level averages only.

Usage, from the repo root:
    python scripts/build_tableau_extracts.py

Outputs:
    dashboard/data/overview_kpis.csv
    dashboard/data/price_volume_by_article.csv

If outputs/summary_tables/price_quintile_summary.csv exists, the script also
checks that its quintiles reproduce that table, so the dashboard and the
notebook can't drift apart silently.
"""

from pathlib import Path
import sys

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
TXN = ROOT / "data" / "processed" / "transactions_filtered.csv"
ART = ROOT / "data" / "processed" / "articles_filtered.csv"
OUT = ROOT / "dashboard" / "data"
NOTEBOOK_QUINTILES = ROOT / "outputs" / "summary_tables" / "price_quintile_summary.csv"

SAMPLE_FRACTION = 0.5  # set in notebook 01
MIN_UNITS = 10         # article floor, same as notebook 04
MIN_ARTICLES = 25      # category needs this many eligible articles for quintiles


def add_price_quintile(group: pd.DataFrame) -> pd.DataFrame:
    """Same rule as notebook 04: quintiles of avg price within a category."""
    group = group.copy()
    if len(group) < MIN_ARTICLES:
        group["price_quintile"] = pd.NA
        return group
    group["price_quintile"] = pd.qcut(
        group["avg_price_scaled"].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]
    ).astype("Int64")
    return group


def main() -> int:
    for path in (TXN, ART):
        if not path.exists():
            print(f"Missing {path}. Run notebooks/01_data_exploration.ipynb first.")
            return 1
    OUT.mkdir(parents=True, exist_ok=True)

    txn = pd.read_csv(
        TXN,
        usecols=["t_dat", "customer_id", "article_id", "price"],
        dtype={"customer_id": "string", "article_id": "int64", "price": "float64"},
        parse_dates=["t_dat"],
    )
    articles = pd.read_csv(ART, usecols=["article_id", "product_group_name"])

    # Overview tile values. Customers come from transactions, not the customers
    # table, which holds everyone active in the window before sampling.
    kpis = pd.DataFrame([{
        "transactions": len(txn),
        "customers": txn["customer_id"].nunique(),
        "articles_sold": txn["article_id"].nunique(),
        "first_date": txn["t_dat"].min().date().isoformat(),
        "last_date": txn["t_dat"].max().date().isoformat(),
        "sample_fraction": SAMPLE_FRACTION,
        "sample_note": "50% of customers active Jun 22 to Sep 22, 2020, all their transactions kept",
    }])
    kpis.to_csv(OUT / "overview_kpis.csv", index=False)
    print(kpis.T.to_string(header=False))

    # Article-level price versus volume, mirroring notebook 04.
    per_article = (
        txn.merge(articles, on="article_id", how="inner")
        .groupby(["product_group_name", "article_id"], as_index=False)
        .agg(units_sold=("price", "size"), avg_price_scaled=("price", "mean"))
    )
    if len(per_article["units_sold"]) and per_article["units_sold"].sum() != len(txn):
        print("Warning: join dropped or duplicated rows. Check articles_filtered.csv.")

    eligible = per_article[per_article["units_sold"] >= MIN_UNITS]
    eligible = pd.concat(
        [add_price_quintile(g) for _, g in eligible.groupby("product_group_name")],
        ignore_index=True,
    )
    eligible["in_quintile_analysis"] = eligible["price_quintile"].notna()
    eligible = eligible.sort_values(["product_group_name", "avg_price_scaled"])
    eligible.to_csv(OUT / "price_volume_by_article.csv", index=False)
    print(f"\nprice_volume_by_article.csv: {len(eligible):,} articles with {MIN_UNITS}+ units")

    # Cross-check against the notebook's saved quintile table.
    if NOTEBOOK_QUINTILES.exists():
        ours = (
            eligible.dropna(subset=["price_quintile"])
            .groupby(["product_group_name", "price_quintile"])
            .agg(article_count=("article_id", "count"), median_units_sold=("units_sold", "median"))
            .reset_index()
        )
        ref = pd.read_csv(NOTEBOOK_QUINTILES)
        check = ref.merge(ours, on=["product_group_name", "price_quintile"], suffixes=("_nb", "_new"))
        same = (
            len(check) == len(ref)
            and (check["article_count_nb"] == check["article_count_new"]).all()
            and (check["median_units_sold_nb"] == check["median_units_sold_new"]).all()
        )
        print("Matches notebook 04 quintiles:", "yes" if same else "NO, investigate before publishing")
        if not same:
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
