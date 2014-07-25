--**********************************************************************
-- Script Name:          CSM_CUP1_DC_ORDERS_IR99999.sql
-- Author/Written by:    Kunal joshi
-- Description           update CSM And OMS Tables
-- Date:                 07/24/2014
-- Email Address:        Kunal.joshi@centurylink.com
-- Success criteria:     Tables updated successfully
--***********************************************************************      
        

SELECT ban,
        product_id,
        price_plan,
        pp_seq_no,
        order_no,
        feature_code,
        ftr_effective_date,
        ftr_eff_issue_date,
        ftr_expiration_date,
        pp_effective_date,
        ftr_exp_issue_date,
        sys_update_date,
        application_id
   FROM &owner.oms_service_feature
   WHERE     ban = &v_ban
  --      AND product_id = &v_product_id
        AND (price_plan, pp_seq_no) IN (&v_price_plan_pp_seq_no_list)
        AND ftr_expiration_date IS NULL;

 UPDATE &owner.oms_service_feature
    SET ftr_effective_date = TO_DATE (&v_back_date, 'DD-MON-YYYY'),
        ftr_eff_issue_date = TO_DATE (&v_back_date, 'DD-MON-YYYY'),
    --  pp_effective_date = TO_DATE (&v_back_date, 'DD-MON-YYYY'),
        sys_update_date = SYSDATE,
        application_id = &v_appl_id
    WHERE     ban = &v_ban
  --       AND product_id = &v_product_id
         AND (price_plan, pp_seq_no) IN (&v_price_plan_pp_seq_no_list)
         AND ftr_expiration_date is NULL
         AND omsa_group_id IN
               (SELECT DISTINCT p.omsa_group_id
                  FROM &owner.oms_product_version p, &owner.oms_order o
                 WHERE     p.billing_product_id IN (&v_product_id)
                       AND p.ban_id = &v_ban
                       AND p.product_version = o.product_version
                       AND o.om_order_id IN (&v_om_order_id_list)
                       AND o.order_version_status = 'CU');