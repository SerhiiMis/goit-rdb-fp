-- 1.1 Database creation
CREATE DATABASE pandemic;

-- 1.2 Database usage
USE pandemic;

-- 2.1 Creating tables
CREATE TABLE Country (
    Id INT PRIMARY KEY AUTO_INCREMENT,
    Entity VARCHAR(255) NOT NULL,
    Code VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE Disease_Statistics (
    Country_id INT,
    Year INT NOT NULL,
    Number_yaws DECIMAL(20,10) DEFAULT NULL,
    polio_cases INT DEFAULT NULL,
    cases_guinea_worm INT DEFAULT NULL,
    Number_rabies DECIMAL(20,10) DEFAULT NULL,
    Number_malaria DECIMAL(20,10) DEFAULT NULL,
    Number_hiv DECIMAL(20,10) DEFAULT NULL,
    Number_tuberculosis DECIMAL(20,10) DEFAULT NULL,
    Number_smallpox INT DEFAULT NULL,
    Number_cholera_cases INT DEFAULT NULL,
    PRIMARY KEY (Country_id , Year),
    FOREIGN KEY (Country_id)
        REFERENCES Country (Id) ON DELETE CASCADE
);

-- 2.2 Creating a function to convert text type to decimal
DELIMITER //
CREATE FUNCTION to_decimal(input TEXT) RETURNS DECIMAL(20,10) DETERMINISTIC NO SQL
BEGIN
    DECLARE result DECIMAL(20,10);
    IF input IS NULL OR input = '' THEN
        RETURN NULL;
    END IF;
    
    SET result = CAST(input AS DECIMAL(20,10));
    RETURN result;
END //
DELIMITER ;
    

-- 2.3 Fill in the data
INSERT INTO Country (Entity, Code)
SELECT DISTINCT Entity, Code FROM infectious_cases;

INSERT INTO Disease_Statistics (
    Country_id, Year, Number_yaws, polio_cases, cases_guinea_worm, 
    Number_rabies, Number_malaria, Number_hiv, 
    Number_tuberculosis, Number_smallpox, Number_cholera_cases
)
SELECT 
    c.Id, 
    ic.Year, 
    to_decimal(ic.Number_yaws), 
    NULLIF(ic.polio_cases, ''), 
    NULLIF(ic.cases_guinea_worm, ''), 
    to_decimal(ic.Number_rabies), 
    to_decimal(ic.Number_malaria), 
    to_decimal(ic.Number_hiv), 
    to_decimal(ic.Number_tuberculosis), 
    NULLIF(ic.Number_smallpox, ''), 
    NULLIF(ic.Number_cholera_cases, '')
FROM infectious_cases ic
JOIN Country c ON ic.Code = c.Code;

-- 2.4 The comnmand
SELECT COUNT(*) FROM infectious_cases;

-- 3.1 Calculatnig the average, min, max, and sum for the each unique combination of Entity, Code or Id
SELECT 
    Country_id, 
    AVG(Number_rabies) AS avg_rabies,
    MIN(Number_rabies) AS min_rabies,
    MAX(Number_rabies) AS max_rabies,
    SUM(Number_rabies) AS sum_rabies
FROM Disease_Statistics
WHERE Number_rabies IS NOT NULL  
GROUP BY Country_id;

-- 3.2 Sorting the result by average
SELECT 
    Country_id, 
    AVG(Number_rabies) AS avg_rabies,
    MIN(Number_rabies) AS min_rabies,
    MAX(Number_rabies) AS max_rabies,
    SUM(Number_rabies) AS sum_rabies
FROM Disease_Statistics
WHERE Number_rabies IS NOT NULL  
GROUP BY Country_id
ORDER BY avg_rabies DESC;

-- 3.3 10 lines to display
SELECT ic.country_id, c.entity, c.code, MAX(ic.number_rabies) AS max_number_rabies, SUM(ic.number_rabies) AS sum_number_rabies
FROM infectious_cases ic
JOIN countries c ON ic.country_id = c.country_id
WHERE ic.number_rabies != ''
GROUP BY ic.country_id
ORDER BY max_number_rabies DESC
LIMIT 10;

-- 4 Year difference using Select
SET @current_date = CURDATE();

SELECT
    Year,
    makedate(year, 1) AS Year_start_sate,
    @current_date as 'Current_date',
    FLOOR(DATEDIFF(@current_date, makedate(year, 1)) / 365) AS Year_difference
FROM Disease_Statistics;

-- 5.1 Creating a function
DROP FUNCTION IF EXISTS YearDifference;

DELIMITER //

CREATE FUNCTION YearDifference(input_year INT)
RETURNS INT DETERMINISTIC NO SQL
BEGIN
  DECLARE year_start_date DATE;
  DECLARE year_difference INT;

  SET year_start_date = MAKEDATE(input_year, 1);
  SET year_difference = FLOOR(DATEDIFF(CURDATE(), year_start_date) / 365);

  RETURN year_difference;
END //

DELIMITER ;

-- 5.2 Using the function
ALTER TABLE disease_statistics
ADD COLUMN Year_difference INT AFTER Year;

SET SQL_SAFE_UPDATES = 0;
UPDATE disease_statistics AS ds
SET Year_difference = YearDifference(ds.Year);
SET SQL_SAFE_UPDATES = 1;

SELECT Year, Year_difference FROM disease_statistics;
