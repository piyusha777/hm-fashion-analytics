# Data notes

What this data can and can't support. Each note was confirmed while building the analysis, and every number here comes from the notebooks or `outputs/summary_tables/`.

## Scope and sampling

- **Source:** the [H&M Personalized Fashion Recommendations](https://www.kaggle.com/competitions/h-and-m-personalized-fashion-recommendations) Kaggle competition, published by H&M Group. Only the public competition files are used.
- **Full log:** 31,788,324 transaction rows, Sep 20, 2018 to Sep 22, 2020.
- **Window:** the final three months, Jun 22 to Sep 22, 2020. That's 4,056,792 rows and 535,417 customers.
- **Sample:** 50% of the customers in that window (random, seed 42), with every one of their transactions kept. That gives **267,708 customers and 2,029,325 transactions**. Sampling customers instead of rows keeps each customer's history whole.
- **Not in the data:** web or app behaviour, marketing campaigns, returns, stock levels, and any true sign-up date.

## Price

**`price` is anonymized and scaled. It is not currency.** Values are small decimals (median about 0.025, max about 0.59). H&M didn't publish real prices for this competition. So every "monetary" value here (RFM spend, category revenue, price quintiles) is a relative score in scaled price units. Nothing in this project should be read as dollars or kronor.

## Customer segmentation (RFM)

- All three measures come from the three-month window. **Lost** means one or two purchase days and nothing in the final 47+ days of the window. It describes lapsed behaviour within the window, not a confirmed permanent churn.
- **Ties decide scores, so they have to be handled.** About 49% of customers bought on exactly one day. An earlier version ranked frequency with `method='first'`, which split that tie by row order: about 24,600 one-time buyers got a mid-level F score at random, and about 14,000 of them landed in At Risk. The published version gives equal values equal scores (fixed bins for frequency, quintiles on raw recency). Segment sizes changed a lot, but Lost was the largest segment under both versions.
- Segment rules are a standard RFM-style mapping applied in order. The cut-offs are judgment calls. Different reasonable cut-offs move customers between neighbouring segments.

## Cohort retention

- **Cohorts are weekly, by design.** With three months of data, monthly cohorts would give three or four groups and almost no follow-up time for the later ones. Weekly cohorts give 14 groups and up to 13 follow-up weeks.
- **The metric is repeat-purchase retention within the observed window.** A customer's "first purchase" is the first one this data can see.
- **The first cohort is left-censored and inflated.** The week of June 22 holds 61,829 customers, nearly double the next cohort (32,914). Everyone who was already shopping before the window and bought in week one gets counted as new. Its retention is higher too (about 13 to 20% in most weeks, versus about 6 to 15% for later cohorts). That reflects loyal regulars mixed in, not better acquisition. It stays in the table, flagged, and the headline figures exclude it.
- **The last week of every cohort is partial.** The data ends on Tuesday, Sep 22, so each cohort's final column covers two days. Those cells read low for that reason only.

## Product performance

- **"Unknown" is a real category value** in H&M's data (20,882 units), not a processing error. It stays in.
- **Category volume is extremely long-tailed.** Garment Upper body, Lower body and Full body account for 71.7% of units. Several categories have double-digit units or fewer (Fun 2, Furniture 7, Underwear/nightwear 11). Category comparisons use a 1,000-unit floor, which keeps 12 of 18 categories.
- **Units and revenue rank categories differently.** Accessories sold more than twice the units of Shoes (99,723 vs 44,458) but slightly less scaled revenue (1,456.9 vs 1,482.7), because its average price is less than half (0.0146 vs 0.0334). No single "top performers" list is honest without naming the measure.
- **Individual worst sellers can't be named.** With a 10-unit floor, every bottom-5 item sat at exactly 10 units, and 454 articles are tied there. Any named list would be an arbitrary pick. The real finding is the distribution: 13,389 of 26,894 articles in the top three categories (49.8%) sold fewer than 10 units in the window. Some will be late launches or size and colour variants rather than failures.

## Price versus volume

- **Observational, not elasticity.** No article was deliberately sold at different prices. These results compare different articles within a category, so they can reflect product mix, audience size or season as much as price. Nothing here is causal.
- **The relationship depends on the category.** Within categories (articles with 10+ units, categories with 25+ such articles):
  - Garment Upper body: mean units fall with price (130 → 126 → 101 → 94 → 76).
  - Garment Full body: an inverted U (94 → 109 → 116 → 93 → 59). The cheapest items are not the best sellers.
  - Swimwear: volume rises with price (median 26.5 → 45 → 151 → 160 → 164).
  - Accessories: flat.
- **Report medians with means.** A few very high-volume articles inflate some means. Socks & Tights looks erratic on means (72 → 51 → 97 → 152 → 55) and much flatter on medians (65 → 42 → 40.5 → 49 → 37). Where they disagree, the median decides.
- **Only Swimwear shows a meaningful correlation,** and it's positive (Spearman 0.406). Eight of ten categories have |Spearman r| below 0.15.
- **Significance is not strength.** Garment Upper body returns p < 0.0001 with Spearman r = -0.075. The tiny p-value comes from 6,820 articles, not from a strong relationship.
- **Where Pearson and Spearman disagree in sign** (Garment Lower body, Socks & Tights), there's no reliable monotonic relationship.
- **A near-zero correlation is not "no relationship".** Garment Full body has a clear inverted U and a Spearman r of -0.044. A curve that rises then falls cancels out in a correlation coefficient, which is why the quintile charts sit next to the correlation table.
- Bags, Items and Stationery have fewer than 25 eligible articles and are left out of the quintile analysis by design.
