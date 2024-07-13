use pizza   -- use the database

select count(*) from order_details          -- 48620 records
select count(*) from orders                 -- 21350 records
select count(*) from pizza_types            -- 32 records
select count(*) from pizzas                 -- 96 records
 
 
 
 
 -- calculate the total orders placed
 select count(DISTINCT order_id) as TOTAL_ORDER  from orders            -- 21350
 
 
 
 
 
 -- calculate total revenue 
 select sum(od.quantity*p.price) as Total_Revenue from
 order_details od join
 pizzas p on p.pizza_id=od.pizza_id                          -- 817860
 
  
  
  
  
-- highest rated pizza
select * from pizzas 
where price =(select max(price) from pizzas)              -- the_greek XXL 





-- highest rated pizza

select * from pizzas p
join pizza_types pt
on pt.pizza_type_id=p.pizza_type_id
where price=(select max(price) from pizzas)





-- most common pizza size available

select size,number from
(select size,count(*) as number,
rank() over( order by count(*) desc) as 'rnk'
from pizzas 
group by size)k
where k.rnk=1                                            -- small size




-- most common pizza size ordered
select size,count(*) from order_details od
join pizzas p on p.pizza_id=od.pizza_id
group by size
order by count(*) desc
Limit 1




-- select top 5 ordered pizza types and their quantities
select * from
(select pizza_type_id,sum(quantity) as total_quantity from
pizzas p 
join order_details od
on p.pizza_id=od.pizza_id
group by pizza_type_id)p
order by total_quantity DESC
LIMit 5




-- make a table for total quantity of each pizza ordered and also for each size (id)
select p.pizza_id,pizza_type_id,sum(quantity) as total_ordered from pizzas p
join order_details od 
on od.pizza_id=p.pizza_id
group by p.pizza_id,pizza_type_id
order by sum(quantity)




-- make a table for total quantity of each pizza(name) ordered and also for each size

select pt.name,sum(quantity) as total_order from pizza_types pt
join pizzas p on p.pizza_type_id=pt.pizza_type_id
join order_details od on od.pizza_id=p.pizza_id
group by pt.name
order by sum(quantity) desc




-- total quantity for each pizza category

select pt.category,sum(quantity) as total_order from pizza_types pt
join pizzas p on p.pizza_type_id=pt.pizza_type_id
join order_details od on od.pizza_id=p.pizza_id
group by pt.category
order by sum(quantity) desc





-- determine the distributions of othe orders by hour of the day
-- sol1
select left(time,2) as time ,count(*) as total_order  from orders
group by left(time,2)
order by left(time,2) asc


-- sol2
select hour(time),count(*) as total_order from orders
group by hour(time)
order by hour(time) asc




-- category wise pizza type

select category , count(name) from pizza_types group by category



-- total pizza sales per day 
select date,sum(quantity) as total_quantity_sell
from order_details od join
orders o on o.order_id=od.order_id
group by  date
order by date asc



-- average sales per day
select round(avg (total_quantity_sell),0) as  Daily_Average_Sell from
(select date,sum(quantity) as total_quantity_sell
from order_details od join
orders o on o.order_id=od.order_id
group by  date
order by date asc)k                                      -- 138



-- top  3 ordered pizza type based on revenue
select pizza_type_id,round(sum(price*quantity),1) as Total_Revenue from pizzas p
join order_details od
on od.pizza_id=p.pizza_id
group by pizza_type_id
order by  Total_Revenue DESC
limit 3



-- top  3 ordered pizza name based on revenue
select name,round(sum(price*quantity),0) as Total_Revenue from pizzas p
join order_details od
on od.pizza_id=p.pizza_id
join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
group by name
order by  Total_Revenue DESC
limit 3
        
        
 -- percentage contribution of each pizza in total revenue (name)
 select name,type_wise_revenue, round(((type_wise_revenue)/(Total_revenue))*100,1) as Portion from
(select *,sum(type_wise_revenue) over() as Total_revenue from( 
select name,round(sum(price*quantity),0) as type_wise_revenue
from pizzas p
join order_details od
on od.pizza_id=p.pizza_id
join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
group by name)k)p
 order by Portion desc
 
 
 
  -- percentage contribution of each pizza in total revenue (Category)
  
select category,type_wise_revenue, round(((type_wise_revenue)/(Total_revenue))*100,1) as Portion from
(select *,sum(type_wise_revenue) over() as Total_revenue from( 
select category,round(sum(price*quantity),0) as type_wise_revenue
from pizzas p
join order_details od
on od.pizza_id=p.pizza_id
join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
group by category)k)p
 order by Portion desc
 
 
 
 -- cumulative revenue over time
 
 select *, round(sum(Total_Revenue) over(order by date asc rows between unbounded preceding and current row),1) as Cumulative_Revenue from
(select date,round(sum(price*quantity),1) as Total_Revenue from order_details od
join orders o on o.order_id=od.order_id
join pizzas p on p.pizza_id=od.pizza_id
 group by  date
 order by date ASC)k
 
 
 
 -- determine top 3 most ordered pizza type based revenue for each category 
 
 select * from
 (select * ,dense_rank()over(partition by category order by Revenue Desc) as ranking 
 from
 (select category,p.pizza_type_id,round(sum(price*quantity),1) as Revenue  from order_details od 
 join pizzas p on p.pizza_id=od.pizza_id 
 join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
 group by  category,p.pizza_type_id)k)p
 where p.ranking<4
 
 
-- quarter wise sell analysis

with date as(
select *,
CASE
	when quarter(date)=1 then'Q-1'
    when quarter(date)=2 then'Q-2'
    when quarter(date)=3 then'Q-3'
    else 'Q-4'
End as Quarter
from orders)

select Quarter,round(sum(price*quantity),1) as Quarter_wise_Revenue  from
order_details od 
join date d on d.order_id=od.order_id
join pizzas p on p.pizza_id=od.pizza_id
 group by Quarter
 
 -- quarter wise best selling pizza based on revenue
with date as(
select *,
CASE
	when quarter(date)=1 then'Q-1'
    when quarter(date)=2 then'Q-2'
    when quarter(date)=3 then'Q-3'
    else 'Q-4'
End as Quarter
from orders)
 
 select Quarter,name,Revenue from
 (select * ,dense_rank()over (partition by Quarter order by Revenue Desc) as rnk from
 (select Quarter,name,round(sum(quantity*price),1) as Revenue
 from pizzas p
 join order_details od  on od.pizza_id=p.pizza_id
 join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
 join date d on d.order_id=od.order_id
 group by Quarter,name)k)p
 where p.rnk<2
 


-- time wise selling average in a day

with days as(
 select * ,
 case
	when left(time,2)<12 then 'Morning'
    when left(time,2)>=12 and left(time,2)<15  then 'Noon'
    when left(time,2)>=15 and left(time,2)<18  then 'After Noon'
    when left(time,2)>=18 and left(time,2)<20  then 'Evening'
    else 'Night'
    end as Time_Portion
from orders)

select Time_Portion,Total_Revenue,round((Total_Revenue/day_no),0) as Average_Revenue from
(select Time_Portion,round(sum(price*quantity),0) as Total_Revenue,count(Distinct date) as day_no from days d
join order_details od on od.order_id=d.order_id
join pizzas p on p.pizza_id=od.pizza_id
group by Time_Portion)k                                
--  So, most selling hour is Noon and after noon [12-18]

 
 
 -- best demanding pizza according to time in a day based on order
 with days as(
 select * ,
 case
	when left(time,2)<12 then 'Morning'
    when left(time,2)>=12 and left(time,2)<15  then 'Noon'
    when left(time,2)>=15 and left(time,2)<18  then 'After Noon'
    when left(time,2)>=18 and left(time,2)<20  then 'Evening'
    else 'Night'
    end as Time_Portion
from orders)
 
 select Time_Portion,name,Order_quantity from
 
 (select *,dense_rank() over(partition by Time_Portion order by Order_quantity desc) as rnk from
 (select Time_Portion,name,sum(quantity) as Order_quantity from days d
 join order_details od on od.order_id=d.order_id
 join pizzas p on p.pizza_id=od.pizza_id
 join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
 group by Time_Portion,name)k)p
 where p.rnk=1
 
 
 
-- highest revenue in a single order
 select max(Revenue) as Highest_Revenue_from_a_single_order from
 (select order_id,sum(price*quantity) as Revenue from order_details od
 join pizzas p on p.pizza_id=od.pizza_id
 group by order_id)p
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 