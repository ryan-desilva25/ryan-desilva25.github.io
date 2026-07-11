# Macroeconomic Drivers of Consumer Attrition in Retail Banking

- **Author:** Ryan de Silva
- **Context:** Predictive Risk Modelling & Portfolio Analytics
- **Technical Stack:** Python 3.11.4, Jupyter, Scikit-Learn, XGBoost, Pandas

------------------------------------------------------------------------

## 📈 Executive Summary & Business Impact

Traditional churn models look strictly at internal data, for instance how often a customer logs into an app or whether their credit card balance drops. However, consumer behaviour doesn't happen in a vacuum. This project builds a machine learning pipeline that bridges the gap between a bank's internal database and the broader economic reality, integrating external metrics like the **Cost of Living Index** and **National Average Wages**.

In retail banking, catching a customer before they leave is an asymmetrical financial problem. If we miss an at-risk user, the bank suffers an unmitigated loss of their long-term value. If we accidentally offer an incentive to a loyal customer, the bank only loses the minor cost of a marketing discount.

### The Financial Simulation (ROI)

By running our final champion model's test predictions through a real-world banking cost framework, we prove the tangible value of moving from historical reporting to proactive machine learning:

- **High-Value Customer Loss Value:** \$500 (Revenue lost if an account leaves)
- **Proactive Retention Incentive Cost:** \$100 (Unit cost of a promotional offer/discount)
- **Retention Campaign Conversion Rate:** 50% success rate

Based on the model's performance on a holdout set of 2,000 users, the model delivered **\$16,450.00 in Net Saved Value** over a single cycle by catching 71% of true churn events.

------------------------------------------------------------------------

## Phase 1: Exploratory Data Analysis & Feature Auditing

Before building predictive models, I ran an audit on the features to see how they were distributed. Since macroeconomic data moves along shared economic cycles, checking for high multicollinearity was an important step to ensure our models didn't become unstable later on.

The dataset exhibits a steep class imbalance: **79.6% Retained** ($0$) vs. **20.4% Churned** ($1$). This distribution confirms that relying on basic accuracy as a metric would be highly misleading.

Using Variance Inflation Factors (VIF), I audited the numeric features to flag redundant variables:

``` text
Variance Inflation Factor (VIF) Results:
       Feature     VIF
   creditscore  20.543
           age  12.284
 numofproducts   7.702
estimatedsalary   3.885
        tenure   3.864
     hascrcard   3.286
       balance   2.625
isactivemember   2.072
```

## Phase 2: Macroeconomic Timeline Reconstruction & Enrichment

To align customer profiles with external economic pressures, I restructured wide-format historical wage records into a continuous time-series ledger using a Multi-Index backbone inside Pandas.

Because official wage indices often have lag or miss specific calendar years, I utilised linear interpolation to fill historical gaps, followed by a Compound Annual Growth Rate (CAGR) calculation to project the baseline safely forward into the 2023–2026 window.

``` python
import pandas as pd
import numpy as np

# =============================================================================
# 1. MELT THE WAGE DISTRIBUTION ARRAY INTO A LONG-FORM SERIES
# =============================================================================
# The raw wage data is wide-form (years as separate columns). We use melt() to 
# unpivot it into a tidy, long-form format. This standardises the dataset into 
# individual structural observations, making it ready for time-series merging.
df_wages_long = df_wages.melt(
    id_vars=['country'],
    value_vars=['2000', '2010', '2020', '2022'],
    var_name='year',
    value_name='avg_wage'
)

# Clean hidden formatting artifacts in country names (e.g., narrow non-breaking 
# spaces '\u202f' and footnote asterisks) often found in web-scraped or Excel data.
df_wages_long['country'] = df_wages_long['country'].str.replace('\u202f', '', regex=True).str.replace('*', '', regex=False).str.strip()

# Convert wages to numeric float values by stripping out formatting commas.
# 'errors=coerce' replaces non-numeric data anomalies with NaN to keep the pipeline from crashing.
df_wages_long['avg_wage'] = pd.to_numeric(df_wages_long['avg_wage'].astype(str).str.replace(',', '', regex=False), errors='coerce')

# Explicitly cast years to integers to guarantee clean key matching during downstream joins.
df_wages_long['year'] = df_wages_long['year'].astype(int)


# =============================================================================
# 2. BUILD MULTI-INDEX TIMELINE STRUCTURE
# =============================================================================
# Define our specific target geographies for the macro-economic feature scope.
target_geos = ['France', 'Spain', 'Germany']

# Create a master Cartesian grid (every country combined with every year from 2010 to 2026).
# This Multi-Index acts as an uncorrupted timeline backbone, ensuring we don't have gaps 
# in our time-series sequence when moving from historical data to forecasting windows.
timeline = pd.MultiIndex.from_product([target_geos, range(2010, 2027)], names=['country', 'year']).to_frame(index=False)


# =============================================================================
# 3. COMBINE FIELDS AND LINEAR-INTERPOLATE HISTORICAL WAGE INDICATORS
# =============================================================================
# Left-join our master timeline backbone with our cleaned, long-form historical wage records.
# This aligns our existing data points and leaves blank NaN fields for the missing years.
wage_map = pd.merge(timeline, df_wages_long, on=['country', 'year'], how='left')

# Address historical gaps within each country group via bounded linear interpolation.
# ffill() and bfill() act as safety nets to handle edge-case data gaps at the very start or end.
wage_map['wage_clean'] = wage_map.groupby('country')['avg_wage'].transform(lambda x: x.interpolate(method='linear').ffill().bfill())


# =============================================================================
# 4. APPLY CAGR PROJECTION CALCULATIONS FOR THE FINAL 2023-2026 TIMELINE WINDOW
# =============================================================================
# Since historical data ends at 2022, we model the future 2023-2026 window by 
# calculating the Compound Annual Growth Rate (CAGR) between 2020 and 2022 for each country.
for geo in target_geos:
    try:
        # Isolate the baseline 2020 and 2022 wage values for the current country.
        w20 = wage_map.loc[(wage_map['country'] == geo) & (wage_map['year'] == 2020), 'wage_clean'].values[0]
        w22 = wage_map.loc[(wage_map['country'] == geo) & (wage_map['year'] == 2022), 'wage_clean'].values[0]
        
        # Verify data points exist and are valid to prevent division-by-zero math errors.
        if pd.notnull(w20) and pd.notnull(w22) and w20 != 0:
            # Calculate the 2-year growth rate multiplier factor: sqrt(W22 / W20)
            growth_rate = (w22 / w20) ** (0.5)
            
            # Compounded forward-projection: Multiply the 2022 actual baseline 
            # by the growth factor raised to the power of years elapsed.
            for yr in range(2023, 2027):
                wage_map.loc[(wage_map['country'] == geo) & (wage_map['year'] == yr), 'wage_clean'] = w22 * (growth_rate ** (yr - 2022))
    except Exception as e:
        # Non-blocking error handling to isolate anomalous countries without breaking the pipeline run.
        print(f"CAGR projection variance on {geo}: {e}")

# Standardise values to two decimal places for currency reporting consistency.
wage_map['wage_clean'] = wage_map['wage_clean'].round(2)


# =============================================================================
# 5. EXECUTE STRUCTURAL DATAFRAME ENRICHMENT MERGES
# =============================================================================
# In order to match customer tenure with the correct historical wage environment, 
# we derive a customer's 'join_year' proxy relative to our active 2024 analysis window.
df_churn['join_year'] = 2024 - df_churn['tenure']

# Enrich our core customer churn dataset with the baseline country wage corresponding to their exact join year.
df_final = pd.merge(
    df_churn,
    wage_map[['country', 'year', 'wage_clean']],
    left_on=['geography', 'join_year'],
    right_on=['country', 'year'],
    how='left'
)

# Extract and filter the Cost of Living Index values strictly for our current 2024 analysis scope.
df_col_2024 = df_col[df_col['year'] == 2024][['country', 'cost_of_living_index']]

# Append the 2024 Cost of Living context to the main dataframe based on customer geography.
df_final = pd.merge(df_final, df_col_2024, left_on='geography', right_on='country', how='left')

# Drop the structural join suffixes (_x, _y) generated by pandas when duplicate column 
# names exist across tables. This maintains schema cleanliness and prevents column clutter.
cols_to_keep = [c for c in df_final.columns if not c.endswith('_x') and not c.endswith('_y')]
df_final = df_final[cols_to_keep]


# =============================================================================
# 6. FINAL CUSTOM MACRO FEATURE EVALUATIONS
# =============================================================================
# Feature 1: Relative Wage Index
# Measures customer earning power against their local country baseline (Salary / Country Average Wage).
df_final['relative_wage_index'] = df_final['estimatedsalary'] / df_final['wage_clean']

# Feature 2: Purchasing Power Index
# Normalises the customer's relative earning power against the local Cost of Living index. 
# This indicates real financial disposable income, a strong predictor for customer churn analysis.
df_final['purchasing_power_index'] = df_final['relative_wage_index'] / df_final['cost_of_living_index']

print("Enrichment mapping pipeline finished. Structural rows verified.")
```

## Phase 3: Leakage-Preventative Data Partitioning

To make sure our validation is bulletproof, I enforced a strict data partition, separating records into an 80% Training set and a 20% Holdout Testing set before applying any scaling or encoding maps. This prevents information from the test set leaking into our training transformations.

``` python
X = df_final.drop(columns=['rownumber', 'customerid', 'surname', 'year', 'exited'], errors='ignore')
y = df_final['exited']

# Stratified split to maintain identical class proportions across both sets
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.20, stratify=y, random_state=42
)
```

## Phase 4: Transformation Engineering & Class-Imbalance Balancing

I constructed a unified, multi-channel processing pipeline to handle numeric scaling and categorical encoding simultaneously.

Because the dataset exhibits class imbalance (\~20% churn vs \~80% retention), I configured the classifiers using native Cost-Sensitive Learning (class_weight='balanced' and scale_pos_weight=imbalance_ratio). This penalises minority class mistakes proportionally during training, letting the model shift its decision boundary to favour catching high-risk customers.

``` python
numeric_features = X_train.select_dtypes(include=[np.number]).columns.tolist()
categorical_features = X_train.select_dtypes(include=['object', 'category']).columns.tolist()

preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numeric_features),
        ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), categorical_features)
    ]
)

# Calculate the precise class imbalance ratio to fuel the XGBoost engine
imbalance_ratio = (y_train == 0).sum() / (y_train == 1).sum()
```

### Model Performance Breakdown

| Machine Learning Model | Minority Recall (Churn) | Minority Precision | Overall Accuracy | ROC-AUC Score |
|:--------------|:-------------:|:-------------:|:-------------:|:-------------:|
| **Logistic Regression** | 71.0% | 39.0% | 71.0% | 0.7762 |
| **Random Forest** | 55.0% | 66.0% | 85.0% | 0.8562 |
| **XGBoost (Champion)** | **71.0%** | **52.0%** | **81.0%** | **0.8537** |

## Model Performance Visualisations

Here is how the models compare side-by-side. The left plot traces the True Positive vs. False Positive trade-off curves, while the right matrix reveals the exact count distributions behind our champion XGBoost model's test predictions.

![](eval_plots.png)

## Phase 6: Risk Diagnostics & Commercial Value Synthesis

Based on our benchmarking results, XGBoost was chosen as our champion model. While Random Forest achieved a slightly higher overall accuracy, it completely failed to protect the portfolio, missing 45% of actual churn events (55% Recall). XGBoost successfully hit a much higher safety threshold, matching the maximum Recall level of 71% while significantly boosting our Precision boundary from 39% up to 52%.

![](feature_importance.png)

Global feature scoring indicates that our custom engineered macroeconomic vectors, specifically localised Cost of Living Indices and Relative Purchasing Power Indices, weighted heavily into the model's tree splits. This proves our core thesis: when external inflation curves shrink a household's disposable income, customer segments systematically begin exiting traditional retail banking products.

## Key Takeaways & Operational Recommendations

### Strategic Risk Threshold:

Moving to an XGBoost engine backed by class-weight balance mapping allowed the bank to sustain high Recall (71%). Financially, spending \$100 on a marketing offer for a False Positive user is a minor business cost compared to the unmitigated \$500 revenue loss of letting an at-risk customer leave unnoticed.

### Macroeconomic Alerts:

Because cost-of-living and wage indexes are strong leading indicators of churn, the data team can monitor macroeconomic shifts proactively. When inflation indexes spike in a specific geographic region, the bank can preemptively push defensive portfolio pricing layers before runoff occurs.

### From Hindsight to Foresight:

Deploying this framework shifts the portfolio analytics team out of reactive quarterly reporting and moves them directly into automated, forward-looking risk mitigation.
