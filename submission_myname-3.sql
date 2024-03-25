/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
SELECT State, COUNT(*) AS customer_count
FROM Customer_t
GROUP BY State;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/

WITH FeedbackNumber AS (
    SELECT CASE customer_feedback
               WHEN 'Very Bad' THEN 1
               WHEN 'Bad' THEN 2
               WHEN 'Okay' THEN 3
               WHEN 'Good' THEN 4
               WHEN 'Very Good' THEN 5
               ELSE NULL
           END AS feedback_value,
           EXTRACT(YEAR FROM order_date) AS year,
           EXTRACT(QUARTER FROM order_date) AS quarter
    FROM order_t
)
SELECT year, quarter, AVG(feedback_value) AS average_rating
FROM FeedbackNumber
GROUP BY year, quarter;







-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/
WITH FeedbackPercentage AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year,
           EXTRACT(QUARTER FROM order_date) AS quarter,
           SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) AS very_bad,
           SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS bad,
           SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS okay,
           SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) AS good,
           SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS very_good,
           COUNT(*) AS total_feedback
    FROM order_t
    GROUP BY year, quarter
)
SELECT year, quarter,
       (very_bad * 100 / total_feedback) AS very_bad_percentage,
       (bad * 100 / total_feedback) AS bad_percentage,
       (okay * 100 / total_feedback) AS okay_percentage,
       (good * 100 / total_feedback) AS good_percentage,
       (very_good * 100 / total_feedback) AS very_good_percentage
FROM FeedbackPercentage;






-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/
SELECT vehicle_maker, COUNT(*) AS customer_count
FROM product_t
JOIN order_t ON product_t.product_id = order_t.product_id
GROUP BY vehicle_maker
ORDER BY customer_count DESC
LIMIT 5;



-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/
WITH PreferredMakes AS (
    SELECT State, vehicle_maker, COUNT(*) AS make_count,
           ROW_NUMBER() OVER (PARTITION BY State ORDER BY COUNT(*) DESC) AS rn
    FROM product_t
    JOIN order_t ON product_t.product_id = order_t.product_id
    JOIN Customer_t ON order_t.customer_id = Customer_t.customer_id
    GROUP BY State, vehicle_maker
)
SELECT State, vehicle_maker, make_count
FROM PreferredMakes
WHERE rn = 1;



-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/
SELECT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(QUARTER FROM order_date) AS quarter,
       COUNT(*) AS order_count
FROM order_t
GROUP BY year, quarter
ORDER BY year, quarter;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
      WITH RevenueQuarterly AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(QUARTER FROM order_date) AS quarter,
           SUM(Quantity * vehicle_price * (1 - discount)) AS revenue
    FROM order_t
    GROUP BY year, quarter
),
QoQRevenueChange AS (
    SELECT year, quarter, revenue,
           LAG(revenue) OVER (ORDER BY year, quarter) AS prev_revenue
    FROM RevenueQuarterly
)
SELECT year, quarter, 
       ((revenue - prev_revenue) / prev_revenue) * 100 AS qoq_revenue_change_percentage
FROM QoQRevenueChange
WHERE prev_revenue IS NOT NULL;

      

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
SELECT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(QUARTER FROM order_date) AS quarter,
       SUM(Quantity * vehicle_price * (1 - discount)) AS revenue,
       COUNT(*) AS order_count
FROM order_t
GROUP BY year, quarter
ORDER BY year, quarter;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/
SELECT c.credit_card_type, AVG(o.discount) AS average_discount
FROM order_t o
JOIN Customer_t c ON o.customer_id = c.customer_id
GROUP BY c.credit_card_type;







-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
SELECT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(QUARTER FROM order_date) AS quarter,
       AVG(DATEDIFF(ship_date, order_date)) AS average_shipping_days
FROM order_t
WHERE ship_date IS NOT NULL
GROUP BY year, quarter
ORDER BY year, quarter;



-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------

/* for Powerpoint bussiness */

/* Total revenue*/
SELECT SUM(Quantity * vehicle_price * (1 - discount)) AS total_revenue
FROM order_t;

/* Total Orders*/
SELECT COUNT(*) AS total_orders
FROM order_t;

/* Total customers*/
SELECT COUNT(*) AS total_customers
FROM Customer_t;
/* Avg rating */
WITH FeedbackNumber AS (
    SELECT CASE customer_feedback
               WHEN 'Very Bad' THEN 1
               WHEN 'Bad' THEN 2
               WHEN 'Okay' THEN 3
               WHEN 'Good' THEN 4
               WHEN 'Very Good' THEN 5
               ELSE NULL
           END AS feedback_value
    FROM order_t
)
SELECT AVG(feedback_value) AS average_rating
FROM FeedbackNumber;

/* Last Quarter Revenue */ 
WITH RevenueQuarterly AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(QUARTER FROM order_date) AS quarter,
           SUM(Quantity * vehicle_price * (1 - discount)) AS revenue
    FROM order_t
    GROUP BY year, quarter
)
SELECT revenue
FROM RevenueQuarterly
ORDER BY year DESC, quarter DESC
LIMIT 1;
/* Last Qtr Orders */ 
WITH OrderQuarterly AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year, EXTRACT(QUARTER FROM order_date) AS quarter,
           COUNT(*) AS order_count
    FROM order_t
    GROUP BY year, quarter
)
SELECT order_count
FROM OrderQuarterly
ORDER BY year DESC, quarter DESC
LIMIT 1;

/* Avg Days to Ship */ 
SELECT AVG(DATEDIFF(ship_date, order_date)) AS avg_days_to_ship
FROM order_t
WHERE ship_date IS NOT NULL;

/* %Good feedback */
WITH FeedbackPercentage AS (
    SELECT SUM(CASE WHEN customer_feedback = 'Good' OR customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS good_feedback_count,
           COUNT(*) AS total_feedback_count
    FROM order_t
)
SELECT (good_feedback_count * 100 / total_feedback_count) AS percentage_good_feedback
FROM FeedbackPercentage;








