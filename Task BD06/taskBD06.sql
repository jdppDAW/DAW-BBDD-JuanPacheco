USE classicmodels;

/*
Exercise 1

An employee cannot be inserted into the employees table if another employee with the title "Sales Manager" already exists 
in the same office. 
In other words, there can only be one "Sales Manager" per office (officeCode). 

If a new employee with the title "Sales Manager" is inserted into an office that already has one, 
the trigger must throw an error with a message indicating that a "Sales Manager" already exists in that office. 
The trigger only prevents insertion and does not handle updates. 
*/

DROP TRIGGER IF EXISTS unique_manager;

DELIMITER $$

CREATE TRIGGER unique_manager
BEFORE INSERT ON employees 
FOR EACH ROW	
BEGIN
	IF NEW.jobTitle LIKE 'Sales Manager%' 
		AND EXISTS(
			SELECT 1
			FROM employees
			WHERE officeCode = NEW.officeCode
			AND jobTitle LIKE 'Sales Manager%')
	THEN 
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Only one Sales Manager is allowed per office';
    END IF;
END$$

DELIMITER ;

-- testing insertion into an office without Sales Manager 

INSERT INTO employees(employeeNumber,lastName,firstName,extension,email,officeCode,reportsTo,jobTitle) 
VALUES (2056,'Patterson','Mary','x4611','mpatterso@classicmodelcars.com','3',1002,'Sales Manager');

-- testing insertion into an office with a Sales Manager

INSERT INTO employees(employeeNumber,lastName,firstName,extension,email,officeCode,reportsTo,jobTitle) 
VALUES (3056,'Patterson','Mary','x4611','mpatterso@classicmodelcars.com','1',1002,'Sales Manager');

/*
Exercise 2

A customer cannot have more than 3 active orders (statuses 'In Process', 'On Hold', or 'Shipped') at any given time. 
Create a trigger that checks this condition before inserting into the orders table, throwing an error with 
a custom message if the customer attempts to create a fourth active order. Demonstrate how to test the trigger. 
*/

DROP TRIGGER IF EXISTS order_limit;

DELIMITER $$

CREATE TRIGGER order_limit
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
	DECLARE current_orders INT;
    
    SELECT COUNT(*)
    INTO current_orders
    FROM orders
    WHERE customerNumber = NEW.customerNumber
    AND `status` IN ('In Process', 'On Hold', 'Shipped');
    
	IF NEW.status IN ('In Process', 'On Hold', 'Shipped')
	AND current_orders >= 3
	THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A customer cannot have more than 3 active orders';
	END IF;
END$$

DELIMITER ;

-- testing insertion of active orders: CUSTOMER 489 has 2 "Shipped orders so the INSERT should work once and then fail the second time 

SELECT * FROM orders WHERE customerNumber = 489;

INSERT INTO orders(orderNumber,orderDate,requiredDate,shippedDate,`status`,comments,customerNumber) 
VALUES (80100,'2003-01-06','2003-01-13','2003-01-10','Shipped',NULL,489);

INSERT INTO orders(orderNumber,orderDate,requiredDate,shippedDate,`status`,comments,customerNumber) 
VALUES (90100,'2003-01-06','2003-01-13','2003-01-10','Shipped',NULL,489);

/*
Exercise 3 
 
We want to ensure that every order placed has stock available in the inventory. 
Before inserting an order detail into the orderdetails table, verify that the product is in stock 
and that the requested quantity does not exceed the available stock (quantityInStock). 
If the product is not in stock or the requested quantity exceeds the stock, 
the trigger must throw an error with a descriptive message (different for each case). 
Demonstrate how to test the trigger. 

*/

DROP TRIGGER IF EXISTS has_stock;

DELIMITER $$

CREATE TRIGGER has_stock
BEFORE INSERT ON orderdetails
FOR EACH ROW
BEGIN
	DECLARE stock_count INT;
    
    SELECT quantityInStock
    INTO stock_count
    FROM products p 
    WHERE p.productCode = NEW.productCode;
    
	IF stock_count = 0
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The product must be in stock to place an order';
	ELSEIF stock_count < NEW.quantityOrdered 
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock to fulfill the order';
	END IF;

END$$

DELIMITER ;

-- testing trigger for orders above stock

INSERT INTO orders VALUES (90100,'2003-01-06','2003-01-13','2003-01-10','Shipped',NULL,487);

INSERT INTO orderdetails VALUES(90100, 'S24_2000', 14, '56.55', 1);
INSERT INTO orderdetails VALUES(90100, 'S24_2000', 55, '34.12', 1);

-- testing trigger for orders on products with 0 stock

INSERT INTO products VALUES('S90_9678','1969 Harley Davidson Ultimate Chopper','Motorcycles','1:10','Min Lin Diecast','This replica features working kickstand, front suspension, gear-shift lever, footbrake lever, drive chain, wheels and steering. All parts are particularly delicate due to their precise scale and require special care and attention.',0,'48.81','95.70');

INSERT INTO orderdetails VALUES(90100, 'S90_9678', 1, '34.12', 1);

/*
Exercise 4

Create a procedure named delete_employee to delete an employee from the employees table in classicmodels. Before deletion, ensure the following conditions are met: 
	1. Customers assigned to the employee must be reassigned to the employee's supervisor. 
	2. Employees supervised by the employee must be reassigned to the employee's supervisor. 
	3. If the employee has no supervisor (i.e., they are the president), they cannot be deleted, and a custom error must be returned. 
	   The procedure must accept the employeeNumber as a parameter and return a custom error if the employeeNumber does not exist. 

*/

DROP PROCEDURE IF EXISTS delete_employee;

DELIMITER $$ 

CREATE PROCEDURE delete_employee(IN employee INT)
BEGIN
	DECLARE supervisor INT;
    DECLARE employee_exists INT;
		
	SELECT COUNT(*)
    INTO employee_exists
    FROM employees
    WHERE employeeNumber = employee;
        
    IF employee_exists = 0 
	THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Employee does not exist.';
	ELSE
		SELECT reportsTo 
		INTO supervisor
		FROM employees
		WHERE employeeNumber = employee;   
			
        IF supervisor IS NULL
		THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'The employee is the President and cannot be deleted';
		ELSE			 
			UPDATE customers
			SET salesRepEmployeeNumber = supervisor
			WHERE salesRepEmployeeNumber = employee;
        
			UPDATE employees 
			SET reportsTo = supervisor
			WHERE reportsTo = employee;
                
            DELETE FROM employees
			WHERE employeeNumber = employee;
		END IF;
	END IF;
END$$
    
DELIMITER ;

-- testing procedure with an inexistent employee, the President and a real employee

CALL delete_employee(9999);

CALL delete_employee(1002);

CALL delete_employee(1056);

/*
Exercise 5

Create a procedure named customers_sales_report that accepts three parameters: 
	1. The office name (office_name) as an input parameter. 
	2. The year (year_param) as an input parameter. 
	3. An output parameter that returns a detailed report of monthly sales for the employees of that office during the specified year (based on orderDate). 

The report must include: 
	The full name of the employee. 
	The customer's name (customerName). 
	The total sales made by the employee for that customer during the year. 

If no sales are found, the procedure must return a message indicating that no data is available. 

*/

DROP PROCEDURE IF EXISTS customers_sales_report;

DELIMITER $$

CREATE PROCEDURE customers_sales_report(IN office_name varchar(50), IN year_param INT, OUT monthly_report LONGTEXT)
BEGIN
	IF NOT EXISTS(
		SELECT 1 
        FROM offices o
        JOIN employees e ON o.officeCode = e.officeCode
        JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
        JOIN orders ord ON c.customerNumber = ord.customerNumber
        JOIN orderdetails od ON ord.orderNumber = od.orderNumber
        WHERE o.city = office_name
        AND YEAR(ord.orderDate) = year_param
        )
    THEN
		SET monthly_report = CONCAT('No sales data available for office "', office_name, '" in year ', year_param, '.'); 
    ELSE
		SELECT GROUP_CONCAT(
					CONCAT('** Employee: ', full_name,
							'  ** Customer: ', customer,
							'  ** Total Sales: ', total_sales)
					SEPARATOR '\n'
                    )
		INTO monthly_report
		FROM (
			SELECT CONCAT(e.firstName, ' ', e.lastName) AS full_name,
				   c.customerName AS customer,
                   SUM(od.quantityOrdered * od.priceEach) AS total_sales
			FROM offices o
			JOIN employees e ON o.officeCode = e.officeCode
			JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
			JOIN orders ord ON c.customerNumber = ord.customerNumber
			JOIN orderdetails od ON ord.orderNumber = od.orderNumber
			WHERE o.city = office_name
			AND YEAR(ord.orderDate) = year_param
			GROUP BY e.employeeNumber, c.customerName)
		AS report;
	END IF;
END$$

DELIMITER ;

-- testing procedure with a test for London 2005 which holds sales and then with NYC 2006 which does not

CALL customers_sales_report('London', 2005, @report);

CALL customers_sales_report('NYC', 2006, @report);

SELECT @report;

/*
Exercise 6

Create a function that takes a customerNumber (customer ID) as a parameter 
and returns a string summarizing the number of orders and products purchased by that customer. 

*/

DROP FUNCTION IF EXISTS customer_summary;

DELIMITER $$

CREATE FUNCTION customer_summary(customerID INT) 
RETURNS LONGTEXT 
READS SQL DATA
BEGIN
	DECLARE total_orders INT;
    DECLARE total_products INT;
    
    SELECT COUNT(DISTINCT orderNumber)
    INTO total_orders
    FROM orders
    WHERE customerNumber = customerID;
    
    SELECT COUNT(DISTINCT productCode)
    INTO total_products
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    WHERE o.customerNumber = customerID;
    
    IF total_orders = 0
    THEN
		RETURN 'No orders or products';
    ELSE
		RETURN CONCAT(total_orders, ' order/s and ', total_products, ' product/s');
	END IF;
END$$

DELIMITER ;

-- test with a client with orders

SELECT customer_summary(103);

-- test with a client without orders

SELECT customer_summary(999);

-- test with multiple clients 

SELECT customerNumber, customerName, customer_summary(customerNumber) AS summary
FROM customers
ORDER BY customerNumber;
