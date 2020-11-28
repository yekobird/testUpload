SELECT *
        from (WITH NEW_FUND_BS_RISKRANK AS (SELECT A.SECURITYCODE, A.RISKLEVEL
        FROM FUND_BS_RISKRANK A,
        (SELECT SECURITYCODE,
        MAX(REPORTDATE) REPORTDATE
        FROM FUND_BS_RISKRANK
        WHERE EISDEL = '0'
        GROUP BY SECURITYCODE) B
        WHERE A.SECURITYCODE = B.SECURITYCODE
        AND A.REPORTDATE = B.REPORTDATE
        AND EISDEL = '0'), NEW_FUND_BS_LIMITITER AS (SELECT A.SECURITYCODE,
        A.LIMITSUM
        FROM FUND_BS_LIMITITER A,
        (SELECT SECURITYCODE,
        MAX(STARTDATE) STARTDATE
        FROM FUND_BS_LIMITITER
        WHERE EISDEL = '0'
        AND ITEM =
        '110'
        GROUP BY SECURITYCODE) B
        WHERE A.SECURITYCODE =
        B.SECURITYCODE
        AND A.STARTDATE =
        B.STARTDATE
        AND A.EISDEL = '0'
        AND ITEM =
        '110'
        AND A.COMPANYCODE IS NULL),

        NEW_FUND AS (SELECT FBO.SECURITYCODE, FBO.ARSNAMEIN,FBO.Secinnercode
        FROM VIEW_IN_OUT_FUND_CENTRAL VIOFC, FUND_BS_OFINFO FBO
        WHERE VIOFC.SECINNERCODE = FBO.SECINNERCODE
        AND VIOFC.FUND_SORT_NAME = '货币型'
        AND VIOFC.IS_IN_SELL = 0
        and VIOFC.MARKETCODE in (1, 2, 4)
        AND FBO.ARSNAMEIN IS NOT NULL)

        SELECT SECURITYCODE FUND_CODE,
        ARSNAMEIN      FUND_NAME,
        FUNDSORT       FUND_SORT,
        FUNDSORTNAME   FUND_SORT_NAME,
        YIELD7DAY      RETURN_RATE,
        RSORT          R_SORT,
        RISKLEVEL      RISK_GRADE,
        LIMITSUM       INDI_MIN_BUY,
        STAR           STAR,
        FUNDSOURCE     FUND_SOURCE
        FROM (SELECT A.*,
        NULL AS FUNDSORT,
        NULL AS FUNDSORTNAME,
        TO_CHAR(ROUND(B.YIELD7DAY, 2), 'FM9999999990.00') YIELD7DAY,
        ROUND(B.YIELD7DAY, 2) RSORT,
        DECODE(C.RISKLEVEL,001,'云湾基金风险评价标准',001001,'低风险',001002,'较低风险',001003,'中风险',001004,'较高风险',001005,'高风险',
        002,'天天基金风险评价标准',002001,'高风险',002002,'中高风险',002003,'中风险',002004,'中低风险',002005,'低风险') AS RISKLEVEL,
        D.LIMITSUM,
        NULL AS STAR,
        2 as FUNDSOURCE
        FROM NEW_FUND A
        LEFT JOIN S102_FUND_NV_NV B
        ON A.SECURITYCODE = B.SECURITYCODE
        LEFT JOIN NEW_FUND_BS_RISKRANK C
        ON A.SECURITYCODE = C.SECURITYCODE
        LEFT JOIN NEW_FUND_BS_LIMITITER D
        ON A.SECURITYCODE = D.SECURITYCODE
        LEFT JOIN S102_XONE_FUND_INFO SX
        ON A.SECINNERCODE = SX.FUND_INTL 
        WHERE A.ARSNAMEIN IS NOT NULL
        AND SX.TRD_ID = '22' /*交易行为：基金申购*/
        ORDER BY RSORT DESC NULLS LAST)
        union all

        select *
        from (select a.fund_code, /*基金代码*/
        a.fund_name, /*基金名称*/
        rtrim(a.fund_sort) fund_sort, /*基金类型*/
        a.fund_sort_name, /*基金类型名称*/
        to_char(round(e.YIELD7DAY, 2), 'fm99999999999999999990.00') return_rate, /*最近七日收益所折算的年资产收益率*/
        round(e.YIELD7DAY, 2) r_sort,
        to_char(decode(a.risk_grade,0,'低风险',1,'中低风险',2,'中等风险',3,'中高风险',4,'高风险')) as risk_grade, /*基金风险等级*/
        a.indi_min_buy, /*个人最低购买限额*/
        f.star, /*基金星级*/
        a.fund_source  /*1:场外基金 2：场内基金*/
        from (

        select fc.fund_code,
        fc.fund_name,
        fc.fund_sort,
        fc.fund_sort_name,
        fc.fund_status,
        case
        when fc.indi_min_buy > 0 then
        fc.indi_min_buy
        else
        decode(fc.fund_status,
        1,
        fc.indi_first_min_sub,
        fc.indi_first_min_app)
        end indi_min_buy,
        fc.risk_grade,
        t.correscode correscode,
        nvl(t.securitycode, fc.fund_code) securitycode,
        1 as fund_source
        from s102_out_funds_central fc,
        (select cores.correscode correscode,
        max(cores.securitycode) securitycode
        from cdsy_corres cores
        where cores.correstype in
        ('06', '04', '13', '46')
        group by cores.correscode) t,
        s102_xone_fund_info sx
        where fc.fund_code = t.correscode(+)
        and fc.fund_intl = sx.fund_intl(+)
        and sx.trd_id = '22'   /*交易行为：基金申购*/
        and fc.fund_status not in ('3', 'a')
        and fc.fund_sort = '7'
        ) a
        left join fund_bs_ofinfo c
        on a.securitycode = c.securitycode
        left join s102_fund_nv_nv e
        on a.securitycode = e.securitycode
        left join (select a.secucode, a.fundability010_star star
        from s102_ja_fund_ability a
        where a.enddate =
        (select max(b.enddate)
        from s102_ja_fund_ability b
        where b.secucode = a.secucode)
        group by a.secucode, a.fundability010_star) f
        on a.fund_code = f.secucode
        where c.eisdel = '0'
        and c.enddate is null
        order by r_sort desc nulls last)
        where indi_min_buy <= 1000
        ) res
        order by res.r_sort desc nulls last
