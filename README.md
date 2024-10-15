# SQL Project - Data Cleaning

## Overview
This project focuses on data cleaning using the [Layoffs 2022 dataset](https://www.kaggle.com/datasets/swaptr/layoffs-2022) sourced from Kaggle. The goal is to clean and prepare the data for further analysis by addressing issues such as duplicates, standardization of data, handling null values, and removing unnecessary rows and columns.

## Project Steps

1. **Create a Staging Table**: A staging table is created to hold the raw data, allowing for safe cleaning without affecting the original dataset.

2. **Check for Duplicates**: Identified and handled duplicate records to ensure data integrity.

3. **Standardize Data**: Cleaned up inconsistencies in the data such as leading/trailing spaces, variations in industry names, and erroneous country names.

4. **Handle Null Values**: Analyzed and managed null values in critical columns while retaining necessary information for further analysis.

5. **Remove Unnecessary Rows and Columns**: Deleted entries that did not contribute useful information and removed temporary columns used during the cleaning process.

## Final Output
After the data cleaning process, the final cleaned dataset is available in the `layoffs_staging2` table, ready for [exploratory data analysis(EDA)](https://github.com/khadeejach20/EDA-on-Layoffs-Dataset) or further processing.

## How to Run
To execute the SQL queries, you can use any MySQL-compatible database management tool. Load the original dataset into a MySQL database and run the provided SQL scripts sequentially.

## Acknowledgments
- Dataset source: [Kaggle - Layoffs 2022](https://www.kaggle.com/datasets/swaptr/layoffs-2022)
