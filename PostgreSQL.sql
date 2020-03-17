--普通函数创建

CREATE OR REPLACE FUNCTION f_mb_ss_inspection_data_upsert2 (
	IN in_userid								VARCHAR(64),
	IN in_hospcode							VARCHAR(64),  
	IN in_ssid				 					VARCHAR(64),  
	IN in_inspectiontime       	VARCHAR(64),
	IN in_inspectionid  				VARCHAR(64),
  IN in_inspectionitemcode   	VARCHAR(64),
  IN in_inspectionsubitemcode VARCHAR(64),
  IN in_inspectionindexcode  	VARCHAR(64),
  IN in_inspectionindexvalue1 VARCHAR(64),
  IN in_inspectionindexvalue2 VARCHAR(64),
  IN in_inspectionindexvalue3 VARCHAR(64),
  IN in_inspectionhospcode   	VARCHAR(64),
  IN in_inspectionhospname   	VARCHAR(64),
  IN in_inspectionusercode   	VARCHAR(64),
  IN in_inspectionusername   	VARCHAR(64),
  IN in_verfusercode         	VARCHAR(64),
  IN in_verfusername         	VARCHAR(64),
  IN in_datasourcetype       	INT4       ,
  IN in_datasourcedevice     	TEXT      ,
	
	OUT retcode integer, OUT retvalue text)

 RETURNS record
 LANGUAGE plpgsql
AS $function$

/*
 * 函数说明：保存患者动态体征数据检查表。 暂不支持update操作
 * 参数：按要求填写参数
 *  * 返回：
 *     retcode： 小于0，失败；==0成功
 *     retvalue：返回成功或失败的信息
 * 备注：外部程序调用必须判断retcode的返回值进行处理
*/
declare
	--	入参说明
	--	程序变量说明
	
	v_createdtime   					TIMESTAMP DEFAULT Now();
	v_modifiedtime  					TIMESTAMP DEFAULT Now();
	v_inspectiontime    			TIMESTAMP DEFAULT Now();
	v_cnt 		    						int4 DEFAULT 0;
	v_inspectionitem					record;
	v_inspectionid						VARCHAR(64);
	v_gendercode   						VARCHAR(64) DEFAULT NULL;			--性别编码
	v_jsonb_inspectionqa  jsonb;
begin

	if (trim(in_ssid) = '' or trim(in_inspectiontime) = '') then
		retcode := -6;
		retvalue := '{"error_msg":"field value is null or empty"}';
		return;
	end if;
	
	if (trim(in_inspectionitemcode) = '' or trim(in_inspectionsubitemcode) = '' or trim(in_inspectionindexcode) = '') then
		retcode := -6;
		retvalue := '{"error_msg":"field value is null or empty"}';
		return;
	end if;

	if (trim(in_inspectiontime) != '') THEN
		v_inspectiontime = to_timestamp(in_inspectiontime, 'yyyy-MM-dd hh24:mi:ss');
	end if;

	-- 生成uuid
	select zxuuid() into v_inspectionid;

	--性别编码
	select gendercode into v_gendercode from t_ss_base where ssid = in_ssid;
	
	-- 查询检查指标字典表
	select * into v_inspectionitem 
	from t_dict_inspection_item 
	where 		inspectionitemcode = in_inspectionitemcode 
				and inspectionsubitemcode = in_inspectionsubitemcode 
				and inspectionindexcode = in_inspectionindexcode;

	--RAISE NOTICE '%', v_inspectionid;

	
	select  f.retvalue into v_jsonb_inspectionqa from  f_mb_qa_inspection(
					in_inspectionitemcode, 
					in_inspectionsubitemcode, 
					in_inspectionindexcode, 
					in_inspectionindexvalue1, 
					in_inspectionindexvalue2, 
					in_inspectionindexvalue3,
					v_gendercode
				) as f;   

	
--	if(v_jsonb_inspectionqa->>'errorcode' = '-1') then
--		retcode := 0;
--		retvalue := '{"error_msg":"success"}';
--		return;
--	end if ;
	
	insert into t_mb_ss_inspection_data 
						(
							id,
							hospcode                      ,                     
						    ssid                          ,                     
						    inspectiontime                ,                     
						    inspectionitemcode            ,                     
						    inspectionitemname            ,                     
						    inspectionsubitemcode         ,                     
						    inspectionsubitemname         ,                     
						    inspectionindexcode           ,                     
						    inspectionindexname           ,                     
						    inspectionindexvalue1         ,                     
						    inspectionindexvalue2         ,                     
						    inspectionindexvalue3         ,                     
						    inspectionindexunit           ,                     
						    inspectionindexref            ,
						    inspectionmethod              ,
						    inspectionindexqa             ,
						    inspectionindextype           ,
						    inspectionhospcode            ,
						    inspectionhospname            ,
						    inspectionusercode            ,
						    inspectionusername            ,
						    verfusercode                  ,
						    verfusername                  ,
						    datasourcetype                ,
						    datasourcedevice              ,
						    modifiedtime                  ,
						    createdtime                   
						)
		values (					 
						in_inspectionid,
						in_hospcode                      ,   
						in_ssid                          ,   
						v_inspectiontime                 ,   
						v_inspectionitem.inspectionitemcode,--IN in_inspectionitemcode   VARCHAR(64),
					  v_inspectionitem.inspectionitemname,--IN in_inspectionitemname   VARCHAR(64),
					  v_inspectionitem.inspectionsubitemcode,--IN in_inspectionsubitemcode VARCHAR(64),
					  v_inspectionitem.inspectionsubitemname,--IN in_inspectionsubitemname VARCHAR(64),
					  v_inspectionitem.inspectionindexcode,--IN in_inspectionindexcode  VARCHAR(64),
					  v_inspectionitem.inspectionindexname,--IN in_inspectionindexname  VARCHAR(64),
					  in_inspectionindexvalue1,--IN in_inspectionindexvalue1 VARCHAR(64),
					  in_inspectionindexvalue2,--IN in_inspectionindexvalue2 VARCHAR(64),
					  in_inspectionindexvalue3,--IN in_inspectionindexvalue3 VARCHAR(64),
					  v_inspectionitem.inspectionindexunit,--IN in_inspectionindexunit  VARCHAR(64),
					  v_inspectionitem.inspectionindexref,--IN in_inspectionindexref   VARCHAR(64),
					  '',--IN in_inspectionmethod     VARCHAR(64),
						v_jsonb_inspectionqa,
						v_inspectionitem.inspectionindextype,--IN in_inspectionindextype  INT4,
						in_inspectionhospcode            ,   
						in_inspectionhospname            ,   
						in_inspectionusercode            ,   
						in_inspectionusername            ,   
						in_verfusercode                  ,   
						in_verfusername                  ,   
						in_datasourcetype                ,   
						in_datasourcedevice              ,   
            v_modifiedtime									 ,
            v_createdtime) 
            on conflict (id) 
			do update set 
			hospcode=             excluded.hospcode                      ,                     
			ssid=                 excluded.ssid                          ,                     
			inspectiontime=       excluded.inspectiontime                ,                     
			inspectionitemcode=   excluded.inspectionitemcode            ,                     
			inspectionitemname=   excluded.inspectionitemname            ,                     
			inspectionsubitemcode=excluded.inspectionsubitemcode         ,                     
			inspectionsubitemname=excluded.inspectionsubitemname         ,                     
			inspectionindexcode=  excluded.inspectionindexcode           ,                     
			inspectionindexname=  excluded.inspectionindexname           ,                     
			inspectionindexvalue1=excluded.inspectionindexvalue1         ,                     
			inspectionindexvalue2=excluded.inspectionindexvalue2         ,                     
			inspectionindexvalue3=excluded.inspectionindexvalue3         ,                     
			inspectionindexunit=  excluded.inspectionindexunit           ,                     
			inspectionindexref=   excluded.inspectionindexref            ,
			inspectionmethod=     excluded.inspectionmethod              ,
			inspectionindexqa=    f_mb_qa_inspection(
							in_inspectionitemcode, 
							in_inspectionsubitemcode, 
							in_inspectionindexcode, 
							in_inspectionindexvalue1, 
							in_inspectionindexvalue2, 
							in_inspectionindexvalue3,
							v_gendercode
						)::JSONB             ,
			inspectionindextype=  excluded.inspectionindextype           ,
			inspectionhospcode=   excluded.inspectionhospcode            ,
			inspectionhospname=   excluded.inspectionhospname            ,
			inspectionusercode=   excluded.inspectionusercode            ,
			inspectionusername=   excluded.inspectionusername            ,
			verfusercode=         excluded.verfusercode                  ,
			verfusername=         excluded.verfusername                  ,
			datasourcetype=       excluded.datasourcetype                ,
			datasourcedevice=     excluded.datasourcedevice              ,
			modifiedtime=         excluded.modifiedtime                  ;       
	
	--	处理返回结果
	retcode := 0;
	retvalue := '{"error_msg":"success"}';

end

 $function$



--触发器函数	
CREATE OR REPLACE FUNCTION trig_mb_ss_inspection_suspected_insert ()
	
RETURNS trigger 
 LANGUAGE plpgsql
AS $function$
	
	/*
	 * 函数说明：插入动态体征数据时，根据检测指标判断是否疑似患者，疑似患者筛查
	 * 参数：按要求填写参数
	 *  * 返回：
	 *     retcode： 小于0，失败；==0成功
	 *     retvalue：返回成功或失败的信息
	 * 备注：外部程序调用必须判断retcode的返回值进行处理
	*/
	declare
		--	入参说明
		--	程序变量说明
		v_inspectioncode VARCHAR(64) default NULL ;
	  v_suspecteddisecode	 VARCHAR(64) default NULL;
	  v_suspecteddisename	 VARCHAR(64) default NULL;
	begin
	
	  v_inspectioncode = concat(NEW.inspectionitemcode, NEW.inspectionsubitemcode, NEW.inspectionindexcode);
	
		-- 单导心电
	  if (v_inspectioncode = '100310011001') then	
	  	if (position('"0.0"' in NEW.inspectionindexvalue1) = 0) then 	-- 不是心电图未见异常的患者都是疑似心脏疾病
		  		v_suspecteddisecode = '1';
			  	v_suspecteddisename = '心脏疾病';
		  end if;
		  	
	  -- 高血压
	  elsif (v_inspectioncode = '100110051001') then
	  
				if (NEW.inspectionindexqa::JSONB->>'qaflag' = '2') then 
		  		v_suspecteddisecode = '2';
			  	v_suspecteddisename = '高血压';
		  	end if;
		  	
		-- 空腹血糖 or 餐后2小时血糖
	  elsif (v_inspectioncode = '100210011001' or v_inspectioncode = '100210011002') then
			if (NEW.inspectionindexqa::JSONB->>'qaflag' = '2') then 
		  		v_suspecteddisecode = '3';
			  	v_suspecteddisename = '糖尿病';
		  end if;
	
	  end if;
	
		if (v_suspecteddisecode is not null) then
		
			PERFORM f_mb_ss_suspected_dise_upsert(
			  			'',
			  			NEW.hospcode,
			  			NEW.ssid,
			  			v_suspecteddisecode,
			  			v_suspecteddisename,
			  			to_char(NEW.inspectiontime, 'yyyy-mm-dd hh24:mi:ss'),
			  			NEW.id
			  		);
			
		end if;
	
		--	返回null 不执行之后的触发器
		RETURN NULL; -- result is ignored since this is an AFTER trigger
	
	end
	
 $function$;
 
 --触发器
 
DROP TRIGGER IF EXISTS trig_mb_ss_inspection_suspected ON t_mb_ss_inspection_data;

create trigger trig_mb_ss_inspection_suspected AFTER INSERT ON t_mb_ss_inspection_data FOR EACH ROW  
	EXECUTE procedure trig_mb_ss_inspection_suspected_insert();
