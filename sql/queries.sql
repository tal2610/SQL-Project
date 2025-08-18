--Final project

-- 1. KPIs by Year and Quarter
-- Calculates gross revenue, discounts, net revenue, orders, quantity, and unique products
-- grouped by year and quarter, to analyze performance trends over time.
select year(OrderDate) as year, datepart(QUARTER, OrderDate) as QUARTER,
       sum(UnitPrice*Quantity) as gross,
       sum(Discount*UnitPrice*Quantity) as Discount,
       sum(UnitPrice*Quantity) - sum(Discount*UnitPrice*Quantity) as Net_Revenue,
       COUNT(distinct od.OrderID) as orders,
       sum(Quantity) as Quantity,
       COUNT(distinct ProductID) as products
from [Order Details] od
join Orders o on od.OrderID=o.OrderID
group by year(OrderDate), datepart(QUARTER, OrderDate)
order by 1,2;


-- 2. Shipment Performance by Product (1997)
-- Shows how long it took to ship each product (days_to_ship) and order counts,
-- filtered to products with >200 shipping days in 1997.
select ProductName, sum(DateDiff) as Days_To_Ship, count(*) as orders
from (
    select ProductName, DATEDIFF(DAY, OrderDate, ShippedDate) as DateDiff
    from Orders o
    join [Order Details] od on o.OrderID=od.OrderID 
    join Products p on p.ProductID=od.ProductID
    where year(OrderDate) = 1997 
) a
group by ProductName
having sum(DateDiff) > 200
order by 2 desc;


-- 3. Revenue and KPIs by Selected Countries
-- Calculates gross revenue, discounts, net revenue, orders, quantity, and product counts
-- for Germany, USA, Brazil, and Austria.
select ShipCountry,
       sum(Quantity*UnitPrice) as Gross_Revenue,
       sum(Discount*UnitPrice*Quantity) as Discount,
       sum(UnitPrice*Quantity) - sum(Discount*UnitPrice*Quantity) as Net_Revenue,
       COUNT(distinct od.OrderID) as orders,
       sum(Quantity) as Quantity,
       COUNT(distinct ProductID) as products
from Orders o
join [Order Details] od on o.OrderID=od.OrderID
where ShipCountry in ('Germany','USA','Brazil','Austria')
group by ShipCountry;


-- 4. Monthly Revenue & Orders (1997)
-- Breaks down revenue and orders by month with month names for better readability.
select month(OrderDate) as Month,
       CASE MONTH(OrderDate)
            WHEN 1 THEN 'January' WHEN 2 THEN 'February' WHEN 3 THEN 'March'
            WHEN 4 THEN 'April'   WHEN 5 THEN 'May'      WHEN 6 THEN 'June'
            WHEN 7 THEN 'July'    WHEN 8 THEN 'August'   WHEN 9 THEN 'September'
            WHEN 10 THEN 'October'WHEN 11 THEN 'November'WHEN 12 THEN 'December'
       END AS month_name,
       sum(Quantity*UnitPrice) as Gross_Revenue,
       COUNT(distinct od.OrderID) as orders
from Orders o
join [Order Details] od on o.OrderID=od.OrderID
where YEAR(OrderDate) = 1997
group by month(OrderDate)
order by 1;


-- 5. Shipping Company Performance (1997)
-- Evaluates shippers by total number of orders and shipping days.
select CompanyName, COUNT(*) as orders, sum(DateDiff) as Days_to_Ship
from (
    select CompanyName, OrderDate, DATEDIFF(DAY, OrderDate, ShippedDate) as DateDiff
    from Orders o
    join Shippers s on o.ShipVia=s.ShipperID
) a
where YEAR(OrderDate) = 1997
group by CompanyName;


-- 6. Top and Bottom Products (1997)
-- Lists the 5 best and 5 worst-performing products by order count.
select ProductName, orders
from (
    select ProductName, orders,
           DENSE_RANK() over(order by orders asc) as rank_asc,
           DENSE_RANK() over(order by orders desc) as rank_desc
    from (
        select ProductName, COUNT(od.ProductID) as orders
        from [Order Details] od 
        join Orders o on o.OrderID=od.OrderID
        join Products p on p.ProductID=od.ProductID
        where YEAR(OrderDate) = 1997
        group by ProductName
    ) a
) b
where rank_asc <= 5 or rank_desc <= 5;


-- 7. Top 10% Products by Orders (1997)
-- Provides category & product-level performance (orders, revenue, discounts, etc).
select top 10 PERCENT CategoryName, ProductName,
       count(distinct od.OrderID) as Orders,
       sum(Quantity) as Quantity,
       sum(Quantity*od.UnitPrice) as Gross_Revenue,
       sum(Discount*od.UnitPrice*Quantity) as Discount,
       sum(od.UnitPrice*Quantity)-sum(Discount*od.UnitPrice*Quantity) as Net_Revenue
from Orders o
join [Order Details] od on o.OrderID=od.OrderID 
join Products p on p.ProductID=od.ProductID 
join Categories c on p.CategoryID=c.CategoryID
where year(OrderDate) = 1997
group by CategoryName, ProductName
order by 3 desc;


-- 8. Low Stock Products
-- Lists products with <10 units in stock along with units on order.
select CategoryName, ProductName, UnitsInStock, UnitsOnOrder
from Products p
join Categories c on c.CategoryID=p.CategoryID
where UnitsInStock < 10
order by 2;


-- 9. Employee Performance (1997)
-- Shows top 5 and bottom 5 employees based on number of orders handled.
select FirstName, Orders, Performance
from (
    select top 5 FirstName, COUNT(distinct od.OrderID) as Orders, 'Top 5' as Performance
    from Employees e
    join Orders o on e.EmployeeID=o.EmployeeID  
    join [Order Details] od on o.OrderID=od.OrderID
    where YEAR(OrderDate) = 1997
    group by FirstName
    order by 2 desc
) a
union all
select FirstName, Orders, Performance
from (
    select top 5 FirstName, COUNT(distinct od.OrderID) as Orders, 'Bottom 5' as Performance
    from Employees e
    join Orders o on e.EmployeeID=o.EmployeeID  
    join [Order Details] od on o.OrderID=od.OrderID
    where YEAR(OrderDate) = 1997
    group by FirstName
    order by 2 asc
) b;


-- 10. Employee & Title-Level KPIs (1997)
-- Shows revenue, discount, net revenue, orders, and quantity by employee,
-- and aggregated totals at the title level.
select Title, FirstName, gross, Discount, Net_Revenue, orders, Quantity,
       sum(orders) over(partition by title) as sum_orders,
       sum(Quantity) over(partition by title) as sum_Quantity,
       sum(gross) over(partition by title) as sum_Gross,
       sum(Discount) over(partition by title) as Sum_Discount,
       sum(Net_Revenue) over(partition by title) as sum_Net
from (
    select Title, FirstName,
           sum(UnitPrice*Quantity) as gross,
           sum(Discount*UnitPrice*Quantity) as Discount,
           sum(UnitPrice*Quantity) - sum(Discount*UnitPrice*Quantity) as Net_Revenue,
           COUNT(distinct od.OrderID) as orders,
           sum(Quantity) as Quantity
    from Employees e
    join Orders o on e.EmployeeID=o.EmployeeID  
    join [Order Details] od on o.OrderID=od.OrderID
    where YEAR(OrderDate) = 1997
    group by Title, FirstName
) a;


-- 11. Regional Performance
-- Calculates revenue, orders, and revenue per order by region.
select region, orders, revenue, revenue/orders as revenue_per_order
from (
    select region,
           SUM(Quantity*UnitPrice) as revenue,
           COUNT(distinct orderid) as orders
    from (
        select distinct o.OrderID as orderid, r.RegionDescription as region, Quantity, UnitPrice
        from Region r
        join Territories t on r.RegionID=t.RegionID
        join EmployeeTerritories et on t.TerritoryID=et.TerritoryID
        join Orders o on o.EmployeeID=et.EmployeeID 
        join [Order Details] od on o.OrderID=od.OrderID
    ) a
    group by region
) b
order by 4 desc;


-- 12. Comprehensive KPI Dataset
-- Prepares a wide KPI dataset (orders, products, revenue, discounts, shipping, employees, etc.)
-- for dashboard creation and visualization.
select od.OrderID, o.OrderDate, MONTH(OrderDate) as month,
       DATEPART(QUARTER, OrderDate) as QUARTER,
       c.CustomerID, c.city,
       s.ShipperID, s.CompanyName,
       e.EmployeeID, e.Title, e.FirstName,
       p.ProductName, ca.CategoryName,
       Quantity*od.UnitPrice as gross_revenue,
       Discount*od.UnitPrice*Quantity as Discount,
       Quantity,
       DATEDIFF(DAY, OrderDate, ShippedDate) as days_to_ship,
       COUNT(od.ProductID) OVER (PARTITION BY o.OrderID) AS products,
       COUNT(o.OrderID) OVER (PARTITION BY o.OrderID) AS orders
from Orders o
join Customers c on o.CustomerID=c.CustomerID 
join Shippers s on s.ShipperID=o.ShipVia
join Employees e on e.EmployeeID=o.EmployeeID
join [Order Details] od on od.OrderID=o.OrderID
join Products p on p.ProductID = od.ProductID
join Categories ca on ca.CategoryID=p.CategoryID;

