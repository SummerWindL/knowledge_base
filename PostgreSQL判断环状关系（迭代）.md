# table
```postgresql
CREATE TABLE t_relationship_cfg (
	hospcode varchar(64) NOT NULL,
	parenthospcode varchar(64) NOT NULL,
	hosplevelcode varchar(64) NULL,
	hosplevelname varchar(64) NULL,
	remark text NULL,
	modifiedtime timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	createdtime timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT pk_t_relationship_cfg PRIMARY KEY (hospcode, parenthospcode)
);

INSERT INTO aigw.t_relationship_cfg
(hospcode, parenthospcode, hosplevelcode, hosplevelname, remark, modifiedtime, createdtime)
VALUES('000005', '000012', '', '', '', '2020-09-15 11:14:17.907', '2020-09-15 11:14:17.907');
INSERT INTO aigw.t_relationship_cfg
(hospcode, parenthospcode, hosplevelcode, hosplevelname, remark, modifiedtime, createdtime)
VALUES('000011', 'R10011VBJ', '', '', '', '2020-09-15 11:39:51.771', '2020-09-15 11:39:51.771');
INSERT INTO aigw.t_relationship_cfg
(hospcode, parenthospcode, hosplevelcode, hosplevelname, remark, modifiedtime, createdtime)
VALUES('000011', '000017', '', '', '', '2020-09-15 11:41:08.249', '2020-09-15 11:41:08.249');
INSERT INTO aigw.t_relationship_cfg
(hospcode, parenthospcode, hosplevelcode, hosplevelname, remark, modifiedtime, createdtime)
VALUES('000001', '000011', '', '', '', '2020-09-15 11:51:25.373', '2020-09-15 11:51:25.373');
INSERT INTO aigw.t_relationship_cfg
(hospcode, parenthospcode, hosplevelcode, hosplevelname, remark, modifiedtime, createdtime)
VALUES('000001', '000245', '', '', '', '2020-09-15 12:01:21.860', '2020-09-15 12:01:21.860');
INSERT INTO aigw.t_relationship_cfg
(hospcode, parenthospcode, hosplevelcode, hosplevelname, remark, modifiedtime, createdtime)
VALUES('000001', '000014', '', '', '', '2020-09-15 13:47:11.512', '2020-09-15 13:47:11.512');
INSERT INTO aigw.t_relationship_cfg
(hospcode, parenthospcode, hosplevelcode, hosplevelname, remark, modifiedtime, createdtime)
VALUES('000001', '000127', '', '', '', '2020-09-15 13:47:18.481', '2020-09-15 13:47:18.481');

```


# 函数判断

```postgresql
CREATE OR REPLACE FUNCTION f_relationship_cfg_check (
	IN in_userid varchar(64),
	
	IN in_hospcode VARCHAR(64),		--	下级医院编码
	IN in_parenthospcode VARCHAR(64),	--	上级医院编码
	
   OUT retcode integer, 
   OUT retvalue text)
LANGUAGE plpgsql
AS $function$


/**
 * 检查是否允许建立指定的医院上下级关系
 * 当出现以下情况，则不允许建立：
 * 1. 环状关系；
 * 2. 多解树/图状关系（即：多路线同一个出口的迷宫图）
 */
declare
	v_createdtime   TIMESTAMP DEFAULT Now();
	v_modifiedtime  TIMESTAMP DEFAULT Now();
	v_cnt int4 default 0 ;
begin
	
	--userid
	if (in_userid IS  NULL OR length(trim(in_userid)) <= 0) then
		retcode := -6;
		retvalue := '{"error_msg":"in_userid field value is null or empty"}';
		return;
	end if;
	
	--医院编码合法性校验
	if (in_hospcode IS  NULL OR  length(trim(in_hospcode))<= 0) then
		retcode := -6;
		retvalue := '{"error_msg":"in_hospcode field value is null or empty"}';
		return;
	end if;
	
	if (in_parenthospcode IS  NULL OR  length(trim(in_parenthospcode))<= 0) then
		retcode := -6;
		retvalue := '{"error_msg":"in_parenthospcode field value is null or empty"}';
		return;
	end if;
    

	--	1. 检查是否出现环状关系
	with recursive c_record (hospcode) as (
		select hospcode from t_mb_hosp_relationship_cfg a 
			where a.parenthospcode = in_hospcode
			
		union all 
		
		select a.hospcode from t_mb_hosp_relationship_cfg a 
			inner join c_record on a.parenthospcode = c_record.hospcode
	)
	select count(1) into v_cnt from c_record a 
		where a.hospcode = in_parenthospcode ;

	if (v_cnt > 0) then --	出现环状关系
		retcode := -15;
		retvalue := '{"error_msg":"出现环状关系"}';
		return;	
	end if ;

	--	2. 检查是否出现多解树/图状关系
	with recursive c_record (parenthospcode) as (
		values(in_hospcode)  
		
		union all 
		
		values(in_parenthospcode) 
		
		union all 
		
		select a.parenthospcode from t_mb_hosp_relationship_cfg a 
			inner join c_record on a.hospcode = c_record.parenthospcode
	) , 
	c_record_cnt as (
	 	select parenthospcode , count(1) as cnt from c_record group by parenthospcode
	)
	select count(1) into v_cnt from c_record_cnt
		where cnt>1 ;
	
	if (v_cnt > 0) then --	出现多解树/图状关系
		retcode := -16;
		retvalue := '{"error_msg":"出现多解树/图状关系"}';
		return;	
	end if ;

	retcode := 0;
	retvalue := '{"error_msg":"success"}';

end

 $function$

```
