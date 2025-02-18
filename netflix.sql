SET SESSION sql_mode = '';

-- Netflix Project
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix 
(
	show_id VARCHAR(5),
	`type` VARCHAR(10),
	title VARCHAR(150),
	director VARCHAR(200),
	`cast` VARCHAR(1000),
	country VARCHAR(150),
	date_added VARCHAR(50),
	release_year INT,
	rating VARCHAR(10),
	duration VARCHAR(15),
	listed_in VARCHAR(100),
	description VARCHAR(250)
);

SELECT * FROM netflix_titles;

-- preprocessing data
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

SELECT 
	date_added, 
	STR_TO_DATE(date_added, '%M %d, %YYYY') AS converted_date
FROM netflix_titles;

ALTER TABLE netflix_titles ADD COLUMN date_added_new DATE;

UPDATE netflix_titles
SET date_added_new = STR_TO_DATE(date_added, '%M %d, %Y');

-- 15 Businerss Problem & Solutions

-- 1. Count the number of Movies and TV shows
SELECT 
	`type`,
	COUNT(*) AS total_content
FROM netflix_titles
GROUP BY 1;

-- 2 find the most common rating for movies and tv shows
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

-- 3. list all movies released in a spesific year (e.g.. 2020)
SELECT
	`type`, 
	title,
	release_year
FROM netflix_titles
WHERE release_year = 2020 AND `type` = 'Movie'; 

-- 4. Find the top 5 countries with the most content on netflix
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

-- 5. Identify the longest movie?
WITH type_movie AS
(
SELECT
	`type`,
	title,
	duration 
FROM netflix_titles
WHERE `type` = 'Movie'
AND duration LIKE '%min'
)
SELECT
	title,
	duration 
FROM type_movie
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;

-- 6. Find content added in the 5 years 
SELECT
	*
FROM netflix_titles
WHERE date_added_new >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR);

-- 7. find all movies/TV Show by director rajiv chilaka
SELECT
	`type`,
	title,
	director 
FROM netflix_titles
WHERE director LIKE '%Rajiv Chilaka%';

-- 8. list all tv shows with more than 5 season
SELECT
	*,
	CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS seasons
FROM netflix_titles
WHERE `type` = 'TV Show'
AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > '5'
ORDER BY seasons ASC;

-- 9. count the number of content items in each genre
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

-- 10. find each year and the average numbers of content release by india on netflix, return top 5 year with highest avg content release
SELECT 
    YEAR(date_added_new) AS years,
        COUNT(*) AS total_conten_per_year,
    COUNT(*)/ 12 AS avg_conten 
FROM netflix_titles
WHERE country = 'India'
GROUP BY  YEAR(date_added_new)
ORDER BY COUNT(*)
LIMIT 5;

-- 11. list all movies that are documentaries
SELECT 
	`type`,
	title,
	listed_in 
FROM netflix_titles
WHERE `type` = 'Movie' AND listed_in LIKE '%Documentaries%'; 

-- 12. find all content without a director
SELECT 
	*
FROM netflix_titles
WHERE director IS NULL OR director = '';

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years
SELECT 
	*
FROM netflix_titles 
WHERE `type` = 'Movie' 
AND `cast` LIKE '%Salman Khan%'
AND release_year  >= YEAR(DATE_SUB(CURDATE(), INTERVAL 10 YEAR));

-- 14. find the top 10 actors who have appeared in the highest number of movies produced in India

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

-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the 
-- description field , label content containing these keywords as 'Bad' and all other content as 'Good'
-- count how many items fail into each category

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
