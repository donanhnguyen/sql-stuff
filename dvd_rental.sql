-- A.  Summarize one real-world written business report that can be created from the DVD Dataset from the “Labs on Demand Assessment Environment and DVD Database” attachment. 


-- The goal of this report is to analyze the most popular film categories in different countries based on the total revenue generated. The revenue is calculated by multiplying the rental rate by the rental duration for each film rental. By understanding which film categories generate the most revenue in each country, we can make more informed decisions on marketing strategies, inventory allocation, and customer targeting for specific regions.
-- The detailed table provides granular information for each rental transaction, including specific details about the film, its category, the customer location, and the total revenue generated. 
-- The summary table aggregates data by film category and country, summarizing the total revenue per category in each country. 


-- 1.  Identify the specific fields that will be included in the detailed table and the summary table of the report.


-- Detailed Table:
-- film_id: The unique identifier for the film.
-- film_category: The category or genre of the film (e.g., Action, Comedy).
-- rental_rate: The cost per rental for the film.
-- rental_duration: The duration of the rental in days.
-- total_revenue: A calculated field representing the total revenue from each rental (rental_rate * rental_duration).
-- customer_id: The unique identifier for the customer renting the film.
-- country: The country in which the rental took place, extracted via joins through the customer and address data.
-- Summary Table:
-- country: The country where the rental took place.
-- film_category: The genre or category of the film.
-- total_revenue: The total revenue generated for each film category in each country, calculated by summing the revenue from the detailed table.
-- total_rentals: number of rentals


-- 2.  Describe the types of data fields used for the report.


-- For detailed table:


--     film_id = Integer,
--     Film_category = String,
--     rental_rate = Decimal,
--     Rental_duration = Integer,
--     total_revenue = Decimal,
--     customer_id = Integer,
--     Country = String


-- For summary table:


-- country = String),
--     Film_category = String,
--     Total_category_revenue = Decimal,
--     total_rentals = Integer


-- 3.  Identify at least two specific tables from the given dataset that will provide the data necessary for the detailed table section and the summary table section of the report.


-- Film Table
-- Film Category Table
-- Category Table
-- Rental Table
-- Customer Table
-- Address Table
-- City Table
-- Country Table


-- 4.  Identify at least one field in the detailed table section that will require a custom transformation with a user-defined function and explain why it should be transformed (e.g., you might translate a field with a value of N to No and Y to Yes).


-- The total price of the rental (rental rate * duration) will require transformation from USD (the company’s base currency for example) to different currencies based on the country in which the customer is from. The function should take in the US rate, and the other country’s rate, and return the converted amount. It should be transformed because each country uses the DVD rental service, but their prices will be different depending on their currency. It would also allow customers as well as stakeholders to see the prices in their currency, overall improving user experience.


-- 5.  Explain the different business uses of the detailed table section and the summary table section of the report. 


-- The primary business use case is to determine how to target audiences better in different countries, cater to their needs more, ultimately making more money by producing more traffic.
-- The goal is to find out which categories of films are most popular in each country. For example, if we found out that American customers rent Sci-Fi films the most often, we now know that Sci-Fi films are the ones that need to be shown first in the DVD rental store. 
-- The detailed table section should show all the raw data of the rentals, film genres, customer’s location, and the amount of money generated from the rental by multiplying its rate by duration.
-- The summary table section should show the most popular genre by country (example would be if it showed that American customers rented Sci-Fi the most, European customers rented Romance the most, etc.). We can use this information to determine which films to get more inventory of for each country that the customers come from. In addition, we can potentially put these genre of films at the front of the DVD rental store, for example, to catch their attention better upon entering.


-- 6.  Explain how frequently your report should be refreshed to remain relevant to stakeholders.


-- Every month the data needs to be re-run and refreshed. A month is a good amount of time to allow for sufficient enough data and rentals to form an accurate analysis, versus if there was only 1 additional rental and the report being re-run.
 
-- B.  Provide original code for function(s) in text format that perform the transformation(s) you identified in part A4.


DROP FUNCTION IF EXISTS convert_currency_from_usd(NUMERIC, NUMERIC);

CREATE FUNCTION convert_currency_from_usd(usd NUMERIC, conversion_rate NUMERIC) 
RETURNS NUMERIC 
AS 
$$ 
BEGIN 
    -- If the conversion rate is 1 (for USD), return the original USD amount
    IF conversion_rate = 1 THEN
        RETURN usd;
    ELSE
        -- Otherwise, perform the conversion
        RETURN usd * conversion_rate;
    END IF;
END; 
$$ 
LANGUAGE plpgsql;

 
-- C.  Provide original SQL code in a text format that creates the detailed and summary tables to hold your report table sections.


-- Detailed table for film rentals and their information:


DROP TABLE IF EXISTS detailed_film_rentals;
CREATE TABLE detailed_film_rentals (
    film_id INT,
    film_category VARCHAR(255),
    rental_rate DECIMAL(5, 2),
    rental_duration INT,
    total_revenue DECIMAL(10, 2),
    customer_id INT,
    country VARCHAR(100)
);


-- Summary table for total revenue per category per country:


DROP TABLE IF EXISTS popular_categories_by_country;
CREATE TABLE popular_categories_by_country (
    country VARCHAR(100),
    film_category VARCHAR(255),
    total_category_revenue DECIMAL(10, 2),
    total_rentals INT
);


-- D.  Provide an original SQL query in a text format that will extract the raw data needed for the detailed section of your report from the source database.


SELECT 
    f.film_id,
    c.name AS film_category,
    f.rental_rate,
    f.rental_duration,
    (f.rental_rate * f.rental_duration) AS total_revenue,
    r.customer_id,
    co.country
FROM 
    film AS f
JOIN 
    film_category AS fc ON f.film_id = fc.film_id
JOIN 
    category AS c ON fc.category_id = c.category_id
JOIN 
    rental AS r ON f.film_id = r.rental_id
JOIN 
    customer AS cu ON r.customer_id = cu.customer_id
JOIN 
    address AS a ON cu.address_id = a.address_id
JOIN 
    city AS ci ON a.city_id = ci.city_id
JOIN 
    country AS co ON ci.country_id = co.country_id;



 
-- E.  Provide original SQL code in a text format that creates a trigger on the detailed table of the report that will continually update the summary table as data is added to the detailed table.
 
CREATE OR REPLACE FUNCTION update_summary_table() 
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM popular_catgories_by_country 
        WHERE country = NEW.country 
          AND film_category = NEW.film_category
    ) THEN
        UPDATE popular_catgories_by_country
        SET 
            total_category_revenue = total_category_revenue + NEW.total_revenue,
            total_rentals = total_rentals + 1
        WHERE 
            country = NEW.country 
            AND film_category = NEW.film_category;
    ELSE
        INSERT INTO popular_catgories_by_country (country, film_category, total_category_revenue, total_rentals)
        VALUES (NEW.country, NEW.film_category, NEW.total_revenue, 1);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_update_summary ON detailed_film_rentals; 
CREATE TRIGGER trg_update_summary
AFTER INSERT ON detailed_film_rentals
FOR EACH ROW
EXECUTE FUNCTION update_summary_table();






-- F.  Provide an original stored procedure in a text format that can be used to refresh the data in both the detailed table and summary table. The procedure should clear the contents of the detailed table and summary table and perform the raw data extraction from part D.
-- 1.  Identify a relevant job scheduling tool that can be used to automate the stored procedure.

CREATE OR REPLACE PROCEDURE refresh_data()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE detailed_film_rentals;

    TRUNCATE TABLE summary_category_revenue;

    INSERT INTO detailed_film_rentals (film_id, film_category, rental_rate, rental_duration, total_revenue, customer_id, country)
    SELECT 
        f.film_id,
        c.name AS film_category,
        f.rental_rate,
        f.rental_duration,
        (f.rental_rate * f.rental_duration) AS total_revenue,
        r.customer_id,
        co.country
    FROM 
        film AS f
    JOIN 
        film_category AS fc ON f.film_id = fc.film_id
    JOIN 
        category AS c ON fc.category_id = c.category_id
    JOIN 
        rental AS r ON f.film_id = r.rental_id
    JOIN 
        customer AS cu ON r.customer_id = cu.customer_id
    JOIN 
        address AS a ON cu.address_id = a.address_id
    JOIN 
        city AS ci ON a.city_id = ci.city_id
    JOIN 
        country AS co ON ci.country_id = co.country_id;

END;
$$;

-- A relevant job scheduling tool that can be used to automatically run this stored procedure is pgAgent, especially if it’s a PostgreSQL database.
