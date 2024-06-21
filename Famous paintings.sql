SELECT 
    *
FROM
    famous_paintings.work
WHERE
    museum_id IS NULL;

SELECT 
    *
FROM
    museum m
WHERE
    NOT EXISTS( SELECT 
            1
        FROM
            work w
        WHERE
            w.museum_id = m.museum_id);

SELECT 
    *
FROM
    product_size
WHERE
    sale_price > regular_price;
    
SELECT 
    *
FROM
    product_size
WHERE
    sale_price < (regular_price * 0.5);

#Which canva size costs the most?

SELECT cs.label AS canva, ps.sale_price
FROM (
    SELECT *,
           RANK() OVER (ORDER BY sale_price DESC) AS rnk
    FROM product_size
) ps
JOIN canvas_size cs ON cs.size_id = ps.size_id 
WHERE ps.rnk = 1;

# Fetch the top 10 most famous painting subject

select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;

SELECT DISTINCT
    m.name AS museum_name, m.city, m.state, m.country
FROM
    museum_hours mh
        JOIN
    museum m ON m.museum_id = mh.museum_id
WHERE
    day = 'Sunday'
        AND EXISTS( SELECT 
            1
        FROM
            museum_hours mh2
        WHERE
            mh2.museum_id = mh.museum_id
                AND mh2.day = 'Monday');

SELECT 
    COUNT(1)
FROM
    (SELECT 
        museum_id, COUNT(1)
    FROM
        museum_hours
    GROUP BY museum_id
    HAVING COUNT(1) = 7) x;

#Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

	select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;
    
    #Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;

#Display the 3 least popular canva sizes

SELECT label, ranking, no_of_paintings
FROM (
    SELECT cs.size_id, cs.label, COUNT(*) AS no_of_paintings,
           DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
    FROM work w
    JOIN product_size ps ON ps.work_id = w.work_id
    JOIN canvas_size cs ON CAST(cs.size_id AS CHAR) = ps.size_id
    GROUP BY cs.size_id, cs.label
) x
WHERE x.ranking <= 3;


#Which museum has the most no of most popular painting style?

	with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;


#Identify the artists whose paintings are displayed in multiple countries

	WITH cte AS (
    SELECT DISTINCT a.full_name AS artist, m.country
    FROM work w
    JOIN artist a ON a.artist_id = w.artist_id
    JOIN museum m ON m.museum_id = w.museum_id
)
SELECT artist, COUNT(*) AS no_of_countries
FROM cte
GROUP BY artist
HAVING COUNT(*) > 1
ORDER BY no_of_countries DESC;



#Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.

WITH cte_country AS (
    SELECT country, COUNT(*) AS country_count,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk_country
    FROM museum
    GROUP BY country
),
cte_city AS (
    SELECT city, COUNT(*) AS city_count,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk_city
    FROM museum
    GROUP BY city
)
SELECT 
    (SELECT GROUP_CONCAT(DISTINCT country) FROM cte_country WHERE rnk_country = 1) AS top_countries,
    (SELECT GROUP_CONCAT(DISTINCT city) FROM cte_city WHERE rnk_city = 1) AS top_cities;



# Which country has the 5th highest no of paintings?

	with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;


#Which are the 3 most popular and 3 least popular painting styles?

	with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;


# Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.

	select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	
