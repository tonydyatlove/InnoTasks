-- 1. Вывести количество фильмов в каждой категории, отсортировать по убыванию.
select category.name, count(film_id) as amount_in_each_category
from film_category
join category on film_category.category_id = category.category_id 
group by name
order by amount_in_each_category desc

--2. Вывести 10 актеров, чьи фильмы больше всего арендовали, отсортировать по убыванию.
select first_name, last_name, count(rental_id) as amount_of_rental_films
from rental 
left join inventory on rental.inventory_id = inventory.inventory_id 
join film_actor on inventory.film_id = film_actor.film_id 
left join actor on film_actor.actor_id = actor.actor_id 
group by actor.actor_id 
order by amount_of_rental_films desc
limit 10

--3. Вывести категорию фильмов, на которую потратили больше всего денег.
select category.name, sum(replacement_cost) as most_expensive_category
from film
left join film_category on film.film_id = film_category.film_id 
join category on film_category.category_id = category.category_id
group by category.name
order by most_expensive_category desc
limit 1

--4. Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.
select title  
from film 
left join inventory on film.film_id = inventory.film_id
where inventory.film_id is null 

--5. Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”.
--Если у нескольких актеров одинаковое кол-во фильмов, вывести всех.
with ranked as
(select actor.first_name, actor.last_name, 
dense_rank() over (order by count(actor.actor_id) desc) as rank
from category 
join film_category on category.category_id = film_category.category_id 
join film_actor on film_category.film_id = film_actor.film_id 
left join actor on film_actor.actor_id = actor.actor_id 
where category.name = 'Children'
group by actor.actor_id) 
select ranked.first_name, ranked.last_name, rank
from ranked
where rank <= 3

--6. Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). 
--Отсортировать по количеству неактивных клиентов по убыванию.
select city.city, count(case when customer.active = 0 then 1 end) as amount_of_unactive,
count(case when customer.active = 1 then 1 end) as amount_of_active
from customer 
join address on customer.address_id = address.address_id 
join city on address.city_id = city.city_id 
group by city.city  
order by amount_of_unactive desc, amount_of_active desc

--7. Вывести категорию фильмов, у которой самое большое кол-во часов 
--суммарной аренды в городах (customer.address_id в этом city), 
--и которые начинаются на букву “a”. 
--То же самое сделать для городов в которых есть символ “-”. 
--Написать все в одном запросе.
select s.category_name, max(sum_hours) as max_rental_sum
from ((select category.name as category_name, sum(rental.return_date - rental.rental_date) as sum_hours
from category 
join film_category on category.category_id = film_category.category_id 
join inventory on film_category.film_id = inventory.film_id 
join rental on inventory.inventory_id = rental.inventory_id 
join customer on rental.customer_id = customer.customer_id 
join address on customer.address_id = address.address_id 
join city on address.city_id = city.city_id 
where starts_with(city.city, 'a') 
group by category.name 
order by sum_hours desc
limit 1)
union 
(select category.name as category_name, sum(rental.return_date - rental.rental_date) as sum_hours
from category 
join film_category on category.category_id = film_category.category_id 
join inventory on film_category.film_id = inventory.film_id
join rental on inventory.inventory_id = rental.inventory_id 
join customer on rental.customer_id = customer.customer_id 
join address on customer.address_id = address.address_id 
join city on address.city_id = city.city_id 
where city.city like '%-%' 
group by category.name
order by sum_hours desc
limit 1
)) as s 
group by s.category_name


--если в 7 запросе использовать CTE, то в блоке with необходимо доставать данные с названиями городов,
--однако этот скрипт работать не будет, т.к. просит, чтобы столбец city был в group by или агрегатной функции.
--Если же мы засунем city в группировку или агрегатную функцию, то мы сможем получить доступ к городам,
--но не сможем получить правильно посчитанную сумму. А просто так обратиться к названию города в блоках с фильтрацией 
--мы не сможем (через category_with_max_rental.city), т.к. не доставали данные city в блоке with.
--А если достанем, то наткнёмся на проблему, описанную выше. Уверен, что есть какой-то другой более оптимальный способ
--выполнить этот запрос. Хотелось бы узнать какой)

--with category_with_max_rental as (
--select category.name, city.city, sum(rental.return_date - rental.rental_date) as sum_hours
--from category 
--join film_category on category.category_id = film_category.category_id 
--join inventory on film_category.film_id = inventory.film_id
--join rental on inventory.inventory_id = rental.inventory_id 
--join customer on rental.customer_id = customer.customer_id 
--join address on customer.address_id = address.address_id 
--join city on address.city_id = city.city_id 
--group by category.name
--order by sum_hours desc 
----limit 1
--),
--cities as (
--select category.name, city.city
--from category 
--join film_category on category.category_id = film_category.category_id 
--join inventory on film_category.film_id = inventory.film_id
--join rental on inventory.inventory_id = rental.inventory_id 
--join customer on rental.customer_id = customer.customer_id 
--join address on customer.address_id = address.address_id 
--join city on address.city_id = city.city_id 
--)

--select max(category_with_max_rental.sum_hours)--category_with_max_rental.city, category_with_max_rental.name, 
--from category_with_max_rental
--right join cities on category_with_max_rental.name = cities.name
--where cities.city like 'a%'
--union
--(select max(category_with_max_rental.sum_hours)
--from category_with_max_rental
--where category_with_max_rental.city like '%-%')
