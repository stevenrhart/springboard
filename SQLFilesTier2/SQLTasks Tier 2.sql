/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT name 
  FROM Facilities
 WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(*) AS no_cost_facilities
  FROM Facilities
 WHERE membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, 
	   name,
	   membercost,
	   monthlymaintenance
  FROM Facilities
 WHERE membercost < 0.2 * monthlymaintenance;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT * 
  FROM Facilities
 WHERE facid IN (1,5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name,
	   monthlymaintenance,
	   CASE WHEN monthlymaintenance <= 100 THEN 'cheap'
	   ELSE 'expensive' END AS maintenance_category
  FROM Facilities
 ORDER BY monthlymaintenance;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname, 
       surname
  FROM Members
 WHERE joindate 
    IN (SELECT MAX(joindate)
          FROM Members);


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT firstname,
       surname
  FROM Members
 WHERE memid 
    IN (SELECT DISTINCT(memid)
  		  FROM Bookings
 		 WHERE facid 
	 		IN (SELECT facid
     	  		  FROM Facilities
     	 		  WHERE name LIKE 'Tennis%'))
 ORDER BY firstname;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT b.bookid,
	   f.name as facility,
	   CONCAT(m.firstname, " ", m.surname) AS member,
	   CASE WHEN b.memid > 0 THEN b.slots * f.membercost
			ELSE b.slots * f.guestcost END AS totalcost
  FROM Facilities AS f
  JOIN Bookings AS b
    ON b.facid = f.facid
  JOIN Members AS m
    ON m.memid = b.memid
 WHERE starttime LIKE '2012-09-14%'
 GROUP BY bookid, facility, member
HAVING totalcost > 30
 ORDER BY totalcost DESC;


/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT bookid,
       facility,
       member,
       totalcost 
  FROM (SELECT b.bookid,
               f.name as facility,
               (m.firstname || " " || m.surname) AS member,
	       CASE WHEN m.memid = 0 THEN b.slots * f.guestcost
		    ELSE b.slots * f.membercost END AS totalcost
	  FROM Members AS m
	 INNER JOIN Bookings AS b
	    ON m.memid = b.memid
	 INNER JOIN Facilities AS f
	    ON b.facid = f.facid
	 WHERE b.starttime LIKE '2012-09-14%'
	) AS bookings
 WHERE totalcost > 30
 ORDER BY totalcost DESC;


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
SELECT sub2.facility,
       SUM(sub2.cost_by_type) AS totalrevenue
  FROM (SELECT sub.*,
	       CASE WHEN sub.memtype = 0 THEN sub.slots * sub.guestcost
	            ELSE sub.slots * sub.membercost END AS cost_by_type
         FROM (SELECT f.name AS facility,
                      f.membercost AS membercost,
       		      f.guestcost AS guestcost,
	   	      b.facid,
	              CASE WHEN b.memid = 0 THEN 0
	                   ELSE 1 END AS memtype,
	              SUM(b.slots) AS slots
                 FROM Bookings AS b
                INNER JOIN Facilities AS f
                   ON f.facid = b.facid
                GROUP BY f.name, f.membercost, f.guestcost, b.facid, memtype) AS sub
       ) AS sub2
 GROUP BY sub2.facility
HAVING totalrevenue < 1000
 ORDER BY totalrevenue DESC;


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT CONCAT(m3.surname, ", ", m3.firstname) AS member,
       CASE WHEN m3.recommendedby > 0 THEN m3.recommendedby
	    ELSE 0 END AS recommendedby,
       sub.recommender
  FROM Members AS m3
 INNER JOIN (SELECT m2.memid,
	       	    CONCAT(m2.surname, ", ", m2.firstname) AS recommender
  	       FROM Members as m2
 	      WHERE memid IN (SELECT DISTINCT(m1.recommendedby) 
  				FROM Members AS m1)
            ) AS sub
	 ON sub.memid = m3.recommendedby
 ORDER BY member;

/* Q12: Find the facilities with their usage by member, but not guests */
SELECT f.name,
       SUM(sub.num_slots) AS total_slots
  FROM Facilities f
 INNER JOIN (SELECT facid,
                    CASE WHEN memid = 0 THEN 0
                         ELSE slots END AS num_slots
               FROM Bookings) AS sub
         ON f.facid = sub.facid
 GROUP BY f.name
 ORDER BY total_slots DESC;

/* Q13: Find the facilities usage by month, but not guests */

SELECT f.name,
       sub.month,
       sub.total_slots
  FROM Facilities f
 INNER JOIN (SELECT DISTINCT(facid),
             	    SUBSTRING(starttime, 1, 7) AS month,
		    SUM(CASE WHEN memid = 0 THEN 0
			     ELSE slots END) AS total_slots
	      FROM Bookings
             GROUP BY facid, month) AS sub
	 ON f.facid = sub.facid
 GROUP BY f.name, sub.month
 ORDER BY f.name, sub.month;



