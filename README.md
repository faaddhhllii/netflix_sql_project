# Netflix TV Show and Movies Data Analaysis Using SQL

![Netflix_logo](https://github.com/faaddhhllii/netflix_sql_project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
```
## Preprocessing Data 

### Checking and handling missing values country

```sql
SELECT
	country,
	COUNT(*) AS total_content
FROM netflix_titles
GROUP BY 1
ORDER BY 2 DESC;

SELECT * FROM netflix_titles WHERE country = '';

UPDATE 
	netflix_titles 
SET country = 'United States'
WHERE country = '';
```
### Change type data column date_added
```sql

SELECT 
	date_added, 
	STR_TO_DATE(date_added, '%M %d, %YYYY') AS converted_date
FROM netflix_titles;

ALTER TABLE netflix_titles ADD COLUMN date_added_new DATE;

UPDATE netflix_titles
SET date_added_new = STR_TO_DATE(date_added, '%M %d, %Y');
```
## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT 
    type,
    COUNT(*)
FROM netflix
GROUP BY 1;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
WITH common_rating AS 
(
SELECT
	DISTINCT `type`,
	rating,
	COUNT(*) AS total_rating,
	RANK() OVER(PARTITION BY `type` ORDER BY COUNT(*) DESC) ranking
FROM netflix_titles
GROUP BY 1, 2
)
SELECT 
	*
FROM common_rating
WHERE ranking = 1;
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT
	`type`, 
	title,
	release_year
FROM netflix_titles
WHERE release_year = 2020 AND `type` = 'Movie'; 
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
SELECT 
    new_country,
    COUNT(show_id) AS total_content
FROM (
    SELECT 
        show_id,
        TRIM(value) AS new_country
    FROM netflix_titles,
    JSON_TABLE(
        CONCAT('["', REPLACE(country, ',', '","'), '"]'),
        "$[*]" COLUMNS (value VARCHAR(255) PATH "$")
    ) AS country_list
) AS country_split
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
SELECT 
    new_country,
    COUNT(show_id) AS total_content
FROM (
    SELECT 
        show_id,
        TRIM(value) AS new_country
    FROM netflix_titles,
    JSON_TABLE(
        CONCAT('["', REPLACE(country, ',', '","'), '"]'),
        "$[*]" COLUMNS (value VARCHAR(255) PATH "$")
    ) AS country_list
) AS country_split
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
SELECT
	*
FROM netflix_titles
WHERE date_added_new >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR);
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT
	`type`,
	title,
	director 
FROM netflix_titles
WHERE director LIKE '%Rajiv Chilaka%';
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT
	*,
	CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS seasons
FROM netflix_titles
WHERE `type` = 'TV Show'
AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > '5'
ORDER BY seasons ASC;
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
WITH RECURSIVE genre_split AS (
    SELECT 
        show_id, 
        SUBSTRING_INDEX(listed_in, ',', 1) AS genre,
        SUBSTRING_INDEX(listed_in, ',', -1) AS remaining,
        listed_in
    FROM netflix_titles
    UNION ALL
    SELECT 
        show_id, 
        SUBSTRING_INDEX(remaining, ',', 1) AS genre,
        SUBSTRING_INDEX(remaining, ',', -1) AS remaining,
        listed_in
    FROM genre_split
    WHERE remaining LIKE '%,%'
)
SELECT genre, COUNT(*) AS total_content
FROM genre_split
WHERE genre IS NOT NULL AND genre <> ''
GROUP BY genre
ORDER BY total_content DESC;
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
SELECT 
    YEAR(date_added_new) AS years,
        COUNT(*) AS total_conten_per_year,
    COUNT(*)/ 12 AS avg_conten 
FROM netflix_titles
WHERE country = 'India'
GROUP BY  YEAR(date_added_new)
ORDER BY COUNT(*)
LIMIT 5;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
SELECT 
	`type`,
	title,
	listed_in 
FROM netflix_titles
WHERE `type` = 'Movie' AND listed_in LIKE '%Documentaries%'; 
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
SELECT 
	*
FROM netflix_titles
WHERE director IS NULL OR director = '';
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
SELECT 
	*
FROM netflix_titles 
WHERE `type` = 'Movie' 
AND `cast` LIKE '%Salman Khan%'
AND release_year  >= YEAR(DATE_SUB(CURDATE(), INTERVAL 10 YEAR));
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
SELECT 
    actor,
    COUNT(*) AS total_content
FROM (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', n.n), ',', -1)) AS actor
    FROM 
        netflix_titles
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
    ON CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) >= n.n - 1
    WHERE country LIKE '%India%' AND `type` = 'Movie'
) AS actors
GROUP BY actor
ORDER BY total_content DESC
LIMIT 10;
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
WITH new_table AS
(
SELECT
	description,
	CASE 
		WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad_Content'
		ELSE 'Good_Content'
	END AS category
FROM netflix_titles
)
SELECT
	category,
	COUNT(*) AS total_content
FROM new_table
GROUP BY 1;
```

