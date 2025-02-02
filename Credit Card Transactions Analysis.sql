

-- Doing exploratory analysis to find the key requirements of Credit Card Transactions


-- Creating card_base, customer_base, fraud_base and transaction_base tables in the datebase

drop table if exists Card_base;
create table if not exists Card_base
(
	Card_Number		varchar(50),
	Card_Family		varchar(30),
	Credit_Limit	int,
	Cust_ID			varchar(20)
);


drop table if exists customer_base;
create table if not exists Customer_base
(
	Cust_ID						varchar(20),
	Age 						int,
	Customer_Segment			varchar(30),
	Customer_Vintage_Group		varchar(20)
);


drop table if exists fraud_base;
create table if not exists Fraud_base
(
	Transaction_ID		varchar(20),
	Fraud_Flag			int
);


drop table if exists transaction_base;
create table if not exists Transaction_base
(
	Transaction_ID			varchar(20),
	Transaction_Date		date,
	Credit_Card_ID			varchar(50),
	Transaction_Value		decimal,
	Transaction_Segment		varchar(20)
);

-- Imported data into tables from csv files


select * from card_base;
select * from customer_base;
select * from fraud_base;
select * from transaction_base;


-- How many customers have done transactions over 49000?

select 
count(distinct cb.cust_id) as customer_count
from transaction_base as tb
left join card_base as cb
	on tb.credit_card_id = cb.card_number
where tb.transaction_value > 49000;

-- Which card type has done the most no of transactions without having any fraudulent transactions.

select
t.card_family,
count(*) as total_transactions
from
	(
	select
	*
	from transaction_base as tb
	left join fraud_base as fb
		on tb.transaction_id = fb.transaction_id
	left join card_base as cb
		on tb.credit_card_id = cb.card_number
	where fb.fraud_flag is null
	) as t
group by t.card_family
order by total_transactions desc
limit 1



-- Identify the range of credit limit of customers who have done fraudulent transactions


select
min(cb.credit_limit) as min_fraud_credit_limit,
max(cb.credit_limit) as max_fraud_credit_limit
from Transaction_base as tb
join fraud_base as fb
	on tb.transaction_id = fb.transaction_id
join card_base as cb
	on tb.credit_card_id = cb.card_number;



--  What is the average age of customers who are involved in fraud transactionsbased on different card type?



select
cb.card_family,
round(avg(age),2) as average_age
from Transaction_base as tb
join fraud_base as fb
	on tb.transaction_id = fb.transaction_id
join card_base as cb
	on tb.credit_card_id = cb.card_number
join customer_base as cusb
	on cb.cust_id = cusb.cust_id
group by cb.card_family
;

-- Identify the month when highest no of fraudulent transactions occured.


with cte1 as 
	(
		select
			to_char(transaction_date,'Month') as monthname,
			count(*) as fraud_transaction_count,
			dense_rank() over(order by count(*) desc) as fraud_count_rank
		from transaction_base as tb
		join fraud_base as fb
			on tb.transaction_id = fb.transaction_id
		group by to_char(transaction_date,'Month')
	)
select 
monthname,fraud_transaction_count
from cte1
where fraud_count_rank = 1
;


-- Identify the customer who has done the most transaction value without involving in any fraudulent transactions.
with cte1 as
	(
		select
		distinct cust_id
		from transaction_base as tb
		left join card_base as cb
			on tb.credit_card_id = cb.card_number
		join fraud_base as fb
			on tb.transaction_id = fb.transaction_id
	),
	cte2 as
	(
		select
		cb.cust_id,
		tb.transaction_id,
		tb.transaction_value,
		dense_rank() over(order by tb.transaction_value desc) as trans_value_rank
		from transaction_base as tb
		left join card_base as cb
			on tb.credit_card_id = cb.card_number
		where cb.cust_id not in (select cust_id from cte1)
	)
select
cust_id
from  cte2
where trans_value_rank = 1
;


-- Check and return any customers who have not done a single transaction

select
distinct cusb.cust_id
from customer_base as cusb
left join card_base as cb
	on cusb.cust_id = cb.cust_id
left join transaction_base as tb
	on cb.card_number = tb.credit_card_id
where tb.transaction_id is null



-- What is the highest and lowest credit limit given to each card type?


select
card_family,
min(credit_limit) as min_credit_limit,
max(credit_limit) as max_credit_limit
from card_base 
group by card_family
order by min_credit_limit asc
;


-- What is the total value of transactions done by customers who come under the age bracket of 20-30 yrs, 30-40 yrs, 40-50 yrs, 50+ yrs and 0-20 yrs.


with cte1 as
	(
	select
	case
		when age > 0 and age <= 20 then '0-20 yrs'
		when age > 20 and age <= 30 then '20-30 yrs'
		when age > 30 and age <= 40 then '30-40 yrs'
		when age > 40 and age <= 50 then '40-50 yrs' else '50+ yrs'
	end as age_group,
	tb.transaction_value
	from  transaction_base as tb 
	left join card_base as cb
		on tb.credit_card_id = cb.card_number
	join customer_base as cusb
		on cusb.cust_id = cb.cust_id
	)
select
age_group,
sum(transaction_value) as total_transaction_value
from cte1
group by age_group
order by age_group asc
;


-- Which card type has done the  total highest value of transactions without having any fraudulent transactions.


with cte1 as
	(
	select
			cb.card_family,
			sum(tb.transaction_value) as total_transaction_value,
			dense_rank() over(order by sum(tb.transaction_value) desc) as trans_value_rank
		from transaction_base as tb
		left join fraud_base as fb
			on tb.transaction_id = fb.transaction_id
		left join card_base as cb
			on tb.credit_card_id = cb.card_number
		where fb.fraud_flag is null
		group by cb.card_family	
	)
select
card_family,
total_transaction_value
from cte1
where trans_value_rank = 1









