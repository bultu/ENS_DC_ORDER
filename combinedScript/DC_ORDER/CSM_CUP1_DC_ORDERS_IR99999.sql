--**************************************************************
-- SCRIPT NAME:     CSM_CUP1_DC_ORDERS_IR99999.sql
-- AUTHOR:          Kunal Joshi
-- DATE:            07/22/2014
-- APPLICATION ID:  I999999 

-- DESCRIPTION:     this script is to fix multiple different types of DC order problems from the result.txt file

-- RELEASE:         12.3

-- SUCCESS CRITERIA: Multiple records updated.

-- TABLE:            OMS_PRODUCT_VERSION, OMS_ORDER

--**************************************************************



set serveroutput on size 1000000

set echo on

DEFINE owner = cuappc.

DEFINE REF=curefss1.

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

WHENEVER SQLERROR EXIT FAILURE ROLLBACK;



DECLARE    v_table_order           &owner.oms_order.om_order_id%type;

    v_table_om_prod_id      &owner.oms_order.om_product_id%type;

    v_table_dc_group        varchar2(35);

    v_table_cnt             number := 0;

	  v_prod_ver							&owner.oms_product_version.product_version%type;

   

------------------------------------------------------------------------------------------------------

--IPV_Pend_Order_with_Pend_Disc

------------------------------------------------------------------------------------------------------



procedure IPV_Pend_Order_with_Pend_Disc(pban             &owner.oms_order.ban%type,

                                        p_order_id       &owner.oms_order.om_order_id%type,

                                        p_om_prod_id     &owner.oms_order.om_product_id%type) is

    v_om_prod_id        &owner.oms_product_version.om_product_id%type;

    v_prod_ver          &owner.oms_product_version.product_version%type;

    v_max_prod_ver      &owner.oms_product_version.product_version%type;

    v_appid             varchar2(6) := 'DC_CNV';

    v_prod_ver_cnt      number := 0;

    v_om_order_status   &owner.oms_order.om_order_status%type;

    v_ban               &owner.oms_order.ban%type;

    

begin

	    dbms_output.put_line('IPV_Pend_Order_with_Pend_Disc Starting...');

    dbms_output.put_line('OM Order ID:          '||p_order_id);

    

    

    

    begin

        select om_product_id, om_order_status, product_version, ban

        into v_om_prod_id, v_om_order_status, v_prod_ver, v_ban

        from &owner.oms_order 

        where om_order_id = p_order_id

        and order_version_status in ('CU','CA');

        

    exception 

        when no_data_found then

            dbms_output.put_line('There was no current or cancelled version of order.  Making max order version current.');

        

            update &owner.oms_order o

            set o.order_version_status = 'CU',

                o.application_id = 'DC_CNV',

                o.sys_update_date = sysdate

            where o.om_order_id = p_order_id

            and o.order_version = (select max(oo.order_version) from &owner.oms_order oo

                                   where oo.om_order_id = o.om_order_id);

                                   

            select om_product_id, om_order_status, product_version, ban

            into v_om_prod_id, v_om_order_status, v_prod_ver, v_ban

            from &owner.oms_order 

            where om_order_id = p_order_id

            and order_version_status in ('CU','CA');

        

        when too_many_rows then

            dbms_output.put_line('There were too many rows found');

            

            /*update &owner.oms_order o

            set o.order_version_status = 'HI',

		o.application_id = 'DC_CNV',

		o.sys_update_date = sysdate

            where o.om_order_id = p_order_id

            and o.order_version_status in ('CU','CA')

            and o.order_version = (select min(oo.order_version) from &owner.oms_order oo

                                   where oo.om_order_id = o.om_order_id

                                   and oo.order_version_status in ('CU','CA'));

            

            select om_product_id, om_order_status, product_version, ban

            into v_om_prod_id, v_om_order_status, v_prod_ver, v_ban

            from &owner.oms_order 

            where om_order_id = p_order_id

            and order_version_status in ('CU','CA');*/

            

    end;

        

    dbms_output.put_line('BAN:                  '||v_ban);

    

    v_table_order := p_order_id;

    v_table_om_prod_id := v_om_prod_id;

    v_table_dc_group := 'IPV_Pend_Order_with_Pend_Disc';

    

    if v_om_order_status = 'CA' then

        dbms_output.put_line('Order has been cancelled');

    else

    

        dbms_output.put_line('OM Prod ID:           '||v_om_prod_id);

        

        select count(*) into v_prod_ver_cnt

        from &owner.oms_product_version

        where product_version = v_prod_ver;

        

        if v_prod_ver_cnt = 0 then

            dbms_output.put_line('Product Version does NOT exist in oms_product_version.  Use product_version from oms_order. '||v_prod_ver);

        else

            v_prod_ver := '';

            select cuappo.omprdver_1sq.nextval into v_prod_ver from dual;

            dbms_output.put_line('Product Version exists in oms_product_version.  Pull new product version from sequence. '||v_prod_ver);

            update &owner.oms_order

            set product_version = v_prod_ver,

                application_id = v_appid,

		sys_update_date = sysdate

            where product_version = (select max(product_version) from &owner.oms_order 

                                     where om_order_id = p_order_id

                                     and om_product_id = v_om_prod_id)

            and om_order_id = p_order_id

            and om_product_id = v_om_prod_id;   

        end if;

        

        select max(product_version) into v_max_prod_ver

        from &owner.oms_product_version

        where om_product_id = v_om_prod_id;

        

        insert into &owner.oms_product_version

        select OM_PRODUCT_ID, v_prod_ver, SYS_CREATION_DATE, sysdate, OPERATOR_ID, v_appid, DL_SERVICE_CODE, DL_UPDATE_STAMP, 

               OM_PRODUCT_STATUS, 'PE', ADDRESS_ID, PRODUCT_TYPE, DELIVERY_COMPL_DATE, NAME_ID, PROD_STATUS_RSN_CODE, SUBMARKET, TN_NPA, 

               TN_NXX, TN_LINENO, OM_TN_TYPE, POTS_ID, OMSA_GROUP_ID, OMILEC_GROUP_ID, OMUSOC_GROUP_ID, PRODUCT_SUB_TYPE, BAN_ID, SAG_ADDRESS_ID, 

               MSAG_ADDRESS_ID, WAIVE_IND, WAIVE_RSN, LEC_TYPE, CALLER_NAME_ID, BILLING_PRODUCT_ID, LL_EFF_DATE, LL_EXP_DATE, LL_TRIBAL_IND, 

               LL_FEDERAL_IND, LL_STATE_IND, LK_UP_IND, TELASSIST_IND, LL_CASE_NO, BUS_RES_IND, ALT_PROD_DESC, TAX_ID, SSN, IP_ID, NP_IND, CUSTOMER_PON, 

               OPX_SEQUENCE, COLLECTION_FLAG, OMRI_GROUP_ID, REQ_PROD_ID, FIXED_SM_IND, SHIP_ADDRESS_ID, RS_LINK_PROD_TP, RS_LINK_PROD_NO, BUSINESS_UNIT, 

               CROSS_BOUND_EX, REFER_TO, INP_NUMBER, TRACS_ID, WIRE_MAINT_IND, CLIPS_IND, OMDI_GROUP_ID, OMPIN_GROUP_ID, LRN_NUMBER, OMCNT_GROUP_ID, 

               TRACKING_STATUS, TN_VOICEDATA_TP, OMRN_GROUP_ID, LL_EFF_ISSUE_DATE, DC_LSP_ID, PRODUCT_EXTENSION, COMPRD_GROUP_ID, OMCI_GROUP_ID, 

               ASSOC_PROD_ID, BILL_RESTRICTION, MCP_IND, 'Y', SUPPRESS_NAF_IND, LL_QUAL_PROG, DOB, SSN_LAST_FOUR

        from &owner.oms_product_version o

        where o.om_product_id = v_om_prod_id

        and o.product_version = v_max_prod_ver;        

    end if;

    dbms_output.put_line('---------------------------------------------------------------------');

    dbms_output.put_line(' ');

    EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

   

end IPV_Pend_Order_with_Pend_Disc;

 

 ------------------------------------------------------------------------------------------------------

--IPV_Disc_with_pend_order

------------------------------------------------------------------------------------------------------  

procedure IPV_Disc_with_pend_order(pban             &owner.oms_order.ban%type,

                            p_order_id       &owner.oms_order.om_order_id%type,

                            p_om_prod_id     &owner.oms_order.om_product_id%type) is

    v_om_prod_id        &owner.oms_product_version.om_product_id%type;

    v_prod_ver          &owner.oms_product_version.product_version%type;

    v_max_prod_ver      &owner.oms_product_version.product_version%type;

    v_appid             varchar2(6) := 'DC_CNV';

    v_prod_ver_cnt      number := 0;

    v_om_order_status   &owner.oms_order.om_order_status%type;

    v_ban               &owner.oms_order.ban%type;

    

begin

    dbms_output.put_line('IPV_Disconnect_with_pending_order Starting...');

    dbms_output.put_line('OM Order ID:          '||p_order_id);

    

    begin

        select om_product_id, om_order_status, product_version, ban

        into v_om_prod_id, v_om_order_status, v_prod_ver, v_ban

        from &owner.oms_order 

        where om_order_id = p_order_id

        and order_version_status in ('CU','CA');

        

    exception when no_data_found then

    

        dbms_output.put_line('There was no current or cancelled version of order.  Making max order version current.');

    

        update &owner.oms_order o

        set o.order_version_status = 'CU',

	    o.application_id = 'DC_CNV',

            o.sys_update_date = sysdate

        where o.om_order_id = p_order_id

        and o.order_version = (select max(oo.order_version) from &owner.oms_order oo

                               where oo.om_order_id = o.om_order_id);

                               

        select om_product_id, om_order_status, product_version, ban

        into v_om_prod_id, v_om_order_status, v_prod_ver, v_ban

        from &owner.oms_order 

        where om_order_id = p_order_id

        and order_version_status in ('CU','CA');

        

    end;

        

    dbms_output.put_line('BAN:                  '||v_ban);

    v_table_order := p_order_id;

    v_table_om_prod_id := v_om_prod_id;

    v_table_dc_group := 'IPV_Research_Needed';

    

    if v_om_order_status = 'CA' then

        dbms_output.put_line('Order has been cancelled');

    else

    

        dbms_output.put_line('OM Prod ID:           '||v_om_prod_id);

        

        select count(*) into v_prod_ver_cnt

        from &owner.oms_product_version

        where product_version = v_prod_ver;

        

        if v_prod_ver_cnt = 0 then

            dbms_output.put_line('Product Version does NOT exist in oms_product_version.  Use product_version from oms_order. '||v_prod_ver);

        else

            v_prod_ver := '';

            select cuappo.omprdver_1sq.nextval into v_prod_ver from dual;

            dbms_output.put_line('Product Version exists in oms_product_version.  Pull new product version from sequence. '||v_prod_ver);

            update &owner.oms_order

            set product_version = v_prod_ver,

                application_id = v_appid,

		sys_update_date = sysdate

            where product_version = (select max(product_version) from &owner.oms_order 

                                     where om_order_id = p_order_id

                                     and om_product_id = v_om_prod_id)

            and om_order_id = p_order_id

            and om_product_id = v_om_prod_id;   

        end if;

        

        select max(product_version) into v_max_prod_ver

        from &owner.oms_product_version

        where om_product_id = v_om_prod_id;

        

        insert into &owner.oms_product_version

        select OM_PRODUCT_ID, v_prod_ver, SYS_CREATION_DATE, sysdate, OPERATOR_ID, v_appid, DL_SERVICE_CODE, DL_UPDATE_STAMP, 

               OM_PRODUCT_STATUS, 'PE', ADDRESS_ID, PRODUCT_TYPE, DELIVERY_COMPL_DATE, NAME_ID, PROD_STATUS_RSN_CODE, SUBMARKET, TN_NPA, 

               TN_NXX, TN_LINENO, OM_TN_TYPE, POTS_ID, OMSA_GROUP_ID, OMILEC_GROUP_ID, OMUSOC_GROUP_ID, PRODUCT_SUB_TYPE, BAN_ID, SAG_ADDRESS_ID, 

               MSAG_ADDRESS_ID, WAIVE_IND, WAIVE_RSN, LEC_TYPE, CALLER_NAME_ID, BILLING_PRODUCT_ID, LL_EFF_DATE, LL_EXP_DATE, LL_TRIBAL_IND, 

               LL_FEDERAL_IND, LL_STATE_IND, LK_UP_IND, TELASSIST_IND, LL_CASE_NO, BUS_RES_IND, ALT_PROD_DESC, TAX_ID, SSN, IP_ID, NP_IND, CUSTOMER_PON, 

               OPX_SEQUENCE, COLLECTION_FLAG, OMRI_GROUP_ID, REQ_PROD_ID, FIXED_SM_IND, SHIP_ADDRESS_ID, RS_LINK_PROD_TP, RS_LINK_PROD_NO, BUSINESS_UNIT, 

               CROSS_BOUND_EX, REFER_TO, INP_NUMBER, TRACS_ID, WIRE_MAINT_IND, CLIPS_IND, OMDI_GROUP_ID, OMPIN_GROUP_ID, LRN_NUMBER, OMCNT_GROUP_ID, 

               TRACKING_STATUS, TN_VOICEDATA_TP, OMRN_GROUP_ID, LL_EFF_ISSUE_DATE, DC_LSP_ID, PRODUCT_EXTENSION, COMPRD_GROUP_ID, OMCI_GROUP_ID, 

               ASSOC_PROD_ID, BILL_RESTRICTION, MCP_IND, 'Y', SUPPRESS_NAF_IND, LL_QUAL_PROG, DOB, SSN_LAST_FOUR

        from &owner.oms_product_version o

        where o.om_product_id = v_om_prod_id

        and o.product_version = v_max_prod_ver;        

        

        update &owner.oms_product_version

				set mpv_ind = null,

				    sys_update_date = sysdate, 

				    application_id = 'DC_CNV'

				where om_product_id = v_om_prod_id

				and product_version = v_max_prod_ver

				and mpv_ind = 'Y';

				

				update &owner.oms_order

				set mpv_ind = null,

				    sys_update_date = sysdate, 

				    application_id = 'DC_CNV'

				where om_product_id = v_om_prod_id

				and product_version = v_max_prod_ver

				and mpv_ind = 'Y';

				

				update &owner.oms_order

				set mpv_ind = 'Y',

				    sys_update_date = sysdate, 

				    application_id = 'DC_CNV'

				where om_product_id = v_om_prod_id

				and product_version = v_prod_ver

				and mpv_ind is null

				;

    end if;

    dbms_output.put_line('---------------------------------------------------------------------');

    dbms_output.put_line(' ');

end IPV_Disc_with_pend_order;

------------------------------------------------------------------------------------------------------

--IPV_Research_Needed

------------------------------------------------------------------------------------------------------



procedure IPV_Research_Needed(pban             &owner.oms_order.ban%type,

                            p_order_id       &owner.oms_order.om_order_id%type,

                            p_om_prod_id     &owner.oms_order.om_product_id%type) is

    v_om_prod_id        &owner.oms_product_version.om_product_id%type;

    v_prod_ver          &owner.oms_product_version.product_version%type;

    v_max_prod_ver      &owner.oms_product_version.product_version%type;

    v_appid             varchar2(6) := 'DC_CNV';

    v_prod_ver_cnt      number := 0;

    v_om_order_status   &owner.oms_order.om_order_status%type;

    v_ban               &owner.oms_order.ban%type;

    

begin

    dbms_output.put_line('IPV_Research_Needed Starting...');

    dbms_output.put_line('OM Order ID:          '||p_order_id);

    

    begin

        select om_product_id, om_order_status, product_version, ban

        into v_om_prod_id, v_om_order_status, v_prod_ver, v_ban

        from &owner.oms_order 

        where om_order_id = p_order_id

        and order_version_status in ('CU','CA');

        

    exception when no_data_found then

    

        dbms_output.put_line('There was no current or cancelled version of order.  Making max order version current.');

    

        update &owner.oms_order o

        set o.order_version_status = 'CU',

	    o.application_id = 'DC_CNV',

            o.sys_update_date = sysdate

        where o.om_order_id = p_order_id

        and o.order_version = (select max(oo.order_version) from &owner.oms_order oo

                               where oo.om_order_id = o.om_order_id);

                               

        select om_product_id, om_order_status, product_version, ban

        into v_om_prod_id, v_om_order_status, v_prod_ver, v_ban

        from &owner.oms_order 

        where om_order_id = p_order_id

        and order_version_status in ('CU','CA');

        

    end;

        

    dbms_output.put_line('BAN:                  '||v_ban);

    v_table_order := p_order_id;

    v_table_om_prod_id := v_om_prod_id;

    v_table_dc_group := 'IPV_Research_Needed';

    

    if v_om_order_status = 'CA' then

        dbms_output.put_line('Order has been cancelled');

    else

    

        dbms_output.put_line('OM Prod ID:           '||v_om_prod_id);

        

        select count(*) into v_prod_ver_cnt

        from &owner.oms_product_version

        where product_version = v_prod_ver;

        

        if v_prod_ver_cnt = 0 then

            dbms_output.put_line('Product Version does NOT exist in oms_product_version.  Use product_version from oms_order. '||v_prod_ver);

        else

            v_prod_ver := '';

            select cuappo.omprdver_1sq.nextval into v_prod_ver from dual;

            dbms_output.put_line('Product Version exists in oms_product_version.  Pull new product version from sequence. '||v_prod_ver);

            update &owner.oms_order

            set product_version = v_prod_ver,

                application_id = v_appid,

		sys_update_date = sysdate

            where product_version = (select max(product_version) from &owner.oms_order 

                                     where om_order_id = p_order_id

                                     and om_product_id = v_om_prod_id)

            and om_order_id = p_order_id

            and om_product_id = v_om_prod_id;   

        end if;

        

        select max(product_version) into v_max_prod_ver

        from &owner.oms_product_version

        where om_product_id = v_om_prod_id;

        

        insert into &owner.oms_product_version

        select OM_PRODUCT_ID, v_prod_ver, SYS_CREATION_DATE, sysdate, OPERATOR_ID, v_appid, DL_SERVICE_CODE, DL_UPDATE_STAMP, 

               OM_PRODUCT_STATUS, 'PE', ADDRESS_ID, PRODUCT_TYPE, DELIVERY_COMPL_DATE, NAME_ID, PROD_STATUS_RSN_CODE, SUBMARKET, TN_NPA, 

               TN_NXX, TN_LINENO, OM_TN_TYPE, POTS_ID, OMSA_GROUP_ID, OMILEC_GROUP_ID, OMUSOC_GROUP_ID, PRODUCT_SUB_TYPE, BAN_ID, SAG_ADDRESS_ID, 

               MSAG_ADDRESS_ID, WAIVE_IND, WAIVE_RSN, LEC_TYPE, CALLER_NAME_ID, BILLING_PRODUCT_ID, LL_EFF_DATE, LL_EXP_DATE, LL_TRIBAL_IND, 

               LL_FEDERAL_IND, LL_STATE_IND, LK_UP_IND, TELASSIST_IND, LL_CASE_NO, BUS_RES_IND, ALT_PROD_DESC, TAX_ID, SSN, IP_ID, NP_IND, CUSTOMER_PON, 

               OPX_SEQUENCE, COLLECTION_FLAG, OMRI_GROUP_ID, REQ_PROD_ID, FIXED_SM_IND, SHIP_ADDRESS_ID, RS_LINK_PROD_TP, RS_LINK_PROD_NO, BUSINESS_UNIT, 

               CROSS_BOUND_EX, REFER_TO, INP_NUMBER, TRACS_ID, WIRE_MAINT_IND, CLIPS_IND, OMDI_GROUP_ID, OMPIN_GROUP_ID, LRN_NUMBER, OMCNT_GROUP_ID, 

               TRACKING_STATUS, TN_VOICEDATA_TP, OMRN_GROUP_ID, LL_EFF_ISSUE_DATE, DC_LSP_ID, PRODUCT_EXTENSION, COMPRD_GROUP_ID, OMCI_GROUP_ID, 

               ASSOC_PROD_ID, BILL_RESTRICTION, MCP_IND, 'Y', SUPPRESS_NAF_IND, LL_QUAL_PROG, DOB, SSN_LAST_FOUR

        from &owner.oms_product_version o

        where o.om_product_id = v_om_prod_id

        and o.product_version = v_max_prod_ver;        

    end if;

    dbms_output.put_line('---------------------------------------------------------------------');

    dbms_output.put_line(' ');

      EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

end IPV_Research_Needed;

   

------------------------------------------------------------------------------------------------------

--csLsCntct

------------------------------------------------------------------------------------------------------



procedure csLsCntct(pban             &owner.oms_order.ban%type,

                    p_order_id       &owner.oms_order.om_order_id%type,

                    p_om_prod_id     &owner.oms_order.om_product_id%type) is

    v_contact_seq_no    &owner.contact_info.contact_seq_no%type;

    v_max_link_seq_no    &owner.address_name_link.link_seq_no%type;

    v_next_link_seq_no  &owner.address_name_link.link_seq_no%type;

    

begin

    dbms_output.put_line('csLsCntct Starting...');

    

    begin

        select ci.contact_seq_no

        into v_contact_seq_no

        from &owner.contact_info ci,

             &owner.address_name_link anl

        where ci.contact_cust_id = pban

        and ci.contact_seq_no = anl.contact_seq_no(+)

        and ci.contact_cust_id = anl.ban(+)

        and anl.contact_seq_no is null;

        

    exception when no_data_found then

        dbms_output.put_line('[csLsCntct] ERROR!: No data found ');

    

    end;

    

    select max(link_seq_no)

    into v_max_link_seq_no

    from &owner.address_name_link

    where ban = pban

    and link_type = 'C';

    

    select cuappo.linkid_1sq.nextval into v_next_link_seq_no from dual;

    

    dbms_output.put_line('BAN...................'||pban);

    dbms_output.put_line('Next Link Seq No......'||v_next_link_seq_no);

    dbms_output.put_line('Contact Seq No........'||v_contact_seq_no);

    dbms_output.put_line('Max Link Seq No.......'||v_max_link_seq_no);

    

    insert into &owner.address_name_link

    select v_next_link_seq_no, CUSTOMER_ID, BAN, PRODUCT_ID, PRODUCT_TYPE, FC_SEQ_NO, LINK_TYPE, EFFECTIVE_DATE, NAME_ID, ADDRESS_ID, SYS_CREATION_DATE, 

           sysdate, OPERATOR_ID, 'DC_CNV', DL_SERVICE_CODE, DL_UPDATE_STAMP, EXPIRATION_DATE, CONV_RUN_NO, FOREIGN_SEQ_NO, IN_CITY_ZONE, 

           ALIAS, GEO_OVERRIDE_IND, v_contact_seq_no, CNT_SEQ_NO, NODE_ID, ADDR_POSITION, SHIPADR_SEQ_NO

    from &owner.address_name_link

    where ban = pban

    and link_seq_no = v_max_link_seq_no;

    

    dbms_output.put_line('DONE');

    

    dbms_output.put_line('---------------------------------------------------------------------');

    dbms_output.put_line(' ');

      EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

   

end csLsCntct;

   

------------------------------------------------------------------------------------------------------

--remove_invalid_ban

------------------------------------------------------------------------------------------------------



PROCEDURE remove_invalid_ban (p_bundle_ban  &owner.oms_ban_bundle.ban%type,

                              p_bundle_seq  &owner.oms_ban_bundle.bundle_seq%type) is

    

    cursor c_bundle_ban (v_c_bundle_ban &owner.oms_ban_bundle.ban%type,

                         v_c_bundle_seq &owner.oms_ban_bundle.bundle_seq%type)

    is

        select distinct bund.om_product_id as om_product_id

        from &owner.oms_bundle_ord_depend bund,

             &owner.oms_product_version opv,

             &owner.oms_ban_bundle obb

        where bund.bundle_seq = v_c_bundle_seq

        and bund.om_product_id = opv.om_product_id

        and obb.bundle_seq = bund.bundle_seq

        and opv.product_ver_status = 'CU'

        and obb.om_bundle_ver_status = 'CU'

        and opv.ban_id != v_c_bundle_ban;

                              

begin

    for v_rec in c_bundle_ban(p_bundle_ban, p_bundle_seq) loop



        delete from &owner.oms_bundle_ord_depend

        where bundle_seq = p_bundle_seq

        and om_product_id = v_rec.om_product_id;

    end loop;

      EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');



END remove_invalid_ban;

   

------------------------------------------------------------------------------------------------------

--IPV_with_no_pend_ord_prod_act

------------------------------------------------------------------------------------------------------



PROCEDURE IPV_with_no_pend_ord_prod_act (pban             &owner.oms_order.ban%type,

                                        p_order_id       &owner.oms_order.om_order_id%type,

                                        p_om_prod_id     &owner.oms_order.om_product_id%type

) IS

    v_om_prod_id        &owner.oms_product_version.om_product_id%type;

    v_prod_ver          &owner.oms_product_version.product_version%type;

    v_max_prod_ver      &owner.oms_product_version.product_version%type;

    v_appid             varchar2(6) := 'DC_CNV';

    v_bundle_cnt        number := 0;

    v_bundle_seq        &owner.oms_bundle_ord_depend.bundle_seq%type;

    v_bundle_ban        &owner.oms_ban_bundle.ban%type;

    v_bundle_ban_cnt    number := 0;

    v_om_order_status   &owner.oms_order.om_order_status%type;

BEGIN 

    dbms_output.put_line('IPV_with_no_pend_ord_prod_act Starting...');

    dbms_output.put_line('OM Order ID:          '||p_order_id);

    

    begin

    

         select om_product_id, om_order_status

         into v_om_prod_id, v_om_order_status

         from &owner.oms_order 

         where om_order_id = p_order_id

         and order_version_status in ('CU','CA');

    exception

    	when too_many_rows then

    	         select om_product_id, om_order_status

               into v_om_prod_id, v_om_order_status

               from &owner.oms_order 

               where om_order_id = p_order_id

               and order_version_status in ('CU','CA')

               and om_order_status != 'CP';

    end;

    

    v_table_order := p_order_id;

    v_table_om_prod_id := v_om_prod_id;

    v_table_dc_group := 'IPV_with_no_pend_ord_prod_act';

    

    if v_om_order_status = 'CA' then

        dbms_output.put_line('Order has been cancelled');

    else

    

        dbms_output.put_line('OM Prod ID:           '||v_om_prod_id);

            

        select cuappo.omprdver_1sq.nextval into v_prod_ver from dual;

        

        select max(product_version) into v_max_prod_ver

        from &owner.oms_product_version

        where om_product_id = v_om_prod_id;

        

        insert into &owner.oms_product_version

        select OM_PRODUCT_ID, v_prod_ver, SYS_CREATION_DATE, sysdate, OPERATOR_ID, v_appid, DL_SERVICE_CODE, DL_UPDATE_STAMP, 

               OM_PRODUCT_STATUS, 'PE', ADDRESS_ID, PRODUCT_TYPE, DELIVERY_COMPL_DATE, NAME_ID, PROD_STATUS_RSN_CODE, SUBMARKET, TN_NPA, 

               TN_NXX, TN_LINENO, OM_TN_TYPE, POTS_ID, OMSA_GROUP_ID, OMILEC_GROUP_ID, OMUSOC_GROUP_ID, PRODUCT_SUB_TYPE, BAN_ID, SAG_ADDRESS_ID, 

               MSAG_ADDRESS_ID, WAIVE_IND, WAIVE_RSN, LEC_TYPE, CALLER_NAME_ID, BILLING_PRODUCT_ID, LL_EFF_DATE, LL_EXP_DATE, LL_TRIBAL_IND, 

               LL_FEDERAL_IND, LL_STATE_IND, LK_UP_IND, TELASSIST_IND, LL_CASE_NO, BUS_RES_IND, ALT_PROD_DESC, TAX_ID, SSN, IP_ID, NP_IND, CUSTOMER_PON, 

               OPX_SEQUENCE, COLLECTION_FLAG, OMRI_GROUP_ID, REQ_PROD_ID, FIXED_SM_IND, SHIP_ADDRESS_ID, RS_LINK_PROD_TP, RS_LINK_PROD_NO, BUSINESS_UNIT, 

               CROSS_BOUND_EX, REFER_TO, INP_NUMBER, TRACS_ID, WIRE_MAINT_IND, CLIPS_IND, OMDI_GROUP_ID, OMPIN_GROUP_ID, LRN_NUMBER, OMCNT_GROUP_ID, 

               TRACKING_STATUS, TN_VOICEDATA_TP, OMRN_GROUP_ID, LL_EFF_ISSUE_DATE, DC_LSP_ID, PRODUCT_EXTENSION, COMPRD_GROUP_ID, OMCI_GROUP_ID, 

               ASSOC_PROD_ID, BILL_RESTRICTION, MCP_IND, 'Y', SUPPRESS_NAF_IND, LL_QUAL_PROG, DOB, SSN_LAST_FOUR

        from &owner.oms_product_version o

        where o.om_product_id = v_om_prod_id

        and o.product_version = v_max_prod_ver;               

        

        update &owner.oms_order

        set product_version = v_prod_ver,

            application_id = v_appid,

	    sys_update_date = sysdate

        where product_version = (select max(product_version) from &owner.oms_order 

                                 where om_order_id = p_order_id

                                 and om_product_id = v_om_prod_id)

        and om_order_id = p_order_id

        and om_product_id = v_om_prod_id;

        

        --Is OM_PRODUCT_ID in a bundle?    

        select count(*) into v_bundle_cnt

        from &owner.oms_bundle_ord_depend 

        where om_product_id = v_om_prod_id;

        

        if v_bundle_cnt > 0 then

            --Does bundle contain more than one ban?

            begin

		            select count(distinct opv.ban_id), obb.ban, obb.bundle_seq

		            into v_bundle_ban_cnt, v_bundle_ban, v_bundle_seq

		            from &owner.oms_product_version opv,

		                 &owner.oms_bundle_ord_depend bund,

		                 &owner.oms_ban_bundle obb

		            where opv.om_product_id = bund.om_product_id

		            and bund.bundle_seq = (select distinct bundle_seq 

		                                   from &owner.oms_bundle_ord_depend o

		                                   where o.om_product_id = v_om_prod_id

		                                   and o.bundle_seq_ver = (select max(o2.bundle_seq_ver)

		                                                            from &owner.oms_bundle_ord_depend o2

		                                                            where o2.om_product_id = o.om_product_id

		                                                            and o2.dependency_type not in ('AC')))

		            and opv.product_ver_status in ('CU','PE')

		            and bund.bundle_seq = obb.bundle_seq

		            and obb.om_bundle_ver_status = 'CU'

		            group by obb.ban, obb.bundle_seq

		            ;

		        exception

		        	when no_data_found then

		        		select count(distinct opv.ban_id), obb.ban, obb.bundle_seq

		            into v_bundle_ban_cnt, v_bundle_ban, v_bundle_seq

		            from &owner.oms_product_version opv,

		                 &owner.oms_bundle_ord_depend bund,

		                 &owner.oms_ban_bundle obb

		            where opv.om_product_id = bund.om_product_id

		            and bund.bundle_seq = (select distinct bundle_seq 

		                                   from &owner.oms_bundle_ord_depend o

		                                   where o.om_product_id = v_om_prod_id

		                                   and o.bundle_seq_ver = (select max(o2.bundle_seq_ver)

		                                                            from &owner.oms_bundle_ord_depend o2

		                                                            where o2.om_product_id = o.om_product_id

		                                                            and o2.dependency_type in ('AC')))

		            and opv.product_ver_status in ('CU','PE')

		            and bund.bundle_seq = obb.bundle_seq

		            and obb.om_bundle_ver_status = 'CU'

		            group by obb.ban, obb.bundle_seq

		            ;

		        end;

            

            dbms_output.put_line('BAN:                  '||v_bundle_ban);

            dbms_output.put_line('Bundle Seq:           '||v_bundle_seq);

            

            if v_bundle_ban_cnt > 1 then

                dbms_output.put_line('Multiple BANs within in a bundle');

                remove_invalid_ban(v_bundle_ban, v_bundle_seq);

            end if;

        else

            dbms_output.put_line('Product not in a bundle');

        end if;

    end if;

    

    dbms_output.put_line('---------------------------------------------------------------------');

    dbms_output.put_line(' ');

        EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

    

END IPV_with_no_pend_ord_prod_act;

   

------------------------------------------------------------------------------------------------------

--pom_cr_srv_agr_ver

------------------------------------------------------------------------------------------------------



procedure pom_cr_srv_agr_ver(p_ban          &owner.oms_order.ban%type,

                             p_om_order_id  &owner.oms_order.om_order_id%type,

                             p_om_prod_id   &owner.oms_order.om_product_id%type) is

    v_order_type            &owner.oms_order.order_type%type;

    bund_cntr               number := 0;

    

    cursor bundle_products(c_om_product_id  &owner.oms_bundle_ord_depend.om_product_id%type) is

        select bund.bundle_seq, bund.om_product_id, bund.om_order_id

        from &owner.oms_bundle_ord_depend bund,

             &owner.oms_ban_bundle obb,

             (select distinct bundle_seq from &owner.oms_bundle_ord_depend where om_product_id = c_om_product_id) a

        where bund.bundle_seq = a.bundle_seq

        and bund.bundle_seq = obb.bundle_seq

        and obb.om_bundle_ver_status = 'CU'

        and obb.om_bundle_status = 'AC'

        and bund.bundle_seq_ver = obb.bundle_seq_ver; 

                       

begin



    dbms_output.put_line('Starting pom_cr_srv_agr_ver...');

    dbms_output.put_line('    Om Order ID: '||p_om_order_id);

    dbms_output.put_line('    Om Prod ID:  '||p_om_prod_id);

    

    select count(*) into bund_cntr

    from &owner.oms_bundle_ord_depend bund,

         &owner.oms_ban_bundle obb,

         (select distinct bundle_seq from &owner.oms_bundle_ord_depend where om_product_id = p_om_prod_id) a

    where bund.bundle_seq = a.bundle_seq

    and bund.bundle_seq = obb.bundle_seq

    and obb.om_bundle_ver_status = 'CU'

    and obb.om_bundle_status = 'AC'

    and bund.bundle_seq_ver = obb.bundle_seq_ver;

    

    if bund_cntr > 0 then



        for v_rec in bundle_products(p_om_prod_id) loop

            select order_type into v_order_type

            from &owner.oms_order

            where om_order_id = v_rec.om_order_id

            and om_product_id = v_rec.om_product_id

            and order_version_status = 'CU';



            dbms_output.put_line('Order '||v_rec.om_order_id||' order_type: '||v_order_type);

            dbms_output.put_line('    OM Prod ID: (bundle)  '||v_rec.om_product_id);

            

            iF v_order_type in ('DC','CH','RE') then

                update &owner.oms_srv_agreement

                set sa_mode = 'EP',

                		sys_update_date = sysdate,

                		application_id = 'DC_CNV'

                where service_agreement_id in

                    (select osa.service_agreement_id

                    from &owner.oms_product_version opv,

                         &owner.oms_srv_agreement osa

                    where opv.om_product_id = v_rec.om_product_id

                    and opv.product_ver_status in ('CU','PE')

                    and opv.omsa_group_id = osa.omsa_group_id

                    and osa.price_plan in ('CLD5409B','CLDL178W')

                    and osa.sa_mode != 'EP');

                

                dbms_output.put_line('oms_srv_agreement: '||SQL%ROWCOUNT);

                    

                update &owner.oms_service_feature

                set sf_mode = 'EP',

                		sys_update_date = sysdate,

                		application_id = 'DC_CNV'

                where service_feature_id in

                    (select osa.service_feature_id

                    from &owner.oms_product_version opv,

                         &owner.oms_service_feature osa

                    where opv.om_product_id = v_rec.om_product_id

                    and opv.product_ver_status in ('CU','PE')

                    and opv.omsa_group_id = osa.omsa_group_id

                    and osa.price_plan in ('CLD5409B','CLDL178W')

                    and osa.sf_mode != 'EP');    

                

                dbms_output.put_line('oms_service_feature: '||SQL%ROWCOUNT);

                

            end if;

            

        end loop;

        

    else

        select order_type into v_order_type

        from &owner.oms_order

        where om_order_id = p_om_order_id

        and om_product_id = p_om_prod_id

        and order_version_status = 'CU';



        dbms_output.put_line('Order '||p_om_order_id||' order_type: '||v_order_type);

        dbms_output.put_line('    OM Prod ID: (bundle)  '||p_om_prod_id);

        

        if v_order_type = 'DC' then

            update &owner.oms_srv_agreement

            set sa_mode = 'EP',

            		sys_update_date = sysdate,

            		application_id = 'DC_CNV'

            where service_agreement_id in

                (select osa.service_agreement_id

                from &owner.oms_product_version opv,

                     &owner.oms_srv_agreement osa

                where opv.om_product_id = p_om_prod_id

                and opv.product_ver_status in ('CU','PE')

                and opv.omsa_group_id = osa.omsa_group_id

                and osa.price_plan in ('CLD5409B','CLDL178W')

                and osa.sa_mode != 'EP');

            

            dbms_output.put_line('oms_srv_agreement: '||SQL%ROWCOUNT);

                

            update &owner.oms_service_feature

            set sf_mode = 'EP',

            		sys_update_date = sysdate,

            		application_id = 'DC_CNV'

            where service_feature_id in

                (select osa.service_feature_id

                from &owner.oms_product_version opv,

                     &owner.oms_service_feature osa

                where opv.om_product_id = p_om_prod_id

                and opv.product_ver_status in ('CU','PE')

                and opv.omsa_group_id = osa.omsa_group_id

                and osa.price_plan in ('CLD5409B','CLDL178W')

                and osa.sf_mode != 'EP');    

            

            dbms_output.put_line('oms_service_feature: '||SQL%ROWCOUNT);

            

        end if;

        

    end if;

            

			dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

          EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

    

    

end pom_cr_srv_agr_ver;

   

------------------------------------------------------------------------------------------------------

--pp_not_found_research

------------------------------------------------------------------------------------------------------

	

procedure pp_not_found_research(p_ban          &owner.oms_order.ban%type,

                                p_om_order_id  &owner.oms_order.om_order_id%type,

                                p_om_prod_id   &owner.oms_order.om_product_id%type) is

		v_product_id					&owner.product.product_id%type;

		v_product_type				&owner.product.product_type%type;

		v_act_date						date;

		v_price_plan					&owner.price_plan.price_plan%type;

		

		cursor c_price_plan(v_ban &owner.service_agreement.ban%type,

												v_product_id &owner.service_agreement.product_id%type,

												v_product_type &owner.service_agreement.product_type%type,

												v_activity_date date) is

			select distinct ppr.price_plan into v_price_plan

		  FROM &owner.BILLING_ACCOUNT   BA,

		       &owner.PRODUCT           PRD,

		       &owner.SERVICE_AGREEMENT SA,

		       &owner.PRICE_PLAN        PP1,

		       &owner.PROMOTION_TERMS   PRMT,

		       &owner.PP_RANKING        PPR

		 WHERE SA.BAN = p_ban

		   AND SA.PRODUCT_ID = v_product_id

		   AND SA.PRODUCT_TYPE = v_product_type

		   AND SA.BAN = BA.BAN

		   AND SA.BAN = PRD.CUSTOMER_ID(+)

		   AND SA.M_PRODUCT_ID = PRD.PRODUCT_ID(+)

		   AND SA.M_PRODUCT_TYPE = PRD.PRODUCT_TYPE(+)

		   AND NVL(SA.EXPIRATION_DATE, '1-Jan-4700') >= v_act_date

		   AND SA.PRICE_PLAN = PP1.PRICE_PLAN

		   AND SA.EFFECTIVE_DATE >= PP1.EFFECTIVE_DATE

		   AND SA.EFFECTIVE_DATE <= NVL(PP1.EXPIRATION_DATE, '1-Jan-4700')

		   AND PRMT.PRICE_PLAN(+) = PP1.PRICE_PLAN

		   AND PRMT.EFFECTIVE_DATE(+) = PP1.EFFECTIVE_DATE

		   AND PP1.PRICE_PLAN = PPR.PRICE_PLAN

		   AND v_act_date BETWEEN PPR.EFFECTIVE_DATE AND NVL(PPR.EXPIRATION_DATE, '1-Jan-4700')

		   AND NVL(SA.PICC_IND, 'N') != 'Y'

		   AND (SA.EFFECTIVE_DATE <> NVL(SA.EXPIRATION_DATE, '1-Jan-4700'))

		   and ppr.product_type_code != sa.product_type;



begin



	 dbms_output.put_line('pp_not_found_research Starting.......');

	 dbms_output.put_line('OM Order ID: '||p_om_order_id);

	 dbms_output.put_line('OM Prod ID: '||p_om_prod_id);

	 dbms_output.put_line('BAN: '||p_ban);

	 v_act_date := sysdate;

	 

	 begin

	 

			 select distinct opv.billing_product_id, opv.product_type

			 into v_product_id, v_product_type

			 from &owner.oms_order oo,

			 			&owner.oms_product_version opv

			 where oo.om_product_id = opv.om_product_id

			 and oo.product_version = opv.product_version

			 and opv.product_ver_status IN ('CU','HI')

			 and oo.om_order_id = p_om_order_id

			 and oo.om_product_id = p_om_prod_id

			 and oo.ban = p_ban;

	 exception

	 		when too_many_rows then

 				select distinct opv.billing_product_id, opv.product_type

				 into v_product_id, v_product_type

				 from &owner.oms_order oo,

				 			&owner.oms_product_version opv

				 where oo.om_product_id = opv.om_product_id

				 and oo.product_version = opv.product_version

				 and opv.product_ver_status  IN ('CU','HI')

				 and oo.om_order_id = p_om_order_id

				 and oo.om_product_id = p_om_prod_id

				 and oo.ban = p_ban;

	 end;

	 		

	 

	 dbms_output.put_line('Prod ID: '||v_product_id);

	 dbms_output.put_line('Prod Type: '||v_product_type);

	 dbms_output.put_line('Activity Date: '||v_act_date);

	 

	 for v_rec in c_price_plan(p_ban,v_product_id, v_product_type,v_act_date) loop

	 

				 update &owner.oms_srv_agreement

				 set sa_mode = 'AD',

				 		 sys_update_date = sysdate,

				 		 application_id = 'DC_CNV'

				 where service_agreement_id = (select osa.service_agreement_id

				 															 from &owner.oms_srv_agreement osa,

															              (select omsa_group_id

															              from &owner.oms_product_version opv,

															                   (select om_product_id, product_version from &owner.oms_order

															                    where om_order_id = p_om_order_id 

															                    and order_version_status = 'CU' 

															                    and om_order_status = 'DC') a

															              where opv.om_product_id = a.om_product_id

															              and opv.product_version = a.product_version) b

																			where osa.omsa_group_id = b.omsa_group_id

																			and osa.expiration_date is null

																			and osa.sa_mode = 'AC'

																			and osa.price_plan = v_rec.price_plan);

			   dbms_output.put_line('    Invalid Price Plan: '||v_rec.price_plan);

  

   end loop;

  

																

			dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

          EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

	

end pp_not_found_research;



function isDateValid(f_date_to_test in varchar2)

          return boolean is

       vCount number := 0;

       vYear  number := 0;

       vMonth number := 0;

       vDay    number := 0;

  begin

       dbms_output.put_line('    Begin isDateValid function');

       

       vYear := to_number(substr(f_date_to_test,1,4));

       vMonth := to_number(substr(f_date_to_test,5,2));

       vDay := to_number(substr(f_date_to_test,7,2));

       

       dbms_output.put_line('      Date to test: '||f_date_to_test);

       

       if (vYear between 1950 and 2037) and

           (vMonth between 1 and 12) and

           (vDay between 1 and 31) then

       

           vCount := 1;

           --dbms_output.put_line('      Date is good');

       else

           vCount := 0;

           --dbms_output.put_line('      Date is bad');

       end if;

       

       return (vCount > 0);

       

  end;           

   

------------------------------------------------------------------------------------------------------

--GnDts_AddMonths

------------------------------------------------------------------------------------------------------	



procedure GnDts_AddMonths(p_ban          &owner.oms_order.ban%type,

                          p_om_order_id  &owner.oms_order.om_order_id%type,

                          p_om_prod_id   &owner.oms_order.om_product_id%type) is

    v_omri            &owner.oms_product_version.omri_group_id%type;

    v_discount_code    &owner.ban_discount.discount_code%type;

    v_eff_date        &owner.ban_discount.effective_date%type;

    v_exp_date        &owner.ban_discount.expiration_date%type;

    v_product_id      &owner.oms_product_version.billing_product_id%type;

    v_valid_date      &owner.ban_discount.effective_date%type;

    v_disc_plan_lvl		&owner.discount_plan.discount_plan_level%type;

    v_disc_dur			  &owner.discount_plan.discount_duration%type;

    vYear  number := 0;

    vMonth number := 0;

    vDay    number := 0;

    v_new_effective_date &owner.ban_discount.effective_date%type;

    

    cursor c_get_omri_group_id(v_ban &owner.oms_product_version.ban_id%type,

    													 v_om_prd_id &owner.oms_product_version.om_product_id%type) is

    select distinct omri_group_id 

    from &owner.oms_product_version

		where ban_id = p_ban

		  and om_product_id = p_om_prod_id

		  and omri_group_id is not null;

    

    cursor c_rel_info(v_omri_group_id  &owner.oms_product_version.omri_group_id%type) is

    select trim(substr(related_number,1,10)) as discount_code,

           nvl(trim(substr(related_number,11,8)),'00000000') as effective_date,

           nvl(trim(substr(related_number,20,8)),'00000000') as expiration_date,

           ri_id

    from &owner.oms_related_info

    where omri_group_id = v_omri_group_id;

    

    cursor c_check_ban_discount(v_ban &owner.oms_product_version.ban_id%type,

    														v_om_product_id &owner.oms_product_version.om_product_id%type) is

    	select opv.ban_id, trim(substr(ori.related_number,1,10)) as discount_code, opv.billing_product_id, opv.product_type,

			       to_date(substr(ori.related_number,11,8),'YYYYMMDD') as effective_date, to_date(substr(ori.related_number,20,8),'YYYYMMDD') as expiration_date,

			       opv.dl_service_code

			from &owner.oms_product_version opv,

			     &owner.oms_related_info ori

			where opv.ban_id = v_ban

			and opv.om_product_id = v_om_product_id

			and opv.product_ver_status = 'CU'

			and opv.omri_group_id = ori.omri_group_id

			and not exists        

			    (select 1 from &owner.ban_discount bd

			     where bd.ban = opv.ban_id

			     and bd.product_id = opv.billing_product_id

			     and bd.product_type = opv.product_type

			     and trim(substr(ori.related_number,1,10)) = trim(bd.discount_code));



begin



  dbms_output.put_line('GnDts_AddMonths Starting.....');

  

  dbms_output.put_line('BAN: '||p_ban);

  dbms_output.put_line('Om Prod ID: '||p_om_prod_id);

  dbms_output.put_line('Om Order ID: '||p_om_order_id); 

  

  begin

		  

		  select billing_product_id into v_product_id 

		  from &owner.oms_product_version

		  where om_product_id = p_om_prod_id

		  and ban_id = p_ban

		  and product_ver_status = 'CU';



	  

--	  select omri_group_id into v_omri from &owner.oms_product_version

--	  where ban_id = p_ban

--	  and om_product_id = p_om_prod_id

--	  and product_ver_status = 'CU';

  exception 

  	when no_data_found then

  		select billing_product_id into v_product_id 

		  from &owner.oms_product_version

		  where om_product_id = p_om_prod_id

		  and ban_id = p_ban

		  and product_ver_status = 'PE';

		  

		  

	  select omri_group_id into v_omri from &owner.oms_product_version

     where ban_id = p_ban

	  and om_product_id = p_om_prod_id

	  and product_ver_status = 'PE';



	end;

  dbms_output.put_line('Product ID: '||v_product_id);





	for v_omri_group_id_rec in c_get_omri_group_id(p_ban, p_om_prod_id) loop

	

			  dbms_output.put_line('  Inside OMRI loop');

	

			  dbms_output.put_line('  OMRI: '||v_omri_group_id_rec.omri_group_id);

			  

			  for v_rec in c_rel_info(v_omri_group_id_rec.omri_group_id) loop

			  

			    dbms_output.put_line('    Discount_code: '||v_rec.discount_code);

			    dbms_output.put_line('    Effective_date: '||v_rec.effective_date);

			    dbms_output.put_line('    RI_ID: '||v_rec.ri_id);

			

					select discount_plan_level, discount_duration into v_disc_plan_lvl, v_disc_dur

					from &owner.discount_plan

					where trim(discount_plan_cd) = trim(v_rec.discount_code)

					and exp_date is null;

					

					

					dbms_output.put_line('    Discount Plan Level: '||v_disc_plan_lvl);

					dbms_output.put_line('    Discount Duration  : '||v_disc_dur);

					

					if trim(v_rec.effective_date) in ('00000000','19000101') then

						 dbms_output.put_line('    Fixing effective_date');

						 v_rec.effective_date := to_char(add_months(to_date(v_rec.expiration_date,'YYYYMMDD'), (v_disc_dur * -1)),'YYYYMMDD');

			       dbms_output.put_line('    after fixing:  Effective_date: '||v_rec.effective_date);

			       

			       	  update &owner.oms_related_info

						    set related_number = rpad(v_rec.discount_code,10,' ')||v_rec.effective_date||' '||v_rec.expiration_date,

						      		sys_update_date = sysdate,

						      		application_id = 'DC_CNV'

						    where omri_group_id = v_omri_group_id_rec.omri_group_id

						    and ri_id = v_rec.ri_id;

			

				  end if;

			

					if trim(v_rec.expiration_date) in ('00000000','19000101') then

						 dbms_output.put_line('    Fixing expiration_date');

						 v_rec.expiration_date := to_char(add_months(to_date(v_rec.effective_date,'YYYYMMDD'), (v_disc_dur * 1)),'YYYYMMDD');

			       dbms_output.put_line('    after fixing:  expiration_date: '||v_rec.expiration_date);

			       

			       	  update &owner.oms_related_info

						    set related_number = rpad(v_rec.discount_code,10,' ')||v_rec.effective_date||' '||v_rec.expiration_date,

						      		sys_update_date = sysdate,

						      		application_id = 'DC_CNV'

						    where omri_group_id = v_omri_group_id_rec.omri_group_id

						    and ri_id = v_rec.ri_id;

			

				  end if;

				  

			

			    if(isDateValid(v_rec.effective_date) = true) then

			      dbms_output.put_line('        Date is good');

			    else

			      dbms_output.put_line('        Date is BAD');

			      

			  		if v_disc_plan_lvl = 'B' then

							raise_application_error(-20101, 'Discount is Ban Level');

			   		end if;

			

			      

			      begin

			      		--Pull effective date from the ban_discount table

			          select max(effective_date) into v_valid_date

			          from &owner.ban_discount

			          where ban = p_ban

			          and product_id = v_product_id

			          and trim(discount_code) = trim(v_rec.discount_code);

			          

			          

			      exception

			        when no_data_found then

			        	-- Pull effective date from the oms_srv_agreement table

			          

			        	begin

					        	select max(osa.ftr_effective_date) into v_valid_date

					          from &owner.discount_category dc,

					               &owner.oms_service_feature osa,

					               &owner.oms_product_version opv

					          where (dc.price_plan = osa.price_plan or dc.feature_code = osa.feature_code)

					          and osa.omsa_group_id = opv.omsa_group_id

					          and trim(dc.disc_plan_cd) = trim(v_rec.discount_code)

					          and opv.ban_id = p_ban

					          and opv.om_product_id = p_om_prod_id

					          and opv.product_ver_status = 'CU';

					      exception

					      	when no_data_found then

					      		begin

							        	select max(osa.ftr_effective_date) into v_valid_date

							          from &owner.discount_category dc,

							               &owner.oms_service_feature osa,

							               &owner.oms_product_version opv

							          where (dc.price_plan = osa.price_plan or dc.feature_code = osa.feature_code)

							          and osa.omsa_group_id = opv.omsa_group_id

							          and trim(dc.disc_plan_cd) = trim(v_rec.discount_code)

							          and opv.ban_id = p_ban

							          and opv.om_product_id = p_om_prod_id

							          and opv.product_ver_status = 'PE';

							      exception

							      	when no_data_found then

							      		dbms_output.put_line('    customer does not have correct pp/feature to get discount');

							      end;

					          

					      end;

					      	

			      

			      end;

			      

			      dbms_output.put_line('          Valid Date: '||v_valid_date);

			      

			      if trim(v_valid_date) is not null then

					      update &owner.oms_related_info

					      set related_number = rpad(v_rec.discount_code,10,' ')||to_char(v_valid_date,'YYYYMMDD')||' '||v_rec.expiration_date,

					      		sys_update_date = sysdate,

					      		application_id = 'DC_CNV'

					      where omri_group_id = v_omri_group_id_rec.omri_group_id

					      and ri_id = v_rec.ri_id;

					      

					  end if;

			    end if;

			    

			    dbms_output.put_line('  Expiration_date: '||v_rec.expiration_date);

			    if(isDateValid(v_rec.expiration_date) = true) then

			      dbms_output.put_line('        Date is good');

			    else

			      dbms_output.put_line('        Date is BAD');

			      

			   		if v_disc_plan_lvl = 'B' then

							raise_application_error(-20101, 'Discount is Ban Level');

			   		end if;

			

			    end if;

			    

			

			  

			  end loop;

	end loop;

	

	for v_ban_disc in c_check_ban_discount(p_ban, p_om_prod_id) loop

	

			   insert into &owner.ban_discount (BAN, DISCOUNT_CODE, PRODUCT_ID, PRODUCT_TYPE, DISC_SEQ_NO, SYS_CREATION_DATE, 

			   SYS_UPDATE_DATE, OPERATOR_ID, APPLICATION_ID, DL_SERVICE_CODE, DL_UPDATE_STAMP, EFFECTIVE_DATE, DISC_BY_OPID, 

			   EXPIRATION_DATE, ORDER_NO, ORIG_EXPIRATION_DATE, NODE_ID, AUTO_ADD_IND)

				 values (v_ban_disc.ban_id, v_ban_disc.discount_code, v_ban_disc.billing_product_id, v_ban_disc.product_type, 

				 cuappo.DISCOUNT_1SQ.nextval, sysdate, sysdate, 1059931, 'DC_CNV', v_ban_disc.dl_service_code, null, 

				 v_ban_disc.effective_date, 0, v_ban_disc.expiration_date, 0, null, null, '');



	

  end loop;

  

			dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

      

       EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

      

      

  

end GnDts_AddMonths;



   

------------------------------------------------------------------------------------------------------

--insert_into_history

------------------------------------------------------------------------------------------------------	



procedure insert_into_history(v_ban             &owner.oms_order.ban%type,

                                 v_om_order_id     &owner.oms_order.om_order_id%type,

                                 v_om_product_id   &owner.oms_order.om_product_id%type) is

                                 

   v_sa_rows_inserted             number := 0;

   v_sf_rows_inserted             number := 0;

   v_tot_sf_rows_inserted         number := 0;

   v_tot_sa_rows_inserted         number := 0;

   v_osa_rows_updated             number := 0;

   v_osf_rows_updated             number := 0;

   v_tot_osa_rows_updated         number := 0;

   v_tot_osf_rows_updated         number := 0;

   v_rows_processed               number := 0;

   dt                             char(50);



   cursor oms_cursor(t_ban             &owner.oms_order.ban%type,

                     t_om_order_id     &owner.oms_order.om_order_id%type,

                     t_om_product_id   &owner.oms_order.om_product_id%type) is

      select o.om_order_id, opv.ban_id as ban, opv.billing_product_id as product_id, opv.product_type, osa.price_plan, osa.sa_unique_id, osa.omsa_group_id, opv.product_version,

          (select omsa_group_id

           from &owner.oms_product_version opv3

           where opv3.product_version = (select max(opv2.product_version)

                                         from &owner.oms_product_version opv2

                                         where opv2.om_product_id = opv.om_product_id

                                         and opv2.ban_id = opv.ban_id

                                         and opv2.product_version < opv.product_version

                                         and opv2.product_ver_status in ('CU','HI','PE'))) as history_omsa_group_id

      from &owner.oms_order o, &owner.oms_product_version opv, &owner.oms_srv_agreement osa

      where o.om_order_id = t_om_order_id

      and o.om_product_id = t_om_product_id

      and o.ban = t_ban

      and o.order_version_status = 'CU'

      and opv.om_product_id = o.om_product_id

      and opv.product_version = o.product_version

      and opv.ban_id = o.ban

      and osa.omsa_group_id = opv.omsa_group_id

      and osa.sa_mode <> 'AD'

      and exists(select *

                 from &owner.service_agreement sa

                 where sa.ban = o.ban

                 and sa.product_id = opv.billing_product_id

                 and sa.product_type = opv.product_type

                 and sa.price_plan = osa.price_plan

                 and sa.sa_unique_id = osa.sa_unique_id

                 and sa.expiration_date is null)

      and not exists (select *

                       from &owner.oms_order o2

                       where o2.ban = o.ban

                       and o2.om_product_id = o.om_product_id

                       and o2.order_version_status = 'CU'

                       and o2.om_order_status in ('NE','DE','DC')

                       and o2.om_order_id < o.om_order_id)

      and not exists(select *

                     from &owner.oms_srv_agreement osa2

                     where osa2.omsa_group_id = (select omsa_group_id

                                                 from &owner.oms_product_version opv3

                                                 where opv3.product_version = (select max(opv2.product_version)

                                                                               from &owner.oms_product_version opv2

                                                                               where opv2.om_product_id = opv.om_product_id

                                                                               and opv2.ban_id = opv.ban_id

                                                                               and opv2.product_version < opv.product_version

                                                                               and opv2.product_ver_status in ('CU','HI')))

                     and osa2.sa_unique_id = osa.sa_unique_id);    

                     

   cursor  oms_cursor_2(i_ban              in &owner.oms_order.ban%type,

                      i_om_order_id      in &owner.oms_order.om_order_id%type,

                      i_om_product_id    in &owner.oms_order.om_product_id%type) is

      select o.ban, o.om_order_id, opv.billing_product_id as product_id, opv.product_type, osa.price_plan, osa.sa_unique_id, opv.omsa_group_id

      from &owner.oms_order o, &owner.oms_product_version opv, &owner.oms_srv_agreement osa

      where o.om_order_id = i_om_order_id

      and o.om_product_id = i_om_product_id

      and o.ban = i_ban

      and o.order_version_status = 'CU'

      and opv.om_product_id = o.om_product_id

      and opv.product_version = o.product_version

      and opv.ban_id = o.ban

      and osa.omsa_group_id = opv.omsa_group_id

      and osa.sa_mode = 'AC'

      and not exists(select *

                     from &owner.service_agreement sa

                     where sa.ban = o.ban

                     and sa.product_id = opv.billing_product_id

                     and sa.price_plan = osa.price_plan

                     and sa.sa_unique_id = osa.sa_unique_id)

      and not exists(select *

                     from &owner.oms_product_version opv1, &owner.oms_srv_agreement osa1

                     where opv1.om_product_id = opv.om_product_id

                     and opv1.product_version < opv.product_version

                     and opv1.ban_id = opv.ban_id

                     and opv1.product_ver_status in ('CU','HI')

                     and osa1.omsa_group_id = opv1.omsa_group_id

                     and osa1.price_plan = osa.price_plan

                     and osa1.sa_unique_id = osa.sa_unique_id)

                     ;

                     

   cursor  oms_cursor_3(i_ban              in &owner.oms_order.ban%type,

                      i_om_order_id      in &owner.oms_order.om_order_id%type,

                      i_om_product_id    in &owner.oms_order.om_product_id%type) is

      select o.ban, o.om_order_id, opv.billing_product_id as product_id, opv.product_type, osa.price_plan, osa.sa_unique_id, opv.omsa_group_id

      from &owner.oms_order o, &owner.oms_product_version opv, &owner.oms_srv_agreement osa

      where o.om_order_id = i_om_order_id

      and o.om_product_id = i_om_product_id

      and o.ban = i_ban

      and o.order_version_status = 'CU'

      and opv.om_product_id = o.om_product_id

      and opv.product_version = o.product_version

      and opv.ban_id = o.ban

      and osa.omsa_group_id = opv.omsa_group_id

      and osa.sa_mode = 'AC'

      and not exists(select *

                     from &owner.service_agreement sa

                     where sa.ban = o.ban

                     and sa.product_id = opv.billing_product_id

                     and sa.price_plan = osa.price_plan

                     and sa.sa_unique_id = osa.sa_unique_id

                     and sa.expiration_date is null)

      and osa.price_plan = 'SCRCMP12' and o.ban = 301862751;

                                 

   begin

   		dbms_output.put_line('Starting insert_into_history.....');

   

   v_sa_rows_inserted := 0;

   v_sf_rows_inserted := 0;

   v_osa_rows_updated := 0;

   v_osf_rows_updated := 0;

   v_rows_processed := v_rows_processed + 1;

   

   for oms_pointer in oms_cursor(v_ban, v_om_order_id, v_om_product_id) loop

      

      insert into &owner.oms_srv_agreement using

      select &owner.OMSAGR_1SQ.nextval,   SYS_CREATION_DATE,   SYS_UPDATE_DATE,  OPERATOR_ID,   APPLICATION_ID,   DL_SERVICE_CODE,  DL_UPDATE_STAMP,  

             oms_pointer.history_omsa_group_id, BAN,  PRODUCT_ID, PRODUCT_TYPE,  PRICE_PLAN, PP_SEQ_NO,  PP_VER_NO,  PP_EFFECTIVE_DATE,   CUSTOMER_ID,   EFFECTIVE_DATE,   

             SERVICE_TYPE,  EXPIRATION_DATE,  PP_LEVEL_CODE, DEALER_CODE,   CONV_RUN_NO,   EFFECTIVE_ISSUE_DATE,   EXPIRATION_ISSUE_DATE,  TRX_ID,  

             ORDER_NO,   FTR_SPREAD_IND,   SA_UNIQUE_ID,  ORIG_FULL_PRICE_PLAN,   ORIG_FULL_PP_EFF_DATE,  REVERSE_HANDLE_STS,  PICC_IND,   

             PP_MAC_MMC_INT,   SPLIT_DEALER_CODE,   IU_SHARED_NODE_ID,   'AD', MEDIA_TYPE, BUNDLE_CODE,   BUNDLE_CODE_SEQ,  DISCONNECT_RSN,   

             SUB_BUNDLE_CODE,  SUB_BUNDLE_CODE_SEQ, PP_PROMO,   PROMO_SA_UNIQUE_ID,  ORDER_AGGREGATOR, PON

      from &owner.oms_srv_agreement

      where omsa_group_id in (oms_pointer.omsa_group_id)

      and sa_unique_id = oms_pointer.sa_unique_id

      and not exists (select *

                      from &owner.oms_srv_agreement

                      where omsa_group_id in (oms_pointer.history_omsa_group_id)

                      and sa_unique_id = oms_pointer.sa_unique_id);



      v_sa_rows_inserted := SQL%ROWCOUNT;

      v_tot_sa_rows_inserted := v_tot_sa_rows_inserted + v_sa_rows_inserted;

      



      insert into &owner.oms_service_feature using

      select &owner.OMSFT_1SQ.nextval,  SYS_CREATION_DATE,  SYS_UPDATE_DATE,  OPERATOR_ID,  APPLICATION_ID,  DL_SERVICE_CODE,  DL_UPDATE_STAMP,  

             oms_pointer.history_omsa_group_id,  BAN,  PRODUCT_ID,  PRODUCT_TYPE,  PRICE_PLAN,  PP_SEQ_NO,  SERVICE_FTR_SEQ_NO,  FTR_PP_VER_NO,  PP_EFFECTIVE_DATE,  

             CUSTOMER_ID,  FEATURE_CODE,  SERVICE_TYPE,  PP_LEVEL_CODE,  FTR_EFFECTIVE_DATE,  FTR_EFF_RSN_CODE,  FTR_EXPIRATION_DATE,  FTR_EXP_RSN_CODE,  

             SERVICE_FTR_QTY,  FTR_SPECIAL_TELNO,  FTR_SPECIAL_TN_DATE,  PAGER_TYPE,  PAGER_CLASS,  PAGER_TN,  PAGER_PIN,  RC_WAIVER_EFF_DATE,  

             RC_WAIVER_EXPR_DATE,  RC_WAIVER_RSN,  RC_WAIVER_OPID,  CONV_RUN_NO,  LSA_CODE,  FTR_EFF_ISSUE_DATE,  FTR_EXP_ISSUE_DATE,  FTR_TRX_ID,  

             FTR_PREV_SEQ_NO,  FTR_VAD_TN,  FTR_ADD_SW_PRM,  ORDER_NO,  SF_UNIQUE_ID,  SA_UNIQUE_ID,  CUST_SPEC_CATEGORY,  DEALER_CODE,  SPLIT_DEALER_CODE,  

             'AD',  TDNP_DATE,  TO_BAN,  RC_DISCOUNT_AMT_PCT,  RC_DISCOUNT_TYPE,  RC_DISCOUNT_REASON,  SERVICE_EFFECTIVE_DATE,  SERVICE_EXPIRATION_DATE,  

             EXTENDED_INFO_HDR_ID,  DISCONNECT_RSN,  MEDIA_TYPE,  VP_RATE,  BUNDLE_CODE,  BUNDLE_CODE_SEQ,  SUB_BUNDLE_CODE,  SUB_BUNDLE_CODE_SEQ,  

             ORDER_AGGREGATOR,  BUNDLE_SEQ,  BDL_REQ_IND,  PON

      from &owner.oms_service_feature

      where omsa_group_id in (oms_pointer.omsa_group_id)

      and sa_unique_id = oms_pointer.sa_unique_id

      and not exists (select *

                      from &owner.oms_service_feature

                      where omsa_group_id in (oms_pointer.history_omsa_group_id)

                      and sa_unique_id = oms_pointer.sa_unique_id);

                                            

      v_sf_rows_inserted := SQL%ROWCOUNT;

      v_tot_sf_rows_inserted := v_tot_sf_rows_inserted + v_sf_rows_inserted;

      

         dbms_output.put_line(' Inserting into history Ban: ' || v_ban || 

                              ' Order: ' || v_om_order_id || 

                              ' Product_id: ' || trim(oms_pointer.product_id) ||

                              ' Product_type: ' || trim(oms_pointer.product_type) ||

                              ' Om_order_id: ' || rpad(oms_pointer.om_order_id,10) || 

                              ' Price_plan: ' || trim(oms_pointer.price_plan) ||

                              ' SA Unique_id: ' || oms_pointer.omsa_group_id ||

                              ' OMSA Inserted: ' || v_sa_rows_inserted ||

                              ' OMSF Inserted: ' || v_sf_rows_inserted);

      

      end loop;

      

     for oms_pointer_2 in oms_cursor_2(v_ban, v_om_order_id, v_om_product_id) loop

      

         

         

          update &owner.oms_srv_agreement

          set sa_mode = 'AD',

              application_id = 'DC_CNV',

              sys_update_date = sysdate

          where omsa_group_id = oms_pointer_2.omsa_group_id

          and price_plan = oms_pointer_2.price_plan

          and sa_unique_id = oms_pointer_2.sa_unique_id;

          

          v_osa_rows_updated := SQL%ROWCOUNT;

          v_tot_osa_rows_updated := v_tot_osa_rows_updated + v_osa_rows_updated;

          

          update &owner.oms_service_feature

          set sf_mode = 'AD',

              application_id = 'DC_CNV',

              sys_update_date = sysdate

          where omsa_group_id = oms_pointer_2.omsa_group_id

          and price_plan = oms_pointer_2.price_plan

          and sa_unique_id = oms_pointer_2.sa_unique_id

          and sf_mode in ('AC','IN');

          

          v_osf_rows_updated := SQL%ROWCOUNT;

          v_tot_osf_rows_updated := v_tot_osf_rows_updated + v_osf_rows_updated;

          

          update &owner.oms_service_feature

          set sf_mode = 'EX',

              ftr_expiration_date = ftr_effective_date,

              application_id = 'DC_CNV',

              sys_update_date = sysdate

          where omsa_group_id = oms_pointer_2.omsa_group_id

          and price_plan = oms_pointer_2.price_plan

          and sa_unique_id = oms_pointer_2.sa_unique_id

          and sf_mode in ('EP');

          

          v_osf_rows_updated := v_osf_rows_updated + SQL%ROWCOUNT;

          v_tot_osf_rows_updated := v_tot_osf_rows_updated + v_osf_rows_updated;

      

          dbms_output.put_line('BAN: ' || v_ban || 

                              ' Order: ' || v_om_order_id || 

                              ' Product_id: ' || trim(oms_pointer_2.product_id) ||

                              ' Product_type: ' || trim(oms_pointer_2.product_type) ||   ' Changing SA Mode Price plan: ' || oms_pointer_2.price_plan || ' SA Unique_id: ' || oms_pointer_2.sa_unique_id || ' OSA Updated: ' ||

                                v_osa_rows_updated || ' OSF Updated: ' || v_osf_rows_updated);

         

      end loop;

      

      for oms_pointer_3 in oms_cursor_3(v_ban, v_om_order_id, v_om_product_id) loop

      

         

         

          update &owner.oms_srv_agreement

          set sa_mode = 'AD',

              application_id = 'DC_CNV',

              sys_update_date = sysdate

          where omsa_group_id = oms_pointer_3.omsa_group_id

          and price_plan = oms_pointer_3.price_plan

          and sa_unique_id = oms_pointer_3.sa_unique_id;

          

          v_osa_rows_updated := SQL%ROWCOUNT;

          v_tot_osa_rows_updated := v_tot_osa_rows_updated + v_osa_rows_updated;

          

          update &owner.oms_service_feature

          set sf_mode = 'AD',

              application_id = 'DC_CNV',

              sys_update_date = sysdate

          where omsa_group_id = oms_pointer_3.omsa_group_id

          and price_plan = oms_pointer_3.price_plan

          and sa_unique_id = oms_pointer_3.sa_unique_id

          and sf_mode in ('AC','IN');

          

          v_osf_rows_updated := SQL%ROWCOUNT;

          v_tot_osf_rows_updated := v_tot_osf_rows_updated + v_osf_rows_updated;

          

          update &owner.oms_service_feature

          set sf_mode = 'EX',

              ftr_expiration_date = ftr_effective_date,

              application_id = 'DC_CNV',

              sys_update_date = sysdate

          where omsa_group_id = oms_pointer_3.omsa_group_id

          and price_plan = oms_pointer_3.price_plan

          and sa_unique_id = oms_pointer_3.sa_unique_id

          and sf_mode in ('EP');

          

          v_osf_rows_updated := v_osf_rows_updated + SQL%ROWCOUNT;

          v_tot_osf_rows_updated := v_tot_osf_rows_updated + v_osf_rows_updated;

      

          dbms_output.put_line('BAN: ' || v_ban || 

                              ' Order: ' || v_om_order_id || 

                              ' Product_id: ' || trim(oms_pointer_3.product_id) ||

                              ' Product_type: ' || trim(oms_pointer_3.product_type) ||   ' Changing SA Mode Price plan: ' || oms_pointer_3.price_plan || ' SA Unique_id: ' || oms_pointer_3.sa_unique_id || ' OSA Updated: ' ||

                                v_osa_rows_updated || ' OSF Updated: ' || v_osf_rows_updated);

         

      end loop;

			dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

          EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

      

   

end insert_into_history;

   

------------------------------------------------------------------------------------------------------

--No_Script_Needed_MnlnInfoINT

------------------------------------------------------------------------------------------------------	

   

procedure No_Script_Needed_MnlnInfoINT(p_ban          &owner.oms_order.ban%type,

										                   p_om_order_id  &owner.oms_order.om_order_id%type,

	                									   p_om_prod_id   &owner.oms_order.om_product_id%type) is

	                									         

	 begin

	 	

	 		dbms_output.put_line('Starting No_Script_Needed_MainlineInfoINT.....');

      dbms_output.put_line('OM Order ID:          '||p_om_order_id);

      dbms_output.put_line('OM Prod ID:           '||p_om_prod_id);

      dbms_output.put_line('BAN:                  '||p_ban);

	 		

	 	

	 		update &owner.oms_order

			set sr_no = null,

	  		  lci_no = null,

	    		move_disconnect_date = null,

	    		application_id = 'DC_CNV',

	    		sys_update_date = sysdate

			where om_order_id = p_om_order_id

			and order_version_status = 'CU';

			

			dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

          EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');



	                									          

	 end No_Script_Needed_MnlnInfoINT;

   

------------------------------------------------------------------------------------------------------

--correct_sa_mode

------------------------------------------------------------------------------------------------------	 



	 procedure correct_sa_mode(pban             &owner.oms_order.ban%type,

                             p_order_id       &owner.oms_order.om_order_id%type,

                             p_om_prod_id     &owner.oms_order.om_product_id%type) is



			   dt                       char(50);

			   v_app_id                 char(6) := 'DC_CNV';

			   v_tot_rows_processed     number := 0;

			   v_tot_rows_updated       number := 0;

			   v_rows_updated           number := 0;

			   v_sf_rows_updated        number := 0;

			   v_sf_tot_rows_updted     number := 0;

			

			   cursor oms_sa_cursor(t_ban               in &owner.oms_order.ban%type,

			                        t_om_order_id       in &owner.oms_order.om_order_id%type,

			                        t_om_product_id     in &owner.oms_order.om_product_id%type) is

			   select osa.ban, osa.product_id, osa.product_type, osa.omsa_group_id, osa.price_plan, osa.pp_seq_no, osa.sa_unique_id, osa.sa_mode, 'AC' as correct_sa_mode, o.order_type

			   from &owner.oms_order o, &owner.oms_product_version opv, &owner.oms_srv_agreement osa

			   where o.om_order_id = t_om_order_id

			   and o.om_product_id = t_om_product_id

			   and o.ban = t_ban

			   and o.order_version_status = 'CU'

			   and o.om_order_status <> 'CP'

			   and opv.product_version = o.product_version

			   and osa.omsa_group_id = opv.omsa_group_id

			   and osa.sa_mode not in ('AD','AC','EP')

			   and exists(select *

			              from &owner.service_agreement sa

			              where sa.ban = osa.ban

			              and sa.price_plan = osa.price_plan

			              and sa.sa_unique_id = osa.sa_unique_id

			              and sa.pp_seq_no = osa.pp_seq_no

			              and sa.expiration_date is null)

			   and exists(select *

			              from &owner.oms_service_feature osf

			              where osf.omsa_group_id = osa.omsa_group_id

			              and osf.price_plan = osa.price_plan

			              and osf.sa_unique_id = osa.sa_unique_id

			              and osf.pp_seq_no = osa.pp_seq_no

			              and osf.sf_mode = 'AC')

			   union

			   select osa.ban, osa.product_id, osa.product_type, osa.omsa_group_id, osa.price_plan, osa.pp_seq_no, osa.sa_unique_id, osa.sa_mode, 'AD' as correct_sa_mode, o.order_type

			   from &owner.oms_order o, &owner.oms_product_version opv, &owner.oms_srv_agreement osa

			   where o.om_order_id = t_om_order_id

			   and o.om_product_id = t_om_product_id

			   and o.ban = t_ban

			   and o.order_version_status = 'CU'

			   and o.om_order_status <> 'CP'

			   and opv.product_version = o.product_version

			   and osa.omsa_group_id = opv.omsa_group_id

			   and osa.sa_mode not in ('AD','AC','EP')

			   and not exists(select *

			                  from &owner.service_agreement sa

			                  where sa.ban = osa.ban

			                  and sa.price_plan = osa.price_plan

			                  and sa.pp_seq_no = osa.pp_seq_no

			                  and sa.sa_unique_id = osa.sa_unique_id)

			   and not exists(select *

			                  from &owner.oms_service_feature osf

			                  where osf.omsa_group_id = osa.omsa_group_id

			                  and osf.price_plan = osa.price_plan

			                  and osf.sa_unique_id = osa.sa_unique_id

			                  and osf.pp_seq_no = osa.pp_seq_no

			                  and osf.sf_mode in ('AC'))

			   union

			   select osa.ban, osa.product_id, osa.product_type, osa.omsa_group_id, osa.price_plan, osa.pp_seq_no, osa.sa_unique_id, osa.sa_mode, 'EP' as correct_sa_mode, o.order_type

			   from &owner.oms_order o, &owner.oms_product_version opv, &owner.oms_srv_agreement osa

			   where o.om_order_id = t_om_order_id

			   and o.om_product_id = t_om_product_id

			   and o.ban = t_ban

			   and o.order_version_status = 'CU'

			   and o.om_order_status <> 'CP'

			   and opv.product_version = o.product_version

			   and osa.omsa_group_id = opv.omsa_group_id

			   and osa.sa_mode not in ('AD','AC','EP')

			   and exists(select *

			              from &owner.service_agreement sa

			              where sa.ban = osa.ban

			              and sa.price_plan = osa.price_plan

			              and sa.pp_seq_no = osa.pp_seq_no

			              and sa.sa_unique_id = osa.sa_unique_id)

			   and not exists(select *

			                  from &owner.oms_service_feature osf

			                  where osf.omsa_group_id = osa.omsa_group_id

			                  and osf.price_plan = osa.price_plan

			                  and osf.sa_unique_id = osa.sa_unique_id

			                  and osf.pp_seq_no = osa.pp_seq_no

			                  and osf.sf_mode in ('AC','AD','IN'))

			   and exists(select *

			              from &owner.oms_service_feature osf

			              where osf.omsa_group_id = osa.omsa_group_id

			              and osf.price_plan = osa.price_plan

			              and osf.sa_unique_id = osa.sa_unique_id

			              and osf.pp_seq_no = osa.pp_seq_no

			              and osf.sf_mode in ('EP'))

			   union

			   select osa.ban, osa.product_id, osa.product_type, osa.omsa_group_id, osa.price_plan, osa.pp_seq_no, osa.sa_unique_id, osa.sa_mode, 'AD' as correct_sa_mode, o.order_type

			   from &owner.oms_order o, &owner.oms_product_version opv, &owner.oms_srv_agreement osa

			   where o.om_order_id = t_om_order_id

			   and o.om_product_id = t_om_product_id

			   and o.ban = t_ban

			   and o.order_version_status = 'CU'

			   and o.om_order_status <> 'CP'

			   and opv.product_version = o.product_version

			   and osa.omsa_group_id = opv.omsa_group_id

			   and osa.sa_mode not in ('AD','EP')

			   and o.order_type = 'NI';

                  

   begin

   	  dbms_output.put_line('correct_sa_mode Starting...');

    

      

      v_rows_updated := 0;

      v_sf_rows_updated := 0;

   

      for oms_sa_pointer in oms_sa_cursor(pban, p_order_id, p_om_prod_id) loop

      

         update &owner.oms_srv_agreement

         set sa_mode = oms_sa_pointer.correct_sa_mode,

             sys_update_date = sysdate,

             application_id = v_app_id

         where omsa_group_id = oms_sa_pointer.omsa_group_id

         and sa_unique_id = oms_sa_pointer.sa_unique_id

         and price_plan = oms_sa_pointer.price_plan

         and pp_seq_no = oms_sa_pointer.pp_seq_no  

         and sa_mode = oms_sa_pointer.sa_mode;

         

         v_rows_updated := SQL%ROWCOUNT;

         v_tot_rows_updated := v_tot_rows_updated + v_rows_updated;

         

         if(oms_sa_pointer.order_type = 'NI' and oms_sa_pointer.correct_sa_mode = 'AD') then

         

            update &owner.oms_service_feature

            set sf_mode = oms_sa_pointer.correct_sa_mode,

                sys_update_date = sysdate,

                application_id = v_app_id

            where omsa_group_id = oms_sa_pointer.omsa_group_id

            and sa_unique_id = oms_sa_pointer.sa_unique_id

            and price_plan = oms_sa_pointer.price_plan

            and pp_seq_no = oms_sa_pointer.pp_seq_no  

            and sf_mode in ('IN','AC');

         

         v_sf_rows_updated := SQL%ROWCOUNT;

         v_sf_tot_rows_updted := v_sf_tot_rows_updted + v_sf_rows_updated;

         

         end if;

      

         dbms_output.put_line('Order: ' || p_order_id ||

                              ' Ban: ' || pban ||

                              ' Om product id: ' || p_om_prod_id ||

                              ' Correcting sa_mode for:  ' ||

                              ' Product Id: ' || oms_sa_pointer.product_id ||

                              ' Product type: ' || oms_sa_pointer.product_type ||

                              ' Omsa Group Id: ' || oms_sa_pointer.omsa_group_id ||

                              ' Price plan: ' || oms_sa_pointer.price_plan ||

                              ' Pp Seq No: ' || oms_sa_pointer.pp_seq_no ||

                              ' Sa unique id: ' || oms_sa_pointer.sa_unique_id ||

                              ' Current SA mode: ' || oms_sa_pointer.sa_mode ||

                              ' New SA mode: ' || oms_sa_pointer.correct_sa_mode ||

                              ' Rows Updated: ' || v_rows_updated ||

                              ' SF Rows Updated: ' || v_sf_rows_updated);

                              

      end loop;

      

      if(v_rows_updated = 0) then

      

         dbms_output.put_line('Order: ' || p_order_id ||

                              ' Ban: ' || pban ||

                              ' Om product id: ' || p_om_prod_id ||

                              ' Not Updated.');

      

      end if;

      

      v_tot_rows_processed := v_tot_rows_processed + 1;

      dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

          EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

   

   end correct_sa_mode;

   

------------------------------------------------------------------------------------------------------

--correct_sa_mode_no_script

------------------------------------------------------------------------------------------------------  



PROCEDURE correct_sa_mode_no_script (p_ban          &owner.oms_order.ban%type,

                          p_om_order_id  &owner.oms_order.om_order_id%type,

                          p_om_prod_id   &owner.oms_order.om_product_id%type) is



			i_ban                     &owner.oms_order.ban%TYPE;

			i_om_order_id             &owner.oms_order.om_order_id%TYPE;

			i_om_product_id           &owner.oms_order.om_product_id%TYPE;

			marker                    &owner.oms_srv_agreement.application_id%TYPE;

			active                    &owner.oms_srv_agreement.sa_mode%TYPE;

			expire                    &owner.oms_srv_agreement.sa_mode%TYPE;

			add                       &owner.oms_srv_agreement.sa_mode%TYPE;

			v_cnt                     INTEGER:=0;

			t_cnt                     INTEGER:=0;

			l_cnt                     INTEGER:=0;

			dt                        CHAR(30);           --for date/time

			

			type osa is table of &owner.oms_srv_agreement%ROWTYPE;

			osa_array osa;



			-----------------------------------------------------------------------------------------------------------------------

			--  M A I N   P R O C E D U R E

			-----------------------------------------------------------------------------------------------------------------------

			BEGIN

					dbms_output.put_line('correct_sa_mode_no_script Starting...');

    

			

			v_cnt :=0;

			

			SELECT O.*

			  BULK COLLECT INTO osa_array

			  FROM &owner.SERVICE_AGREEMENT S

			     , &owner.OMS_SRV_AGREEMENT O

			 WHERE S.BAN            = O.BAN

			   AND S.PRODUCT_ID     = O.PRODUCT_ID

			   AND S.PRODUCT_TYPE   = O.PRODUCT_TYPE

			   AND S.EFFECTIVE_DATE = O.EFFECTIVE_DATE

			   AND S.SA_UNIQUE_ID   = O.SA_UNIQUE_ID

			   AND S.PP_SEQ_NO      = O.PP_SEQ_NO

			   AND S.BAN = p_ban

			   AND O.OMSA_GROUP_ID IN

			       (SELECT OMSA_GROUP_ID

			          FROM &owner.OMS_PRODUCT_VERSION

			         WHERE (OM_PRODUCT_ID, PRODUCT_VERSION) IN

			               (SELECT OM_PRODUCT_ID, PRODUCT_VERSION

			                  FROM &owner.OMS_ORDER

			                 WHERE OM_ORDER_ID = p_om_order_id

			                   AND ORDER_VERSION_STATUS = 'CU'

			                   AND OM_ORDER_STATUS IN ('DC','DE')))

			   AND NOT SA_MODE IN ('AC', 'AD', 'EP');

			

			

			IF SQL%ROWCOUNT > 0 THEN

			

			    DBMS_OUTPUT.PUT_LINE ('SQL row count from Select is:' || SQL%ROWCOUNT);

			    v_cnt := SQL%ROWCOUNT;

			

			    FOR l_cnt IN 1 .. osa_array.COUNT

			    LOOP

			    

			        DBMS_OUTPUT.PUT_LINE ('Pass: '|| l_cnt); 

			

			

			        IF osa_array(l_cnt).expiration_date IS NULL THEN

			

			            DBMS_OUTPUT.PUT_LINE ('Updating SA_MODE to AC in OMS_SRV_AGREEMENT for');

			            DBMS_OUTPUT.PUT_LINE ('BAN:            ' || p_ban);

			            DBMS_OUTPUT.PUT_LINE ('ORDER_NO:       ' || p_om_order_id);

			            DBMS_OUTPUT.PUT_LINE ('OMS_PRODUCT_ID: ' || p_om_prod_id);

			

			

			            UPDATE &owner.OMS_SRV_AGREEMENT

			               SET APPLICATION_ID  = marker,

			                   SYS_UPDATE_DATE = SYSDATE,

			                   SA_MODE = active

			             WHERE SERVICE_AGREEMENT_ID = osa_array(l_cnt).service_agreement_id;

			

			        ELSE

			

			            DBMS_OUTPUT.PUT_LINE ('Updating SA_MODE to EP in OMS_SRV_AGREEMENT for');

			            DBMS_OUTPUT.PUT_LINE ('BAN:            ' || p_ban);

			            DBMS_OUTPUT.PUT_LINE ('ORDER_NO:       ' || p_om_order_id);

			            DBMS_OUTPUT.PUT_LINE ('OMS_PRODUCT_ID: ' || p_om_prod_id);

			

			            UPDATE &owner.OMS_SRV_AGREEMENT

			               SET APPLICATION_ID  = marker,

			                   SYS_UPDATE_DATE = SYSDATE,

			                   SA_MODE = expire

			             WHERE SERVICE_AGREEMENT_ID = osa_array(l_cnt).service_agreement_id;

			

			        END IF;

			

			    END LOOP;

			

			ELSIF SQL%ROWCOUNT = 0 THEN

			

			    DBMS_OUTPUT.PUT_LINE ('Updating SA_MODE to AD in OMS_SRV_AGREEMENT for');

			    DBMS_OUTPUT.PUT_LINE ('BAN:            ' || p_ban);

          DBMS_OUTPUT.PUT_LINE ('ORDER_NO:       ' || p_om_order_id);

          DBMS_OUTPUT.PUT_LINE ('OMS_PRODUCT_ID: ' || p_om_prod_id);

			

			

			    UPDATE &owner.OMS_SRV_AGREEMENT

			       SET APPLICATION_ID  = marker,

			           SYS_UPDATE_DATE = SYSDATE,

			           SA_MODE = add

			      WHERE BAN = p_ban

			        AND OMSA_GROUP_ID IN

			           (SELECT OMSA_GROUP_ID

			              FROM &owner.OMS_PRODUCT_VERSION

			             WHERE (OM_PRODUCT_ID, PRODUCT_VERSION) IN

			                   (SELECT OM_PRODUCT_ID, PRODUCT_VERSION

			                      FROM &owner.OMS_ORDER

			                     WHERE OM_ORDER_ID = p_om_order_id

			                       AND ORDER_VERSION_STATUS = 'CU'))

			        AND NOT SA_MODE IN ('AC', 'AD', 'EP');

			

			    v_cnt := v_cnt+1;

			

			END IF;

			

			    t_cnt := t_cnt+v_cnt;

			            

			DBMS_OUTPUT.PUT_LINE ('ROWS UPDATED IN OMS_SRV_AGREEMENT FOR BAN ' ||p_ban || ': ' ||  v_cnt);

			DBMS_OUTPUT.PUT_LINE ('***********************************************************************'); 

			dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

			 

			

			EXCEPTION

			  WHEN NO_DATA_FOUND THEN

			    DBMS_OUTPUT.PUT_LINE ('ROW NOT FOUND FOR BAN ' ||p_ban || ': ' ||  v_cnt);

			  WHEN OTHERS THEN

			    DBMS_OUTPUT.PUT_LINE ('OSA RECORD DOES NOT NEED UPDATING FOR THIS ORDER');

			    

END correct_sa_mode_no_script;



------------------------------------------------------------------------------------------------------

--create_pending_prod

------------------------------------------------------------------------------------------------------  



   procedure create_pending_prod(v_ban               in &owner.oms_order.ban%type,

                                 v_om_order_id       in &owner.oms_order.om_order_id%type,

                                 v_om_product_id     in &owner.oms_order.om_product_id%type) is





   dt                    char(50);

   v_app_id              char(6) := 'DC_CNV';

   v_rows_inserted       number := 0;

   v_tot_prod_inserted   number := 0;

   v_tot_rows_processed  number := 0;



   cursor product_cursor(t_ban                in &owner.oms_order.ban%type,

                         t_om_product_id      in &owner.oms_order.om_product_id%type,

                         t_om_order_id        in &owner.oms_order.om_order_id%type) is

      select o.om_order_id, o.om_product_id, opv.ban_id as ban, opv.billing_product_id as product_id, opv.product_type, opv.submarket, opv.bus_res_ind, o.due_date, 

             opv.business_unit, null as init_activation_date, 'PA' as prod_status_rsn_code, 'RES' as prod_status_last_act, 'P' as prod_status,

             null as earliest_actv_date, trunc(o.creation_date) as prod_sts_issue_date, '01-JAN-2000' as effective_date, 'D' as call_sort_type

      from &owner.oms_order o, &owner.oms_product_version opv

      where o.om_order_id = t_om_order_id

      and o.om_product_id = t_om_product_id

      and o.ban = t_ban

      and order_version_status = 'CU'

      and order_type = 'NI'

      and opv.product_version = o.product_version

      and opv.submarket is not null

      and not exists(select *

                     from &owner.product p

                     where p.customer_id = opv.ban_id

                     and p.product_id = opv.billing_product_id

                     and p.product_type = opv.product_type)

      and not exists (select *

                     from &owner.product p

                     where p.product_id = opv.billing_product_id

                     and p.product_type = opv.product_type

                     and p.customer_id <> opv.ban_id

                     and p.prod_status = 'A');

                     

      begin

         dbms_output.put_line('create_pending_prod Starting...');

         v_rows_inserted := 0;

         v_tot_rows_processed := v_tot_rows_processed + 1;

      

         for product_pointer in product_cursor(v_ban, v_om_product_id, v_om_order_id) loop

         

            insert into &owner.product (product_id, product_type, customer_id, sys_creation_date, operator_id, application_id, dl_service_code, effective_date, 

                     prod_status, prod_status_date, prod_status_last_act, prod_status_rsn_code, customer_ban, prod_sts_issue_date, 

                     prod_creation_src, prod_usage_threshold, tpv_ind, pic_cng_charge_tp, orig_prod_seq_no, order_no, sc_waive_ind, 

                     sub_market_code, call_sort_type, bus_res_ind, business_unit) 

              values (product_pointer.product_id,product_pointer.product_type, product_pointer.ban, sysdate, 20000428, v_app_id,'0',product_pointer.effective_date,product_pointer.prod_status,product_pointer.effective_date,

                      product_pointer.prod_status_last_act,product_pointer.prod_status_rsn_code,product_pointer.ban,product_pointer.prod_sts_issue_date,'C',.01,'N','2', &owner.PRODUCT_1SQ.NEXTVAL,0,'N', product_pointer.submarket, 

                      product_pointer.call_sort_type,product_pointer.bus_res_ind,product_pointer.business_unit);

         

            v_rows_inserted := SQL%ROWCOUNT;   

         

            dbms_output.put_line('Ban: ' || product_pointer.ban ||

                                 ' Om_product_id: ' || product_pointer.om_product_id ||

                                 ' Order_id: ' || product_pointer.om_order_id ||

                                 ' Inserted Product: ' ||

                                 ' Product_id: ' || product_pointer.product_id || 

                                 ' Product_type: ' || product_pointer.product_type ||

                                 ' Submarket: ' || product_pointer.submarket ||

                                 ' Bus_res_ind: ' || product_pointer.bus_res_ind ||

                                 ' Effective_date: ' || product_pointer.effective_date ||

                                 ' Prod_sts_issue_date: ' || product_pointer.prod_sts_issue_date ||

                                 ' Rows Inserted: ' || v_rows_inserted);

                                 

            v_tot_prod_inserted := v_tot_prod_inserted + v_rows_inserted;

         

         end loop;

         

         if (v_rows_inserted = 0) then

            dbms_output.put_line('Ban: ' || v_ban ||

                                 ' Om_product_id: ' || v_om_product_id ||

                                 ' Order_id: ' || v_om_order_id || ' Nothing to be done.');

         end if;

         

      dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

          EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');



      end create_pending_prod;



------------------------------------------------------------------------------------------------------

--csCnclProd_Failed

------------------------------------------------------------------------------------------------------       

   

PROCEDURE csCnclProd_Failed (v_ban &owner.oms_product_version.ban_id%TYPE,

                             v_ord_id &owner.oms_order.om_order_id%TYPE,

                             v_om_prod &owner.oms_order.om_product_id%TYPE)

AS



			i_ban                 &owner.oms_product_version.ban_id%TYPE;

			i_ord_id              &owner.oms_order.om_order_id%TYPE;

			i_om_prod             &owner.oms_order.om_product_id%TYPE;

			cnt                   INTEGER:=0;

			V_PROD_SEQ_NO         INTEGER:=0;

			



			CURSOR csCnclProd_cur (v_ban     &owner.oms_product_version.ban_id%TYPE,

			                       v_ord_id  &owner.oms_order.om_order_id%TYPE,

			                       v_om_prod &owner.oms_order.om_product_id%TYPE)

			IS 

			    

			SELECT DISTINCT p.customer_id, p.product_id, p.product_type, p.prod_status

			  FROM &owner.oms_order o, &owner.oms_product_version opv, &owner.product p

			 WHERE o.ban = v_ban

			   AND om_order_id = v_ord_id

			   AND o.om_product_id = v_om_prod

			   AND opv.om_product_id = o.om_product_id

			   AND o.om_order_status = 'DC'

			   AND o.order_version_status= 'CU'

			   AND product_ver_status IN ('CU','PE')

			   AND p.product_id = opv.billing_product_id

			   AND p.customer_id = opv.ban_id

			   AND o.om_product_id = opv.om_product_id;



			

			BEGIN

				dbms_output.put_line('csCnclProd_Failed Starting...');

			

			FOR csCnclProd_rec IN csCnclProd_cur (v_ban,v_ord_id,v_om_prod)

			    LOOP

			

			SELECT COUNT(0)

			  INTO CNT

			  FROM &owner.product_history

			 WHERE CUSTOMER_ID = csCnclProd_rec.customer_id

			   AND PRODUCT_ID = csCnclProd_rec.product_id

			   AND PRODUCT_TYPE = csCnclProd_rec.product_type

			   AND PROD_STATUS = 'A'

			   AND PROD_SEQ_NO = (SELECT MAX(PROD_SEQ_NO)

			                        FROM &owner.PRODUCT_HISTORY

			                       WHERE CUSTOMER_ID = csCnclProd_rec.customer_id

			                         AND PRODUCT_ID = csCnclProd_rec.product_id

			                         AND PRODUCT_TYPE = csCnclProd_rec.product_type);

			

			DBMS_OUTPUT.PUT_LINE ('PROD_HIST count = '||CNT);

			

			IF CNT > 0 THEN

			

			--**GET MAX PRODUCT SEQUENCE NUMBER:

			    SELECT MAX(PROD_SEQ_NO) 

			      INTO V_PROD_SEQ_NO

			      FROM &OWNER.PRODUCT_HISTORY

			     WHERE CUSTOMER_ID = csCnclProd_rec.customer_id

			       AND PRODUCT_ID = csCnclProd_rec.product_id

			       AND PRODUCT_TYPE = csCnclProd_rec.product_type;

			

			    DBMS_OUTPUT.PUT_LINE ('Inserting PRODUCT_HISTORY row');

			

			--**Insert record in product_history:  

			    INSERT 

			      INTO &owner.PRODUCT_HISTORY

			      SELECT PRODUCT_ID,PRODUCT_TYPE,CUSTOMER_ID,NVL(v_prod_seq_no, 0) + 1,SYS_CREATION_DATE,sysdate,OPERATOR_ID,'DC_CNV',

			             DL_SERVICE_CODE,DL_UPDATE_STAMP,EFFECTIVE_DATE,EFFECTIVE_DATE as EXPIRATION_DATE,INIT_ACTIVATION_DATE,'P',

			             PROD_STATUS_DATE,PROD_STATUS_LAST_ACT,PROD_STATUS_RSN_CODE,CUSTOMER_BAN,TAX_CTY_EXMP_IND,TAX_CNT_EXMP_IND,

			             TAX_STT_EXMP_IND,TAX_FED_EXMP_IND,REQ_ST_GRACE_PERIOD,REQ_END_GRACE_PERIOD,COMMIT_START_DATE,COMMIT_END_DATE,

			             COMMIT_REASON_CODE,COMMIT_ORIG_NO_MONTH,SUSP_RC_RATE_TYPE,PROD_GROUP_NO,RAO,REP_CODE,REQ_DEPOSIT_AMT,NEXT_PROD,

			             NEXT_PROD_CHG_DATE,PRV_PROD,PRV_PROD_CHG_DATE,NEXT_BAN,NEXT_BAN_MOVE_DATE,PRV_BAN,PRV_BAN_MOVE_DATE,

			             PROD_STS_ISSUE_DATE,ACTIVATE_WAIVE_RSN,EARLIEST_ACTV_DATE,PROD_CREATION_SRC,PROD_USAGE_THRESHOLD,TPV_IND,

			             TN_VOICE_DATA_TP,CARRIER_ID,CARRIER_ACCOUNT_ID,CARR_DEPOSIT_IND,CARR_STATUS,DUAL_PIC_CD,LOA_SENT_DATE,LOA_RECEIVED_DATE,

			             PIC_CNG_CHARGE_TP,TERMINAL_IND,POTS,PERSONAL_800,TYPE_800,VANITY_TRANSLATION,PREV_CUST,CALLING_CARD_QTY,CALLING_CARD_TYPE,

			             BATCH_ID,INTERLATA_CRE_SOURCE,INTRALATA_CRE_SOURCE,LOGO_CODE,COMPANY_CODE,ORIG_PROD_SEQ_NO,DEALER_CODE,SPEAKING_LANGUAGE,

			             FULFILLMENT_LANGUAGE,INTERLATA_CIC,INTRALATA_CIC,ISDN_IND,DIR_ASSIST_NAME,DIR_ASSIST_DATE,PERS_RING_IND,ORDER_NO,

			             CIS_ID,TKN,CUSTOMER_REQ_DATE,ACTIVATION_STATUS,CUST_CONCESSION_IND,PIC_RESTRICTION,TOLL_BLOCK_CD,PROD_ACTV_SRC,

			             TM_CALL_ORIGINATOR,AOS_INCLUDES_CANADA,CIRCUIT_ID,LEC_SALE_CODE,P_POTS_STATUS_DATE,O_POTS_STATUS_DATE,TFS_STATUS_DATE,

			             PIC_LINE_TYPE,SC_WAIVE_IND,SC_WAIVE_CHANGE_DT,FAX_IND,INTERNET_IND,CONTRACT_IND,CONTRACT_EXP_DATE,REP_NAME,

			             INTERLATA_CIC_EFF_DATE,INTRALATA_CIC_EFF_DATE,PAC_PIN_NO_DIG,FAC_IND,INTERLATA_CIC_FRZ_IND,INTRALATA_CIC_FRZ_IND,

			             INTERLATA_CIC_EXP_DATE,INTRALATA_CIC_EXP_DATE,SUB_MARKET_CODE,LRN_NUMBER,SUB_ACTV_LOCATION,INIT_COM_DLR,

			             LST_COM_ACTV_DLR,LST_COM_SPLT_DLR,IXC_CODE,IXC_EFFECTIVE_DATE,IXC_CHG_DLR_CD,IXC_CHG_DLR_SPLT_CD,BUSINESS_ENTITY_CODE,

			             CALL_SORT_TYPE,LATEST_CD_IND,PRODUCT_ESN,VIP_IND,CENTREX_IND,TAX_GST_EXMP_IND,TAX_PST_EXMP_IND,TAX_HST_EXMP_IND,

			             TAX_GST_EXMP_EFF_DT,TAX_PST_EXMP_EFF_DT,TAX_HST_EXMP_EFF_DT,TAX_GST_EXMP_EXP_DT,TAX_PST_EXMP_EXP_DT,TAX_HST_EXMP_EXP_DT,

			             TAX_GST_EXMP_RF_NO,TAX_PST_EXMP_RF_NO,TAX_HST_EXMP_RF_NO,MSN1,MSN2,TAX_RM_EXMP_IND,TAX_RM_EXMP_DATE,PAPER_WORK_STATUS,

			             PAPER_WORK_REQUIRED,PAPER_WORK_DATE,PAPER_WORK_REF_NO,CONV_RUN_NO,SPANC_CODE,PAPER_WORK_TRNS_NO,RMS_REF_STORE_ID,

			             RMS_REF_TYPE,RMS_REF_OD,INIT_COM_SPLIT_DLR,LST_COM_ACTV_CD,LST_COM_ACTV_DATE,LST_ACTV_DLR,LST_DLR_ACTV_CD,

			             CTN_SEQ_NO,HIERARCHY_ID,USER_SEG,USER_SUBSEG,ROOT_ID,PRIP_ACCOUNT,EZ_ACCOUNT,EZ_BILL_METHOD,EZ_RATE_PLAN,EZ_SALES_PERSON,

			             EZ_REFERRAL,PHOTO_ID_IND,PILOT_DN_IND,CEP_GROUP_NAME,VOICEMAIL_NO,VOICEMAIL_IND,GROUP_CODE,SUBGROUP_CODE,

			             PRIMARY_IND,COMPANION_PRODUCT_ID,PROD_SUB_TYPE,NT_SOL_SEQ_NO,NT_SOL_TP,INTL_IND,PR_VENDOR_CIRCID,ECCKT_ID_A,

			             ECCKT_ID_Z,LAP_LOC_A,LAP_LOC_Z,CIRCUIT_CLLI,CIRCUIT_ORDER_NUMBER,PON,BUS_RES_IND,ESS_TYPE,PROD_STS_2ND_ACT_DATE,

			             ALT_PROD_DESC,PRODUCT_TAX_ID,PRODUCT_SSN,BILL_RESTRICTION,LOA_INDICATOR,LOA_STATUS,IPCUSTNUM,IPUSER,IPPASSWD,

			             INTL_CIC,INTL_CIC_EFF_DATE,INTL_CIC_FRZ_IND,INTL_CIC_EXP_DATE,INTL_CRE_SOURCE,TABLE_NUM,LL_EFF_DATE,LL_EXP_DATE,

			             LL_TRIBAL_IND,LL_FEDERAL_IND,LL_STATE_IND,LKUP_IND,TELASSIST_IND,LL_CASE_NO,NP_IND,IPADDRESS,IPDOMAIN,HOW_PICD,

			             REG_CORP_IND,CO_LOCATION,RS_LINK_PROD_NO,RS_LINK_PROD_TP,BUSINESS_UNIT,PIC_DISPUTE_IND,PIC_DISPUTE_UPDATE_DT,

			             IEPIC_SELECTED_BY,IAPIC_SELECTED_BY,INP_NUMBER,PRODUCT_VERSION,LL_EFF_ISSUE_DATE,DC_LSP_ID,PRODUCT_EXTENSION,

			             ASSOC_PROD_ID,SECTION_CODE,SUPPRESS_NAF_IND,LL_QUAL_PROG,DOB,SSN_LAST_FOUR

			        FROM &owner.product

			       WHERE CUSTOMER_ID = csCnclProd_rec.customer_id

			         AND PRODUCT_ID = csCnclProd_rec.product_id

			         AND PRODUCT_TYPE = csCnclProd_rec.product_type;

			

			END IF;

			

			

			UPDATE &owner.product

			   SET prod_status = 'A',

			       application_id = 'DC_CNV',

			       sys_update_date = SYSDATE

			 WHERE product_id = csCnclProd_rec.product_id

			   AND customer_id = csCnclProd_rec.customer_id;

			

			dbms_output.put_line('BAN is :'||csCnclProd_rec.customer_id);

			dbms_output.put_line('OLD prod_status is :'||csCnclProd_rec.prod_status);

			dbms_output.put_line('');

			

			

			END LOOP;

			dbms_output.put_line('---------------------------------------------------------------------');

      dbms_output.put_line(' ');

          EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');



END csCnclProd_Failed;





------------------------------------------------------------------------------------------------------

--backdated_more_than_6_months

------------------------------------------------------------------------------------------------------ 



PROCEDURE backdated_more_than_6_months (i_ban           &owner.service_agreement.ban%TYPE,

                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE) is



					--i_ban              &owner.service_agreement.ban%TYPE;

					----i_om_order_id      &owner.oms_order.om_order_id%TYPE;

					--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

					marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

					invalid_discount   &owner.oms_related_info.related_number%TYPE;

					v_cnt              INTEGER:=0;

					t_cnt              INTEGER:=0;

					dt                 CHAR(30);           --for date/time

					i_due_date         &owner.oms_order.due_date%TYPE;

					i_bill_eff_date    &owner.oms_order.bill_eff_date%TYPE;

					

					

					--MAIN CURSOR

					CURSOR upd_ord_date (i_ban              &owner.service_agreement.ban%TYPE,

					                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

					                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

					IS

					select o.om_order_id,order_version,order_type,om_order_status,order_version_status,o.om_product_id,o.ban,o.product_version,

					       opv.omsa_group_id,opv.billing_product_id,opv.product_type,product_sub_type,om_product_status,product_ver_status,

					       o.due_date,o.bill_eff_date 

					from &owner.oms_order o,&owner.oms_product_version opv

					WHERE o.ban = i_ban

					AND o.om_order_id = i_om_order_id

					AND o.om_product_id = i_om_product_id

					AND o.om_product_id = opv.om_product_id

					AND o.product_version = opv.product_version

					--AND om_order_status = 'DC'

					AND order_version_status = 'CU'

					;

					

					---------------------------------

					--  M A I N   P R O C E D U R E

					---------------------------------

					

					BEGIN

						dbms_output.put_line('backdated_more_than_6_months Starting...');

					

					FOR upd_ord_date_rec IN upd_ord_date (i_ban,i_om_order_id,i_om_product_id)

					  LOOP

					

					i_bill_eff_date:=SYSDATE-178;

					

					DBMS_OUTPUT.PUT_LINE (' '); 

					DBMS_OUTPUT.PUT_LINE ('UPDATING ORDER : '||upd_ord_date_rec.om_order_id);            

					DBMS_OUTPUT.PUT_LINE ('PRIOR DUE DATE WAS: '||upd_ord_date_rec.Due_date);

					DBMS_OUTPUT.PUT_LINE ('NEW DUE DATE IS: '||i_due_date);

					DBMS_OUTPUT.PUT_LINE ('PRIOR BILL EFFECTIVE DATE WAS: '||upd_ord_date_rec.bill_eff_date);

					DBMS_OUTPUT.PUT_LINE ('NEW BILL EFFECTIVE DATE IS: '||i_bill_eff_date);

					DBMS_OUTPUT.PUT_LINE (' '); 

					

					UPDATE &owner.oms_order

					SET application_id = 'DC_CNV',

					sys_update_date = SYSDATE,

					due_date = sysdate,

					bill_eff_date = i_bill_eff_date

					WHERE om_order_id = upd_ord_date_rec.om_order_id;

					

					    v_cnt := SQL%ROWCOUNT;

					    t_cnt := t_cnt+v_cnt;

					 

					END LOOP;

					--COMMIT;

					dbms_output.put_line('---------------------------------------------------------------------');

          dbms_output.put_line(' ');



					EXCEPTION

					  WHEN NO_DATA_FOUND THEN

					    NULL;          

					  WHEN OTHERS THEN

					    DBMS_OUTPUT.PUT_LINE ('NO INVALID SA_MODES FOUND FOR THIS ORDER');

					    

END backdated_more_than_6_months;



------------------------------------------------------------------------------------------------------

--blbn_olnrc

------------------------------------------------------------------------------------------------------ 



PROCEDURE blbn_olnrc (i_ban           &owner.service_agreement.ban%TYPE,

                                  i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                  i_om_product_id   &owner.oms_order.om_product_id%TYPE) is



--i_ban              &owner.service_feature.ban%TYPE;

i_product_id       &owner.service_feature.product_id%TYPE;

i_product_type     &owner.service_feature.product_type%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_feature.application_id%TYPE := 'DC_CNV';

sf_cnt              INTEGER:=0;

v_cnt              INTEGER:=0;

osf_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

i_omsa_group_id    &owner.oms_srv_agreement.omsa_group_id%TYPE;



v_submarket         &owner.product.sub_market_code%TYPE;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR del_ftr (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

select o.om_order_id,order_version,order_type,om_order_status,order_version_status,o.om_product_id,o.ban,o.product_version,

       opv.omsa_group_id,opv.billing_product_id,opv.product_type,product_sub_type,om_product_status,product_ver_status,submarket 

from &owner.oms_order o,&owner.oms_product_version opv

WHERE o.ban = i_ban

AND o.om_order_id = i_om_order_id

AND o.om_product_id = i_om_product_id

AND o.om_product_id = opv.om_product_id

AND o.product_version = opv.product_version

AND om_order_status = 'DC'

AND order_version_status = 'CU'

;



--

CURSOR gt_pp_ftrs_oms (i_omsa_group_id  &owner.oms_service_feature.omsa_group_id%TYPE)

IS  

SELECT ban,product_id,product_type,price_plan,feature_code,ftr_effective_date,sf_mode,omsa_group_id 

FROM &owner.oms_service_feature osf

WHERE omsa_group_id = i_omsa_group_id

--AND ftr_expiration_date IS NULL -- even expired features will cause DC order

AND feature_code NOT IN (SELECT feature_code FROM &owner.rated_feature rf

                         WHERE osf.price_plan = rf.price_plan

                         AND osf.feature_code = rf.feature_code

                         AND rf.sub_market_code = v_submarket

                         AND rf.expiration_date IS NULL)

;



CURSOR gt_pp_ftrs (i_ban  &owner.service_feature.ban%TYPE,

                   i_product_id  &owner.service_feature.product_id%TYPE,

                   i_product_type  &owner.service_feature.product_type%TYPE)

IS  

SELECT ban,product_id,product_type,price_plan,feature_code,ftr_effective_date

FROM &owner.service_feature sf

WHERE ban  = i_ban

AND product_id = i_product_id

AND product_type = i_product_type

--AND ftr_expiration_date IS NULL -- even expired features will cause DC order

AND feature_code NOT IN (SELECT feature_code FROM &owner.rated_feature rf

                         WHERE sf.price_plan = rf.price_plan

                         AND sf.feature_code = rf.feature_code

                         AND rf.sub_market_code = v_submarket

                         AND rf.expiration_date IS NULL)

;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------

BEGIN

		dbms_output.put_line('blbn_olnrc Starting...');

		

		FOR del_ftr_rec IN del_ftr (i_ban,i_om_order_id,i_om_product_id)

		  LOOP

		v_cnt :=0;

		

		-- update records

		IF del_ftr_rec.order_type = 'MV'

		THEN

		DBMS_OUTPUT.PUT_LINE ('BAN :'||del_ftr_rec.ban||' ORDER '||del_ftr_rec.om_order_id||' IS A MOVE ORDER--using product.sub_market_code: '); 

		SELECT DISTINCT sub_market_code INTO v_submarket FROM &owner.product WHERE product_id = del_ftr_rec.billing_product_id

		AND customer_id = del_ftr_rec.ban AND prod_status = 'A' AND product_type = del_ftr_rec.product_type;

		ELSE

		v_submarket:=del_ftr_rec.submarket;

		END IF;

		

		i_omsa_group_id:=del_ftr_rec.omsa_group_id;

		i_product_id:=del_ftr_rec.billing_product_id;

		i_product_type:=del_ftr_rec.product_type; 

		--------------------------------------------------------------------------------------------------------------------------------

		--FIRST DELETE INVALID FEATURES IN OMS_SERVICE_FEATURE

		--------------------------------------------------------------------------------------------------------------------------------

		

		FOR gt_pp_ftrs_oms_rec IN gt_pp_ftrs_oms (i_omsa_group_id)

		  LOOP

		 

		 

		DBMS_OUTPUT.PUT_LINE ('DELETING INVALID FEATURES IN OMS_SERVICE_FEATURE FOR BAN: '||gt_pp_ftrs_oms_rec.BAN);

		DBMS_OUTPUT.PUT_LINE ('PRODUCT_ID : '||gt_pp_ftrs_oms_rec.product_id); 

		DBMS_OUTPUT.PUT_LINE ('PRODUCT_TYPE : '||gt_pp_ftrs_oms_rec.product_type); 

		DBMS_OUTPUT.PUT_LINE ('PRICE_PLAN : '||gt_pp_ftrs_oms_rec.price_plan); 

		DBMS_OUTPUT.PUT_LINE ('FEATURE_CODE : '||gt_pp_ftrs_oms_rec.feature_code); 

		DBMS_OUTPUT.PUT_LINE ('EFFECTIVE_DATE : '||gt_pp_ftrs_oms_rec.ftr_effective_date); 

		DBMS_OUTPUT.PUT_LINE ('SF_MODE : '||gt_pp_ftrs_oms_rec.sf_mode);

		DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID : '||gt_pp_ftrs_oms_rec.omsa_group_id);

		DBMS_OUTPUT.PUT_LINE (' ');

		

		

		DELETE FROM &owner.oms_service_feature osf

		WHERE ban = gt_pp_ftrs_oms_rec.BAN

		AND product_id = gt_pp_ftrs_oms_rec.product_id

		AND product_type = gt_pp_ftrs_oms_rec.product_type

		AND price_plan = gt_pp_ftrs_oms_rec.price_plan

		AND feature_code = gt_pp_ftrs_oms_rec.feature_code

		AND omsa_group_id = gt_pp_ftrs_oms_rec.omsa_group_id

		--AND ftr_expiration_date IS NULL -- even expired features will cause DC order

		AND feature_code NOT IN (SELECT feature_code FROM &owner.rated_feature rf

		                         WHERE osf.price_plan = rf.price_plan

		                         AND osf.feature_code = rf.feature_code

		                         AND rf.sub_market_code = v_submarket

		                         AND rf.expiration_date IS NULL)

		;

		    v_cnt := SQL%ROWCOUNT;

		    osf_cnt:=osf_cnt+v_cnt;

		

    --Delete rows in oms_srv_agreement where sa_mode is EP but no row exists in CSM.

          DELETE FROM &owner.oms_srv_agreement osa

          WHERE ban = gt_pp_ftrs_oms_rec.BAN

          AND product_id = gt_pp_ftrs_oms_rec.product_id

          AND omsa_group_id =gt_pp_ftrs_oms_rec.omsa_group_id

          AND sa_mode = 'EP'

          AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

                       WHERE sa.ban = osa.ban

                       AND sa.product_id = osa.product_id

                       AND sa.product_type = osa.product_type

                       AND sa.price_plan = osa.price_plan

                       AND sa.sa_unique_id = osa.sa_unique_id

                       --AND sa.expiration_date IS NULL

                       ) 

                       ;   

		  

		DBMS_OUTPUT.PUT_LINE ('DELETED '||v_cnt||' INVALID FEATURES IN OMS_SERVICE_FEATURE FOR BAN: '||gt_pp_ftrs_oms_rec.BAN); 

		DBMS_OUTPUT.PUT_LINE (' ');

		

		END LOOP;-- end gt_pp_ftrs_oms loop

		

		--------------------------------------------------------------------------------------------------------------------------------

		--NOW  DELETE INVALID FEATURES IN SERVICE_FEATURE

		--------------------------------------------------------------------------------------------------------------------------------

		

		

		FOR gt_pp_ftrs_rec IN gt_pp_ftrs (i_ban,i_product_id,i_product_type)

		  LOOP

		  

		 

		DBMS_OUTPUT.PUT_LINE ('DELETING INVALID FEATURES IN SERVICE_FEATURE FOR BAN: '||gt_pp_ftrs_rec.BAN);

		DBMS_OUTPUT.PUT_LINE ('PRODUCT_ID : '||gt_pp_ftrs_rec.product_id); 

		DBMS_OUTPUT.PUT_LINE ('PRODUCT_TYPE : '||gt_pp_ftrs_rec.product_type); 

		DBMS_OUTPUT.PUT_LINE ('PRICE_PLAN : '||gt_pp_ftrs_rec.price_plan); 

		DBMS_OUTPUT.PUT_LINE ('FEATURE_CODE : '||gt_pp_ftrs_rec.feature_code); 

		DBMS_OUTPUT.PUT_LINE ('EFFECTIVE_DATE : '||gt_pp_ftrs_rec.ftr_effective_date);

		DBMS_OUTPUT.PUT_LINE (' ');

		 

		

		

		DELETE FROM &owner.service_feature sf

		WHERE ban = gt_pp_ftrs_rec.BAN

		AND product_id = gt_pp_ftrs_rec.product_id

		AND product_type = gt_pp_ftrs_rec.product_type

		AND price_plan = gt_pp_ftrs_rec.price_plan

		AND feature_code = gt_pp_ftrs_rec.feature_code

		--AND ftr_expiration_date IS NULL -- even expired features will cause DC order

		AND feature_code NOT IN (SELECT feature_code FROM &owner.rated_feature rf

		                         WHERE sf.price_plan = rf.price_plan

		                         AND sf.feature_code = rf.feature_code

		                         AND rf.sub_market_code = v_submarket

		                         AND rf.expiration_date IS NULL)

		;

		    v_cnt := SQL%ROWCOUNT;

		    sf_cnt:=sf_cnt+v_cnt;

		           

		DBMS_OUTPUT.PUT_LINE ('DELETED '||v_cnt||' INVALID FEATURES IN SERVICE_FEATURE FOR BAN: '||gt_pp_ftrs_rec.BAN);

		DBMS_OUTPUT.PUT_LINE (' ');

		END LOOP; -- end gt_pp_ftrs loop

		

		

		END LOOP; -- end del_ftr_rec loop

		--COMMIT;

		dbms_output.put_line('---------------------------------------------------------------------');

		dbms_output.put_line(' ');    



		EXCEPTION

		  WHEN NO_DATA_FOUND THEN

		    NULL;          

		  WHEN OTHERS THEN

		    DBMS_OUTPUT.PUT_LINE ('NO INVALID FEATURES FOUND FOR THIS BAN');

END blbn_olnrc;



------------------------------------------------------------------------------------------------------

--csRsCanCtn

------------------------------------------------------------------------------------------------------ 



PROCEDURE csRsCanCtn (v_ban &owner.oms_product_version.ban_id%TYPE,

                      v_ord_id &owner.oms_order.om_order_id%TYPE,

                      v_om_prod &owner.oms_order.om_product_id%TYPE)

IS



CURSOR csRsCanCtn_cur (v_ban     &owner.oms_product_version.ban_id%TYPE,

                       v_ord_id  &owner.oms_order.om_order_id%TYPE,

                       v_om_prod &owner.oms_order.om_product_id%TYPE)

IS 

    

SELECT DISTINCT p.customer_id,p.product_id,p.product_type,p.prod_status

  FROM &owner.oms_order o,&owner.oms_product_version opv,&owner.product p

 WHERE o.ban= v_ban

   AND om_order_id = v_ord_id

   AND o.om_product_id = v_om_prod

   AND opv.om_product_id = o.om_product_id

   and opv.product_type = p.product_type

   AND o.om_order_status = 'DC'

   AND o.order_version_status= 'CU'

 --AND opv.om_product_status = 'AC'

   AND product_ver_status IN ('CU','PE')

   AND p.product_id = opv.billing_product_id

   AND p.customer_id = opv.ban_id

   AND o.om_product_id = opv.om_product_id;





BEGIN

		dbms_output.put_line('csRsCanCtn Starting...');

		



		FOR csRsCanCtn_rec IN csRsCanCtn_cur (v_ban,v_ord_id,v_om_prod)

		    LOOP

		

		UPDATE &owner.product

		   SET prod_status = 'P',

		       sys_update_date = sysdate,

		       application_id = 'DC_CNV'

		 WHERE product_id = csRsCanCtn_rec.product_id

		   and product_type = csRsCanCtn_rec.product_type

		   AND customer_id = csRsCanCtn_rec.customer_id;

		

		dbms_output.put_line('BAN is :'||csRsCanCtn_rec.customer_id);

		dbms_output.put_line('OLD prod_status is :'||csRsCanCtn_rec.prod_status);

		dbms_output.put_line('');

		

		

		END LOOP;

		dbms_output.put_line('---------------------------------------------------------------------');

		dbms_output.put_line(' ');   

		    EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');



END csRsCanCtn;





------------------------------------------------------------------------------------------------------

--dcs_up_ftr_lcycl

------------------------------------------------------------------------------------------------------ 





PROCEDURE dcs_up_ftr_lcycl (i_ban           &owner.service_agreement.ban%TYPE,

                            i_om_order_id   &owner.oms_order.om_order_id%TYPE,

                            i_om_product_id &owner.oms_order.om_product_id%TYPE)

is



i_exp_date         &owner.service_agreement.effective_date%TYPE;

--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

iban               &owner.service_agreement.ban%TYPE;

iptype             &owner.service_agreement.product_type%TYPE;

ipid               &owner.service_agreement.product_id%TYPE;

iorderid           &owner.oms_order.om_order_id%TYPE;



iomsa              &owner.oms_product_version.omsa_group_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR get_cus_info (iban           &owner.service_agreement.ban%TYPE,

                     iomorderid     &owner.oms_order.om_order_id%TYPE,

                     iomproductid   &owner.oms_order.om_product_id%TYPE)

IS 

SELECT ban,billing_product_id,product_type,om_order_id,opv.omsa_group_id 

FROM &owner.oms_order o, &owner.oms_product_version opv

WHERE o.om_order_id = iomorderid

AND opv.om_product_id = iomproductid

AND o.product_version = opv.product_version

AND o.om_product_id = opv.om_product_id

AND ban_id = iban

--AND om_product_status = 'AC'

AND order_version IN (SELECT MAX(order_version) FROM &owner.oms_order o2

                      WHERE o.om_order_id = o2.om_order_id

                      AND o.om_product_id = o2.om_product_id

                      AND o.ban = o2.ban);



--main cursor to drive the procedure to expire SA

CURSOR sa_exp_pp_seq  (iban              &owner.service_agreement.ban%TYPE,

                       ipid              &owner.service_agreement.product_id%TYPE,

                       iptype           &owner.service_agreement.product_type%TYPE)

IS

SELECT ban,product_id,product_type,price_plan,pp_seq_no

FROM &owner.service_agreement sa

WHERE ban = iban

AND product_id = ipid

AND product_type = iptype

AND expiration_date IS NULL

AND pp_seq_no NOT IN (SELECT MAX(pp_seq_no) FROM &owner.service_agreement sa2

                      WHERE sa.ban = sa2.ban

                      AND sa.product_id = sa2.product_id

                      AND sa.product_type = sa2.product_type

                      AND sa.price_plan = sa2.price_plan)

ORDER BY 5 

;



--main cursor to drive the procedure to expire SF

CURSOR sf_exp_pp_seq  (iban              &owner.service_agreement.ban%TYPE,

                       ipid              &owner.service_agreement.product_id%TYPE,

                       iptype            &owner.service_agreement.product_type%TYPE)

IS

SELECT ban,product_id,product_type,price_plan,feature_code,pp_seq_no--,COUNT(*)

FROM &owner.service_feature sf

WHERE ban = iban

AND product_id = ipid

AND product_type = iptype

AND ftr_expiration_date IS NULL

AND pp_seq_no NOT IN (SELECT MAX(pp_seq_no) FROM &owner.service_feature sf2

                      WHERE sf.ban = sf2.ban

                      AND sf.product_id = sf2.product_id

                      AND sf.product_type = sf2.product_type

                      AND sf.price_plan = sf2.price_plan

                      AND sf2.ftr_expiration_date IS NULL)

;



--main cursor to drive the procedure to expire OSA

CURSOR osa_exp_pp_seq (iban              &owner.service_agreement.ban%TYPE,

                       ipid              &owner.service_agreement.product_id%TYPE,

                       iptype            &owner.service_agreement.product_type%TYPE,

                       iomsa             &owner.oms_product_version.omsa_group_id%TYPE)

IS

SELECT ban,product_id,product_type,price_plan,omsa_group_id,pp_seq_no

FROM &owner.oms_srv_agreement osa

WHERE ban = iban

AND product_id = ipid

AND product_type = iptype

AND expiration_date IS NULL

AND omsa_group_id = iomsa-- 1007990121

AND pp_seq_no NOT IN (SELECT MAX(pp_seq_no) FROM &owner.oms_srv_agreement osa2

                      WHERE osa.ban = osa2.ban

                      AND osa.product_id = osa2.product_id

                      AND osa.product_type = osa2.product_type

                      AND osa.price_plan = osa2.price_plan

                      AND osa.omsa_group_id  = osa2.omsa_group_id )  

;



--main cursor to drive the procedure to expire OSF

CURSOR osf_exp_pp_seq (iban              &owner.service_agreement.ban%TYPE,

                       ipid              &owner.service_agreement.product_id%TYPE,

                       iptype            &owner.service_agreement.product_type%TYPE,

                       iomsa             &owner.oms_product_version.omsa_group_id%TYPE)

IS

SELECT ban,product_id,product_type,price_plan,feature_code,omsa_group_id,pp_seq_no

FROM &owner.oms_service_feature osf

WHERE ban = iban

AND product_id = ipid

AND product_type = iptype

AND ftr_expiration_date IS NULL

--AND omsa_group_id = 1007990121

AND pp_seq_no NOT IN (SELECT MAX(pp_seq_no) FROM &owner.oms_service_feature osf2

                      WHERE osf.ban = osf2.ban

                      AND osf.product_id = osf2.product_id

                      AND osf.product_type = osf2.product_type

                      AND osf.price_plan = osf2.price_plan

                      AND osf.feature_code = osf2.feature_code

                      AND osf.omsa_group_id  = osf2.omsa_group_id )        

;





-----------------------------------------------------------------------------------------------------------------------

--D E F I N E    M A I N    P R O C E D U R E 

-----------------------------------------------------------------------------------------------------------------------







BEGIN

				dbms_output.put_line('dcs_up_ftr_lcycl Starting...');

				

				FOR get_cus_info_rec IN get_cus_info (i_ban,i_om_order_id,i_om_product_id)

				    LOOP

				

				

				--assign variables as necessary for processing cursors;

				iban:=get_cus_info_rec.ban;

				ipid:=get_cus_info_rec.billing_product_id;

				iptype:=get_cus_info_rec.product_type;

				iomsa:=get_cus_info_rec.omsa_group_id;

				iorderid:=get_cus_info_rec.om_order_id;

				

				

				---------------------------------------------------------------------------

				--S E R V I C E   A G R E E M E N T 

				---------------------------------------------------------------------------

				

				--Start Processing rows in service_agreement

				FOR sa_exp_pp_seq_rec IN sa_exp_pp_seq (iban,ipid,iptype)

				    LOOP

				   

				    

				    SELECT effective_date INTO i_exp_date

				    FROM &owner.service_agreement

				    WHERE ban = sa_exp_pp_seq_rec.ban

				    AND product_id = sa_exp_pp_seq_rec.product_id

				    AND product_type = sa_exp_pp_seq_rec.product_type

				    AND price_plan = sa_exp_pp_seq_rec.price_plan

				    AND expiration_date IS NULL

				    AND pp_seq_no = sa_exp_pp_seq_rec.pp_seq_no +1 ;

				    

				    --expire invalid pp_seq_no

				    UPDATE &owner.service_agreement

				    SET expiration_date = i_exp_date,

				         sys_update_date = sysdate,

				         application_id = marker,

				         expiration_issue_date = i_exp_date,

				         disconnect_rsn = 'BLAN'

				    WHERE ban = sa_exp_pp_seq_rec.ban

				    AND product_id = sa_exp_pp_seq_rec.product_id

				    AND product_Type = sa_exp_pp_seq_rec.product_type

				    AND price_plan = sa_exp_pp_seq_rec.price_plan

				    AND pp_seq_no = sa_exp_pp_seq_rec.pp_seq_no

				    AND expiration_date is NULL;

				    

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				          

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('Rows Updated in SERVICE_AGREEMENT for BAN ' ||sa_exp_pp_seq_rec.ban || ': ' ||  v_cnt);

				    END LOOP;

				

				

				---------------------------------------------------------------------------

				--S E R V I C E   F E A T U R E 

				---------------------------------------------------------------------------

				FOR sf_exp_pp_seq_rec IN sf_exp_pp_seq (iban,ipid,iptype)

				  LOOP

				    

				  

				    SELECT ftr_effective_date INTO i_exp_date

				    FROM &owner.service_feature

				    WHERE ban = sf_exp_pp_seq_rec.ban

				    AND product_id = sf_exp_pp_seq_rec.product_id

				    AND product_type = sf_exp_pp_seq_rec.product_type

				    AND price_plan = sf_exp_pp_seq_rec.price_plan

				    AND feature_code = sf_exp_pp_seq_rec.feature_code

				    AND ftr_expiration_date IS NULL

				    AND pp_seq_no = sf_exp_pp_seq_rec.pp_seq_no +1 ;

				    

				    --expire invalid pp_seq_no

				    UPDATE &owner.service_feature

				    SET ftr_expiration_date = i_exp_date,

				        sys_update_date = sysdate,

				        application_id = marker,

				        ftr_exp_issue_date = i_exp_date,

				        disconnect_rsn = 'BLAN'

				    WHERE ban = sf_exp_pp_seq_rec.ban

				    AND product_id = sf_exp_pp_seq_rec.product_id

				    AND product_Type = sf_exp_pp_seq_rec.product_type

				    AND price_plan = sf_exp_pp_seq_rec.price_plan

				    AND feature_code = sf_exp_pp_seq_rec.feature_code

				    AND pp_seq_no = sf_exp_pp_seq_rec.pp_seq_no

				    AND ftr_expiration_date is NULL;

				    

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;    

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('Rows Updated in SERVICE_FEATURE FOR BAN ' ||sf_exp_pp_seq_rec.ban || ': ' ||  v_cnt);

				  END LOOP;

				

				

				---------------------------------------------------------------------------

				--O M S   S E R V I C E   A G R E E M E N T 

				---------------------------------------------------------------------------

				FOR osa_exp_pp_seq_rec IN osa_exp_pp_seq (iban,ipid,iptype,iomsa)

				  LOOP

				  

				    

				    SELECT effective_date INTO i_exp_date

				    FROM &owner.oms_srv_agreement

				    WHERE ban = osa_exp_pp_seq_rec.ban

				    AND product_id = osa_exp_pp_seq_rec.product_id

				    AND product_type = osa_exp_pp_seq_rec.product_type

				    AND price_plan = osa_exp_pp_seq_rec.price_plan

				    AND omsa_group_id = osa_exp_pp_seq_rec.omsa_group_id

				    AND expiration_date IS NULL

				    AND pp_seq_no = osa_exp_pp_seq_rec.pp_seq_no +1 ;

				    

				    --expire invalid pp_seq_no

				    

				    UPDATE &owner.oms_srv_agreement

				    SET expiration_date = i_exp_date,

				           sys_update_date = sysdate,

				           application_id = marker,

				           expiration_issue_date = i_exp_date,

				           disconnect_rsn = 'BLAN',

				           sa_mode = 'EP'

				    WHERE ban = osa_exp_pp_seq_rec.ban

				    AND product_id = osa_exp_pp_seq_rec.product_id

				    AND product_type = osa_exp_pp_seq_rec.product_type

				    AND price_plan = osa_exp_pp_seq_rec.price_plan

				    AND omsa_group_id = osa_exp_pp_seq_rec.omsa_group_id

				    AND pp_seq_no = osa_exp_pp_seq_rec.pp_seq_no

				    AND expiration_date IS NULL;

				        

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				            

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('Rows Updated in       OMS_SRV_AGREEMENT FOR BAN ' ||osa_exp_pp_seq_rec.ban || ': ' ||  v_cnt);

				  END LOOP;

				    

				---------------------------------------------------------------------------

				-- O M S   S E R V I C E   F E A T U R E

				---------------------------------------------------------------------------

				FOR osf_exp_pp_seq_rec IN osf_exp_pp_seq (iban,ipid,iptype,iomsa)

				  LOOP

				  

				

				    

				    SELECT ftr_effective_date INTO i_exp_date

				    FROM &owner.oms_service_feature

				    WHERE ban = osf_exp_pp_seq_rec.ban

				    AND product_id = osf_exp_pp_seq_rec.product_id

				    AND product_type = osf_exp_pp_seq_rec.product_type

				    AND price_plan = osf_exp_pp_seq_rec.price_plan

				    AND feature_code = osf_exp_pp_seq_rec.feature_code

				    AND omsa_group_id = osf_exp_pp_seq_rec.omsa_group_id

				    AND ftr_expiration_date IS NULL

				    AND pp_seq_no = osf_exp_pp_seq_rec.pp_seq_no +1 ;

				    

				    --expire invalid pp_seq_no

				    

				    UPDATE &owner.oms_service_feature

				    SET ftr_expiration_date = i_exp_date,

				        sys_update_date = sysdate,

				        application_id = marker,

				        ftr_exp_issue_date = i_exp_date,

				        disconnect_rsn = 'BLAN',

				        ftr_exp_rsn_code = 'B',

				        sf_mode = 'EP'

				    WHERE ban = osf_exp_pp_seq_rec.ban

				    AND product_id = osf_exp_pp_seq_rec.product_id

				    AND product_type = osf_exp_pp_seq_rec.product_type

				    AND price_plan = osf_exp_pp_seq_rec.price_plan

				    AND feature_code = osf_exp_pp_seq_rec.feature_code

				    AND omsa_group_id = osf_exp_pp_seq_rec.omsa_group_id

				    AND ftr_expiration_date IS NULL

				    AND pp_seq_no = osf_exp_pp_seq_rec.pp_seq_no;

				        

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				            

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('Rows Updated in   OMS_SERVICE_FEATURE FOR BAN ' ||osf_exp_pp_seq_rec.ban || ': ' ||  v_cnt);

				    END LOOP;    

				

				         

				END LOOP;



				dbms_output.put_line('---------------------------------------------------------------------');

				dbms_output.put_line(' ');    

				         

				EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('NO DATA FOUND FOR THIS BAN');

    

END dcs_up_ftr_lcycl;





------------------------------------------------------------------------------------------------------

--Key_not_found_for_Discount

------------------------------------------------------------------------------------------------------ 



PROCEDURE Key_not_found_for_Discount (i_ban           &owner.service_agreement.ban%TYPE,

                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

is



--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

invalid_discount   &owner.oms_related_info.related_number%TYPE;

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR rem_disc (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

SELECT ORD.OM_ORDER_ID, ORI.RI_ID, ORI.OMRI_GROUP_ID, ORI.RELATED_NUMBER,ORD.BAN,ORD.OM_PRODUCT_ID

FROM &OWNER.OMS_ORDER ORD, &OWNER.OMS_PRODUCT_VERSION OPV, &OWNER.OMS_RELATED_INFO ORI

WHERE ORD.OM_ORDER_ID = i_om_order_id

AND ORD.OM_PRODUCT_ID = i_om_product_id

AND ORD.BAN = i_ban

AND ORD.ORDER_VERSION_STATUS = 'CU'

AND OPV.OM_PRODUCT_ID = ORD.OM_PRODUCT_ID

AND OPV.PRODUCT_VERSION = ORD.PRODUCT_VERSION

and ORI.OMRI_GROUP_ID = OPV.OMRI_GROUP_ID

AND (TRIM(SUBSTR(ORI.RELATED_NUMBER,0,10)) NOT IN (SELECT TRIM(DISCOUNT_PLAN_CD) FROM &REF.DISCOUNT_PLAN

																																						WHERE effective_date <= SYSDATE)) 

-- The first 10 chars in the related_number field seem to correspond to a discount.

;

--**************************************************************

/*

 Looks like a given order contains discounts that are invalid. As a fix, we need to remove the invalid discount.

 Check the discounts on an order in the oms_order_related_info against valid discounts in the discount_plan table and remove any 

 records that do not look like a valid discount.

*/

-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN

			dbms_output.put_line('Key_not_found_for_Discount Starting...');

			

			FOR rem_disc_rec IN rem_disc (i_ban,i_om_order_id,i_om_product_id)

			  LOOP

			

			invalid_discount:=(TRIM(SUBSTR(rem_disc_rec.RELATED_NUMBER,0,10)));

			-- Delete records found above based on RI_ID

			DELETE FROM &OWNER.OMS_RELATED_INFO

			WHERE RI_ID = rem_disc_rec.RI_ID;

			

			    v_cnt := SQL%ROWCOUNT;

			    t_cnt := t_cnt+v_cnt;

			            

			DBMS_OUTPUT.PUT_LINE (' '); 

			DBMS_OUTPUT.PUT_LINE ('Invalid Discount being removed: '||invalid_discount);

			DBMS_OUTPUT.PUT_LINE ('ROWS DELETED FROM OMS_RELATED_INFO FOR BAN ' ||rem_disc_rec.ban || ': ' ||  v_cnt);

			 

			END LOOP;

			--COMMIT;

			dbms_output.put_line('---------------------------------------------------------------------');

			dbms_output.put_line(' ');    



			EXCEPTION

			  WHEN NO_DATA_FOUND THEN

			    NULL;          

			  WHEN OTHERS THEN

			    DBMS_OUTPUT.PUT_LINE ('NO DISCOUNT FOUND FOR THIS ORDER');

			    

END Key_not_found_for_Discount;





------------------------------------------------------------------------------------------------------

--dom_gb_email_rec

------------------------------------------------------------------------------------------------------ 



PROCEDURE dom_gb_email_rec (i_ban           &owner.service_agreement.ban%TYPE,

                            i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                            i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS



--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

invalid_discount   &owner.oms_related_info.related_number%TYPE;

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR upd_email (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

SELECT email_id, ban, om_product_id, associated_product_id

FROM &owner.oms_email

--FROM oms_email

WHERE ban = i_ban

AND email_id NOT IN (SELECT MAX(email_id) FROM &owner.oms_email

      WHERE ban =i_ban

      AND associated_product_id IN 

          (SELECT DISTINCT assoc_prod_id FROM &owner.oms_product_version 

          WHERE ban_id = i_ban

          AND om_product_id =i_om_product_id) GROUP BY ban) ORDER BY ban;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------







BEGIN

			dbms_output.put_line('dom_gb_email_rec Starting...');	

			

			FOR upd_email_rec IN upd_email (i_ban,i_om_order_id,i_om_product_id)

			  LOOP

			

			      

			UPDATE &owner.oms_email

			      SET  application_id=marker,

			      sys_update_date = SYSDATE, 

			      associated_product_id= trim(upd_email_rec.associated_product_id)||'FIXED' -- Append 'FIXED' to the current value.

			WHERE email_id = upd_email_rec.email_id

			;

			

			--COMMIT;

			    v_cnt := SQL%ROWCOUNT;

			    t_cnt := t_cnt+v_cnt;

			            

			DBMS_OUTPUT.PUT_LINE (' '); 

			DBMS_OUTPUT.PUT_LINE ('ROWS UPDATED IN OMS_EMAIL FOR BAN ' ||upd_email_rec.ban || ': ' ||  v_cnt);

			DBMS_OUTPUT.PUT_LINE ('ASSOCIATED_PRODUCT_ID '||upd_email_rec.associated_product_id||' WAS UPDATED TO '||trim(upd_email_rec.associated_product_id)||'FIXED'); 

			 

			END LOOP;

			--COMMIT;

			dbms_output.put_line('---------------------------------------------------------------------');

			dbms_output.put_line(' ');       



			EXCEPTION

			  WHEN NO_DATA_FOUND THEN

			    NULL;          

			  WHEN OTHERS THEN

			    DBMS_OUTPUT.PUT_LINE ('NO EMAIL_ID NEEDS UPDATING FOR THIS ORDER');

END dom_gb_email_rec;





------------------------------------------------------------------------------------------------------

--OMS_BUNDLE_ORD_DEPEND_PK

------------------------------------------------------------------------------------------------------ 

PROCEDURE OMS_BUNDLE_ORD_DEPEND_PK (i_ban           &owner.service_agreement.ban%TYPE,

                                           i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                           i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS



--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt                 CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR del_obod (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS 

SELECT bundle_seq,bundle_seq_ver,om_order_id,om_product_id

FROM &owner.oms_bundle_ord_depend obod

WHERE om_order_id = i_om_order_id

AND dependency_type IN ('CA', 'BC')

GROUP BY bundle_seq,bundle_seq_ver,om_order_id,om_product_id

HAVING COUNT(*)>1

;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN

				dbms_output.put_line('OMS_BUNDLE_ORD_DEPEND_PK Starting...');		

				

				FOR del_obod_rec IN del_obod (i_ban,i_om_order_id,i_om_product_id)

				 LOOP

				

				DBMS_OUTPUT.PUT_LINE (' inside loop'); 

				

				DELETE FROM &owner.oms_bundle_ord_depend

				WHERE om_order_id = del_obod_rec.om_order_id

				AND om_product_id = del_obod_rec.om_product_id

				AND dependency_type = 'BC';

				

				

				--COMMIT;

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				            

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('REMOVING DUPLICATE RECORD FOR OM_ORDER_ID: ' ||del_obod_rec.om_order_id|| ' OM_PRODUCT_ID: ' ||del_obod_rec.om_product_id|| ' BUNDLE_SEQ: '||del_obod_rec.bundle_seq );

				

				 

				END LOOP;

				--COMMIT;

				dbms_output.put_line('---------------------------------------------------------------------');

				dbms_output.put_line(' ');    



				EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('DUPLICATES DO NOT EXIST FOR THIS ORDER');

END OMS_BUNDLE_ORD_DEPEND_PK;





------------------------------------------------------------------------------------------------------

--original_plan_was_not_found

------------------------------------------------------------------------------------------------------ 

PROCEDURE original_plan_was_not_found (i_ban           &owner.service_agreement.ban%TYPE,

                                           i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                           i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS



--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt                 CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR fix_prod (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS 

SELECT opv.omsa_group_id,opv.om_product_id,opv.product_version,opv.ban_id,opv.billing_product_id,opv.tn_npa,opv.tn_nxx,opv.tn_lineno,opv.sys_creation_date 

FROM &owner.oms_product_version opv

WHERE /*product_type = 'DT'

AND */ban_id = i_ban

AND om_product_id = i_om_product_id

AND (trim(billing_product_id) !=trim(tn_npa||tn_nxx||tn_lineno) OR tn_npa||tn_nxx||tn_lineno IS NULL)

;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN

				dbms_output.put_line('original_plan_was_not_found Starting...');	

				

				FOR fix_prod_rec IN fix_prod (i_ban,i_om_order_id,i_om_product_id)

				 LOOP

				

				UPDATE &owner.oms_product_version

				SET tn_npa = substr(billing_product_id,0,3),

				tn_nxx = substr(billing_product_id,4,3),

				tn_lineno = substr(billing_product_id,7,4),

				application_id = 'DC_CNV',

				sys_update_date = SYSDATE

				WHERE om_product_status != 'DC'

				AND product_ver_status != 'CA'

				AND billing_product_id NOT LIKE 'F%'

				AND billing_product_id NOT LIKE 'A%'

				--AND product_type = 'DT'

				AND ban_id = fix_prod_rec.ban_id

				AND om_product_id = fix_prod_rec.om_product_id

				AND (trim(billing_product_id) !=trim(tn_npa||tn_nxx||tn_lineno) OR tn_npa||tn_nxx||tn_lineno IS NULL);

				

				

				--COMMIT;

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				            

				--DBMS_OUTPUT.PUT_LINE (' '); 

				--DBMS_OUTPUT.PUT_LINE ('ROWS UPDATED IN OMS_EMAIL FOR BAN ' ||fix_prod_rec.ban_id || ': ' ||  v_cnt);

				--DBMS_OUTPUT.PUT_LINE ('TN_NPA||TN_NXX||TN_LINENO '||fix_prod_rec.TN_NPA||fix_prod_rec.TN_NXX||fix_prod_rec.TN_LINENO

				 --                                                 ||' WAS UPDATED TO '||trim(fix_prod_rec.billing_product_id)); 

				 

				END LOOP;

				--COMMIT;

				dbms_output.put_line('---------------------------------------------------------------------');

				dbms_output.put_line(' ');     



				EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('OPV RECORD DOES NOT NEED UPDATING FOR THIS ORDER');

END original_plan_was_not_found;





------------------------------------------------------------------------------------------------------

--unexpire_active_pp

------------------------------------------------------------------------------------------------------ 



PROCEDURE unexpire_active_pp (i_ban           &owner.service_agreement.ban%TYPE,

                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS



--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

invalid_discount   &owner.oms_related_info.related_number%TYPE;

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

v_exp_pp_exists    INTEGER:=0;

v_exp_pp_not_exists INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR upd_sa_mode (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

select o.om_order_id,order_version,order_type,om_order_status,order_version_status,o.om_product_id,o.ban,o.product_version,

       opv.omsa_group_id,opv.billing_product_id,opv.product_type,product_sub_type,om_product_status,product_ver_status 

from &owner.oms_order o,&owner.oms_product_version opv

WHERE o.ban = i_ban

AND o.om_order_id = i_om_order_id

AND o.om_product_id = i_om_product_id

AND o.om_product_id = opv.om_product_id

AND o.product_version = opv.product_version

AND om_order_status = 'DC'

AND order_version_status = 'CU'

;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN

				dbms_output.put_line('unexpire_active_pp Starting...');	

				

				FOR upd_sa_mode_rec IN upd_sa_mode (i_ban,i_om_order_id,i_om_product_id)

				  LOOP

				

				

				SELECT COUNT(*) INTO v_exp_pp_exists

				FROM &owner.oms_srv_agreement osa

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NULL) 

				AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NOT NULL) 

				               ;

				               

				               

				SELECT COUNT(*) INTO v_exp_pp_not_exists

				FROM &owner.oms_srv_agreement osa

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               --AND sa.expiration_date IS NULL

				               ) 

				              

				;               

				                             

				IF v_exp_pp_exists >0 THEN               

				-- update records

				UPDATE &owner.oms_srv_agreement osa

				SET sa_mode = 'EP',

				sys_update_date = SYSDATE,

				application_id = 'DC_CNV',

				expiration_date = effective_date,

				expiration_issue_date = effective_date,

				disconnect_rsn = 'B'

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NULL) 

				AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NOT NULL) 

				               ;

				

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				            

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO EP FOR BAN: '||upd_sa_mode_rec.BAN);

				DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

				END IF;

				

				IF v_exp_pp_not_exists >0 THEN

				-- update records

				UPDATE &owner.oms_srv_agreement osa

				SET sa_mode = 'AD',

				sys_update_date = SYSDATE,

				application_id = 'DC_CNV'

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               --AND sa.expiration_date IS NULL

				               ) 

				;

				               

				

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO AD FOR BAN: '||upd_sa_mode_rec.BAN);

				DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

				END IF;

				

				

				 v_cnt :=0;

				 v_exp_pp_exists :=0;

				 v_exp_pp_not_exists :=0;

				   

				 

				END LOOP;

				--COMMIT;

				dbms_output.put_line('---------------------------------------------------------------------');

				dbms_output.put_line(' ');       



				EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('NO INVALID SA_MODES FOUND FOR THIS ORDER');

				    

  END unexpire_active_pp;



------------------------------------------------------------------------------------------------------

--IPV_with_no_pend_ord

------------------------------------------------------------------------------------------------------ 



	procedure IPV_with_no_pend_ord(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... IPV_with_no_pend_ord proc not created yet');

  end IPV_with_no_pend_ord;

  

  ------------------------------------------------------------------------------------------------------

--IPV_with_no_pend_ord_prod_can

------------------------------------------------------------------------------------------------------ 



	procedure IPV_with_no_pend_ord_prod_can(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... IPV_with_no_pend_ord_prod_can proc not created yet');

  end IPV_with_no_pend_ord_prod_can;

  

  ------------------------------------------------------------------------------------------------------

--Ban_Level_PP_does_not_exists

------------------------------------------------------------------------------------------------------ 

	procedure Ban_Level_PP_does_not_exists(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ...Ban_Level_PP_does_not_exists proc not created yet');

  end Ban_Level_PP_does_not_exists;



------------------------------------------------------------------------------------------------------

--NS_Locked_by_Global_Update

------------------------------------------------------------------------------------------------------ 

	

	procedure NS_Locked_by_Global_Update(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

		v_order			&owner.oms_order.om_order_id%type;

		v_om_prod		&owner.oms_order.om_product_id%type;

		v_ban				&owner.oms_order.ban%type;

	

	begin

		--dbms_output.put_line('TODO ... NS_Locked_by_Global_Update proc not created yet');

		dbms_output.put_line('NS_Locked_by_Global_Update Starting...');	

		

	begin	

		select o.om_order_id, o.om_product_id, o.ban

		into v_order, v_om_prod, v_ban

		from &owner.oms_order o

		where o.om_order_id = i_om_order_id

		and o.order_version_status = 'CU'

		and o.om_order_status != 'CP'	;

	Exception 

		when no_data_found then 

			dbms_output.put_line('order is already complete');

	End;	

		

		dbms_output.put_line('  BAN: '||v_ban);

		dbms_output.put_line('  OM Prod: '||v_om_prod);

		dbms_output.put_line('  Order: '||v_order);

		

		update &owner.CSM_BAN_PROD_LOCK

		set exp_ind = 'Y',

				application_id = 'DC_CNV',

				sys_update_date = sysdate

		where ban = v_ban

		and om_product_id =v_om_prod ;

		

		dbms_output.put_line('---------------------------------------------------------------------');

		dbms_output.put_line(' ');  

		    EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

  end NS_Locked_by_Global_Update;



------------------------------------------------------------------------------------------------------

--No_Script_Sub_Market_Problem

------------------------------------------------------------------------------------------------------   

	procedure No_Script_Sub_Market_Problem(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('REPORT NPA/NXX/LINENO TO DEB DEMAREE..MAY HAVE TO SCRIPT ORDER TO CANCELLED STATUS');

  end No_Script_Sub_Market_Problem;



------------------------------------------------------------------------------------------------------

--Order_Not_found_for_product_id

------------------------------------------------------------------------------------------------------ 

  PROCEDURE Order_Not_found_for_product_id (i_ban             &owner.service_agreement.ban%TYPE,

                           i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                           i_om_product_id   &owner.oms_order.om_product_id%TYPE)

                           

 IS

                           

marker             &owner.service_agreement.application_id%TYPE;

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR rem_invalid_pv (i_ban              &owner.service_agreement.ban%TYPE,

                      i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                      i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

                SELECT OM_PRODUCT_ID,PRODUCT_VERSION,BAN_ID,OM_PRODUCT_STATUS,PRODUCT_VER_STATUS

                FROM &owner.oms_product_version opv

                WHERE om_product_id = i_om_product_id

                AND ban_id = i_ban

;





-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN



FOR rem_invalid_pv_rec IN rem_invalid_pv (i_ban,i_om_order_id,i_om_product_id)

  LOOP



-- Delete invalid product version from oms_product_version if such a record does not exist in oms_order

-- Error appears to be caused by partial rollback of order where OPV was populated but Order table was not.



    DELETE FROM &owner.oms_product_version opv

    WHERE om_product_id = rem_invalid_pv_rec.om_product_id

    AND product_version = rem_invalid_pv_rec.product_version

    AND NOT EXISTS (SELECT 1 FROM &owner.oms_order o

    WHERE o.om_product_id = opv.om_product_id

    AND o.ban = opv.ban_id

    AND o.product_version = opv.product_version)

;



   



    v_cnt := SQL%ROWCOUNT;

    t_cnt := t_cnt+v_cnt;

            

DBMS_OUTPUT.PUT_LINE (' '); 

DBMS_OUTPUT.PUT_LINE ('Invalid product_version being removed: '||rem_invalid_pv_rec.product_version);

DBMS_OUTPUT.PUT_LINE ('ROWS DELETED FROM OMS_PRODUCT_VERSION FOR BAN ' ||rem_invalid_pv_rec.ban_id || ': ' ||  v_cnt);

 

--Lets update the order.order_version_status to 'CU' for the max order version where the product_version

--matches the historical product_version in oms_product_version.  

UPDATE &owner.oms_order o

SET order_version_status = 'CU',

sys_update_date = SYSDATE,

application_id = marker

WHERE om_product_id = rem_invalid_pv_rec.om_product_id

AND order_version IN (SELECT MAX(order_version)

                    FROM &owner.oms_order o2

                    WHERE o2.ban = o.ban

                    AND o2.om_product_id = o.om_product_id

                    AND o2.om_order_id = o.om_order_id

/*                    AND om_order_status = 'CP'

                    AND order_version_status !='CU'*/

                    )

AND EXISTS(SELECT 1 FROM &owner.oms_product_version opv

           WHERE opv.om_product_id = o.om_product_id

           AND opv.ban_id = o.ban

           AND opv.product_version = o.product_version

           AND om_product_status = 'AC'

           AND product_ver_status = 'HI')

AND om_order_status = 'CP'

AND order_version_status = 'HI';



    v_cnt := SQL%ROWCOUNT;

    t_cnt := t_cnt+v_cnt;

            

DBMS_OUTPUT.PUT_LINE (' '); 

DBMS_OUTPUT.PUT_LINE ('UPDATING ORDER_VERSION_STATUS TO CU FOR PRODUCT_VERSION: '||rem_invalid_pv_rec.product_version);

DBMS_OUTPUT.PUT_LINE ('ROWS UPDATEDD FROM OMS_PRODUCT_VERSION FOR BAN ' ||rem_invalid_pv_rec.ban_id || ': ' ||  v_cnt);









END LOOP;

--COMMIT;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;          

  WHEN OTHERS THEN

    DBMS_OUTPUT.PUT_LINE ('NO INVALID PRODUCT_VERSION FOUND FOR THIS ORDER');

END Order_Not_found_for_product_id;

   



------------------------------------------------------------------------------------------------------

--dom_gt_curver_omordr_by_prod

------------------------------------------------------------------------------------------------------ 



	

PROCEDURE dom_gt_curver_omordr_by_prod (i_ban           &owner.service_agreement.ban%TYPE,

                                         i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                         i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS



marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt               CHAR(30);           --for date/time

v_bundle_seq     &owner.oms_bundle_ord_depend.bundle_seq%TYPE;

v_om_order_id    &owner.oms_bundle_ord_depend.om_order_id%TYPE;

v_bundle_seq_ver &owner.oms_bundle_ord_depend.bundle_seq_ver%TYPE;

v_om_product_id &owner.oms_bundle_ord_depend.om_product_id%TYPE;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN

        dbms_output.put_line('dom_gt_curver_omordr_by_prod Starting...');  

        

     BEGIN

        SELECT OBD.bundle_seq,OBD.om_order_id,OBD.om_product_id,OBD.bundle_seq_ver

        INTO v_bundle_seq, v_om_order_id, v_om_product_id,v_bundle_seq_ver

        FROM  &OWNER.OMS_BUNDLE_ORD_DEPEND OBD, 

              (SELECT OBRD.BUNDLE_SEQ, MAX(OBRD.BUNDLE_SEQ_VER) MAX_VER, OBRD.OM_ORDER_ID, OBRD.OM_PRODUCT_ID,my_view.ban, 

                                       my_view.ORDER_VERSION_STATUS,my_view.om_order_status,

                                        my_view.order_version, my_view.product_version, my_view.order_type

               FROM &OWNER.OMS_BUNDLE_ORD_DEPEND  OBRD, 

                    (SELECT om_order_id,om_product_id,ban,ORDER_VERSION_STATUS,om_order_status, order_version, product_version, order_type

                    FROM &OWNER.oms_order 

                    WHERE (ORDER_VERSION_STATUS = 'CU' OR ORDER_VERSION_STATUS = 'CA')

                    AND (om_order_status='DE' or om_order_status ='DC')

                    AND mpv_ind='Y'

                    AND ban = i_ban

                    ) MY_VIEW

         WHERE OBRD.OM_ORDER_ID = MY_VIEW.om_order_id  

         AND OBRD.OM_PRODUCT_ID = MY_VIEW.om_product_id

         GROUP BY OBRD.BUNDLE_SEQ, OBRD.OM_ORDER_ID, OBRD.OM_PRODUCT_ID,my_view.ban,my_view.ORDER_VERSION_STATUS,my_view.om_order_status,

         my_view.order_version, my_view.product_version, my_view.order_type

         ) TMP_OBD  

         WHERE OBD.BUNDLE_SEQ =TMP_OBD.BUNDLE_SEQ

         AND OBD.BUNDLE_SEQ_VER=TMP_OBD.MAX_VER

         AND NOT EXISTS ( select 1 from &OWNER.OMS_ORDER ORD WHERE 

                        ORD.Om_Order_Id = OBD.Om_Order_Id

                        and ORD.OM_PRODUCT_ID= OBD.OM_PRODUCT_ID

                        );

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            NULL;          

          WHEN OTHERS THEN

            DBMS_OUTPUT.PUT_LINE ('NO INVALID OBOD ENTRY FOUND FOR THIS ORDER');

        END; 

         

    DBMS_OUTPUT.PUT_LINE('  Bundle Sequence: '||v_bundle_seq);

    DBMS_OUTPUT.PUT_LINE('  Order ID: '||v_om_order_id);

    DBMS_OUTPUT.PUT_LINE('  OM product_id: '||v_om_product_id);

    DBMS_OUTPUT.PUT_LINE('  Bundle Sequence Version: '||v_bundle_seq_ver);



        DELETE FROM &owner.oms_bundle_ord_depend OBOD

        WHERE OBOD.bundle_seq =v_bundle_seq 

        AND OBOD.om_order_id = v_om_order_id 

        AND OBOD.om_product_id  = v_om_product_id

        AND OBOD.bundle_seq_ver = v_bundle_seq_ver ;



    dbms_output.put_line('---------------------------------------------------------------------');

    dbms_output.put_line(' ');  

        EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('HANDLING EXCEPTIONS FOR THIS ORDER');

            

  END dom_gt_curver_omordr_by_prod;





------------------------------------------------------------------------------------------------------

--dom_gt_curver_omprod

------------------------------------------------------------------------------------------------------ 

		

	procedure dom_gt_curver_omprod(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... dom_gt_curver_omprod proc not created yet');

  end dom_gt_curver_omprod;  





------------------------------------------------------------------------------------------------------

--fix_msag_address

------------------------------------------------------------------------------------------------------ 

	

	procedure fix_msag_address(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... fix_msag_address proc not created yet');

  end fix_msag_address;  



------------------------------------------------------------------------------------------------------

--pcs_handle_move_deposit

------------------------------------------------------------------------------------------------------ 

	

	procedure pcs_handle_move_deposit(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... pcs_handle_move_deposit proc not created yet');

  end pcs_handle_move_deposit;  

	

------------------------------------------------------------------------------------------------------

--pom_change_master_product

------------------------------------------------------------------------------------------------------ 

  

	procedure pom_change_master_product(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS



marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

invalid_discount   &owner.oms_related_info.related_number%TYPE;

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

v_exp_pp_exists    INTEGER:=0;

v_exp_pp_not_exists INTEGER:=0;

v_oms_exp_not_in_csm INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR upd_sa_mode (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

select o.om_order_id,order_version,order_type,om_order_status,order_version_status,o.om_product_id,o.ban,o.product_version,

       opv.omsa_group_id,opv.billing_product_id,opv.product_type,product_sub_type,om_product_status,product_ver_status 

from &owner.oms_order o,&owner.oms_product_version opv

WHERE o.ban = i_ban

AND o.om_order_id = i_om_order_id

AND o.om_product_id = i_om_product_id

AND o.om_product_id = opv.om_product_id

AND o.product_version = opv.product_version

AND om_order_status = 'DC'

AND order_version_status = 'CU'

;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN

				dbms_output.put_line('pom_change_master_product Starting...');	

				

				FOR upd_sa_mode_rec IN upd_sa_mode (i_ban,i_om_order_id,i_om_product_id)

				  LOOP

				

				

				SELECT COUNT(*) INTO v_exp_pp_exists

				FROM &owner.oms_srv_agreement osa

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NULL) 

				AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NOT NULL) 

				               ;

				               

				               

				SELECT COUNT(*) INTO v_exp_pp_not_exists

				FROM &owner.oms_srv_agreement osa

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               --AND sa.expiration_date IS NULL

				               ) 

				              

				;

        

             

				                             

				IF v_exp_pp_exists >0 THEN               

				-- update records

				UPDATE &owner.oms_srv_agreement osa

				SET sa_mode = 'EP',

				sys_update_date = SYSDATE,

				application_id = 'DC_CNV',

				expiration_date = effective_date,

				disconnect_rsn = 'B',

				expiration_issue_date = effective_date

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NULL) 

				AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NOT NULL) 

				               ;

				

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				

                    

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO EP FOR BAN: '||upd_sa_mode_rec.BAN);

				DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

				END IF;

				

				IF v_exp_pp_not_exists >0 THEN

				-- update records

				UPDATE &owner.oms_srv_agreement osa

				SET sa_mode = 'AD',

				sys_update_date = SYSDATE,

				application_id = 'DC_CNV'

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               --AND sa.expiration_date IS NULL

				               ) 

				;

				               

				

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO AD FOR BAN: '||upd_sa_mode_rec.BAN);

				DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

				END IF;

				

				        SELECT COUNT(*) INTO v_oms_exp_not_in_csm

                FROM &owner.oms_srv_agreement osa

                WHERE ban = upd_sa_mode_rec.ban

                AND product_id = upd_sa_mode_rec.billing_product_id

              --AND price_plan = 'CLDL491PO'

                AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

                AND sa_mode = 'EP'

                AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

                       WHERE sa.ban = osa.ban

                       AND sa.product_id = osa.product_id

                       AND sa.product_type = osa.product_type

                       AND sa.price_plan = osa.price_plan

                       AND sa.sa_unique_id = osa.sa_unique_id

                       --AND sa.expiration_date IS NULL

                       ) 

                       ;  

                       

       IF v_oms_exp_not_in_csm>0 THEN

          DELETE FROM &owner.oms_srv_agreement osa

          WHERE ban = upd_sa_mode_rec.ban

          AND product_id = upd_sa_mode_rec.billing_product_id

        --AND price_plan = 'CLDL491PO'

          AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

          AND sa_mode = 'EP'

          AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

                       WHERE sa.ban = osa.ban

                       AND sa.product_id = osa.product_id

                       AND sa.product_type = osa.product_type

                       AND sa.price_plan = osa.price_plan

                       AND sa.sa_unique_id = osa.sa_unique_id

                       --AND sa.expiration_date IS NULL

                       ) 

                       ;                        

       END IF;                

                       

				 v_cnt :=0;

				 v_exp_pp_exists :=0;

				 v_exp_pp_not_exists :=0;

         v_oms_exp_not_in_csm :=0;

				   

				 

				END LOOP;

				--COMMIT;

				dbms_output.put_line('---------------------------------------------------------------------');

				dbms_output.put_line(' ');       



				EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('NO INVALID SA_MODES FOUND FOR THIS ORDER');

				    



  end pom_change_master_product;  

  

------------------------------------------------------------------------------------------------------

--pom_delete_relationship

------------------------------------------------------------------------------------------------------ 

	

	procedure pom_delete_relationship(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... pom_delete_relationship proc not created yet');

  end pom_delete_relationship;  

  

------------------------------------------------------------------------------------------------------

--pp_not_found_doesnt_exists

------------------------------------------------------------------------------------------------------ 

	

PROCEDURE pp_not_found_doesnt_exists (i_ban           &owner.service_agreement.ban%TYPE,

                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS



--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

invalid_discount   &owner.oms_related_info.related_number%TYPE;

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

v_exp_pp_exists    INTEGER:=0;

v_exp_pp_not_exists INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR upd_sa_mode (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

select o.om_order_id,order_version,order_type,om_order_status,order_version_status,o.om_product_id,o.ban,o.product_version,

       opv.omsa_group_id,opv.billing_product_id,opv.product_type,product_sub_type,om_product_status,product_ver_status 

from &owner.oms_order o,&owner.oms_product_version opv

WHERE o.ban = i_ban

AND o.om_order_id = i_om_order_id

AND o.om_product_id = i_om_product_id

AND o.om_product_id = opv.om_product_id

AND o.product_version = opv.product_version

AND om_order_status = 'DC'

AND order_version_status = 'CU'

;



---------------------------------

--  M A I N   P R O C E D U R E

---------------------------------



BEGIN

				dbms_output.put_line('pp_not_found_doesnt_exists Starting...');	

				

				FOR upd_sa_mode_rec IN upd_sa_mode (i_ban,i_om_order_id,i_om_product_id)

				  LOOP

				

				

				SELECT COUNT(*) INTO v_exp_pp_exists

				FROM &owner.oms_srv_agreement osa

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NULL) 

				AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NOT NULL) 

				               ;

				               

				               

				SELECT COUNT(*) INTO v_exp_pp_not_exists

				FROM &owner.oms_srv_agreement osa

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               --AND sa.expiration_date IS NULL

				               ) 

				              

				;               

				                             

				IF v_exp_pp_exists >0 THEN               

				-- update records

				UPDATE &owner.oms_srv_agreement osa

				SET sa_mode = 'EP',

				sys_update_date = SYSDATE,

				application_id = 'DC_CNV',

				expiration_date = effective_date,

				disconnect_rsn = 'B',

				expiration_issue_date = effective_date

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NULL) 

				AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               AND sa.expiration_date IS NOT NULL) 

				               ;

				

				    v_cnt := SQL%ROWCOUNT;

				    t_cnt := t_cnt+v_cnt;

				            

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO EP FOR BAN: '||upd_sa_mode_rec.BAN);

				DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

				END IF;

				

				IF v_exp_pp_not_exists >0 THEN

				-- update records

				UPDATE &owner.oms_srv_agreement osa

				SET sa_mode = 'AD',

				sys_update_date = SYSDATE,

				application_id = 'DC_CNV'

				WHERE ban = upd_sa_mode_rec.ban

				AND expiration_date IS NULL

				AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

				AND sa_mode = 'AC'

				AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

				               WHERE sa.ban = osa.ban

				               AND sa.product_id = osa.product_id

				               AND sa.product_type = osa.product_type

				               AND sa.price_plan = osa.price_plan

				               AND sa.sa_unique_id = osa.sa_unique_id

				               AND sa.pp_seq_no = osa.pp_seq_no

				               --AND sa.expiration_date IS NULL

				               ) 

				;

				               

				

				DBMS_OUTPUT.PUT_LINE (' '); 

				DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO AD FOR BAN: '||upd_sa_mode_rec.BAN);

				DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

				END IF;

				

				

				 v_cnt :=0;

				 v_exp_pp_exists :=0;

				 v_exp_pp_not_exists :=0;

				   

				 

				END LOOP;

				--COMMIT;

				dbms_output.put_line('---------------------------------------------------------------------');

				dbms_output.put_line(' ');       



				EXCEPTION

				  WHEN NO_DATA_FOUND THEN

				    NULL;          

				  WHEN OTHERS THEN

				    DBMS_OUTPUT.PUT_LINE ('NO INVALID SA_MODES FOUND FOR THIS ORDER');

				    

  

  end pp_not_found_doesnt_exists; 



  

------------------------------------------------------------------------------------------------------

--No_basic_pp_found_for_product

------------------------------------------------------------------------------------------------------ 

  

  procedure No_basic_pp_found_for_product(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... No_basic_pp_found_for_product proc not created yet');

  end No_basic_pp_found_for_product;  





------------------------------------------------------------------------------------------------------

--pp_not_found_product_cancelled

------------------------------------------------------------------------------------------------------ 

  

PROCEDURE  pp_not_found_product_cancelled (i_ban           &owner.service_agreement.ban%TYPE,

                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

AS



marker             &owner.service_agreement.application_id%TYPE;

invalid_discount   &owner.oms_related_info.related_number%TYPE;

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

v_exp_pp_exists    INTEGER:=0;

v_exp_pp_not_exists INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR upd_sa_mode (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

select o.om_order_id,order_version,order_type,om_order_status,order_version_status,o.om_product_id,o.ban,o.product_version,

       opv.omsa_group_id,opv.billing_product_id,opv.product_type,product_sub_type,om_product_status,product_ver_status 

from &owner.oms_order o,&owner.oms_product_version opv

WHERE o.ban = i_ban

AND o.om_order_id = i_om_order_id

AND o.om_product_id = i_om_product_id

AND o.om_product_id = opv.om_product_id

AND o.product_version = opv.product_version

AND om_order_status = 'DC'

AND order_version_status = 'CU'

;

BEGIN

	

	dbms_output.put_line('dcs_up_ftr_lcycl Starting...');

FOR upd_sa_mode_rec IN upd_sa_mode (i_ban,i_om_order_id,i_om_product_id)

  LOOP





SELECT COUNT(*) INTO v_exp_pp_exists

FROM &owner.oms_srv_agreement osa

WHERE ban = upd_sa_mode_rec.ban

AND expiration_date IS NULL

AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

AND sa_mode = 'AC'

AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

               WHERE sa.ban = osa.ban

               AND sa.product_id = osa.product_id

               AND sa.product_type = osa.product_type

               AND sa.price_plan = osa.price_plan

               AND sa.sa_unique_id = osa.sa_unique_id

               AND sa.pp_seq_no = osa.pp_seq_no

               AND sa.expiration_date IS NULL) 

AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

               WHERE sa.ban = osa.ban

               AND sa.product_id = osa.product_id

               AND sa.product_type = osa.product_type

               AND sa.price_plan = osa.price_plan

               AND sa.sa_unique_id = osa.sa_unique_id

               AND sa.pp_seq_no = osa.pp_seq_no

               AND sa.expiration_date IS NOT NULL) 

               ;

               

               

SELECT COUNT(*) INTO v_exp_pp_not_exists

FROM &owner.oms_srv_agreement osa

WHERE ban = upd_sa_mode_rec.ban

AND expiration_date IS NULL

AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

AND sa_mode = 'AC'

AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

               WHERE sa.ban = osa.ban

               AND sa.product_id = osa.product_id

               AND sa.product_type = osa.product_type

               AND sa.price_plan = osa.price_plan

               AND sa.sa_unique_id = osa.sa_unique_id

               AND sa.pp_seq_no = osa.pp_seq_no

               --AND sa.expiration_date IS NULL

               ) 

              

;               

                             

IF v_exp_pp_exists >0 THEN               

-- update records

UPDATE &owner.oms_srv_agreement osa

SET sa_mode = 'EP',

sys_update_date = SYSDATE,

application_id = 'DC_CNV',

expiration_date = effective_date,

disconnect_rsn = 'B',

expiration_issue_date = effective_date

WHERE ban = upd_sa_mode_rec.ban

AND expiration_date IS NULL

AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

AND sa_mode = 'AC'

AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

               WHERE sa.ban = osa.ban

               AND sa.product_id = osa.product_id

               AND sa.product_type = osa.product_type

               AND sa.price_plan = osa.price_plan

               AND sa.sa_unique_id = osa.sa_unique_id

               AND sa.pp_seq_no = osa.pp_seq_no

               AND sa.expiration_date IS NULL) 

AND EXISTS(SELECT 1 FROM &owner.service_agreement sa

               WHERE sa.ban = osa.ban

               AND sa.product_id = osa.product_id

               AND sa.product_type = osa.product_type

               AND sa.price_plan = osa.price_plan

               AND sa.sa_unique_id = osa.sa_unique_id

               AND sa.pp_seq_no = osa.pp_seq_no

               AND sa.expiration_date IS NOT NULL) 

               ;



    v_cnt := SQL%ROWCOUNT;

    t_cnt := t_cnt+v_cnt;

            

DBMS_OUTPUT.PUT_LINE (' '); 

DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO EP FOR BAN: '||upd_sa_mode_rec.BAN);

DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

DBMS_OUTPUT.PUT_LINE ('OM_ORDER_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.om_order_id);

END IF;



IF v_exp_pp_not_exists >0 THEN

-- update records

UPDATE &owner.oms_srv_agreement osa

SET sa_mode = 'AD',

sys_update_date = SYSDATE,

application_id = 'DC_CNV'

WHERE ban = upd_sa_mode_rec.ban

AND expiration_date IS NULL

AND omsa_group_id =upd_sa_mode_rec.omsa_group_id

AND sa_mode = 'AC'

AND NOT EXISTS(SELECT 1 FROM &owner.service_agreement sa

               WHERE sa.ban = osa.ban

               AND sa.product_id = osa.product_id

               AND sa.product_type = osa.product_type

               AND sa.price_plan = osa.price_plan

               AND sa.sa_unique_id = osa.sa_unique_id

               AND sa.pp_seq_no = osa.pp_seq_no

               --AND sa.expiration_date IS NULL

               ) 

                     

;

               



DBMS_OUTPUT.PUT_LINE (' '); 

DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED TO AD FOR BAN: '||upd_sa_mode_rec.BAN);

DBMS_OUTPUT.PUT_LINE ('OMSA_GROUP_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.omsa_group_id);

DBMS_OUTPUT.PUT_LINE ('OM_ORDER_ID FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.om_order_id);

END IF;





 v_cnt :=0;

 v_exp_pp_exists :=0;

 v_exp_pp_not_exists :=0;

   

 

END LOOP;



dbms_output.put_line('---------------------------------------------------------------------');

		dbms_output.put_line(' ');  

		--COMMIT;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;          

  WHEN OTHERS THEN

    DBMS_OUTPUT.PUT_LINE ('NO INVALID SA_MODES FOUND FOR THIS ORDER');

END pp_not_found_product_cancelled;



------------------------------------------------------------------------------------------------------

--Product_must_be_suspended

------------------------------------------------------------------------------------------------------  

  procedure Product_must_be_suspended(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... Product_must_be_suspended proc not created yet');

  end Product_must_be_suspended;  

  

------------------------------------------------------------------------------------------------------

--aramAdjEnv

------------------------------------------------------------------------------------------------------	

	procedure aramAdjEnv(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... aramAdjEnv proc not created yet');

  end aramAdjEnv;  

  

------------------------------------------------------------------------------------------------------

--NS_Product_must_be_active

------------------------------------------------------------------------------------------------------  

  procedure NS_Product_must_be_active(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

  

  	v_cnt                     INTEGER:=0;

	  t_cnt                     INTEGER:=0;

  

	CURSOR act_prod (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS 

SELECT p.product_id,p.product_type,p.customer_id

FROM &owner.oms_order o,&owner.oms_product_version opv,&owner.product p

WHERE o.ban=i_ban

AND om_order_id = i_om_order_id

AND o.om_product_id = i_om_product_id

AND opv.om_product_id = o.om_product_id

AND opv.om_product_id = o.om_product_id

AND opv.billing_product_id = p.product_id

AND opv.product_version = o.product_version

AND opv.ban_id = p.customer_ban

AND om_order_status = 'DC'

--AND order_version_status= 'CU'

AND p.prod_status != 'A' 

AND product_ver_status NOT IN ('DC');

	

BEGIN



	dbms_output.put_line('Beginning NS_Product_must_be_active');

  

  FOR act_prod_rec IN act_prod (i_ban,i_om_order_id,i_om_product_id)

 LOOP



		dbms_output.put_line('Beginning NS_Product_must_be_active');



UPDATE &owner.product

SET prod_status = 'A',

prod_status_last_act='RSP',

prod_status_rsn_code='CLES',

sys_update_date = SYSDATE,

application_id = 'DC_CNV'

WHERE customer_id = act_prod_rec.customer_id

AND product_id = act_prod_rec.product_id

AND product_type = act_prod_rec.product_type

AND prod_status != 'A';





--COMMIT;

    v_cnt := SQL%ROWCOUNT;

    t_cnt := t_cnt+v_cnt;

            

DBMS_OUTPUT.PUT_LINE (' '); 

DBMS_OUTPUT.PUT_LINE ('ROWS UPDATED IN PRODUCT FOR BAN ' ||act_prod_rec.customer_id || ': ' ||  v_cnt);

DBMS_OUTPUT.PUT_LINE ('PRODUCT STATUS WAS UPDATED FROM S TO A FOR PRODUCT '||act_prod_rec.product_id);



 

END LOOP;

--COMMIT;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;          

  WHEN OTHERS THEN

    DBMS_OUTPUT.PUT_LINE ('PRODUCT RECORD DOES NOT NEED UPDATING FOR THIS ORDER');

  

  end NS_Product_must_be_active;  

  

------------------------------------------------------------------------------------------------------

--dcs_gt_cnt_BanDisc

------------------------------------------------------------------------------------------------------  

  procedure dcs_gt_cnt_BanDisc(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... dcs_gt_cnt_BanDisc proc not created yet');

  end dcs_gt_cnt_BanDisc;  

  

------------------------------------------------------------------------------------------------------

--pgn_gt_name_address_buf

------------------------------------------------------------------------------------------------------  

procedure pgn_gt_name_address_buf(i_ban           &owner.service_agreement.ban%TYPE,

                                        i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                                        i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS



--i_ban              &owner.service_agreement.ban%TYPE;

--i_om_order_id      &owner.oms_order.om_order_id%TYPE;

--i_om_product_id    &owner.oms_order.om_product_id%TYPE;

marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

dt                 CHAR(30);           --for date/time



 

--MAIN CURSOR

CURSOR fix_prod (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE)

IS

SELECT opv.omsa_group_id,opv.om_product_id,opv.product_version,opv.ban_id,opv.billing_product_id,opv.tn_npa,opv.tn_nxx,opv.tn_lineno,opv.sys_creation_date

FROM &owner.oms_product_version opv

WHERE /*product_type = 'DT'

AND */ban_id = i_ban

AND om_product_id = i_om_product_id

AND (trim(billing_product_id) !=trim(tn_npa||tn_nxx||tn_lineno) OR tn_npa||tn_nxx||tn_lineno IS NULL)

;



-----------------------------------------------------------------------------------------------------------------------

--  M A I N   P R O C E D U R E

-----------------------------------------------------------------------------------------------------------------------



BEGIN

        dbms_output.put_line('original_plan_was_not_found Starting...');



        FOR fix_prod_rec IN fix_prod (i_ban,i_om_order_id,i_om_product_id)

         LOOP



        UPDATE &owner.oms_product_version

        SET tn_npa = substr(billing_product_id,0,3),

        tn_nxx = substr(billing_product_id,4,3),

        tn_lineno = substr(billing_product_id,7,4),

        application_id = 'DC_CNV',

        sys_update_date = SYSDATE

        WHERE om_product_status != 'DC'

        AND product_ver_status != 'CA'

        AND billing_product_id NOT LIKE 'F%'

        AND billing_product_id NOT LIKE 'A%'

        --AND product_type = 'DT'

        AND ban_id = fix_prod_rec.ban_id

        AND om_product_id = fix_prod_rec.om_product_id

        AND (trim(billing_product_id) !=trim(tn_npa||tn_nxx||tn_lineno) OR tn_npa||tn_nxx||tn_lineno IS NULL);



 

        --COMMIT;

            v_cnt := SQL%ROWCOUNT;

            t_cnt := t_cnt+v_cnt;



        --DBMS_OUTPUT.PUT_LINE (' ');

        --DBMS_OUTPUT.PUT_LINE ('ROWS UPDATED IN OMS_EMAIL FOR BAN ' ||fix_prod_rec.ban_id || ': ' ||  v_cnt);

        --DBMS_OUTPUT.PUT_LINE ('TN_NPA||TN_NXX||TN_LINENO '||fix_prod_rec.TN_NPA||fix_prod_rec.TN_NXX||fix_prod_rec.TN_LINENO

         --                                                 ||' WAS UPDATED TO '||trim(fix_prod_rec.billing_product_id));



        END LOOP;

        --COMMIT;

        dbms_output.put_line('---------------------------------------------------------------------');

        dbms_output.put_line(' ');



        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            NULL;

          WHEN OTHERS THEN

            DBMS_OUTPUT.PUT_LINE ('OPV RECORD DOES NOT NEED UPDATING FOR THIS ORDER');

  end pgn_gt_name_address_buf;



------------------------------------------------------------------------------------------------------

--GnDts_DateTimeDiff

------------------------------------------------------------------------------------------------------  

  procedure GnDts_DateTimeDiff (i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... GnDts_DateTimeDiff proc not created yet');

  end GnDts_DateTimeDiff;  

------------------------------------------------------------------------------------------------------

--SERVICE_FEATURE_violated

------------------------------------------------------------------------------------------------------  

  procedure SERVICE_FEATURE_violated (i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... SERVICE_FEATURE_violated proc not created yet');

  end SERVICE_FEATURE_violated;  

------------------------------------------------------------------------------------------------------

--fix_ban_level_pp

------------------------------------------------------------------------------------------------------  

  procedure fix_ban_level_pp (i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... fix_ban_level_pp proc not created yet');

  end fix_ban_level_pp;  

  

  ------------------------------------------------------------------------------------------------------

--Active_Hist_prod_not_found

------------------------------------------------------------------------------------------------------  

  procedure Active_Hist_prod_not_found (i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... Active_Hist_prod_not_found proc not created yet');

  end Active_Hist_prod_not_found;  

  

------------------------------------------------------------------------------------------------------

--pomSendToTracs

------------------------------------------------------------------------------------------------------  

  procedure pomSendToTracs (i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... pomSendToTracs proc not created yet');

  end pomSendToTracs;  

------------------------------------------------------------------------------------------------------

--pom_resume_sus_csm_prod

------------------------------------------------------------------------------------------------------  

  procedure pom_resume_sus_csm_prod (i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... pom_resume_sus_csm_prod proc not created yet');

  end pom_resume_sus_csm_prod;  

  

  

------------------------------------------------------------------------------------------------------

--unknown

------------------------------------------------------------------------------------------------------

	PROCEDURE unknown (i_ban           &owner.service_agreement.ban%TYPE,

                   i_om_order_id     &owner.oms_order.om_order_id%TYPE,

                   i_om_product_id   &owner.oms_order.om_product_id%TYPE)

IS





marker             &owner.service_agreement.application_id%TYPE := 'DC_CNV';

v_cnt              INTEGER:=0;

t_cnt              INTEGER:=0;

v_pp_exists    INTEGER:=0;

dt               CHAR(30);           --for date/time





--MAIN CURSOR

CURSOR upd_sa_mode (i_ban              &owner.service_agreement.ban%TYPE,

                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                 i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

select o.om_order_id,order_version,order_type,om_order_status,order_version_status,o.om_product_id,o.ban,o.product_version,

       opv.omsa_group_id,opv.billing_product_id,opv.product_type,product_sub_type,om_product_status,product_ver_status, osa.product_id,osa.sa_unique_id,

       osa.price_plan,osa.service_agreement_id

from &owner.oms_order o,&owner.oms_product_version opv, &owner.oms_srv_agreement osa

WHERE o.ban = i_ban

AND o.om_order_id = i_om_order_id

AND o.om_product_id = i_om_product_id

AND o.om_product_id = opv.om_product_id

AND o.product_version = opv.product_version

AND osa.ban = o.ban

AND osa.product_id = opv.billing_product_id

AND osa.omsa_group_id = opv.omsa_group_id

AND osa.product_type = opv.product_type

AND sa_mode IS NULL

AND expiration_date IS NULL

AND om_order_status  IN( 'DC','DE')

AND order_version_status = 'CU'

;



---------------------------------

--  M A I N   P R O C E D U R E

---------------------------------



BEGIN

        dbms_output.put_line('Unknown Starting...');  

        

        FOR upd_sa_mode_rec IN upd_sa_mode (i_ban,i_om_order_id,i_om_product_id)

          LOOP

        

        

        SELECT COUNT(*) INTO v_pp_exists

        FROM &owner.service_agreement sa

        WHERE ban = upd_sa_mode_rec.ban

        AND product_id = upd_sa_mode_rec.product_id

        AND price_plan =upd_sa_mode_rec.price_plan

        AND product_type = upd_sa_mode_rec.product_type

        AND sa_unique_id = upd_sa_mode_rec.sa_unique_id

        AND expiration_date IS NULL;

              

                                     

        IF v_pp_exists >0 THEN               

        UPDATE &owner.oms_srv_agreement osa

        SET sa_mode = 'AC',

        sys_update_date = SYSDATE,

        application_id = 'DC_CNV'

        WHERE ban = upd_sa_mode_rec.ban

        AND expiration_date IS NULL

        AND service_agreement_id = upd_sa_mode_rec.service_agreement_id

        AND sa_mode IS NULL;

        

            v_cnt := SQL%ROWCOUNT;

            t_cnt := t_cnt+v_cnt;

                    

        DBMS_OUTPUT.PUT_LINE (' '); 

        DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED FROM NULL TO AC FOR BAN: '||upd_sa_mode_rec.BAN);

        DBMS_OUTPUT.PUT_LINE ('service_agreement_id FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.service_agreement_id);

        

        

        ELSE 

        UPDATE &owner.oms_srv_agreement osa

        SET sa_mode = 'AD',

        sys_update_date = SYSDATE,

        application_id = 'DC_CNV'

        WHERE ban = upd_sa_mode_rec.ban

        AND expiration_date IS NULL

        AND service_agreement_id = upd_sa_mode_rec.service_agreement_id

        AND sa_mode IS NULL;

        

            v_cnt := SQL%ROWCOUNT;

            t_cnt := t_cnt+v_cnt;

                       

        

        DBMS_OUTPUT.PUT_LINE (' '); 

        DBMS_OUTPUT.PUT_LINE ('SA_MODE BEING CHANGED FROM NULL TO AD FOR BAN: '||upd_sa_mode_rec.BAN);

        DBMS_OUTPUT.PUT_LINE ('service_agreement_id FOR PP BEING CHANGED IS : '||upd_sa_mode_rec.service_agreement_id);

        END IF;

        

        

         v_cnt :=0;

         v_pp_exists :=0;

           

         

      END LOOP;

        --COMMIT;

        dbms_output.put_line('---------------------------------------------------------------------');

        dbms_output.put_line(' ');       



        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            NULL;          

          WHEN OTHERS THEN

            DBMS_OUTPUT.PUT_LINE ('NO INVALID SA_MODES FOUND FOR THIS ORDER...NOT SA_MODE RELATED');

            

  

  end unknown;







------------------------------------------------------------------------------------------------------

--Too_many_rows_in_cust_feature

------------------------------------------------------------------------------------------------------

  

  	procedure Too_many_rows_in_cust_feature(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... Too_many_rows_in_cust_feature is handled by outside scirpt');

  end Too_many_rows_in_cust_feature;

  

  ------------------------------------------------------------------------------------------------------

--DCS_UP_PP_DATES

------------------------------------------------------------------------------------------------------

  

  	procedure DCS_UP_PP_DATES(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... DCS_UP_PP_DATES is handled by outside scirpt');

  end DCS_UP_PP_DATES;

  

    ------------------------------------------------------------------------------------------------------

--remove_inv_bundle_seq

------------------------------------------------------------------------------------------------------

  

  	procedure remove_inv_bundle_seq(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... remove_inv_bundle_seq is handled by outside scirpt');

  end remove_inv_bundle_seq;

  

------------------------------------------------------------------------------------------------------

--year_must_be_between

------------------------------------------------------------------------------------------------------

  

  	procedure year_must_be_between(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... year_must_be_between is handled by outside scirpt');

  end year_must_be_between;

  

  

  ------------------------------------------------------------------------------------------------------

--pgn_create_future_trx

------------------------------------------------------------------------------------------------------

  

  	procedure pgn_create_future_trx(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... pgn_create_future_trx is handled by outside scirpt');

  end pgn_create_future_trx;

  

 ------------------------------------------------------------------------------------------------------

--ERROR_in_Bundle

------------------------------------------------------------------------------------------------------

  

  	procedure ERROR_in_Bundle(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... ERROR_in_Bundle is handled by outside scirpt');

  end ERROR_in_Bundle;

      ------------------------------------------------------------------------------------------------------

--pcs_handle_om_olp

------------------------------------------------------------------------------------------------------

  

  	procedure pcs_handle_om_olp(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... pcs_handle_om_olp is handled by outside scirpt');

  end pcs_handle_om_olp;

  

        ------------------------------------------------------------------------------------------------------

--arinGtSbmk

------------------------------------------------------------------------------------------------------

  

  	procedure arinGtSbmk(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... arinGtSbmk is handled by outside scirpt');

  end arinGtSbmk;

  

        ------------------------------------------------------------------------------------------------------

--update_pending_prod

------------------------------------------------------------------------------------------------------

  

  	procedure update_pending_prod(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... update_pending_prod is handled by outside scirpt');

  end update_pending_prod;



------------------------------------------------------------------------------------------------------

--Disc_on_canc_product

------------------------------------------------------------------------------------------------------

  

  	procedure Disc_on_canc_product(i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	IS

	

	begin

		dbms_output.put_line('TODO ... Disc_on_canc_product is handled by outside scirpt');

  end Disc_on_canc_product;

  

------------------------------------------------------------------------------------------------------

--row_not_found_in_MEM_FEATURE

------------------------------------------------------------------------------------------------------

  

  PROCEDURE row_not_found_in_MEM_FEATURE (i_ban           &owner.service_agreement.ban%TYPE,

	                                      i_om_order_id     &owner.oms_order.om_order_id%TYPE,

	                                      i_om_product_id   &owner.oms_order.om_product_id%TYPE)

	

IS



  

  --MAIN CURSOR

CURSOR rem_mem_ftr (i_ban              &owner.service_agreement.ban%TYPE,

                    i_om_order_id      &owner.oms_order.om_order_id%TYPE,

                    i_om_product_id    &owner.oms_order.om_product_id%TYPE) 

IS

    SELECT osf.service_feature_id,feature_code

    from &owner.oms_order o,&owner.oms_product_version opv,&owner.oms_service_feature osf

    where o.om_product_id = opv.om_product_id

    and o.product_version = opv.product_version

    and o.ban = opv.ban_id

    AND osf.ban = o.ban

    AND osf.product_id = opv.billing_product_id

    AND osf.product_type = opv.product_type

    AND osf.omsa_group_id = opv.omsa_group_id

    AND order_version_status = 'CU'

    AND order_version in (select max(order_version) from &owner.oms_order o2

                     WHERE o.ban = o2.ban

                     AND o.om_product_id = o2.om_product_id

                     AND o.om_order_id = o2.om_order_id)

    AND osf.feature_code NOT IN (SELECT FEATURE_CODE FROM &REF.feature f

                                 WHERE f. feature_code = osf.feature_code)

    AND (o.ban, o.om_order_id, o.om_product_id ) in ((i_ban,i_om_order_id,i_om_product_id));

  

 

	BEGIN

		dbms_output.put_line('Beginning row_not_found_in_MEM_FEATURE procedure');

    

  FOR  rem_mem_ftr_rec IN rem_mem_ftr(i_ban,i_om_order_id,i_om_product_id)

  LOOP

  

    DELETE FROM &owner.oms_service_feature

    WHERE service_feature_id = rem_mem_ftr_rec.service_feature_id;

    dbms_output.put_line('Deleted the following invalid feature_code in oms_service_feature: '||rem_mem_ftr_rec.feature_code);

    

  END LOOP;

  

  dbms_output.put_line('---------------------------------------------------------------------');

	dbms_output.put_line(' ');  



EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;          

  WHEN OTHERS THEN

    DBMS_OUTPUT.PUT_LINE ('NO INVALID FEATURES FOUND FOR THIS ORDER');  

  

    END row_not_found_in_MEM_FEATURE;

    

    --------------------------------------------------------------------------------------------------------
--CANCEL ORDER PROCEDURE 
------------------------------------------------------------------------------------------------------

  PROCEDURE CANCEL_ORDER  (i_ban          &owner.oms_order.ban%type,
                          i_om_order_id  &owner.oms_order.om_order_id%type,
                          i_om_product_id   &owner.oms_order.om_product_id%type) 
  IS

    V_MARKER             &OWNER.OMS_ORDER.APPLICATION_ID%TYPE  := 'CANCEL';
    V_BAN                &OWNER.OMS_ORDER.BAN%TYPE;
    V_OM_ORDER_ID        &OWNER.OMS_ORDER.OM_ORDER_ID%TYPE;
    V_OM_PRODUCT_ID      &OWNER.OMS_ORDER.OM_PRODUCT_ID%TYPE;
    V_PRODUCT_VERSION    &OWNER.OMS_ORDER.PRODUCT_VERSION%TYPE;
    V_PRODUCT_TYPE       &OWNER.OMS_PRODUCT_VERSION.PRODUCT_TYPE%TYPE;
    V_BILLING_PRODUCT_ID &OWNER.OMS_PRODUCT_VERSION.BILLING_PRODUCT_ID%TYPE;
    V_ORDER_TYPE         &OWNER.OMS_ORDER.ORDER_TYPE%TYPE;
    v_cnt                INTEGER:=0;
    t_cnt                INTEGER:=0;
    dt                   CHAR(30);           --for date/time
    
    n_total_to_cancel           number(9):=0;
    n_total_rec_handled1        number(9):=0;
    n_total_rec_handled_routed  number(9):=0;
    n_routed_count              number := 0;
    n_deposit_count             number :=0;
    n_new_install_count         number := 0;
    n_total_rec_deposit         number(9):=0;
    

CURSOR CANORD (i_ban              &owner.service_agreement.ban%TYPE,
                 i_om_order_id      &owner.oms_order.om_order_id%TYPE,
                 i_om_product_id    &owner.oms_order.om_product_id%TYPE)        
IS
SELECT UNIQUE OO.OM_ORDER_ID, OO.OM_PRODUCT_ID, OO.PRODUCT_VERSION, OO.BAN, PV.BILLING_PRODUCT_ID, OO.ORDER_TYPE,PV.PRODUCT_TYPE
  FROM &OWNER.OMS_ORDER OO, &OWNER.OMS_PRODUCT_VERSION PV, &OWNER.OMS_TASK OT
 WHERE  OO.ban = i_ban
AND OO.om_order_id>= i_om_order_id
AND OO.om_product_id = i_om_product_id
   AND OO.ORDER_VERSION_STATUS='CU'
   AND OO.OM_ORDER_STATUS <>'CP'
      AND OO.PRODUCT_VERSION = PV.PRODUCT_VERSION 
      AND OO.OM_ORDER_ID = OT.OM_ORDER_ID
AND OO.OM_PRODUCT_ID = OT.OM_PRODUCT_ID
AND NOT EXISTS (SELECT 1 FROM &OWNER.PRODUCT WHERE PRODUCT_ID=PV.BILLING_PRODUCT_ID
                                           AND CUSTOMER_ID=PV.BAN_ID 
                                           AND PRODUCT_TYPE=PV.PRODUCT_TYPE
                                           AND PROD_STATUS='A'
                                           AND EXISTS (SELECT 1 FROM &OWNER.OMS_TASK 
                                           WHERE OM_ORDER_ID=OO.OM_ORDER_ID 
                                                AND OM_PRODUCT_ID=OO.OM_PRODUCT_ID
                                                AND OM_TASK_CODE='COMERR'))         
     ;
     
BEGIN
FOR CANORD_rec IN CANORD (i_ban,i_om_order_id,i_om_product_id)
  LOOP


    V_BAN                :=CANORD_rec.BAN;
    V_OM_ORDER_ID        :=CANORD_rec.OM_ORDER_ID;
    V_OM_PRODUCT_ID      :=CANORD_rec.OM_PRODUCT_ID;
    V_PRODUCT_VERSION    :=CANORD_rec.PRODUCT_VERSION;
    V_PRODUCT_TYPE       :=CANORD_rec.PRODUCT_TYPE;
    V_BILLING_PRODUCT_ID :=CANORD_rec.BILLING_PRODUCT_ID;
    V_ORDER_TYPE         :=CANORD_rec.ORDER_TYPE;
    

   Select order_type 
   into V_ORDER_TYPE
   from &owner.oms_order
   where om_order_id = V_OM_ORDER_ID
   AND OM_PRODUCT_ID = V_OM_PRODUCT_ID 
   and om_order_status not IN ('CP','CA')
   and order_version_status = 'CU';

   
  n_routed_count:=0;
       SELECT COUNT(1) 
         INTO n_routed_count
         FROM &OWNER.OMS_ORDER
        WHERE OM_ORDER_ID = V_OM_ORDER_ID
          AND OM_PRODUCT_ID = V_OM_PRODUCT_ID
          AND ORDER_TYPE = 'NI'
          AND ROUTED_INDICATOR = 'Y';
          
   n_deposit_count:=0;
   Select  COUNT(1)
      INTO n_deposit_count
      FROM &OWNER.OMS_DEPOSIT_SERVICES 
      WHERE Ban = V_BAN
      AND Om_Order_Id = V_OM_ORDER_ID	
      AND deposit_amt > 0;
        
       ------------------------------------------------------
       -- Check routed indicator, we don't want to cancel 
       		-- orders that were already routed                 
       --Check for Deposit, we dont want to cancel
       		-- order with a deposit > 0.00 amount
       ------------------------------------------------------        
       
       if V_ORDER_TYPE = 'NI' then 
       dbms_output.put_line('Order ' || V_OM_ORDER_ID || ' New Install Order Cannot cancel it.');
            n_new_install_count := n_new_install_count + 1;
            
            dbms_output.put_line('New Install:' || n_new_install_count);
            
            RETURN;
            
          END IF;
              
                       
       if n_routed_count = 0 then
                        
            if n_deposit_count > 0 then
            dbms_output.put_line('Order ' || V_OM_ORDER_ID || ' Active Deposit, we cannot cancel it.');
            n_total_rec_deposit := n_total_rec_deposit + 1;
            
            dbms_output.put_line('Active Deposit:' || n_total_rec_deposit);
            
            RETURN;
         
         else    
                    
            UPDATE &OWNER.OMS_ORDER OMO
            SET    OMO.ORDER_VERSION_STATUS = 'CA',
                   OMO.OM_ORDER_STATUS      = 'CA',
                   OMO.ORDER_CANCEL_DATE    = SYSDATE,
                   OMO.ORDER_CANCEL_REASON  = 'ERROR',
                   OMO.APPLICATION_ID       = v_marker,
                   OMO.SYS_UPDATE_DATE      = SYSDATE,
                   OMO.hold_ind             = 'N'      
            WHERE  OMO.OM_ORDER_ID          = V_OM_ORDER_ID AND
                   OMO.OM_PRODUCT_ID        = V_OM_PRODUCT_ID AND
                   OMO.PRODUCT_VERSION      = V_PRODUCT_VERSION AND
                   OMO.ORDER_VERSION_STATUS = 'CU';
     
            --DBMS_OUTPUT.PUT_LINE('OMS_ORDER update: ' || SQL%ROWCOUNT);
     
            UPDATE &OWNER.OMS_PRODUCT_VERSION OPV
            SET    OPV.PRODUCT_VER_STATUS = 'CA',
                   OPV.APPLICATION_ID     = v_marker,
                   OPV.SYS_UPDATE_DATE    = SYSDATE
            WHERE  OPV.OM_PRODUCT_ID      = V_OM_PRODUCT_ID AND
                   OPV.PRODUCT_VERSION    = V_PRODUCT_VERSION;
     
            --DBMS_OUTPUT.PUT_LINE('OMS_PRODUCT_VERSION update: ' || SQL%ROWCOUNT);
     
            UPDATE &OWNER.OMS_TASK OMT
            SET    OMT.OM_TASK_STATUS  = 'CA',
                   OMT.APPLICATION_ID  = v_marker,
                   OMT.SYS_UPDATE_DATE = SYSDATE
            WHERE  OMT.OM_PRODUCT_ID   = V_OM_PRODUCT_ID AND
                   OMT.OM_ORDER_ID      = V_OM_ORDER_ID AND
                   OMT.OM_TASK_STATUS NOT IN ('CA', 'CP');
     
            --DBMS_OUTPUT.PUT_LINE('OMS_TASK update: ' || SQL%ROWCOUNT);

            -----------------------------------------------------------------------
            -- if the order was cancelled and the product is reserved (NI order)
            -- and the routed indicator is N, we can remove the 'P' status
            -- entry from PRODUCT table.
            -----------------------------------------------------------------------
--            dbms_output.put_line('Order ' || V_OM_ORDER_ID || ' Order type ' || V_ORDER_TYPE || ' ban ' || V_BAN || '  product ' || V_BILLING_PRODUCT_ID );
                  
                  if (V_ORDER_TYPE = 'DC') then
             
                --DBMS_OUTPUT.PUT_LINE('OMS_TASK update 4: ' || SQL%ROWCOUNT);
             
             dbms_output.put_line('DC Order ' || V_OM_ORDER_ID || '  ' || V_BAN || ' ' || V_BILLING_PRODUCT_ID || '  ' || V_PRODUCT_TYPE || ' done ' );
                      
                      UPDATE &OWNER.PRODUCT
                      SET PROD_STATUS='A',
                          APPLICATION_ID='MLTIRS'
                      WHERE CUSTOMER_ID=V_BAN 
                        AND PRODUCT_ID=V_BILLING_PRODUCT_ID 
                        AND PRODUCT_TYPE = V_PRODUCT_TYPE
                        AND PROD_STATUS='C';   
                        
            END IF;
            
                              
            if (V_ORDER_TYPE = 'NI' and V_BILLING_PRODUCT_ID IS NOT NULL) then
             
                 DELETE &OWNER.PRODUCT
                  WHERE CUSTOMER_ID = V_BAN
                    AND PRODUCT_ID  = V_BILLING_PRODUCT_ID
                    AND PROD_STATUS='P'
                    AND PRODUCT_TYPE = V_PRODUCT_TYPE;
                    
                 DELETE &OWNER.PRODUCT_HISTORY
                  WHERE CUSTOMER_ID = V_BAN
                    AND PRODUCT_ID  = V_BILLING_PRODUCT_ID
                    AND PRODUCT_TYPE = V_PRODUCT_TYPE;

 								 DELETE &OWNER.SERVICE_FEATURE
                 WHERE BAN = V_BAN
                    AND PRODUCT_ID   = '0000000000'
                    AND PRODUCT_TYPE = 'D'
                    AND SA_UNIQUE_ID IN (SELECT SA_UNIQUE_ID FROM &OWNER.SERVICE_AGREEMENT 
                                         WHERE BAN = V_BAN AND M_PRODUCT_ID = V_BILLING_PRODUCT_ID AND PRODUCT_ID = '0000000000'
                                         AND PRODUCT_TYPE = 'D' AND PP_LEVEL_CODE='B');
                                  
                  DELETE &OWNER.SERVICE_FEATURE
                 WHERE BAN = V_BAN
                    AND PRODUCT_ID  = V_BILLING_PRODUCT_ID
                    AND PRODUCT_TYPE = V_PRODUCT_TYPE;   
                    
                 DELETE &OWNER.SERVICE_AGREEMENT
                 WHERE BAN = V_BAN
                    AND M_PRODUCT_ID = V_BILLING_PRODUCT_ID
                    AND PRODUCT_ID   = '0000000000'
                    AND PRODUCT_TYPE = 'D'
                    AND PP_LEVEL_CODE='B'
                   /* AND PRICE_PLAN IN (SELECT PRICE_PLAN FROM &OWNER.OMS_SRV_AGREEMENT 
                                       WHERE BAN=V_BAN AND PRODUCT_ID=V_BILLING_PRODUCT_ID AND PRODUCT_TYPE = V_PRODUCT_TYPE
                                       AND PP_LEVEL_CODE='B') */
                                       ;

                 DELETE &OWNER.SERVICE_AGREEMENT
                 WHERE BAN = V_BAN
                    AND PRODUCT_ID  = V_BILLING_PRODUCT_ID
                    AND PRODUCT_TYPE = V_PRODUCT_TYPE;

                 DELETE &OWNER.ADDRESS_NAME_LINK
                 WHERE  BAN = V_BAN
                    AND PRODUCT_ID  = V_BILLING_PRODUCT_ID
                    AND PRODUCT_TYPE = V_PRODUCT_TYPE;     
                 
                 DELETE &OWNER.ACCESS_LINE_COUNT
                 WHERE  BAN = V_BAN
                    AND PRODUCT_ID  = V_BILLING_PRODUCT_ID
                    AND PRODUCT_TYPE = V_PRODUCT_TYPE;     
                 
                 
                 
                 dbms_output.put_line('Order ' || V_OM_ORDER_ID || ' ban ' || V_BAN || '  product ' || V_BILLING_PRODUCT_ID || ' in pending status. Cancelling product.');
            
            end if;
     
            -----------------------------------------------------------------------
            -- update last previous order's product_ver_status from 'HI' to 'CU'
            -----------------------------------------------------------------------
     
            UPDATE &owner.oms_product_version opv
            SET    opv.product_ver_status = 'CU',
                   application_id = v_marker,
                   sys_update_date = SYSDATE
            WHERE om_product_id = V_OM_PRODUCT_ID AND
                  product_version IN (SELECT product_version
                             FROM &owner.oms_order
                             WHERE om_product_id = V_OM_PRODUCT_ID
                             AND om_order_status in ('CP')
                             AND order_version_status IN ('CU')
                             AND BAN = v_ban
                             AND om_product_id = V_OM_PRODUCT_ID
                             AND (om_order_id,order_version) IN (SELECT MAX(om_order_id),MAX(order_version)
                                                                 FROM  (SELECT om_order_id
                                                                        FROM &owner.oms_order ord
                                                                        WHERE (om_order_id, order_version) IN (SELECT max(om_order_id), MAX(order_version)
                                                                                                                 FROM &owner.oms_order b
                                                                                                                 WHERE ord.om_order_id = b.om_order_id
                                                                                                                 GROUP BY om_order_id)
                                                                         AND om_order_status in ('CP')
                                                                         AND order_version_status IN ('CU')
                                                                         AND BAN = v_ban
                                                                         AND om_product_id = V_OM_PRODUCT_ID)));
     
            --DBMS_OUTPUT.PUT_LINE('OMS_OPV update: ' || SQL%ROWCOUNT);
            
            ---------------------------------------------------
            -- Clear MCP and MPV indicators for om_product_id
            ---------------------------------------------------
            update &owner.OMS_PRODUCT_VERSION
              set mpv_ind = null, mcp_ind = null
            where OM_PRODUCT_ID = ( SELECT unique OM_PRODUCT_ID FROM &owner.OMS_ORDER WHERE OM_ORDER_ID = V_OM_ORDER_ID AND OM_PRODUCT_ID = V_OM_PRODUCT_ID);
            
            update &owner.OMS_ORDER
              set mpv_ind = null, mcp_ind = null
            where OM_PRODUCT_ID = ( SELECT unique OM_PRODUCT_ID FROM &owner.OMS_ORDER WHERE OM_ORDER_ID = V_OM_ORDER_ID  AND OM_PRODUCT_ID = V_OM_PRODUCT_ID );
            
            ---------------------------------------------------
            -- Update OMS_PRODUCT_VERSION, set MPV_IND
            ---------------------------------------------------
            
            update &owner.OMS_PRODUCT_VERSION 
            set mpv_ind = 'Y', 
                application_id=v_marker 
            where product_version in ( select max(product_version) from &owner.OMS_ORDER 
                                       where OM_PRODUCT_ID in ( SELECT unique OM_PRODUCT_ID 
                                                                FROM &owner.OMS_ORDER WHERE OM_ORDER_ID = V_OM_ORDER_ID AND 
                                                                OM_PRODUCT_ID = V_OM_PRODUCT_ID ) 
            and om_order_id in (select max(om_order_id) 
                                from &owner.oms_order 
                                where om_product_id = V_OM_PRODUCT_ID
                                     and order_version_status = 'CU') 
            and order_version_status in ('CU') and om_order_status <> 'CA') ; 
            
            ---------------------------------------------------
            -- Update OMS_PRODUCT_VERSION, set MCP_IND
            ---------------------------------------------------
            update &owner.OMS_PRODUCT_VERSION
            set mcp_ind = 'Y',application_id=v_marker
            where product_version in ( select max(product_version) from &owner.OMS_ORDER
                                      where OM_PRODUCT_ID in ( SELECT unique OM_PRODUCT_ID FROM &owner.OMS_ORDER
                                                                WHERE OM_ORDER_ID = V_OM_ORDER_ID
                                                                  AND OM_PRODUCT_ID = V_OM_PRODUCT_ID )
                                      and om_order_id in (select max(om_order_id)
                                                        from &owner.oms_order
                                                        where om_product_id = V_OM_PRODUCT_ID
                                                        and order_version_status = 'CU'
                                                        and om_order_status = 'CP'));
            
             
            ---------------------------------------------------
            -- Update OMS_ORDER, set MCP_IND
            ---------------------------------------------------
            update &owner.OMS_ORDER
            set mcp_ind = 'Y',application_id=v_marker
            where product_version in ( select max(product_version) from &owner.OMS_ORDER
                                      where OM_PRODUCT_ID in ( SELECT unique OM_PRODUCT_ID FROM &owner.OMS_ORDER
                                                                WHERE OM_ORDER_ID = V_OM_ORDER_ID
                                                                  AND OM_PRODUCT_ID = V_OM_PRODUCT_ID )
                                      and om_order_id in (select max(om_order_id)
                                                        from &owner.oms_order
                                                        where om_product_id = V_OM_PRODUCT_ID
                                                        and order_version_status = 'CU'
                                                        and om_order_status = 'CP'));
            ---------------------------------------------------
            -- Update OMS_ORDER, set MPV_IND
            ---------------------------------------------------
            update &owner.OMS_ORDER
            set mpv_ind = 'Y',application_id=v_marker
            where product_version in ( select max(product_version) from &owner.OMS_ORDER
		                      where OM_PRODUCT_ID in ( SELECT unique OM_PRODUCT_ID FROM &owner.OMS_ORDER
							       WHERE OM_ORDER_ID = V_OM_ORDER_ID AND OM_PRODUCT_ID = V_OM_PRODUCT_ID )
				       and om_order_id in (select max(om_order_id) from &owner.oms_order
				       where om_product_id = V_OM_PRODUCT_ID and order_version_status = 'CU') 
	                 	       and order_version_status in ('CU') and om_order_status <> 'CA');
	                 	       
            
            n_total_to_cancel := n_total_to_cancel + 1;
           end if;
    else -- if routed ind = 0
    
            ------------------------------------
            -- If the routed indicator is Y, 
            -- we dont want to cancel the order
            ------------------------------------
            dbms_output.put_line('Order ' || V_OM_ORDER_ID || ' was already routed, we cannot cancel it.');
            n_total_rec_handled_routed := n_total_rec_handled_routed + 1;
            
                end if;
     
    n_total_rec_handled1:=n_total_rec_handled1+1;

    END LOOP;

    EXCEPTION
     WHEN NO_DATA_FOUND THEN                               
         dbms_output.put_line('Order ' || V_OM_ORDER_ID || ' could not be updated.');

   dbms_output.put_line('Summary');
   dbms_output.put_line('Total records to cancel:' || n_total_rec_handled1);
   dbms_output.put_line('Total records cancelled:' || n_total_to_cancel);
   dbms_output.put_line('Already Routed:' || n_total_rec_handled_routed);
  
    
END CANCEL_ORDER;

    



------------------------------------------------------------------------------------------------------

--B E G I N   P R O C E S S I N G   A L L   P R O C E D U R E S   F O R   D C   O R D E R S 

------------------------------------------------------------------------------------------------------





	BEGIN

		

   
   ERROR_in_Bundle(311131526,1235565372,903321154);
   ERROR_in_Bundle(435938844,1236478242,914664697);
   ERROR_in_Bundle(439440670,1235562782,915916903);
   ERROR_in_Bundle(439477775,1235903357,915929704);
   ERROR_in_Bundle(439489199,1235985052,915933724);
   ERROR_in_Bundle(439599385,1237328117,915970848);
   ERROR_in_Bundle(439599385,1238531597,915970847);
   GnDts_AddMonths(301391622,1239006262,266000452);
   GnDts_AddMonths(427462513,1239242772,911618025);
   GnDts_AddMonths(439531909,1237714427,915949139);
   IPV_with_no_pend_ord_prod_act(307716490,1231652312,897798238);
   IPV_with_no_pend_ord_prod_act(426735420,1235534402,911372351);
   IPV_with_no_pend_ord_prod_act(436870334,1236478382,914980953);
   Key_not_found_for_Discount(301334276,1238982352,910435756);
   NS_Locked_by_Global_Update(300036309,1230898672,916001194);
   NS_Locked_by_Global_Update(300058716,1233280382,915972672);
   NS_Locked_by_Global_Update(300499768,1227952552,915636301);
   NS_Locked_by_Global_Update(300543252,1235270912,911565927);
   NS_Locked_by_Global_Update(300543252,1239293982,911565927);
   NS_Locked_by_Global_Update(300614022,1238791647,244112654);
   NS_Locked_by_Global_Update(300995355,1228634532,912355438);
   NS_Locked_by_Global_Update(301740012,1238964387,898554112);
   NS_Locked_by_Global_Update(301965329,1238521587,351006130);
   NS_Locked_by_Global_Update(302428433,1231729467,913571597);
   NS_Locked_by_Global_Update(302485082,1233266682,888022265);
   NS_Locked_by_Global_Update(302485082,1234756857,888022265);
   NS_Locked_by_Global_Update(302485082,1238725997,888022265);
   NS_Locked_by_Global_Update(306024572,1239537757,908601110);
   NS_Locked_by_Global_Update(307351366,1234074802,896987901);
   NS_Locked_by_Global_Update(309664271,1239456987,915443852);
   NS_Locked_by_Global_Update(311234916,1238531607,914620657);
   NS_Locked_by_Global_Update(311518040,1238707367,904047439);
   NS_Locked_by_Global_Update(311726328,1230344437,902585876);
   NS_Locked_by_Global_Update(313154805,1230014327,915999341);
   NS_Locked_by_Global_Update(414785414,1232002872,915559330);
   NS_Locked_by_Global_Update(415444572,1233650982,901378741);
   NS_Locked_by_Global_Update(416937923,1235001127,912470490);
   NS_Locked_by_Global_Update(429738269,1236260512,916002861);
   NS_Locked_by_Global_Update(434517923,1232249697,915390689);
   NS_Locked_by_Global_Update(438719685,1232043832,915658482);
   NS_Locked_by_Global_Update(438999774,1231903422,915766639);
   NS_Locked_by_Global_Update(439102933,1222041857,915798769);
   NS_Locked_by_Global_Update(439119352,1233499222,915878654);
   NS_Locked_by_Global_Update(439187810,1234378892,915828427);
   NS_Locked_by_Global_Update(439206358,1234393607,915842404);
   NS_Locked_by_Global_Update(439211797,1228773262,915836385);
   NS_Locked_by_Global_Update(439808345,1232024437,916042136);
   OMS_BUNDLE_ORD_DEPEND_PK(438149152,1239299582,915661829);
   aramAdjEnv(438235464,1235090077,915497489);
   blbn_olnrc(300829433,1238926412,248064609);
   blbn_olnrc(301007745,1239270627,350653624);
   blbn_olnrc(301386988,1238895862,266046750);
   blbn_olnrc(301994468,1238895212,910579738);
   blbn_olnrc(311827622,1238661842,904050906);
   blbn_olnrc(313190172,1239040372,906727920);
   blbn_olnrc(313561627,1238557247,906003661);
   blbn_olnrc(439358602,1239045597,915887720);
   blbn_olnrc(439494163,1239259672,915935104);
   fix_msag_address(302298784,1221170917,890041210);
   fix_msag_address(307330358,1222490717,896163070);
   fix_msag_address(307330358,1222492317,896162934);
   fix_msag_address(307330358,1222494037,896162979);
   fix_msag_address(307330358,1222495572,896163049);
   fix_msag_address(307611223,1237398732,897937529);
   fix_msag_address(308135412,1239438782,897396405);
   fix_msag_address(308321350,1233469837,896681320);
   fix_msag_address(309323434,1232876432,900400298);
   fix_msag_address(309373350,1231663047,899818623);
   fix_msag_address(309756091,1232865267,900872151);
   fix_msag_address(309756091,1232878787,900872160);
   fix_msag_address(309829323,1231590092,900465314);
   fix_msag_address(309971845,1220451247,899591419);
   fix_msag_address(309971845,1220516667,899591402);
   fix_msag_address(309971845,1231594457,899591216);
   fix_msag_address(309971845,1231595332,899590404);
   fix_msag_address(309971845,1231596652,899590879);
   fix_msag_address(310292753,1229783547,900854767);
   fix_msag_address(311063501,1232855117,903940622);
   fix_msag_address(311083882,1226993197,903579870);
   fix_msag_address(311740712,1237919652,903697382);
   fix_msag_address(311784934,1234525647,904148442);
   fix_msag_address(311962164,1214582797,904421363);
   fix_msag_address(311962164,1214642572,904420189);
   fix_msag_address(311964959,1239402962,904417535);
   fix_msag_address(311964959,1239402967,904417538);
   fix_msag_address(311964959,1239402972,904417542);
   fix_msag_address(311964959,1239402977,904417548);
   fix_msag_address(311964959,1239402987,904417553);
   fix_msag_address(312183773,1232657262,903267369);
   insert_into_history(311920319,1238652147,915993059);
   pgn_gt_name_address_buf(431435882,1239316662,915516987);
   pgn_gt_name_address_buf(431435882,1239316667,915964276);
   pp_not_found_research(300382314,1239334322,239014954);
   pp_not_found_research(301323187,1238335117,913593606);
   pp_not_found_research(404447743,1238582002,350615485);
   pp_not_found_research(425740834,1238704897,911160762);
   unknown(300484831,1237375117,242039095);
   unknown(301454477,1239239602,916031784);
   unknown(308044772,1237836857,911919478);
   unknown(313110670,1239245212,916032039);
   unknown(415744553,1231613397,901493821);
   unknown(424183188,1239221092,910402053);
   unknown(436603217,1239501812,915290252);
   unknown(438469751,1237016712,915567013);
   unknown(438721770,1236227127,915659182);
   unknown(439002976,1238678072,915762563);
   unknown(439032483,1237639432,915772303);
   unknown(439224361,1235505992,915840159);
   unknown(439315781,1237615177,915872266);
   unknown(439416409,1237732692,915908571);
   unknown(439495028,1237659102,915935361);
   unknown(439542275,1237832887,915952388);
   unknown(439560584,1238998812,915957940);
   unknown(439687655,1238459892,916001241);
   unknown(439753623,1239009142,916022022);
   year_must_be_between(306003976,1239419552,764044092);
---------------------------------------------------------------
--blbn_olnrc(439277795,1239212997,915859430);--Anurag
---------------------------------------------------------------

dsfsdojfsdjflsdjkfsd

---------------------------END---------------------------------

---------------------------------------------------------------
--Ban_Level_PP_does_not_exists(437017913,1228042707,915036731);--Anurag
---------------------------------------------------------------

sdfsdfsdfsd

---------------------------END---------------------------------

---------------------------------------------------------------
--Ban_Level_PP_does_not_exists(437017913,1228042707,915036731);--Prateek
---------------------------------------------------------------

as

---------------------------END---------------------------------


END;
/