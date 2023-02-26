USE H_accounting;

DROP PROCEDURE IF EXISTS pl_statement;

DELIMITER $$

CREATE PROCEDURE pl_statement (IN calendaryear INT)

BEGIN

-- Declaring all the variables that are being used as a method of calculatino in the PL statement
DECLARE varREV 							DOUBLE DEFAULT 0;
DECLARE varRET 							DOUBLE DEFAULT 0;
DECLARE varCOGS  						DOUBLE DEFAULT 0;
DECLARE varGEXP 						DOUBLE DEFAULT 0;
DECLARE varSEXP 						DOUBLE DEFAULT 0;
DECLARE varOEXP 						DOUBLE DEFAULT 0;
DECLARE varOINC 						DOUBLE DEFAULT 0;
DECLARE varINCTAX 						DOUBLE DEFAULT 0;
DECLARE varOTHTAX						DOUBLE DEFAULT 0;
DECLARE varOTHINC						DOUBLE DEFAULT 0;
DECLARE varREVpreviousyear 				DOUBLE DEFAULT 0;
DECLARE varRETpreviousyear 				DOUBLE DEFAULT 0;
DECLARE varCOGSpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varGEXPpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varSEXPpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOEXPpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOINCpreviousyear				DOUBLE DEFAULT 0;
DECLARE varINCTAXpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOTHTAXpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varOTHINCpreviousyear 			DOUBLE DEFAULT 0;
DECLARE varREVyoy						DOUBLE DEFAULT 0;
DECLARE varRETyoy						DOUBLE DEFAULT 0;
DECLARE varCOGSyoy						DOUBLE DEFAULT 0;
DECLARE varGEXPyoy						DOUBLE DEFAULT 0;
DECLARE varSEXPyoy						DOUBLE DEFAULT 0;
DECLARE varOEXPyoy						DOUBLE DEFAULT 0;
DECLARE varOINCyoy						DOUBLE DEFAULT 0;
DECLARE varINCTAXyoy					DOUBLE DEFAULT 0;
DECLARE varOTHTAXyoy					DOUBLE DEFAULT 0;
DECLARE varOTHINCyoy					DOUBLE DEFAULT 0;
DECLARE varGPM							DOUBLE DEFAULT 0;
DECLARE varGPMpreviousyear				DOUBLE DEFAULT 0;
DECLARE varGPMperc						DOUBLE DEFAULT 0;
DECLARE varGPMpercpreviousyear			DOUBLE DEFAULT 0;
DECLARE varGPMyoy						DOUBLE DEFAULT 0;
DECLARE varNI							DOUBLE DEFAULT 0;
DECLARE varNIpreviousyear				DOUBLE DEFAULT 0;
DECLARE varNIyoy						DOUBLE DEFAULT 0;
DECLARE varREVt							DOUBLE DEFAULT 0;
DECLARE varREVtpreviousyear				DOUBLE DEFAULT 0;
DECLARE varREVtyoy						DOUBLE DEFAULT 0;
DECLARE varNIperc						DOUBLE DEFAULT 0;
DECLARE varNIpercpreviousyear			DOUBLE DEFAULT 0;
DECLARE varNIpercyoy					DOUBLE DEFAULT 0;

-- Dropping the table if it already exists
DROP TABLE IF EXISTS PL;

-- Creating the temporary table from which we will be querying the data from; its a table in which all the data is combined in one big table so that queries can be made shorter without all the joins for each individual query
CREATE TABLE PL AS (
		WITH 	acco AS (SELECT account_id, profit_loss_order, profit_loss_section_id
						FROM `account`),
                
                ss AS (SELECT statement_section_id, statement_section_code, statement_section, statement_section_order, debit_is_positive
						FROM statement_section),
                        
				jeli AS (SELECT journal_entry_id, account_id, IFNULL(debit,0) AS debit, IFNULL(credit,0) AS credit
						FROM journal_entry_line_item),
                        
				je AS 	(SELECT journal_entry_id, entry_date, journal_type_id, journal_entry_code, journal_entry, debit_credit_balanced, cancelled, audited, closing_type
						FROM journal_entry)

-- Joining all the tables together, so that we won't have to repeat this throughout the stored procedure
SELECT *
FROM acco
LEFT JOIN ss
	ON ss.statement_section_id = acco.profit_loss_section_id 
LEFT JOIN jeli
	USING (account_id)
LEFT JOIN je
	USING (journal_entry_id)
);

-- Below we calculate the each field of the PL statement using the variables which we declared in the section above

-- Revenues
SELECT 	SUM(credit) INTO varREV
FROM 	PL
WHERE 	statement_section_code = 'REV'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Revenues previous year
SELECT 	SUM(credit) INTO varREVpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'REV'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varREVyoy = IFNULL(((varREV - varREVpreviousyear)/varREVpreviousyear * 100),0);

-- Return, Refunds and Discounts
SELECT 	SUM(debit) INTO varRET
FROM 	PL
WHERE 	statement_section_code = 'RET'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Return, Refunds and Discounts previous year
SELECT 	SUM(debit) INTO varRETpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'RET'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varRETyoy = IFNULL(((varRET - varRETpreviousyear)/varRETpreviousyear * 100),0);

-- Cost of Goods and Services
SELECT 	SUM(debit) INTO varCOGS
FROM 	PL
WHERE 	statement_section_code = 'COGS'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Cost of Goods and Services previous year
SELECT 	SUM(debit) INTO varCOGSpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'COGS'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varCOGSyoy = IFNULL(((varCOGS - varCOGSpreviousyear)/varCOGSpreviousyear * 100),0);

-- Administrative Expenses
SELECT 	SUM(debit) - SUM(credit) INTO varGEXP
FROM 	PL
WHERE 	statement_section_code = 'GEXP'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Administrative Expenses pervious year
SELECT 	SUM(debit) - SUM(credit) INTO varGEXPpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'GEXP'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varGEXPyoy = IFNULL(((varGEXP - varGEXPpreviousyear)/varGEXPpreviousyear * 100),0);

-- Selling Expenses
SELECT 	SUM(debit) INTO varSEXP
FROM 	PL
WHERE 	statement_section_code = 'SEXP'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Selling Expenses previous year
SELECT 	SUM(debit) INTO varSEXPpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'SEXP'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varSEXPyoy = IFNULL(((varSEXP - varSEXPpreviousyear)/varSEXPpreviousyear * 100),0);

-- Other expenses
SELECT 	SUM(debit) INTO varOEXP
FROM 	PL
WHERE 	statement_section_code = 'OEXP'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Other expenses previous year
SELECT 	SUM(debit) INTO varOEXPpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'OEXP'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varOEXPyoy = IFNULL(((varOEXP - varOEXPpreviousyear)/varOEXPpreviousyear * 100),0);

-- Other income
SELECT 	SUM(debit) INTO varOTHINC
FROM 	PL
WHERE 	statement_section_code = 'OTHINC'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Other income previous year
SELECT 	SUM(debit) INTO varOTHINCpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'OTHINC'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varOTHINCyoy = IFNULL(((varOTHINC - varOTHINCpreviousyear)/varOTHINCpreviousyear * 100),0);

-- Income Tax
SELECT 	SUM(debit) INTO varINCTAX
FROM 	PL
WHERE 	statement_section_code = 'INCTAX'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Income Tax previous year
SELECT 	SUM(debit) INTO varINCTAXpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'INCTAX'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varINCTAXyoy = IFNULL(((varINCTAX - varINCTAXpreviousyear)/varINCTAXpreviousyear * 100),0);

-- Other Tax
SELECT 	SUM(debit) - SUM(credit) INTO varOTHTAX
FROM 	PL
WHERE 	statement_section_code = 'OTHTAX'
AND 	YEAR(entry_date) = calendaryear
AND 	cancelled = 0;

-- Other Tax previous year
SELECT 	SUM(debit) INTO varOTHTAXpreviousyear
FROM 	PL
WHERE 	statement_section_code = 'OTHTAX'
AND 	YEAR(entry_date) = calendaryear-1
AND 	cancelled = 0;

SET 	varOTHTAXyoy = IFNULL(((varOTHTAX - varOTHTAXpreviousyear)/varOTHTAXpreviousyear * 100),0);

-- This block includes all the formulas which are needed to do the necessary calculations within the PL statement
SET varGPM 					= IFNULL((varREV - varCOGS),0); 									
SET varGPMperc 				= IFNULL((varGPM / varREV) * 100,0);
SET varREVt 				= IFNULL(varREV,0) + IFNULL(varOINC,0) - IFNULL(varRET,0);
SET varGPMpreviousyear 		= IFNULL((varREVpreviousyear - varCOGSpreviousyear),0); 						
SET varGPMpercpreviousyear 	= IFNULL((varGPMpreviousyear / varREVpreviousyear) * 100,0);
SET varGPMyoy 				= IFNULL((varGPMperc - varGPMpercpreviousyear) / (varGPMpercpreviousyear) * 100,0);
SET varNI 					= IFNULL(varREVt,0) - IFNULL(varCOGS,0) - IFNULL(varGEXP,0) - IFNULL(varSEXP, 0) - IFNULL(varOEXP, 0) - IFNULL(varINCTAX,0) - IFNULL(varOTHTAX,0);
SET varREVtpreviousyear 	= IFNULL(varREVpreviousyear,0) + IFNULL(varOINCpreviousyear,0) - IFNULL(varRETpreviousyear,0);
SET varNIpreviousyear 		= IFNULL(varREVtpreviousyear,0) - IFNULL(varCOGSpreviousyear,0) - IFNULL(varGEXPpreviousyear,0) - IFNULL(varSEXPpreviousyear, 0) - IFNULL(varOEXPpreviousyear, 0) - IFNULL(varINCTAXpreviousyear,0) - IFNULL(varOTHTAXpreviousyear,0);
SET varNIyoy 				= IFNULL((varNI - varNIpreviousyear) / (varNIpreviousyear) * 100,0);
SET varREVtyoy 				= IFNULL((varREVt - varREVtpreviousyear) / (varREVtpreviousyear) * 100,0);
SET varNIperc				= IFNULL((varNI / varREVt) * 100,0);
SET varNIpercpreviousyear	= IFNULL((varNIpreviousyear / varREVtpreviousyear) * 100,0);
SET varNIpercyoy			= IFNULL((varNIperc - varNIpercpreviousyear) / (varNIpercpreviousyear) * 100,0);


DROP TABLE IF EXISTS pl_statement;

-- WE hereby create the phsyical PL statement table which will be the foundation of our output in the terminal once the stored procedure is called. 
CREATE TABLE pl_statement( 
`Account Name` 			VARCHAR(50),
`Amount This Year` 		VARCHAR(50),
`Amount Previous Year` 	VARCHAR(50),
`YoY Growth(%)` 		VARCHAR(50)
);

-- This is where we insert the values of all the calculations (used above) and put them inside our PL statement
INSERT INTO pl_statement(`Account Name`, `Amount This Year`, `Amount Previous Year`, `YoY Growth(%)`)
VALUES
('Profit & Loss Report' , 'in USD', 'in USD', 'in %'),

(calendaryear, '','',''),

('--------------', '--------------','--------------','--------------'),

('REVENUES', FORMAT(COALESCE(varREV,0),0), FORMAT(COALESCE(varREVpreviousyear,0),0), FORMAT(COALESCE(varREVyoy,0),0)),

('OTHER INCOME', FORMAT(COALESCE(varOTHINC,0),0), FORMAT(COALESCE(varOTHINCpreviousyear,0),0), FORMAT(COALESCE(varOTHINCyoy,0),0)),

('RETURN, REFUNDS AND DISCOUNTS', FORMAT(COALESCE(varRET,0),0), FORMAT(COALESCE(varRETpreviousyear,0),0), FORMAT(COALESCE(varRETyoy,0),0)),

('TOTAL REVENUES', FORMAT(COALESCE(varREVt,0),0), FORMAT(COALESCE(varREVtpreviousyear,0),0), FORMAT(COALESCE(varREVtyoy,0),0)),

('--------------', '--------------','--------------','--------------'),

('COST OF GOODS AND SERVICES', FORMAT(COALESCE(varCOGS,0),0), FORMAT(COALESCE(varCOGSpreviousyear,0),0), FORMAT(COALESCE(varCOGSyoy,0),0)),

('GROSS PROFIT MARGIN', FORMAT(COALESCE(varGPM,0),0), FORMAT(COALESCE(varREVpreviousyear - varCOGSpreviousyear,0),0), FORMAT(COALESCE(((varREV - varCOGS) - (varREVpreviousyear - varCOGSpreviousyear)) / (varREVpreviousyear - varCOGSpreviousyear) * 100,0),0)),

('GROSS PROFIT MARGIN %', FORMAT(COALESCE(varGPMperc,0),0) , FORMAT(COALESCE(varGPMpercpreviousyear,0),0), FORMAT(COALESCE(varGPMyoy,0),0)), 

('--------------', '--------------','--------------','--------------'),

('ADMINISTRATIVE EXPENSES', FORMAT(COALESCE(varGEXP,0),0), FORMAT(COALESCE(varGEXPpreviousyear,0),0), FORMAT(COALESCE(varGEXPyoy,0),0)),

('SELLING EXPENSES', FORMAT(COALESCE(varSEXP,0),0), FORMAT(COALESCE(varSEXPpreviousyear,0),0), FORMAT(COALESCE(varSEXPyoy,0),0)),

('OTHER EXPENSES', FORMAT(COALESCE(varOEXP,0),0), FORMAT(COALESCE(varOEXPpreviousyear,0),0), FORMAT(COALESCE(varOEXPyoy,0),0)),

('--------------', '--------------','--------------','--------------'),

('INCOME TAX', FORMAT(COALESCE(varINCTAX,0),0), FORMAT(COALESCE(varINCTAXpreviousyear,0),0), FORMAT(COALESCE(varINCTAXyoy,0),0)),

('OTHER TAX', FORMAT(COALESCE(varOTHTAX,0),0), FORMAT(COALESCE(varOTHTAXpreviousyear,0),0), FORMAT(COALESCE(varOTHTAXyoy,0),0)),

('--------------', '--------------','--------------','--------------'),

('NET INCOME', FORMAT(COALESCE(varNI,0),0), FORMAT(COALESCE(varNIpreviousyear,0),0), FORMAT(COALESCE(varNIyoy,0),0)),

('NET INCOME %', FORMAT(COALESCE(varNIperc,0),0), FORMAT(COALESCE(varNIpercpreviousyear,0),0), FORMAT(COALESCE(varNIpercyoy,0),0))

;



END $$
DELIMITER ;	
			
CALL pl_statement(2016);
SELECT * 
FROM pl_statement;

