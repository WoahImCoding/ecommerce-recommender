# A/B test design: personalised vs popularity recommendations

_Every number below is computed from the H&M data in `notebooks/06_ab_test.ipynb`._

| Item | Design |
|---|---|
| **Hypothesis** | Personalised post-purchase recommendations (LightGBM ranker) increase the 30-day repeat-purchase rate compared with popularity-based recommendations |
| **Unit and randomisation** | Customer; 50/50 split on a hash of `customer_id`, so each customer always sees the same arm |
| **Enrolment trigger** | A customer's first purchase during the enrolment period |
| **Primary metric** | Repeat purchase within 30 days of enrolment |
| **Secondary metrics** | Recommendation click-through rate, revenue per customer, items per basket |
| **Guardrails** | Return rate, API response time, catalogue coverage |
| **Baseline** | **48.88%** (enrolment weeks 5-12; weekly range 48.06% to 49.58%) |
| **Minimum detectable effect** | **2% relative** (+0.98 points) |
| **Significance / power** | alpha = 0.05 (two-sided) / 80% |
| **Sample size** | **36,793 customers per arm with CUPED** (41,062 without) |
| **Duration** | **2 weeks of enrolment + 30 days of follow-up**, in whole weeks to cover every weekday |
| **Analysis** | Two-proportion z-test on the CUPED-adjusted metric |

## Baseline by week

| Weeks ago | Customers | 30-day repeat rate |
|---|---|---|
| 5 | 71,094 | 48.06% |
| 6 | 74,833 | 48.38% |
| 7 | 82,802 | 49.01% |
| 8 | 80,591 | 48.80% |
| 9 | 77,277 | 49.14% |
| 10 | 75,996 | 49.58% |
| 11 | 85,648 | 49.09% |
| 12 | 115,992 | 48.86% |

## Sample size by minimum detectable effect

| Relative MDE | Absolute change (points) | Customers per arm | Total | Enrolment weeks |
|---|---|---|---|---|
| 2% | +0.98 | 41,062 | 82,124 | 2 |
| 5% | +2.44 | 6,570 | 13,140 | 1 |
| 10% | +4.89 | 1,641 | 3,282 | 1 |
| 15% | +7.33 | 727 | 1,454 | 1 |

Sample size grows with 1 / MDE squared. With about 80,000 buyers a week, traffic is not the constraint;
the 30-day follow-up sets the duration. The MDE is fixed before the test so it cannot be run "until significant".

## Variance reduction (CUPED)

Shopping days in the 90 days before enrolment correlate with the outcome at rho = 0.322.
CUPED removes rho squared = 10.4% of the variance, cutting the sample from 41,062 to 36,793 per arm.

## A/A check

1,000 random 50/50 splits of one real week (identical treatment in both halves) gave a false-positive rate of
**5.5%** against the expected 5%, so the test is well calibrated on this metric.

## Design decisions and risks

- **Population:** all weekly buyers (48.9% baseline) fill the test quickly. New customers only (14.8% month-1 retention)
  would target the biggest problem, since 27.8% never return, but would enrol far fewer people per week.
- **Novelty effect:** check the lift by week since enrolment before calling a winner.
- **Peeking:** analyse only at the planned end date.
- **Decision rule:** ship if the primary metric improves significantly and no guardrail gets worse beyond its threshold.

> This is an experiment **design**. A public dataset has no live traffic, so the test itself is not run.
