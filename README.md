# Bharat Herald Business Analytics Project (RPC 17)

## 📖 Project Overview

This project provides comprehensive business analytics for **Bharat Herald**, a traditional print newspaper company exploring digital transformation opportunities. The analysis covers the period from 2019-2024 and examines print circulation trends, advertising revenue patterns, digital pilot performance, and city-wise market readiness.

## 🎯 Business Context

Bharat Herald is facing the challenges of declining print readership and the need to adapt to digital media consumption patterns. This analysis helps the organization understand:

- Print circulation performance across different cities
- Advertising revenue trends and category concentration
- Digital transformation readiness by market
- Performance of digital pilot initiatives
- Strategic recommendations for future growth

## 📊 Dataset Overview

### **Fact Tables**
- **`fact_print_sales`**: Monthly print performance metrics (copies printed, sold, circulated by city)
- **`fact_ad_revenue`**: Quarterly advertising revenue by city and category
- **`fact_digital_pilot`**: Digital transformation pilot program results (2021 initiative)
- **`fact_city_readiness`**: Digital readiness metrics (literacy, smartphone, internet penetration)

### **Dimension Tables**
- **`dim_city`**: City lookup with tier classification (Tier 1: Delhi, Mumbai, Ahmedabad; Tier 2: Lucknow, Bhopal, Patna, Jaipur, Kanpur, Varanasi; Tier 3: Ranchi)
- **`dim_ad_category`**: Standardized advertising category mapping

### **Data Coverage**
- **Geographic Scope**: 10 major Indian cities across multiple states
- **Time Period**: 2019-2024 (6 years of historical data)
- **Digital Pilot Period**: 2021 (limited digital transformation experiment)
- **Data Volume**: Multiple fact tables with thousands of monthly/quarterly records

## 🗂️ Project Structure

```
code_basics_rpc17/
├── 📁 Datasets/                          # Original raw data files
│   ├── fact_ad_revenue.csv
│   ├── fact_city_readiness.csv
│   ├── fact_digital_pilot.csv
│   └── metadata.txt
├── 📁 New Datasets/                      # Cleaned UTF-8 encoded datasets
│   ├── dim_ad_category_utf8.csv
│   ├── dim_city_utf8.csv
│   ├── fact_print_sales_utf8.csv
│   └── ... (other cleaned datasets)
├── 📁 primary_analysis_queries/          # Primary business analysis queries
│   ├── query1.html - query8.html
├── 📁 ad_hoc_query_results/             # Ad-hoc business request results
│   ├── q1.html - q6.html (Q1-Q6 results)
│   ├── q6_enhanced.html
│   └── q1.csv
├── 📁 primay_analysis_visualizations/    # Data visualizations (if any)
├── 🔧 data_cleaning.sql                 # Data cleaning and standardization scripts
├── 📋 query_validation.sql              # Data quality validation queries
├── 🎯 ad-hoc-query-results.sql         # Business request queries (Q1-Q6)
├── 📄 metadata.txt                      # Comprehensive data dictionary
└── 📚 Supporting Documents/
    ├── ad-hoc-requests.pdf
    ├── Media_Problem Statement.pdf
    ├── Primary_and_Secondary_Analysis.pdf
    └── rpc_17.pdf/pptx
```

## 🔍 Key Business Questions Analyzed

### **Primary Analysis (8 Queries)**
Based on the HTML results files, the primary analysis covers:
1. **Yearly Print Performance Trends** - Total printed, sold, and circulated copies (2019-2024)
2. **City-wise Performance Analysis** - Regional performance breakdown
3. **Seasonal Patterns in Print Sales** - Monthly/quarterly circulation patterns
4. **Advertising Category Performance** - Revenue by category and trends
5. **Digital Readiness Assessment** - City-wise digital adoption metrics
6. **Market Tier Analysis** - Performance by city tier (Tier 1, 2, 3)
7. **Efficiency Metrics** - Print efficiency ratios across markets
8. **Comparative Regional Performance** - Cross-city benchmarking

### **Ad-Hoc Business Requests (Q1-Q6)**

#### **Q1: Monthly Circulation Drop Analysis** 📉
- **Objective**: Identify months where any city recorded the sharpest month-over-month circulation drops
- **Key Findings**: 
  - Varanasi experienced the largest circulation drop in January 2021 (59,807 copies)
  - Varanasi also showed significant drops in November 2019 (55,649 copies) and October 2020 (49,252 copies)
  - Jaipur had a notable drop in January 2020 (51,858 copies)
- **Business Impact**: Identifies problematic periods requiring investigation

#### **Q2: Yearly Revenue Concentration** 💰
- **Objective**: Find advertising categories contributing >50% of yearly revenue
- **Business Impact**: Assess revenue concentration risk and identify diversification opportunities
- **Strategic Value**: Prevent over-dependency on single advertising categories

#### **Q3: 2024 Print Efficiency Leaderboard** 📊
- **Objective**: Rank top 5 cities by print efficiency ratio (net circulation/copies printed)
- **Business Impact**: Optimize printing operations, reduce waste, and improve profitability
- **Operational Value**: Guide resource allocation and operational improvements

#### **Q4: Internet Readiness Growth (2021)** 🌐
- **Objective**: Identify the city with highest internet penetration improvement from Q1→Q4 2021
- **Strategic Value**: Target cities with improving digital infrastructure for expansion
- **Investment Guide**: Prioritize markets showing digital growth potential

#### **Q5: Consistent Multi-Year Decline Analysis** ⚠️
- **Objective**: Identify cities experiencing simultaneous decline in both print circulation AND advertising revenue (2019-2024)
- **Critical Insight**: Markets requiring immediate strategic intervention or exit consideration
- **Risk Assessment**: Early warning system for market viability

#### **Q6: 2021 Readiness vs Pilot Engagement Outlier** 🎯
- **Objective**: Find cities with highest digital readiness but lowest digital pilot engagement
- **Strategic Value**: Understand barriers to digital adoption despite favorable market conditions
- **Product Development**: Identify gaps between market potential and actual product uptake

## 🛠️ Technical Implementation

### **Data Cleaning Process**
- **Currency Standardization**: Normalized "IN RUPEES", "RUPEES" → "INR"
- **Date Standardization**: Unified date formats across tables
  - `fact_ad_revenue.quarter`: Standardized to "Qn-YYYY" format
  - `fact_print_sales.month`: Standardized to "YYYY-MM" format
- **Revenue Data Type Conversion**: VARCHAR → DECIMAL(15,2) for numerical analysis
- **Added Date Indexing**: Performance optimization for time-range queries

### **Data Quality Validation**
- Foreign key consistency checks
- Revenue and metric sanity checks
- Row count and uniqueness validation
- Date range and format verification

## 📈 Key Insights & Findings

### **Print Performance Insights**
- **Significant Circulation Volatility**: Varanasi shows multiple periods of sharp circulation drops (2019-2024)
- **Yearly Performance Trends**: 2019-2024 data reveals varying performance across years
  - 2019: 39.4M printed, 37.1M sold, 39.6M circulated
  - 2020: 36.7M printed, 34.6M sold, 37.6M circulated (COVID impact visible)
  - Subsequent years show recovery and adjustment patterns
- **Efficiency Optimization Opportunities**: Significant variations in print efficiency ratios across cities

### **Market Segmentation Analysis**
- **Tier 1 Cities** (Delhi, Mumbai, Ahmedabad): Premium markets with higher digital readiness
- **Tier 2 Cities** (Lucknow, Bhopal, Patna, Jaipur, Kanpur, Varanasi): Core markets with mixed performance
- **Tier 3 Cities** (Ranchi): Emerging markets requiring different strategies

### **Digital Transformation Readiness**
- City-wise readiness scores enable targeted digital rollout strategy
- 2021 pilot program provides baseline for digital adoption patterns
- Infrastructure readiness vs. actual adoption gap analysis reveals implementation challenges

### **Advertising Revenue Analysis**
- Revenue concentration patterns reveal dependency risks
- Category-wise performance trends guide advertising strategy
- Quarterly patterns help with revenue forecasting and budget planning

### **Critical Business Alerts**
- Certain cities showing concurrent decline in both print circulation AND ad revenue
- Market-specific challenges requiring immediate strategic intervention
- Digital adoption barriers despite favorable market conditions

## 🚀 Getting Started

### **Prerequisites**
- MySQL/MariaDB database server
- SQL client (MySQL Workbench, phpMyAdmin, etc.)
- CSV import capabilities

### **Setup Instructions**

1. **Import Datasets**
   ```sql
   -- Import cleaned datasets from 'New Datasets/' folder
   -- Use UTF-8 encoding for proper character handling
   ```

2. **Run Data Cleaning**
   ```sql
   source data_cleaning.sql
   ```

3. **Validate Data Quality**
   ```sql
   source query_validation.sql
   ```

4. **Execute Analysis**
   ```sql
   -- Run primary analysis queries
   source ad-hoc-query-results.sql
   ```

### **Query Execution Order**
1. 📥 Import datasets
2. 🧹 Execute `data_cleaning.sql`
3. ✅ Run `query_validation.sql` 
4. 🔍 Execute business analysis queries
5. 📊 Generate reports and visualizations

## 💼 Business Value

### **Strategic Decision Support**
- **Market Prioritization**: Data-driven city ranking for resource allocation
  - Tier-based strategy development (Tier 1, 2, 3 markets)
  - ROI-focused investment decisions based on historical performance
- **Digital Strategy**: Readiness-based digital transformation roadmap
  - Phase digital rollout based on infrastructure readiness scores
  - Learn from 2021 pilot program successes and failures
- **Operational Efficiency**: Print optimization recommendations
  - Reduce waste through efficiency ratio improvements
  - Optimize circulation vs. printing ratios by market
- **Revenue Diversification**: Advertising category expansion insights
  - Reduce dependency on high-concentration revenue sources
  - Identify growth opportunities in underperforming categories

### **Performance Monitoring & KPIs**
- **Monthly Circulation Tracking**: Early warning system for market decline
- **Quarterly Revenue Analysis**: Advertising performance monitoring
- **Digital Adoption Metrics**: Progress tracking for digital initiatives
- **Cross-Market Benchmarking**: Identify best practices from top performers
- **Efficiency Dashboards**: Operational performance monitoring

### **Risk Management**
- **Revenue Concentration Risk**: Identify over-dependency on specific ad categories
- **Market Decline Detection**: Early identification of underperforming markets
- **Digital Transition Measurement**: Success metrics for transformation initiatives
- **Competitive Intelligence**: Market position analysis and strategic response

### **Investment & Resource Allocation**
- **Capital Allocation**: Data-driven budget distribution across markets
- **Technology Investment**: Priority markets for digital infrastructure
- **Human Resources**: Staffing optimization based on market potential
- **Marketing Spend**: ROI-optimized marketing budget allocation

## 📋 Data Dictionary

Detailed metadata for all tables and columns is available in:
- `metadata.txt` - Comprehensive data dictionary
- `Datasets/metadata.txt` - Original dataset documentation

## 📞 Project Context

**Project Code**: RPC 17  
**Period Analyzed**: 2019-2024  
**Industry**: Media & Publishing  
**Focus**: Digital Transformation Strategy  

## 🔗 Related Files

- **Problem Statement**: `Media_Problem Statement.pdf`
- **Analysis Guide**: `Primary_and_Secondary_Analysis.pdf`
- **Setup Instructions**: `How to Get Started (A Step-by-Step Guide).pdf`
- **Project Presentation**: `rpc_17.pptx`

---

*This project demonstrates comprehensive business analytics capabilities including data cleaning, validation, trend analysis, and strategic business intelligence for traditional media digital transformation.*