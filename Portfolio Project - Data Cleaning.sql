-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022

SELECT *
FROM layoffs;

-- first thing we want to do is create a staging table. 
-- This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values or blank values
-- 4. remove any columns and rows that are not necessary

-- 1. Remove Duplicates

# First let's check for duplicates
        
SELECT * ,
	ROW_NUMBER() OVER(
		PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
	FROM 
		layoffs_staging
	ORDER BY row_num DESC;

WITH duplicate_cte AS
(
	SELECT * ,
		ROW_NUMBER() OVER(
			PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
		FROM 
			layoffs_staging
)
SELECT * -- DELETE STATEMENT is not available so we have to workaround
	FROM 
		duplicate_cte
	WHERE 
		row_num > 1;

-- let's just look at oda to confirm
SELECT *
FROM layoffs_staging
WHERE company = 'Oda';

-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate

-- these are our real duplicates
WITH duplicate_cte AS
(
	SELECT * ,
		ROW_NUMBER() OVER(
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
		FROM 
			layoffs_staging
)
SELECT * -- DELETE STATEMENT is not available so we have to workaround
	FROM 
		duplicate_cte
	WHERE 
		row_num > 1;

-- one solution, which I think is a good one. Is to create a new table and the result in it with the new column row_num. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

SELECT * 
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- now that we have this we can delete rows were row_num is greater than 2 
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT * 
FROM layoffs_staging2
ORDER BY row_num DESC;

-- 2. Standardizing data

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- there appear to be leading and trailing spaces in the 'company' field, 
-- let's take a look at these
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- let's update the table to remove any leading or trailing spaces from the 'company' field
UPDATE layoffs_staging2
SET company = TRIM(company);

-- ---------------------------------

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- it seems there are three variations for the 'Crypto' industry: 'Crypto', 'CryptoCurrency', and 'Cryto Currency'
-- let's retrieve all rows with 'Crypto' variations to confirm.
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- now let's standardize the 'industry' column by updating all 'Crypto' variations to simply 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- ---------------------------------

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- It seems someone mistakenly added a dot after 'United States'.
-- let's retrieve all rows where the country starts with 'United States'
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- let's check what the country values would look like if we removed the trailing dot
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- now let's update the 'country' column to remove the trailing dot from any occurrence of 'United States.'
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- ---------------------------------

SELECT `date`
FROM layoffs_staging2;

-- now let's convert the 'date' from its current string format (MM/DD/YYYY) into a proper date format using STR_TO_DATE
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- finally let's update the 'date' column to store the values in mysql standard date format
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- let's review the updated table after all the changes
SELECT * 
FROM layoffs_staging2;

-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- keeping having them null because it makes it easier for calculations during the EDA phase
-- no changes needed for these fields

-- -------------------------------------

SELECT DISTINCT industry
FROM layoffs_staging2;

-- let's retrieve rows where the 'industry' field is either NULL or an empty string.
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Let's check details for the company 'Airbnb' to understand its data.
-- there are two entries: one with an empty 'industry' field and the other identifying 'Travel' as the industry
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- let's update the 'industry' field to NULL where it contains an empty string in preparation for filling missing values
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- using the information we just found from airbnb we can fill the missing industry values by identifying
-- rows where 'industry' is NULL and where it is not NULL
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- now lets update the 'industry' field for rows where it is null
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- after the updates let's verify if there are any remaining rows where 'industry' is still NULL
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- it seems 'Bally's Interactive' has only one row and its 'industry' field is empty
-- there is no available information to populate this cell
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- finally let's review the entire table after all the changes
SELECT * 
FROM layoffs_staging2;

-- 4. remove any columns and rows we need to

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- these rows seem to contain data we can't use, so let's delete the entries where both 'total_laid_off' 
-- and 'percentage_laid_off' are NULL as they don't provide useful information
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2;

-- now let's remove the 'row_num' column as it's not needed anymore
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Finally we are done with the data cleaning process
SELECT * 
FROM layoffs_staging2;