-- 1.1
CREATE DATABASE pandemic;

-- 1.2 
USE pandemic;

-- 2.1 
CREATE TABLE countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE
);

-- 2.2 
INSERT INTO countries (entity, code)
SELECT DISTINCT Entity, Code
FROM infectious_cases;

-- 2.3 
ALTER TABLE infectious_cases
ADD COLUMN country_id INT,
ADD FOREIGN KEY (country_id) REFERENCES countries(country_id) ON DELETE CASCADE;

-- 2.4 
UPDATE infectious_cases ic
JOIN countries c ON ic.Entity = c.entity AND ic.Code = c.code
SET ic.country_id = c.country_id;

-- 2.5 
ALTER TABLE infectious_cases
DROP COLUMN Entity,
DROP COLUMN Code;

-- 3.1 
SELECT ic.country_id, c.entity, c.code, AVG(ic.number_rabies) AS avg_number_rabies, SUM(ic.number_rabies) AS sum_number_rabies
FROM infectious_cases ic
JOIN countries c ON ic.country_id = c.country_id
WHERE ic.number_rabies != ''
GROUP BY ic.country_id
ORDER BY avg_number_rabies DESC
LIMIT 10;

-- 3.2 
SELECT ic.country_id, c.entity, c.code, MIN(ic.number_rabies) AS min_number_rabies, SUM(ic.number_rabies) AS sum_number_rabies
FROM infectious_cases ic
JOIN countries c ON ic.country_id = c.country_id
WHERE ic.number_rabies != ''
GROUP BY ic.country_id
ORDER BY min_number_rabies DESC
LIMIT 10;

-- 3.3 
SELECT ic.country_id, c.entity, c.code, MAX(ic.number_rabies) AS max_number_rabies, SUM(ic.number_rabies) AS sum_number_rabies
FROM infectious_cases ic
JOIN countries c ON ic.country_id = c.country_id
WHERE ic.number_rabies != ''
GROUP BY ic.country_id
ORDER BY max_number_rabies DESC
LIMIT 10;

-- 4.1 
DELIMITER //
CREATE PROCEDURE add_column_if_not_exists()
BEGIN
    IF NOT EXISTS (
        SELECT * 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'infectious_cases' 
          AND COLUMN_NAME = 'start_of_year'
    ) THEN
        ALTER TABLE infectious_cases 
        ADD COLUMN start_of_year DATE;
    END IF;
END //
DELIMITER ;

UPDATE infectious_cases
SET start_of_year = STR_TO_DATE(CONCAT(Year, '-01-01'), '%Y-%m-%d');

-- 4.2 
ALTER TABLE infectious_cases
ADD COLUMN `current_date` DATE;

UPDATE infectious_cases
SET `current_date` = CURDATE();

-- 4.3 
ALTER TABLE infectious_cases
ADD COLUMN `year_difference` INT;

UPDATE infectious_cases
SET year_difference = TIMESTAMPDIFF(YEAR, start_of_year, current_date);

-- 5
DELIMITER //
CREATE FUNCTION get_year_diff(input_year INT) 
RETURNS INT 
DETERMINISTIC
BEGIN
    DECLARE start_date DATE;
    DECLARE year_diff INT;
    SET start_date = STR_TO_DATE(CONCAT(input_year, '-01-01'), '%Y-%m-%d');
    SET year_diff = TIMESTAMPDIFF(YEAR, start_date, CURDATE());
    RETURN year_diff;
END //
DELIMITER ;

SELECT 
    Year, 
    get_year_diff(Year) AS year_difference
FROM infectious_cases
