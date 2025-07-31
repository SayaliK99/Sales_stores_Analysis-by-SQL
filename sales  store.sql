select * from [sales store sql]

select * INTO sales_store from [sales store sql]

select * from sales_store

--- Data cleaning
--1 To check for duplicates

select transaction_id , count(*)
from sales_store
group by transaction_id
having count(transaction_id) >1

TXN240646
TXN342128
TXN855235
TXN981773

with CTE AS(
select *,
    ROW_NUMBER() over (partition by transaction_id order by transaction_id) AS Row_num
from sales_store)
select * from CTE
where transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')

---delete this 4 duplicate records

with CTE AS(
select *,
    ROW_NUMBER() over (partition by transaction_id order by transaction_id) AS Row_num
from sales_store)
Delete from CTE
where Row_Num = 2


---Step 2 :-  Correction of headers

 EXEC sp_rename 'sales_store.quantiy', 'Quantity','COLUMN'

 EXEC sp_rename 'sales_store.prce', 'Price','COLUMN'

----Step 3 :- check datatype

select COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales_store'

--change price to float

Alter Table sales_store
Alter Column Price float

---Step 4 :- To check null values


Declare @SQL NVARCHAR(MAX) = '';

select @SQL = STRING_AGG(
     'SELECT ''' + COLUMN_NAME + ''' AS columnName,
	 Count(*) AS NullCount
	 From ' + QuoteName(Table_schema) + '.sales_store
	 where ' + Quotename(COlUMN_NAME) + ' IS NULL',
	 'Union all'
)
within group (order by COLUMN_NAME)
from INFORMATION_SCHEMA.COLUMNS
where Table_name = 'sales_store';

--Exceute the dynamic sql
EXEC sp_executesql @sql;



Declare @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
     'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
	 COUNT(*) AS NullCount
	 FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales_store
	 WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
	 'UNION ALL'
)
WITHIN GROUP(ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales_stores';

--- exceute the dynamic sql
EXEC sp_excecutesql @SQL;

-----treting null values

select * from sales_store
where transaction_id is null
or transaction_id is null
or customer_id is null
or customer_name is null
or customer_age is null
or gender is null
or product_id is null
or product_name is null
or product_category is null
or Quantity is null
or Quantity is null
or Price is null
or payment_mode is null
or time_of_purchase is null
or purchase_date is null

--delete record for transaction id is null bcz not having proper records
Delete from sales_store
where transaction_id is null


--check cust id of ehsaan ram from previous sales and update his customer id
select * from sales_store
where Customer_name = 'Ehsaan Ram'

update  sales_store
SET customer_id = 'CUST9494'
where transaction_id = 'TXN977900'
-------------------------
select * from sales_store
where Customer_name = 'Damini Raju'

update  sales_store
SET customer_id = 'CUST1401'
where transaction_id = 'TXN985663'

----- check cust name, gender, cust age for CUST1003 and update details with previous details
select * from sales_store
where customer_id = 'CUST1003'

update  sales_store
SET customer_name = 'Mahika Saini', customer_age = '35' , gender = 'Male'
where transaction_id = 'TXN432798'

------------------------------------------------------------------------------------------------------------------------------

--Step 5 :- Data Clening

--update gender f to female and m to male
select distinct gender
from sales_store

update sales_store
SET gender = 'M'
where gender = 'Male'

--update payment mode cc to credit card
select distinct payment_mode
from sales_store

update sales_store
SET Payment_mode = 'Credit Card'
where Payment_mode = 'CC'
-------------------------------------------------------------------------------------------

--Step 6 :- DATA ANALYSIS

--# 1. What are the top 5 most selling products by quantity

select Top 5  product_name, sum(Quantity) AS total_quantity_sold
from sales_store
where status = 'delivered'   -- we don't want returned, cancelled or pending products
Group by product_name
order by total_quantity_sold DESC

--Business problem : we don't know which products are most in demand
--Business Impact :  Helps prioritize stock nd boost sales through targeted promotions.

-------------------------------------------------------------------------------------------------------------

---# 2. which products are mostly frequently cancelled

select Top 5  product_name, Count(*) AS total_cancelled
from sales_store
where status = 'cancelled'   -- we don't want returned, cancelled or pending products
Group by product_name
order by total_cancelled DESC

--Business problem : Frequent cancellation affect revenue and customer trust
--Business Impact  : Identify poor-performing products to improve quality or remove from catlog

-----------------------------------------------------------------------------------------------------------------

---# 3. What time of the day has highest number of purchase

select * from sales_store
         select
		    case  
			   when DATEPART(Hour, time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
			   when DATEPART(Hour, time_of_purchase) BETWEEN 5 AND 11 THEN 'Morning'
		       when DATEPART(Hour, time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
			   when DATEPART(Hour, time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
            End AS Time_of_day,
			count(*) AS total_order
		from sales_store
		Group by 
		    case
		        when DATEPART(Hour, time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
			   when DATEPART(Hour, time_of_purchase) BETWEEN 5 AND 11 THEN 'Morning'
		       when DATEPART(Hour, time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
			   when DATEPART(Hour, time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
            End
		    
--Business problem : Find peak sales times.
--Business Impact  : optimize staffing, promotions, and server loads

---------------------------------------------------------------------------------------------------------

---# 4. Who are top 5 highest spending customers?

select * from sales_store

select Top 5 customer_name, 
       Format(sum(Price * Quantity), 'C0', 'en-IN') AS highest_spending     -----C0 - c stands for curent, o-seprated by (,) ,'en-IN' - In stands for indian curreny
from sales_store
Group by Customer_name
order by sum(Price * Quantity) DESC

--Business problem : Identify VIP customers
--Business Impact  : Personalized offers, loyalty rewards, and retention

---------------------------------------------------------------------------------------------------------

---# 5. which product category generate highest revenue

select product_category,
    Format(sum(Price * Quantity), 'C0', 'en-IN') AS highest_revenue     -----C0 - c stands for curent, o-seprated by (,) ,'en-IN' - In stands for indian curreny
from sales_store
Group by product_category
order by sum(Price * Quantity) DESC

--Business problem : Identifytop-performing product categories
--Business Impact  : Allowing business to invest more in high- margin or high demand categories

---------------------------------------------------------------------------------------------------------

---# 6. what is return/cancellation rate per product category

select * from sales_store

---for cancellation
select product_category,
    format(count( case when status = 'cancelled' Then 1 END) * 100.0 /  Count(*), 'N3') + ' %' AS cancelled_percent   ---- N3- N stand for no fomat 3 for 3 decimal digit and % to add percentage symbol at end
from sales_store
Group by product_category
order by cancelled_percent DESC

---for returned
select product_category,
    format(count( case when status = 'Returned' Then 1 END) * 100.0 /  Count(*), 'N3') + ' %' AS Returned_percent   ---- N3- N stand for no fomat 3 for 3 decimal digit and % to add percentage symbol at end
from sales_store
Group by product_category
order by Returned_percent DESC

--Business problem : Reduce returns, improve product desciptions/expectations
--Business Impact  :help idntify and fix producr or logistics issues
---------------------------------------------------------------------------------------------------------

----7. what is most prefeered payment mode ?

select * from sales_store

select payment_mode, count(payment_mode) as Prefered_mode
from sales_store
group by payment_mode
order by Prefered_mode desc

--Business problem : Know which pyment options customers prefer
--Business Impact  : stremline payment procesing, prioritize popular modes
---------------------------------------------------------------------------------------------------------

----#8. How does age group affect purchasing behavior?
select * from sales_store

--select min(customer_age), max(customer_age)
--from sales_store

select 
     case
	   when customer_age BETWEEN  18 AND 25 THEN '18-25'
	   when customer_age BETWEEN  26 AND 35 THEN '26-35'
	   when customer_age BETWEEN  36 AND 50 THEN '36-50'
	   else '50+'
     End as Customer_age,
	 format(sum(price*quantity), 'C0', 'en-IN' )AS total_purchase
from sales_store
group by case
	   when customer_age BETWEEN  18 AND 25 THEN '18-25'
	   when customer_age BETWEEN  26 AND 35 THEN '26-35'
	   when customer_age BETWEEN  36 AND 50 THEN '36-50'
	   else '50+'
	  End
order by total_purchase DESC

--Business problem : Understand customer demographics
--Business Impact  : Trageted maketing and roduct recommondations by age group 
---------------------------------------------------------------------------------------------------------

----#9. Whats the monthly sales trend?
select* from sales_store

--Method 1 
select 
    format(purchase_date, 'yyyy-MM') AS Month_year,
	format(sum(Price * Quantity),'C0', 'en-IN' ) AS total_sales,
	sum(Quantity) AS total_quantity
from sales_store
group by format(purchase_date, 'yyyy-MM')

--method 2 
    select
	    year(purchase_date) AS Years,
		Month(purchase_date) AS Months,
		format(sum(Price * Quantity),'C0', 'en-IN' ) AS total_sales,
	    sum(Quantity) AS total_quantity
from sales_store
group by YEAR(purchase_date), Month(purchase_date)
order by Months

--Business problem : Sales fluctutions go unnoticed
--Business Impact  : plan inventory and marketing according to seasonal trends
---------------------------------------------------------------------------------------------------------

--#10. are certain genders being more specific product categories?

select* from sales_store

--Method 1
select gender, product_category, count(product_category) AS total_purchase
from sales_store
group by gender, product_category
order by gender DESC

--Method 2
 select *
 from(
    select gender, product_category
	from sales_store
	) AS source_table
pivot (
   count(gender)
   for gender IN ([F], [M])
   ) AS pivot_table
 order by product_category

 --Business problem : gender based product preferences
--Business Impact  : personalized ads, gender focused campaigns
---------------------------------------------------------------------------------------------------------
