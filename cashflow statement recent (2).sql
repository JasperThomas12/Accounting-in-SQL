use new_schema;

delimiter $$
drop procedure if exists cashflow_statement;

delimiter $$
create procedure cashflow_statement(in calendaryear INT)
begin 
drop table if exists tableCF;

create table tableCF as (

				 with acco as (select account, account_id, account_code, balance_sheet_order, balance_sheet_section_id
				 from account), 
                 
						ss as (select statement_section_id, statement_section_code, statement_section_order, is_balance_sheet_section
							from statement_section),
                            
						jeli as (select journal_entry_id, account_id, description, ifnull(debit, 0) as debit, ifnull(credit, 0) as credit
								from journal_entry_line_item),
                                
						je as (select journal_entry_id, journal_entry_code, journal_entry, entry_date, debit_credit_balanced, cancelled
							   from journal_entry)
                 
SELECT * 
FROM acco 
LEFT JOIN ss 
ON acco.balance_sheet_section_id = ss.statement_section_id
left join jeli 
using (account_id)
left join je
using (journal_entry_id)
);

-- CASH
select (sum(ifnull(credit, 0)) - sum(ifnull(debit, 0))) into @cash
from tableCF
where account_code LIKE '101%'
and year(entry_date) = calendaryear
and cancelled = 0;

-- BANK ACCOUNTS
select (sum(ifnull(credit, 0)) - sum(ifnull(debit, 0))) into @bank_accounts
from tableCF
where account_code LIKE '102%'
and year(entry_date) = calendaryear
and cancelled = 0;

-- ACCOUNT RECEIVABLES
select -(sum(ifnull(credit, 0)) - sum(ifnull(debit, 0))) into @acc_rec
from tableCF
where account_code LIKE '105%' 
and year(entry_date) = calendaryear
and cancelled = 0;

-- OTHER DEBITORS
select (sum(ifnull(credit, 0)) - sum(ifnull(debit, 0))) into @o_deb
from tableCF
where account_code LIKE '107%'
and year(entry_date) = calendaryear
and cancelled = 0;

-- EQUIPMENT TRANSPORTATION
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @eq_transp
from tableCF
where account_code LIKE '154%'
and year(entry_date) = calendaryear
and cancelled = 0;

-- EQUIPMENT COMPUTERS
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @eq_comp
from tableCF
where account_code LIKE '156%'
and year(entry_date) = calendaryear
and cancelled = 0;

-- EQUIPMENT FURNITURE
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @eq_furn
from tableCF
where account_code LIKE '155%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- DEPRECIATION
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @dep
from tableCF
where `account` like '%depreciation%'
and year(entry_date) = calendaryear
and cancelled = 0;

-- GUARANTEE DEPOSITS
select (sum(ifnull(credit, 0)) - sum(ifnull(debit, 0))) into @g_dep
from tableCF
where account_code LIKE '184%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- ------------- changes in operating -----------------
-- INTERIM TAX PAYMENT
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @int_tax_paym
from tableCF
where account_code IN ('114%', '113%')
and year(entry_date) = calendaryear
and cancelled = 0; 

-- TAXES TO BE CREDITED PRE PAID
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @tax_cred_pre
from tableCF
where account_code LIKE '118%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- TAXES TO BE CREDITED TO BE PAID
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @tax_cred_paid
from tableCF
where account_code LIKE '119%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- SUPPLIER PRE-PAYMENTS
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @sup_paym
from tableCF
where account_code LIKE '120%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- PAYABLES
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @payables
from tableCF
where account_code LIKE '201%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- ACCRUED EXPENSES
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @acc_exp
from tableCF
where account_code LIKE '205%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- ACCRUED TAXES - RECEIVED
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @acc_exp_rec
from tableCF
where account_code LIKE '208%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- ACCRUED TAXES - PENDING
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @acc_exp_pen
from tableCF
where account_code LIKE '209%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- ACCRUED TAXES - TO BE PAID
select (sum(ifnull(debit, 0)) - sum(ifnull(credit, 0))) into @acc_exp_tbp
from tableCF
where account_code LIKE '213%'
and year(entry_date) = calendaryear
and cancelled = 0; 

-- DEFERRED INCOME
select (sum(ifnull(credit, 0)) - sum(ifnull(debit, 0))) into @def_inc
from tableCF
where account_code LIKE '206%'
and year(entry_date) = calendaryear
and cancelled = 0; 

SET @cash_gen_op_act = ifnull(@cash, 0) + ifnull(@bank_accounts, 0) + ifnull(@acc_rec, 0) + ifnull(@o_deb, 0) 
+ifnull(@eq_transp, 0) +ifnull(@eq_comp, 0) +ifnull(@eq_furn, 0) +ifnull(@g_dep, 0) +ifnull(@int_tax_paym, 0) 
+ifnull(@tax_cred_pre, 0) +ifnull(@tax_cred_paid, 0) +ifnull(@sup_paym, 0) +ifnull(@payables, 0) +ifnull(@acc_exp, 0)
+ifnull(@acc_exp_rec, 0) +ifnull(@acc_exp_pen, 0) +ifnull(@acc_exp_tbp, 0) +ifnull(@def_inc, 0);

-- cashflow statement report
drop table if exists cashflow_report; 

create table cashflow_report
			(category VARCHAR(50),
            subcategory VARCHAR (50),
            `current year` VARCHAR (20))
            ;

insert into cashflow_report(category, subcategory, `current year`)
values  ('CASHFLOW STATEMENT', calendaryear,'in usd'),
		('--------------','--------------', '--------------'),
        ('OPERATING ACTIVITIES', ' ',' '),
		(' ', 'NET INCOME', 'insert variable'), 
		(' ', 'CASH', format(coalesce(@cash, 0), 0)),
		(' ', 'BANK ACCOUNTS', format(coalesce(@bank_accounts, 0), 0)),
		(' ', 'ACCOUNTS RECEIVABLE', format(coalesce(@acc_rec, 0), 0)),
		(' ', 'OTHER DEBITORS', format(coalesce(@o_deb, 0), 0)),
		(' ', 'EQUIPMENT TRANSPORTATION', format(coalesce(@eq_transp, 0), 0)),
		(' ', 'EQUIPMENT COMPUTERS', format(coalesce(@eq_comp, 0), 0)),
		(' ', 'EQUIPMENT FURNITURES', format(coalesce(@eq_furn, 0), 0)),
		(' ', 'DEPRECIATION', format(coalesce(@dep, 0), 0)),
		(' ', 'GUARANTEED DEPOSITS', format(coalesce(@g_dep, 0), 0)),
		(' ', 'EQUIPMENT FURNITURES', format(coalesce(@eq_furn, 0), 0)),
        ('CHANGES IN OPERATING ACTIVITIES', ' ',' '),
		(' ', 'INTERIM TAX PAYMENT', format(coalesce(@int_tax_paym, 0), 0)), 
		(' ', 'TAXES TO BE CREDITED - PRE PAID', format(coalesce(@tax_cred_pre, 0), 0)),
		(' ', 'TAXES TO BE CREDITED TO BE PAID', format(coalesce(@tax_cred_paid, 0), 0)),
		(' ', 'SUPPLIER PRE-PAYMENTS', format(coalesce(@sup_paym, 0), 0)),
		(' ', 'PAYABLES', format(coalesce(@payables, 0), 0)),
		(' ', 'ACCRUED EXPENSES', format(coalesce(@acc_exp, 0), 0)),
		(' ', 'ACCRUED TAXES - RECEIVED', format(coalesce(@acc_exp_rec, 0), 0)),
		(' ', 'ACCRUED TAXES - PENDING', format(coalesce(@acc_exp_pen, 0), 0)),
		(' ', 'ACCRUED TAXES - TO BE PAID', format(coalesce(@acc_exp_tbp, 0), 0)),
		(' ', 'DEFERRED INCOME', format(coalesce(@def_inc, 0), 0)),
		('CASH GENERATED BY OP ACTIVITIES', ' ',@cash_gen_op_act),
        ('CHANGES IN OPERATING ACTIVITIES', ' ',' '),
		(' ', 'OWNERS EQUITY', format(coalesce(@def_inc, 0), 0)),

        

        
        ;
        


END $$
DELIMITER ;


CALL cashflow_statement(2016);
select * from cashflow_report;

