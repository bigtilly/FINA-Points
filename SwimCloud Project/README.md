# Swim Score Analysis: Developing a Comprehensive Scoring System

## I. Introduction

This report details the development of a novel scoring system for competitive swimming. The primary goal was to create a system that accurately reflects a swimmer's performance by considering their percentile rank within an event, while also providing a fair bonus for participation in less-contested events and acknowledging record-breaking achievements.

## II. Problem Statement

Traditional scoring methods often fail to capture the nuanced value of a swim. A key challenge was to design a system that:
1.  Rewards high-percentile performances.
2.  Incentivizes participation in events with fewer competitors.
3.  Provides a clear and consistent bonus for breaking existing records.
4.  Remains simple enough for intuitive understanding and, ideally, manual calculation.

## III. Methodology

The development process was iterative and data-driven, involving continuous refinement based on insights gained from data analysis and user feedback. We explored various mathematical models to represent the relationship between swim times and percentiles, moving from initial logistic and rank-based approaches to a final cubic regression model. Emphasis was placed on balancing statistical accuracy with practical interpretability.

## IV. Data

The analysis utilized data from `All Valuable Data - test.csv.csv`. Key variables included:
*   `Time`: The swim time for a given event.
*   `Percentile`: The pre-calculated percentile rank of a swim within its event.
*   `Event`: The specific swimming event (e.g., "X50.Free.Time", "X100.Br.Time", "X100.Back.Time").

Participation counts were also used:
*   `N_counts`: Number of participants per event (`X50.Free.Time` = 979, `X100.Br.Time` = 496, `X100.Back.Time` = 572).
*   `N_ref`: Reference participant count, set to `N_counts["X50.Free.Time"]` (979).

## V. Model Development: The Cubic Scoring System

The final scoring system is built upon a cubic regression model, offering a balance of fit and interpretability. The score for any given swim is calculated through a series of steps:

### Core Idea
The final score is a combination of a `Base Score` (derived from the swim's percentile) and a `Participation Bonus`, with a special `Record Bonus` applied for new records.

### 1. Percentile Calculation (Cubic Regression)
For each event, a cubic regression model is used to predict the `Percentile` from the `Time`. This model captures the non-linear relationship between time and percentile rank.

The general form of the equation is:
`Percentile = (c3 * Time³) + (c2 * Time²) + (c1 * Time) + c0`

The specific coefficients for each event are:

*   **50 Yard Freestyle**
    `Percentile = (0.1521 * Time³) + (-10.0126 * Time²) + (202.1246 * Time) + -1160.6027`

*   **100 Yard Breaststroke**
    `Percentile = (0.0027 * Time³) + (-0.3962 * Time²) + (12.6291 * Time) + 133.9928`

*   **100 Yard Backstroke**
    `Percentile = (0.0038 * Time³) + (-0.5337 * Time²) + (18.9132 * Time) + 1.1849`

*(Note: Percentiles are clipped to a range of 0 to 100 to ensure valid values for subsequent calculations.)*

### 2. Base Score
The `Base Score` is a direct scaling of the calculated `Percentile`:
`Base Score = Percentile * 10`

### 3. Dynamic `k` Value (for Participation Bonus)
The `k` value scales the `Participation Bonus` and dynamically changes based on the `Percentile`. This ensures the bonus diminishes as a swimmer approaches the highest percentiles.

`k = -2 * Percentile + 200`

*   At 0th Percentile: `k = 200`
*   At 50th Percentile: `k = 100`
*   At 100th Percentile: `k = 0`

### 4. Participation Bonus
The `Participation Bonus` rewards swimmers in events with fewer participants, reflecting the idea that placing high in a less-contested event can be more valuable.

`Participation Bonus = k * log(Participation Ratio)`

Where:
*   `Participation Ratio = N_ref / N_event`
*   `N_ref` (Reference Event Count, 50 Free): 979
*   `N_event` (Current Event Count):
    *   50 Free: 979
    *   100 Breast: 496
    *   100 Back: 572

### 5. Record-Breaking Bonus

A special bonus is applied for swims that are faster than the current fastest time in the database for that event.

`Record Bonus = ((Time / Fastest Time in Database) - 1) * 100`

This `Record Bonus` is added to the score that the `Fastest Time in Database` would have received.

### 6. Final Score

The `Final Score` is determined based on whether the swim is a new record:

*   **If `Time < Fastest Time in Database` (New Record):**
    `Final Score = (Score of Fastest Time in Database) + Record Bonus`
    *(The "Score of Fastest Time in Database" is calculated using steps 1-4 for that specific fastest time.)*

*   **Otherwise (Standard Swim):**
    `Final Score = Base Score + Participation Bonus`

## VI. Results and Discussion

The cubic model, combined with the dynamic `k` value and the record-breaking bonus, has proven to be a robust and insightful scoring system.

(Cubic Regression Model Plot Here)

A key finding from this development is that the cubic model drastically improves the mean difference between events, particularly at higher percentiles. This means that the system effectively rewards swimmers for achieving high percentile ranks, while simultaneously acknowledging that a lower-percentile breaststroker (due to the participation bonus) may indeed be a more valuable swimmer in terms of their potential to place higher in meets.

(50 Free Score Histogram Here)
(100 Breast Score Histogram Here)
(100 Back Score Histogram Here)

## VII. Conclusion

The developed scoring system successfully balances performance metrics with strategic considerations like event participation and record-breaking. The cubic regression model provides a mathematically sound yet interpretable framework for evaluating swimmer performance, offering a nuanced and fair assessment that aligns with the stated goals of the project.
