USE classicmodels;

/* 1. What is the purchase price, quantity in stock, and product name of the product with
the highest purchase price? */

SELECT 
    buyPrice AS `Purchase Price`,
    quantityInStock AS `Quantity in Stock`,
    productName AS `Product Name`
FROM
	products
WHERE 
	buyPrice = (
		SELECT 
			MAX(buyPrice)
        FROM
            products);

/* 2. Show customers living on a Lane (with an address containing 'Lane' or 'Ln.') and
whose credit limit is greater than 80,000. */

SELECT 
    *
FROM
    customers
WHERE
    (addressLine1 LIKE '%Lane%' OR addressLine1 LIKE '%Ln.%')
    AND 
    creditLimit > 80000; 

/* 3. Show products (name and code) along with the number of orders they are included
in, only if the product is in more than 50 orders. Then, display products in descending
order by the number of orders. */

SELECT
	p.productName AS `Name`,
    p.productCode AS `Code`,
    COUNT(DISTINCT od.orderNumber) AS `# of Orders`
FROM
	orderdetails od
JOIN
	products p ON od.productCode = p.productCode
GROUP BY
	p.productName,
	p.productCode
HAVING
	COUNT(DISTINCT od.orderNumber) > 50
ORDER BY 
	`# of Orders` DESC;

/* 4. Find the customer name, customer number, and payment amount for those payments
made in 2005 with an amount greater than 100,000. */

SELECT 
	c.customerName AS `Customer Name`,
    c.customerNumber AS `Customer #`,
    p.amount AS `Payment Amount`
FROM 
	payments p
JOIN
	customers c ON p.customerNumber = c.customerNumber
WHERE
	YEAR(p.paymentDate) = 2005
    AND
    p.amount > 100000;

/* 5. Find the customer name and payment date of customers who made payments
managed by employees assigned to the San Francisco office. Sort results by payment
date. */

SELECT 
	c.customerName AS `Customer Name`,
    p.paymentDate AS `Payment Date`
FROM
	payments p
JOIN
	customers c ON p.customerNumber = c.customerNumber
JOIN
	employees e ON c.salesRepEmployeeNumber = e.employeeNumber
JOIN
	offices o ON e.officeCode = o.officeCode
WHERE
	o.city = 'San Francisco'
ORDER BY
	p.paymentDate;
    
/* 6. Find the name and customer number for those who made payments one day before
or after 2004-11-16. */

SELECT
	c.customerName AS `Customer Name`,
    c.customerNumber AS `Customer #`
FROM
	payments p
JOIN
	customers c ON p.customerNumber = c.customerNumber
WHERE
	p.paymentDate IN ('2004-11-15', '2004-11-17'); 
	
-- (p.paymentDate = '2004-11-15' OR p.paymentDate = '2004-11-17');
-- DATE_ADD() DATE_SUB() (?)
    
/* 7. Find all products (all fields) where the product line description contains the word
"Vintage" and the product description contains the word "tires." */

SELECT
	p.*
FROM
	productlines pl
JOIN
	products p ON pl.productLine = p.productLine
WHERE
	(pl.textDescription LIKE '%Vintage%' AND p.productDescription LIKE '%tires%');
    
/* 8. Show the office name (with alias department) and the employee's name for those
employees who has not any customers assigned and whose office is in Japan. */

SELECT 
	o.city AS `Department`,
    CONCAT(e.firstName, ' ', e.lastName) AS `Employee Name`
FROM
	offices o
JOIN
	employees e ON o.officeCode = e.officeCode
LEFT JOIN 
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
WHERE 
	c.customerNumber IS NULL 
    AND 
    o.country = 'Japan';
    
/* 9. Find all data of employees belonging to office with code 6 whose customers have not
made any payment. */

SELECT 
	e.*
FROM 
	employees e
LEFT JOIN
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN
	payments p ON c.customerNumber = p.customerNumber
WHERE
    e.officeCode = 6
GROUP BY 
	e.employeeNumber 
HAVING
	COUNT(p.paymentDate) = 0;

/* 10. Show the name of the office (as department) and the number of employees in each
office, ordering results from highest to lowest number of employees. */

SELECT 
	o.city AS `Department`,
    COUNT(DISTINCT e.employeeNumber) AS `# of Employees`
FROM 
	offices o
JOIN
	employees e ON o.officeCode = e.officeCode
GROUP BY
	o.officeCode 
ORDER BY 
	`# of Employees` DESC;

/* 11. Show the number of orders placed each month of the year, ordered from January to
December. */

SELECT 
	MONTHNAME(orderDate) AS `Month`,
	COUNT(*) AS `# of Orders`
FROM
	orders
-- WHERE YEAR(orderDate) = 2004 (?)
GROUP BY 
	MONTH(orderDate), `Month`
ORDER BY
	MONTH(orderDate);

/* 12. Find the employee number, first name, and last name of employees managing
customers with payments exceeding 100,000 euros, ordering employees by
employeeNumber. */

SELECT DISTINCT
	e.employeeNumber,
    e.firstName, 
    e.lastName
FROM 
	employees e
JOIN
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN
	payments p ON c.customerNumber = p.customerNumber
WHERE 
	p.amount > 100000
ORDER BY
	e.employeeNumber;

/* 13. Show employees from the USA who do not have assigned customers. */

SELECT 
	e.*
FROM 
	offices o
JOIN
	employees e ON o.officeCode = e.officeCode
LEFT JOIN 
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
WHERE
	o.country = 'USA'
    AND
    c.salesRepEmployeeNumber IS NULL;

/* 14. How many years have passed since the older orders was placed? Show the order
number, customer number, and the years passed as antiquity. */

SELECT
	orderNumber,
	customerNumber,
    TIMESTAMPDIFF(YEAR, orderDate, CURDATE()) AS `Antiquity`
FROM 
	orders
WHERE
	orderDate = (
		SELECT 
			MIN(orderDate) 
        FROM 
			orders
	);

/* 15. Show the total number of payments, the minimum amount, and the maximum
amount among all payments. */

SELECT 
	COUNT(checkNumber) AS `# of Payments`,
    MIN(amount) AS `Minimum amount`,
    MAX(amount) AS `Maximum amount`
FROM
	payments;

/* 16. Find the employee ID, first name, and number of customers managed by each
employee, only for employees with assigned customers that made payments below
3,000 euros. */

SELECT 
	e.employeeNumber, 
    e.firstName,
    COUNT(DISTINCT c.customerNumber) AS `Customers`
FROM
	payments p
JOIN
	customers c ON p.customerNumber = c.customerNumber
JOIN
	employees e ON c.salesRepEmployeeNumber = e.employeeNumber
WHERE
	p.amount < 3000
GROUP BY
	e.employeeNumber, e.firstName
ORDER BY
	`Customers` DESC;

/* 17. Select payments (check number and amount) of customers managed by employees
in the NYC office, classifying them by amount as:
Over 50,000: 'Very high payment'
Between 15,000 and 50,000: 'Medium payment'
Less than 15,000: 'Low payment' */

SELECT 
	p.checkNumber AS `Payment`,
    p.amount AS `Amount`,
    CASE
		WHEN p.amount > 50000 THEN 'Very high payment'
        WHEN p.amount >= 15000 THEN 'Medium payment'
        ELSE 'Low payment'
	END AS `Category`
FROM
	offices o 
JOIN
	employees e ON o.officeCode = e.officeCode
JOIN
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN
	payments p ON c.customerNumber = p.customerNumber
WHERE
	o.state = 'NY'
ORDER BY 
	`Category` DESC;

/* 18. Show a list with the branch name (city), first name, and last name of employees
working there, ordered by branch and last name. */

SELECT 
	o.city AS `Branch`,
    e.firstName AS `First Name`,
    e.lastName AS `Last Name`
FROM
	offices o
JOIN
	employees e ON o.officeCode = e.officeCode
ORDER BY 
	o.city, e.lastName;

/* 19. Show the office name of employees who have managed orders placed by the
customer "Atelier graphique." */

SELECT 
	o.city AS `Office`,
    e.firstName AS `First Name`,
    e.lastName AS `Last Name`
FROM 
	customers c
JOIN
	employees e ON c.salesRepEmployeeNumber = e.employeeNumber
JOIN
	offices o ON e.officeCode = o.officeCode
WHERE
	c.customerName = 'Atelier graphique';

/* 20. Show the first name, last name, and job title of employees who do not have the title
"Sales Rep." Add a column with their boss's full name. Employees without a boss
should also be listed. */

SELECT 
	e.firstName AS `First Name`,
    e.lastName AS `Last Name`,
    e.jobTitle AS `Job Title`,
    CONCAT(eb.firstName, ' ', eb.lastName) AS `Boss`
FROM
	employees e
LEFT JOIN 
	employees eb ON e.reportsTo = eb.employeeNumber
WHERE 
	e.jobTitle != 'Sales Rep';

/* 21. Show the name of all offices and the total amount of money in orders managed by
employees in each office. */

SELECT 
	o.city AS `Office`,
    SUM(p.amount) AS `Total Money`
FROM
	offices o 
JOIN
	employees e ON o.officeCode = e.officeCode
JOIN
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN
	payments p ON c.customerNumber = p.customerNumber
GROUP BY 
	o.city
ORDER BY
	`Total Money` DESC;

/* 22. Show the name of Japanese customers who bought products of the "Classic Cars"
product line, and the first and last name of the employees who assigned to them. */

SELECT DISTINCT
	c.customerName,
    e.firstName,
    e.lastName
FROM
	employees e
JOIN 
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN
	orders o ON c.customerNumber = o.customerNumber
JOIN
	orderdetails od ON o.orderNumber = od.orderNumber
JOIN
	products p ON od.productCode = p.productCode
WHERE
	p.productLine = 'Classic Cars'
    AND
    c.country = 'Japan';

/* 23. Show the cities of offices (as office_city) that have at least one employee with five
assigned customers. */

SELECT DISTINCT
	o.city AS `office_city`
FROM 
	offices o
JOIN
	employees e ON o.officeCode = e.officeCode
WHERE e.employeeNumber IN ( 
	SELECT
		salesRepEmployeeNumber
	FROM
		customers 
		GROUP BY
		salesRepEmployeeNumber
	HAVING COUNT(customerNumber) = 5
);

/* 24. Show the order number and date of orders for products of type "Planes," placed by
customers who have made exactly two orders and with orders in May 2024. */

SELECT DISTINCT
	o.orderNumber,
    o.orderDate
FROM
	orders o
JOIN
	orderdetails od ON o.orderNumber = od.orderNumber
JOIN
	products p ON od.productCode = p.productCode
WHERE 
	p.productLine = 'Planes'  
    AND
    o.orderDate BETWEEN '2004-05-01' AND '2004-05-31'
	AND o.customerNumber IN (
		SELECT
			customerNumber
		FROM
			orders
		GROUP BY
			customerNumber
		HAVING
			COUNT(*) = 2
    );
    
/* 25. How many customers are there for each combination of office city and order status?*/

SELECT 
	COUNT(DISTINCT c.customerNumber) AS `Customers`,
    o.city AS `Office`,
    ord.`status` AS `Order Status`
FROM
	offices o 
JOIN
	employees e ON o.officeCode = e.officeCode
JOIN
	customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN
	orders ord ON c.customerNumber = ord.customerNumber
GROUP BY
	o.city, ord.`status`;
