
/* Exercise 1

	• Insert a new record in the customers table using the graphical tool offered
	  by MySQL Workbench. The data must be the following:

Field								Value
	customerNumber						500
	customerName						Stellar Tech Ltd.
	contactLastName						Rivers
	contactFirstName					Julia
	phone								+34 600123456
	addressLine1						99 Innovation Rd.
	addressLine2						NULL
	city								Barcelona
	state								NULL
	postalCode							08018
	country								Spain
	salesRepEmployeeNumber				1056
	creditLimit							75000.00
    
	• Insert a new record into the employees table using the graphical tool. The data
	  must be:

Field								Value	
	employeeNumber						2001
	lastName							Ortega
	firstName							Marc
	extension							x201
	email								marc.o@classicmodels.com
	officeCode							1
	reportsTo							1002
	jobTitle							Sales Rep
    
You must provide screenshots of the data insertion process and the moment before
applying the changes. Describe each capture briefly. */


/* Execise 2 
Insert the following payments into the payments table using SQL statements:

customerNumber		checkNumber			paymentDate			amount
		124				H123				2024-02-06			845.00
		151				H124				2024-02-07			70.00
		112				H125				2024-02-05			1024.00

Copy the SQL statements you used in your submission. Only include the data shown. */

USE classicmodels;

INSERT INTO payments VALUES (124, 'H123', '2024-02-06', 845.00);

INSERT INTO payments VALUES(151, 'H124', '2024-02-07', 70.00);

INSERT INTO payments VALUES(112, 'H125', '2024-02-05', 1024.00);


/* Exercise 3
Modify the addresses of some customers using the graphical tool, and provide
screenshots showing the changes made. Update the records in the customers table as
follows:

customerNumber		city			addressLine1			postalCode
		141			    Girona			43 State St				17001
		124			    Lleida			2 Walls St				25002
		119			    Tarragona		46 Marlborough Rd.		43003 */


/* Exercise 4
Cancel the order made on 2003-09-28, using SQL instructions. Change the status to
'Cancelled', the shippedDate to the current date, and comments to 'Order cancelled due
to delay'. Do this using a single SQL statement.
Copy the statement in your submission. */

UPDATE orders 
SET `status` = 'Cancelled', shippedDate = curdate(), comments = 'Order cancelled due to delay'
WHERE orderDate = '2003-09-28';
        
        
/* Exercise 5
Update all product names of type Trains to include the product code in parentheses. For
example, a product with productCode = S10_1949 and productName = "Vintage Train"
will become:

	"Vintage Train (code S10_1949)"

Do this with a single SQL statement using the proper MySQL functions.

Resource: MySQL functions - W3Schools */

UPDATE products 
SET	productName = concat(productName, ' (', productCode, ')')
WHERE productLine = 'Trains';

-- Note: I wasn’t completely sure if we had to also include the word “code” as well as part of the final result, so I made a statement without it. 
-- Otherwise, the statement would be:

UPDATE products 
SET    productName = concat(productName, ' (code ', productCode, ')')
WHERE productLine = 'Trains';


/* Exercise 6
Increase buyPrice and MSRP of all products with quantityInStock > 500 by 0.02%.
Do this with one SQL statement. */

UPDATE products 
SET buyPrice = round(buyPrice * 1.0002, 2), MSRP = round(MSRP * 1.0002, 2)
WHERE quantityInStock > 500;


/* Exercise 7
Remove all payments made by customers who are represented by employees with the
last name 'Patterson'.

Use a single SQL statement and copy it for the task delivery. */

DELETE FROM payments 
WHERE customerNumber IN ( SELECT c.customerNumber 
						  FROM customers c 
						  JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
						  WHERE e.lastName = 'Patterson');


/* Exercise 8
Delete all customers from Lisbon who have not made any payment.

Use one SQL statement only. */

DELETE FROM customers 
WHERE city = 'Lisbon' 
AND NOT EXISTS ( SELECT customerNumber 
				 FROM payments 
                 WHERE customers.customerNumber = payments.customerNumber);


/* Exercise 9
Add all customers as new employees, using their contact names as first and last name.
Use customerNumber + 2000 as the new employeeNumber, leave all other fields as
'x0000' extension, 'new@company.com' email,'1' officeCode, 'Sales Rep' jobTitle

Use contactFirstName as firstName, contactLastName as lastName.

Do this with a single SQL statement. */

INSERT INTO employees
	(employeeNumber, lastName, firstName, extension, email, officeCode, jobTitle)
SELECT 
	(customerNumber + 2000), contactLastName, contactFirstName, 'x0000', 'new@company.com', '1', 'Sales Rep'
FROM customers;


/* Exercise 10
Cancel all orders made by customers handled by the customer Elizabeth Lincoln.

Change the status to 'Cancelled', shippedDate to the current date, and comments to
'Order cancelled by management'.

Use a single SQL statement. */

UPDATE orders
SET `status` = 'Cancelled', shippedDate = curdate(), comments = 'Order cancelled by management'
WHERE customerNumber IN ( SELECT customerNumber
						  FROM customers c
                          JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
                          WHERE e.firstName = 'Elizabeth'
                          AND e.lastName= 'Lincoln');

