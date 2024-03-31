/*Q1)Who is the senior most employee based on the job title?*/
SELECT * FROM music.employee;
select * from music.employee
order by levels desc
limit 1;

/* Q_2)Which countries have most invoice?*/
SELECT * FROM music.invoice;
select count(*) as c, billing_country
from music.invoice
group by billing_country
order by c desc;

/*Q3.What are the top 3 values of total invoice ?*/
SELECT * FROM music.invoice
order by total desc
limit 3;
/* Q.4)Which city has the best customer ? We would like to throw a promotional music Festival in the city
 we made the most money.Write a query that returns one city that has hilghest sum of invoice totals.
 Return both city name & sum of all invoice totals.*/
SELECT sum(total) as invoice_total ,billing_city FROM music.invoice
group by billing_city
order by invoice_total desc;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
SELECT customer.customer_id,
 customer.first_name, 
 customer.last_name ,
 sum(invoice.total) as total
FROM music.customer
JOIN music.invoice ON customer.customer_id = invoice.customer_id
group by customer.customer_id,
customer.first_name, 
customer.last_name 
order by total desc
limit 1;

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
SELECT distinct email,first_name,last_name 
FROM music.customer
JOIN music.invoice
ON customer.customer_id = invoice.customer_id
JOIN music.invoice_line
ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id in (
      select track_id from music.track
      JOIN music.genre
      ON track.genre_id = genre.genre_id
      WHERE genre.name LIKE 'Rock'
)
Order by email;
/* Q7: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
SELECT name,milliseconds FROM music.track
where milliseconds > (
      select avg(milliseconds) as avg_track_length
      from music.track
)
order by milliseconds desc;

/* Q8: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, 
    artist.name AS artist_name, 
    SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM music.invoice_line
	JOIN music.track ON track.track_id = invoice_line.track_id
	JOIN music.album2 ON album2.album_id = track.album_id
	JOIN music.artist ON artist.artist_id = album2.artist_id
	GROUP BY artist.artist_id, artist.name
    ORDER BY total_sales DESC
    LIMIT 1
)
SELECT c.customer_id,
 c.first_name,
 c.last_name,
 bsa.artist_name, 
 SUM(il.unit_price*il.quantity) AS amount_spent
FROM music.invoice  i
JOIN music.customer  c ON c.customer_id = i.customer_id
JOIN music.invoice_line  il ON il.invoice_id = i.invoice_id
JOIN music.track  t ON t.track_id = il.track_id
JOIN music.album2  alb ON alb.album_id = t.album_id
JOIN best_selling_artist  bsa ON bsa.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;

/* Q9: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM music.invoice_line 
	JOIN music.invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN music.customer ON customer.customer_id = invoice.customer_id
	JOIN music.track ON track.track_id = invoice_line.track_id
	JOIN music.genre ON genre.genre_id = track.genre_id
	GROUP BY customer.country, genre.name, genre.genre_id
	ORDER BY customer.country ASC, purchases DESC
)
SELECT * FROM popular_genre WHERE RowNo <= purchases;

/* Method 2: : Using Recursive */
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM music.invoice_line
		JOIN music.invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN music.customer ON customer.customer_id = invoice.customer_id
		JOIN music.track ON track.track_id = invoice_line.track_id
		JOIN music.genre ON genre.genre_id = track.genre_id
		GROUP BY customer.country, genre.name, genre.genre_id
		ORDER BY customer.country
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY country
		ORDER BY country)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* Q10: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method : using CTE */
WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM music.invoice
		JOIN music.customer ON customer.customer_id = invoice.customer_id
		GROUP BY customer.customer_id,first_name,last_name,billing_country
		ORDER BY billing_country ASC,total_spending DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= customer_id