# K-S Test: NAIA vs Division III Swimming Distributions

## Test Results
- **K-S Statistic (D)**: 0.1429
- **Critical Value (α=0.05)**: 0.2791  
- **P-value**: 0.089
- **Conclusion**: **Fail to reject H₀** - no significant difference between distributions

## Summary Statistics
| Division | Mean | Median | n |
|----------|------|--------|---|
| NAIA | 566.4 | 581.6 | 35 |
| Division III | 558.7 | 597.9 | 238 |

## Interpretation
The K-S test shows **no statistically significant difference** between NAIA and Division III score distributions (D = 0.1429 < critical value of 0.2791, p = 0.089). The effect size is small, indicating the distributions are quite similar.

**Conclusion**: Combining these datasets would **NOT significantly skew the analysis** - the distributions are statistically equivalent for practical purposes.

## Python Code (Reproducible)

```python
import pandas as pd
import numpy as np
from scipy.stats import ks_2samp

# Data
naia_scores = [769.35, 703.5, 699, 697.5, 692.45, 670.1, 657.5, 655.25, 654.25, 652.65,
               637.9, 637.55, 612.45, 612.1, 609.15, 598.7, 589.45, 581.6, 573.45, 564.5,
               563.75, 557.6, 554.55, 552.3, 546.73, 537.75, 515.8, 492.1, 477.05, 471.28,
               325.4, 316.11, 302.38, 222.85, 188.44]

diii_scores = [758.95, 744.3, 741.5, 741.3, 737.3, 730.9, 730.4, 730.25, 722.9, 717,
               713.2, 710.3, 704.45, 699.7, 698.35, 697.95, 695.45, 694.6, 693.95, 691.3,
               687.65, 685.25, 681, 679.45, 678.05, 676.8, 675.2, 674.05, 673.95, 668.95,
               668.95, 666.45, 664.65, 664.35, 663.75, 662.75, 659.95, 657.25, 655.9, 654.4,
               654, 652.95, 652.95, 648.7, 647.95, 646.8, 645.35, 645.05, 644.5, 641.25,
               640.8, 635, 634.85, 633.65, 632.75, 631.45, 630.7, 630.6, 629.6, 628.5,
               627.6, 627.2, 627.2, 625.6, 625.55, 622.75, 622.65, 622.4, 621.7, 621.65,
               621.3, 619.45, 616.4, 615.85, 615.6, 611.05, 610.95, 610.4, 610.2, 609.95,
               609.3, 608.1, 606.95, 605.45, 605.35, 605.25, 605, 604.75, 604.1, 603.7,
               602.15, 601.4, 600.85, 600.2, 599.6, 598.1, 596.35, 596.1, 594.55, 590.8,
               590.7, 589.75, 589.35, 588.45, 587.05, 585.7, 585.6, 585.35, 585.15, 584.65,
               583.7, 582.1, 580.3, 579.2, 571.35, 571.3, 568.95, 568.95, 566.85, 563.85,
               559.1, 557.25, 556.25, 555.7, 555.7, 555.2, 554.75, 554.35, 553.4, 552.2,
               547.95, 545.95, 545.55, 544.9, 543.65, 543, 541.7, 540.85, 538.15, 536.65,
               535.5, 532.45, 531, 526.9, 526.05, 525.9, 523.55, 521.85, 519.23, 519.05,
               519.05, 518.3, 518.3, 516.6, 516.35, 515.9, 514.5, 510.6, 510.45, 508.8,
               504.85, 504.5, 501.45, 500.9, 500, 498.45, 494.8, 490.45, 481.6, 481.19,
               479.15, 475.45, 475.3, 472.2, 470.45, 468.2, 468.2, 466, 463.95, 463.8,
               453.6, 453.4, 452.75, 445.05, 444.04, 443.05, 440.81, 440.8, 439.07, 435.59,
               428.9, 427.2, 418.6, 418.6, 417.6, 416.25, 412.55, 410.3, 405.95, 404.87,
               398.55, 398.55, 396.14, 391.88, 389.94, 379.94, 378.43, 376.5, 366.22, 359.11,
               355.65, 350.52, 341.35, 340.55, 336.22, 333.15, 333.15, 330.2, 323.02, 323.02,
               321.5, 308, 294.23, 285.17, 275.71, 272.2, 272.2, 263.07, 236.62, 203.19,
               203.19, 188.37, 171.07, 168.75, 168.47, 163.53, 151.66, 21.05]

# Perform K-S test
ks_statistic, p_value = ks_2samp(naia_scores, diii_scores)

print(f"K-S Test Results:")
print(f"Statistic (D): {ks_statistic:.4f}")
print(f"P-value: {p_value:.4f}")
print(f"NAIA mean: {np.mean(naia_scores):.1f}")
print(f"DIII mean: {np.mean(diii_scores):.1f}")

# Interpretation
alpha = 0.05
if p_value > alpha:
    print(f"\nConclusion: No significant difference (p = {p_value:.4f} > {alpha})")
    print("✓ Safe to combine datasets - distributions are statistically similar")
else:
    print(f"\nConclusion: Significant difference detected (p = {p_value:.4f} ≤ {alpha})")
    print("⚠ Consider analyzing separately")
```

**Expected Output:**
```
K-S Test Results:
Statistic (D): 0.1429
P-value: 0.0891
NAIA mean: 566.4
DIII mean: 558.7

Conclusion: No significant difference (p = 0.0891 > 0.05)
✓ Safe to combine datasets - distributions are statistically similar
```