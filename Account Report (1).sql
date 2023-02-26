USE h_accounting;

-- Creating a stored procedure begins with the delimiter and create procedure function. 
DELIMITER $$
DROP PROCEDURE IF EXISTS balance_sheet;

DELIMITER $$
CREATE PROCEDURE balance_sheet(in calendaryear INT)
BEGIN
 
 /* Our first step was "cleaning" the messy database that we have. 
 For that, we decided to create a new table called table BS, which is going to be our new databse. 
 We included all the necessary information for the balance sheet from 4 main tables: account, journal_entry, 
 journal_entry_line_item and statement_section.
 We created the table using the "with" function and then we left-joined all the "new" single tables.
 */
CREATE TABLE tableBS AS (

						 WITH acco AS (SELECT `account`, account_id, balance_sheet_order, balance_sheet_section_id
										FROM `account`), 
						 
								ss AS (SELECT statement_section_id, statement_section_code, statement_section_order, is_balance_sheet_section
										FROM statement_section),
									
								jeli AS (SELECT journal_entry_id, account_id, `description`, IFNULL(debit, 0) AS debit, IFNULL(credit, 0) AS credit
										FROM journal_entry_line_item),
										
								je AS (SELECT journal_entry_id, journal_entry_code, journal_entry, entry_date, debit_credit_balanced, cancelled
									   FROM journal_entry)
						 
SELECT * 
FROM acco 
LEFT JOIN ss 
ON acco.balance_sheet_section_id = ss.statement_section_id
LEFT JOIN jeli 
USING (account_id)
LEFT JOIN je
USING (journal_entry_id)
);

/* After, we coded all the needed queries to get the balance of all the necessary accounts to build the report.
Assets includes "Current Assets", "Fixed Assets" and "Deferred Assets".
Liabilities includes "Current Liabilities", "Long Term Liabilities" and "Deferred Liabilities".
Equity includes only "Equity".
We filtered every query by the equivalent statement section id, by the entry date using the "YEAR" function 
and by including the non-cancelled values only. After, we built the query for the previous year as well.
Along the way, we used the "SET" function to build the formulas for the YoY growth and the total assets and liabilities.
*/

-- ------------------------------------------
-- CURRENT ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @c_assets FROM
    tableBS
WHERE
    statement_section_id = 61
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS CURRENT ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @p_c_assets FROM
    tableBS
WHERE
    statement_section_id = 61
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_c_assets = ifnull(((@c_assets - @p_c_assets)/@p_c_assets * 100), 0);

-- FIXED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @f_assets FROM
    tableBS
WHERE
    statement_section_id = 62
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS FIXED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @p_f_assets FROM
    tableBS
WHERE
    statement_section_id = 62
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_f_assets = ifnull(((@f_assets - @p_f_assets)/@p_f_assets * 100), 0);

-- DEFERRED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @d_assets FROM
    tableBS
WHERE
    statement_section_id = 63
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS DEFERRED ASSETS
SELECT 
    (SUM(debit) - SUM(credit))
INTO @p_d_assets FROM
    tableBS
WHERE
    statement_section_id = 63
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_d_assets = ifnull(((@d_assets - @p_d_assets)/@p_d_assets * 100), 0);
SET @total_assets = ifnull(@c_assets, 0) + ifnull(@l_assets, 0) + ifnull(@d_assets, 0);
SET @p_total_assets = ifnull(@p_c_assets, 0) + ifnull(@p_l_assets, 0) + ifnull(@p_d_assets, 0);
SET @yoy_total_assets = ifnull(((@total_assets - @p_total_assets)/@p_total_assets * 100), 0);

-- ------------------------------------------
-- CURRENT LIABILITIES 
SELECT 
    SUM(credit) - SUM(debit)
INTO @c_liab FROM
    tableBS
WHERE
    statement_section_id = 64
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS CURRENT LIABILITIES 
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_c_liab FROM
    tableBS
WHERE
    statement_section_id = 64
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_c_liab = ifnull(((@c_liab - @p_c_liab)/@p_c_liab * 100), 0);

-- LONG TERM LIABILITIES
SELECT 
    SUM(credit) - SUM(debit)
INTO @l_liab FROM
    tableBS
WHERE
    statement_section_id = 65
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS LONG TERM LIABILITIES
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_l_liab FROM
    tableBS
WHERE
    statement_section_id = 65
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_l_liab = ifnull(((@l_liab - @p_l_liab)/@p_l_liab * 100), 0);

-- DEFERRED LIABILITIES
SELECT 
    SUM(credit) - SUM(debit)
INTO @d_liab FROM
    tableBS
WHERE
    statement_section_id = 66
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS DEFERRED LIABILITIES
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_d_liab FROM
    tableBS
WHERE
    statement_section_id = 66
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0;

SET @yoy_d_liab = ifnull(((@d_liab - @p_d_liab)/@p_d_liab * 100), 0);
SET @total_liab = ifnull(@c_liab, 0) + ifnull(@l_liab, 0) + ifnull(@d_liab, 0);
SET @p_total_liab = ifnull(@p_c_liab, 0) + ifnull(@p_l_liab, 0) + ifnull(@p_d_liab, 0);
SET @yoy_total_liab = ifnull(((@total_liab - @p_total_liab)/@p_total_liab * 100), 0);

-- ------------------------------------------
-- EQUITY
SELECT 
    (SUM(credit) - SUM(debit))
INTO @eq FROM
    tableBS
WHERE
    statement_section_id = 67
        AND YEAR(entry_date) = calendaryear
        AND cancelled = 0;

-- PREVIOUS EQUITY
SELECT 
    (SUM(credit) - SUM(debit))
INTO @p_eq FROM
    tableBS
WHERE
    statement_section_id = 67
        AND YEAR(entry_date) = calendaryear - 1
        AND cancelled = 0; 

SET @yoy_eq = ifnull(((@eq - @p_eq)/@p_eq * 100), 0);
SET @total_eq = ifnull(@eq, 0);
SET @p_total_eq = ifnull(@p_eq, 0);
SET @yoy_total_eq = ifnull(((@total_eq - @p_total_eq)/@p_total_eq * 100), 0);

-- ------------------------------------------
/* To build the balance sheet report, we created a table with 5 columns and we inserted all the rows one-by-one, 
including the equivalent formulas. We cleaned the output results using the FORMAT and COALESCE functions. 
*/

DROP TABLE IF EXISTS balance_sheet_report;

CREATE TABLE balance_sheet_report (
    category VARCHAR(50),
    subcategory VARCHAR(50),
    `current year` VARCHAR(20),
    `previous year` VARCHAR(20),
    `YOY growth` VARCHAR(20)
);

INSERT INTO balance_sheet_report(category, subcategory, `current year`, `previous year`, `YOY growth`)
VALUES  ('BALANCE SHEET', ' ','in usd','in usd','in %'),
		('--------------', '--------------',calendaryear, calendaryear - 1, '--------------'),
        ('ASSETS', ' ',' ',' ', ' '),
		(' ',  'TOTAL', format(@total_assets, 0), format(@p_total_assets, 0), format(@yoy_total_assets, 0)),
		(' ',  'CURRENT ASSETS', format(coalesce(@c_assets, 0),0), format(coalesce(@p_c_assets, 0),0), format(coalesce(@yoy_c_assets, 0),0)),
		(' ',  'FIXED ASSETS', format(coalesce(@f_assets, 0), 0), format(coalesce(@p_f_assets, 0), 0), format(coalesce(@yoy_f_assets, 0), 0)),
		(' ',  'DEFERRED ASSETS', format(coalesce(@d_assets, 0), 0), format(coalesce(@p_d_assets, 0), 0), format(coalesce(@yoy_d_assets, 0), 0)),
		('--------------', '--------------','--------------','--------------','--------------'),
        ('LIABILITIES', ' ',' ',' ', ' '),
        (' ',  'TOTAL', format(@total_liab, 0), format(@p_total_liab, 0), format(@yoy_total_liab, 0)),
        (' ', 'CURRENT LIABILITIES', format(coalesce(@c_liab, 0), 0), format(coalesce(@p_c_liab, 0), 0), format(coalesce(@yoy_c_liab, 0), 0)),
		(' ', 'LONG TERM LIABILITIES', format(coalesce(@l_liab, 0), 0), format(coalesce(@p_l_liab, 0), 0), format(coalesce(@yoy_l_liab, 0), 0)),
		(' ', 'DEFERRED LIABILITIES', format(coalesce(@d_liab, 0), 0), format(coalesce(@p_d_liab, 0), 0), format(coalesce(@yoy_d_liab, 0), 0)),
		('--------------', '--------------','--------------','--------------','--------------'),
        ('EQUITY', ' ',format(@total_eq, 0),format(@p_total_eq, 0), ' '),
        (' ', 'TOTAL', format(coalesce(@eq, 0), 0), format(coalesce(@p_eq, 0), 0), format(coalesce(@yoy_eq, 0), 0))
        
        ;
        


END $$
DELIMITER ;

call balance_sheet(2018);
select * from balance_sheet_report;

END $$
DELIMITER ; 



