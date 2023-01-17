/*
=======================================================
VACU SQL Assessment
=======================================================
*/

/*
Question 1
=======================================================
Provide a list of the following field names for all customers 
that have purchased productname “widget”: 
    - contactname
    - address (customers table)
    - city (customers table)
    - postalcode (customers table)
*/

select
        contactname,
        address,
        city,
        postalcode
    from customers c
    inner join orders o on c.customerid = o.customerid
    inner join orderdetails od on o.orderid = od.orderid
        -- There might be a space in 'orderdetails' based on the ERD,
        -- I'd try throwing it in brackets if so
    inner join products p on od.productid = p.productid
    where p.productname = "widget"
;
    )



/*
Question 2
=======================================================
Place the above list into a temp table.
*/

-- It looks like there's two ways to make a temp table in SQL Server
-- This looked like the easiest way, but it felt TOO easy
select
        customerid, -- Adding as 'primary key'
        contactname,
        address,
        city,
        postalcode

    into #widgetBuyers
        -- Important bit that makes the temp table

    from customers c
    inner join orders o on c.customerid = o.customerid
    inner join orderdetails od on o.orderid = od.orderid
    inner join products p on od.productid = p.productid
    where p.productname = "widget"
;

-- When I checked the documentation they only listed the "create table" 
-- then "insert into" method, so that's what I'll go with as my answer
create table #widgetBuyers (
    customerid varchar(5), -- Again, adding as 'primary key'
    contactname varchar(30),
    address varchar(60),
    city varchar(15),
    postalcode varchar(10)
)

insert into #widgetBuyers
select
        customerid,
        contactname,
        address,
        city,
        postalcode
    from customers c
    inner join orders o on c.customerid = o.customerid
    inner join orderdetails od on o.orderid = od.orderid
    inner join products p on od.productid = p.productid
    where p.productname = "widget"
;




/*
Question 3
=======================================================
Pull the list from question 1 from the temp table removing any duplicates. 
Feel free to add fields not previously included if necessary.
*/

-- This will add row numbers that start over each time there's a new 'customerid',
-- meaning I can delete anything over 1 because they'll be duplicates
with cte as (
    select
            customerid,
            contactname,
            address,
            city,
            postalcode,
            row_number() over (partition by customerid order by customerid) rn
        from #widgerBuyers
    )
delete from cte where rn > 1
;




/*
Question 4
=======================================================
Create a temp table including all the following fields for those who have purchased 
productname “widget2” excluding anyone who has purchased anything in the past 6 months. 
Assume the date fields are structured YYYYMMDD. Include the following fields:
    - customerid
    - orderdate
*/

-- Going with a similar method as question 2, create the table first
create table #widget2Buyers (
    customerid varchar(5),
    orderdate date
)

-- Then insert in the rows 
insert into #widget2Buyers
select
        c.customerid,
        convert(date, orderdate)
    from customers c
    inner join orders o on c.customerid = o.customerid
    inner join orderdetails od on o.orderid = od.orderid
    inner join products p on od.productid = p.productid
    where p.productname = "widget2"
    and convert(date, orderdate) >= dateadd(month, -6, current_timestamp) 
            -- Two assumptions
            -- 1) You want orderdates from the last six months, starting right now
            -- 2) That I can't connect with whoever used the YYYYMMDD and convince
            --    them to use a standard date format
;

/*
Question 5
=======================================================
Count how many customers placed an order for a productname of “widget” 
with a quantity of 4 or more.
*/

select count(distinct c.customerid)
    from customers c
    inner join orders o on c.customerid = o.customerid
    inner join orderdetails od on o.orderid = od.orderid
    inner join products p on od.productid = p.productid
    where p.productname = "widget"
    and quantity >= 4
;




/*
Question 6
=======================================================
Find the most recent order for each customer_id and order it from newest to oldest.
*/

select
        c.customerid,
        max(orderdate) recentOrder
            -- Assuming orderdate is a proper date this time because it wasn't spelled out 
            -- in the question, otherwise I'd convert(date, orderdate) it
    from customers c
    inner join orders o on c.customerid = o.customerid
    group by c.customerid
    order by recentOrder desc
;




/*
Question 7
=======================================================
Add the column “active_customer_status” to table customers and place an 
indicator of 1 if the customer has placed an order within the past 6 months. 
Assume the date fields are structured YYYYMMDD. Place an indicator of 0 if 
the customer has not placed an order within the past 6 months.
*/


-- Creating #active_customer_status_table
create #active_customer_status_table (
    customerid varchar(5),
    active_customer_status boolean
)

-- Insert the customer status into the new table
insert into #active_customer_status_table
select
        c.customerid,
        case
            when convert(date, orderdate) >= dateadd(month, -6, current_timestamp) then 1
                    -- Again, assuming 6 months from today
            else 0
            end active_user_status
    from customers c
    inner join orders o on c.customerid = o.customerid
;

-- Altering the customers table to add active_customer_status
alter table customers 
add active_customer_status boolean null
;

-- Updating active_customer_status with the data from #activeUserStatus
update customers
inner join #active_customer_status_table on customers.customerid = #active_customer_status_table.customerid
set customers.active_customer_status = #active_customer_status_table.active_customer_status
;
    