CREATE OR REPLACE PROCEDURE P_INC2014_RT_SALES1(I_MONTH IN VARCHAR2) IS
  /*****************************************
  --功能：retail incentive 基数
  --时间：2013-02-20
  --作者：谭超
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);
  V_MARKDAY    VARCHAR2(20);
  V_BAKVERSION VARCHAR2(10);
  V_MONTH_LY   VARCHAR2(20);
  V_MARKDAY_LY VARCHAR2(20);
  V_ROWNUM     NUMBER;
  --V_Q          VARCHAR2(20);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID
  V_PROC_NAME  := 'P_INC2015_RT_SALES1'; --过程名
  V_PARM_VALUS := I_MONTH; --过程输入参数
  --插入日志
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --过程内容
  -----------------------------------------------------------------------

  DELETE FROM INCENTIVE_RT_SALES1_DC T WHERE T.IMONTH = I_MONTH;
  DELETE FROM INCENTIVE_RT_SALES1_CSHQ T WHERE T.IMONTH = I_MONTH;
  DELETE FROM INC_RT_OOD_CSHQ_HIER03_CSHQ T WHERE T.IMONTH = I_MONTH;

  V_MARKDAY    := I_MONTH || '-01';
  V_MONTH_LY   := TO_CHAR(TO_NUMBER(SUBSTR(I_MONTH, 1, 4)) - 1) || '-' ||
                  SUBSTR(I_MONTH, 6, 2);
  V_MARKDAY_LY := V_MONTH_LY || '-01';
  --V_Q          := SUBSTR(I_MONTH,1,4)||'Q'||TO_CHAR(TO_DATE(I_MONTH,'YYYY-MM'),'Q');
  
  --产品版本
  SELECT T.BAKVERSION
    INTO V_BAKVERSION
    FROM INCENTIVE_VERSION_PRODUCT T
   WHERE I_MONTH >= T.STARTDATE
     AND I_MONTH <= T.ENDDATE;

  --未添加邦迪 ，有数据后核对一下，D_SALE_SALES，D_SALE_BANDAIDSALES是否有重复，
  --D_SALE_SALESTARGET，d_sale_newprodtarget 产品是否有重复，注意新品
  --  OTC 01  吗丁啉 040018  吗丁啉混悬液100ml
  --  OTC 04  达克宁 040001  达克宁散剂20g;04 达克宁 040226  Daktarin Powder 1X40g OTC
  --  OTC 04  达克宁 040230  达克宁喷雾剂1*15ml/瓶  OTC;--04  达克宁 040231  达克宁喷雾剂1*30ml/瓶  OTC
  --  OTC 35  XSM 040202  息斯敏口腔崩解片10mg 1x10片
  ---销售数据

  /*--慢见临时表
   EXECUTE IMMEDIATE 'TRUNCATE TABLE INCENTIVE_SALE_TARGET_TP01';
   EXECUTE IMMEDIATE 'TRUNCATE TABLE INCENTIVE_SALE_SALES_TP01';

  INSERT INTO INCENTIVE_SALE_TARGET_TP01
    SELECT * FROM V_INC_D_SALE_TARGET t
        where t.MARKDAY=V_MARKDAY;

  INSERT INTO INCENTIVE_SALE_SALES_TP01
    SELECT * FROM V_INCENTIVE_D_SALE_SALES T
       WHERE T.MARKDAY = V_MARKDAY;

  INSERT INTO INCENTIVE_SALE_SALES_TP01
    SELECT * FROM V_INCENTIVE_D_SALE_SALES T
       WHERE T.MARKDAY = V_MARKDAY_LY;*/

  --CRS 架构数据
  DELETE FROM INCENTIVE_RT_SALES1_CRS T WHERE T.IMONTH = I_MONTH;

  ----效率慢，拆多个SQL
  EXECUTE IMMEDIATE 'TRUNCATE TABLE INCENTIVE_RT_SALES1_CRS_TP01';

  INSERT INTO INCENTIVE_RT_SALES1_CRS_TP01
     SELECT /*+ordered use_hash (t,t2)  */IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4,
             SUM(T2.RMB) SALES, 0 TARGET, 0 SALES_LY
       FROM ODS_RT_ORG_CRS_HIER         T,
            V_INC_RT_D_SALE_SALES T2,
            INCENTIVE_BU_PRODUCT  T3
      WHERE T.IMONTH = I_MONTH
        AND T2.MARKDAY = V_MARKDAY
        AND T.HID = T2.DRUGSTOREID
        AND T2.PRODUCTID =T3.PRODUCTCODE
        AND T3.BAKVERSION = V_BAKVERSION
        AND T3.BU = 'OTC'
        AND T.STATUS NOT IN ('C')
    GROUP BY IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4;

  INSERT INTO INCENTIVE_RT_SALES1_CRS_TP01
     SELECT /*+ordered use_hash (t,t2)  */IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4,
             0, SUM(T2.RMB), 0
              FROM ODS_RT_ORG_CRS_HIER          T,
                   V_INC_RT_D_SALE_TARGET       T2,
                   INCENTIVE_BU_PRODUCT   T3
             WHERE T.IMONTH = I_MONTH
               AND T2.MARKDAY = V_MARKDAY
               AND T.HID = T2.DRUGSTOREID
               AND T2.PRODUCTID =T3.PRODUCTCODE
               AND T3.BAKVERSION = V_BAKVERSION
               AND T3.BU = 'OTC'
               AND T.STATUS NOT IN ('C')
    GROUP BY IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4;
  --从2015年8月开始OTC RSM奖金计算将不再考核外包5个品牌的30%商业达成 2015/8/27 (周四) 23:31  王崇修改
  INSERT INTO INCENTIVE_RT_SALES1_CRS_TP01
     SELECT /*+ordered use_hash (t,t2)  */IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4,
             0, 0, SUM(T2.RMB) SALES_LY
       FROM ODS_RT_ORG_CRS_HIER     T,
            V_INC_RT_D_SALE_SALES    T2,
            INCENTIVE_BU_PRODUCT  T3
      WHERE T.IMONTH = I_MONTH
        AND T2.MARKDAY = V_MARKDAY_LY
        AND T.HID = T2.DRUGSTOREID
        AND T2.PRODUCTID =T3.PRODUCTCODE
        AND T3.BAKVERSION = V_BAKVERSION
        AND T3.BU = 'OTC'
        AND T.STATUS NOT IN ('C')
        AND (I_MONTH < '2015-08' OR
                   (I_MONTH >= '2015-08' AND
                   t3.brandcode NOT IN ('05', '07', '13', '15', '19')))
   GROUP BY IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4;

  INSERT INTO INCENTIVE_RT_SALES1_CRS
    SELECT IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4,
           SUM(SALES),
           SUM(TARGET),
           SUM(SALES_LY)
      FROM INCENTIVE_RT_SALES1_CRS_TP01 A1
     GROUP BY IMONTH,H1,N1,W1,E1,H2,N2,W2,E2,H3,N3,W3,E3,H4,N4,W4,E4;

  --DC 销售
  --效率慢，拆多个SQL
  EXECUTE IMMEDIATE 'TRUNCATE TABLE INCENTIVE_RT_SALES1_DC_TP01';

  INSERT INTO INCENTIVE_RT_SALES1_DC_TP01
    SELECT /*+ordered use_hash (t1,t)  */T1.IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7,
           SUM(T.RMB) SALES,
           0     TARGET,
           0     SALES_NEW,
           0     TARGET_NEW,
           0     SALES_LY
      FROM V_INC_RT_D_SALE_SALES T,
           ODS_RT_OOD_HIER03           T1,
           INCENTIVE_BU_PRODUCT  T3
     WHERE T.DRUGSTOREID = T1.HID
       AND T.PRODUCTID = T3.PRODUCTCODE
       AND T.MARKDAY = V_MARKDAY
       AND T1.IMONTH = I_MONTH
       AND T3.BU = 'OTC'
       AND T1.STATUS NOT IN ('C')
       AND T3.BAKVERSION = V_BAKVERSION
     GROUP BY T1.IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7;

  INSERT INTO INCENTIVE_RT_SALES1_DC_TP01
    SELECT /*+ordered use_hash (t1,t)  */T1.IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7,
           0, SUM(T.RMB) TARGET, 0, 0, 0
      FROM V_INC_RT_D_SALE_TARGET  T,
           ODS_RT_OOD_HIER03        T1,
           INCENTIVE_BU_PRODUCT   T3
     WHERE T.DRUGSTOREID = T1.HID
       AND T.PRODUCTID = T3.PRODUCTCODE
       AND T.MARKDAY = V_MARKDAY
       AND T1.IMONTH = I_MONTH
       AND T3.BU = 'OTC'
       AND T1.STATUS NOT IN ('C')
       AND T3.BAKVERSION = V_BAKVERSION
    GROUP BY T1.IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7;

  INSERT INTO INCENTIVE_RT_SALES1_DC_TP01
    SELECT /*+ordered use_hash (t1,t)  */T1.IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7,
            0, 0, 0, 0, SUM(T.RMB)
      FROM V_INC_RT_D_SALE_SALES T,
           ODS_RT_OOD_HIER03           T1,
           INCENTIVE_BU_PRODUCT  T3
     WHERE T.DRUGSTOREID = T1.HID
       AND T.PRODUCTID = T3.PRODUCTCODE
       AND T.MARKDAY = V_MARKDAY_LY
       AND T1.IMONTH = I_MONTH
       AND T3.BU = 'OTC'
       AND T1.STATUS NOT IN ('C')
       AND T3.BAKVERSION = V_BAKVERSION
    GROUP BY T1.IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7;

  DELETE FROM INCENTIVE_RT_SALES1_DC T WHERE T.IMONTH = I_MONTH;

  INSERT INTO INCENTIVE_RT_SALES1_DC
    SELECT IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7,
           SUM(SALES),
           SUM(TARGET),
           SUM(SALES_NEW),
           SUM(TARGET_NEW),
           SUM(SALES_LY)
      FROM INCENTIVE_RT_SALES1_DC_TP01
     GROUP BY IMONTH,H1,W1,N1,H2,W2,N2,H3,W3,N3,H4,W4,N4,H5,W5,N5,H6,W6,N6,TEAM,HIER7,H7,REPLACE(W7, ','),N7;
  COMMIT;

  IF I_MONTH >= '2014-01' THEN
    DELETE FROM INC_RT_OOD_CSHQ_HIER02 T WHERE T.IMONTH = I_MONTH;
    INSERT INTO INC_RT_OOD_CSHQ_HIER02
      SELECT T.IMONTH,
             N1,
             W1,
             E1,
             N2,
             W2,
             E2,
             N3,
             W3,
             E3,
             N4,
             W4,
             E4,
             N5,
             W5,
             E5,
             N6,
             W6,
             E6,
             N7,
             W7,
             E7,
             H7,
             CSHQ_ID,
             CSHQ_NAME,
             T2.DRUGSTORE_ID4,
             T2.NODE_NAME4
        FROM ODS_RT_ORG_CSHQ_HIER T, ODS_RT_ORG_DSCHAIN_HIER T2
       WHERE T.IMONTH = I_MONTH
         AND T.IMONTH = T2.IMONTH
         AND T.CSHQ_ID = T2.DRUGSTORE_ID3;
  END IF;

  DELETE FROM INCENTIVE_RT_SALES1_CSHQ T WHERE T.IMONTH = I_MONTH;

  INSERT INTO INCENTIVE_RT_SALES1_CSHQ
    SELECT I_MONTH,
           H1,
           W1,
           N1,
           H2,
           W2,
           N2,
           H3,
           W3,
           N3,
           H4,
           W4,
           N4,
           H5,
           W5,
           N5,
           H6,
           W6,
           N6,
           '',
           HIER7,
           H7,
           REPLACE(W7, ','),
           N7,
           SUM(SALES),
           SUM(TARGET),
           SUM(SALES_NEW),
           SUM(TARGET_NEW),
           SUM(SALES_LY)
      FROM (SELECT /*+ordered use_hash (t,t1)  */T1.*,
                   T.RMB SALES,
                   0  TARGET,
                   0  SALES_NEW,
                   0  TARGET_NEW,
                   0  SALES_LY
              FROM V_INC_RT_D_SALE_SALES T,
                   INC_RT_OOD_CSHQ_HIER02    T1,
                   INCENTIVE_BU_PRODUCT  T3
             WHERE T.DRUGSTOREID = T1.DID
               AND T.PRODUCTID = T3.PRODUCTCODE
               AND T.MARKDAY = V_MARKDAY
               AND T1.IMONTH = I_MONTH
               AND T3.BU = 'OTC'
               AND T3.BAKVERSION = V_BAKVERSION
            UNION ALL
            SELECT /*+ordered use_hash (t,t1)  */T1.*, 0, T.RMB TARGET, 0, 0, 0
              FROM V_INC_RT_D_SALE_TARGET T,
                   INC_RT_OOD_CSHQ_HIER02    T1,
                   INCENTIVE_BU_PRODUCT   T3
             WHERE T.DRUGSTOREID = T1.DID
               AND T.PRODUCTID = T3.PRODUCTCODE
               AND T.MARKDAY = V_MARKDAY
               AND T1.IMONTH = I_MONTH
               AND T3.BU = 'OTC'
               AND T3.BAKVERSION = V_BAKVERSION
            UNION ALL --去年销售
            SELECT /*+ordered use_hash (t,t1)  */T1.*, 0, 0, 0, 0, T.RMB
              FROM V_INC_RT_D_SALE_SALES T,
                   INC_RT_OOD_CSHQ_HIER02   T1,
                   INCENTIVE_BU_PRODUCT   T3
             WHERE T.DRUGSTOREID = T1.DID
               AND T.PRODUCTID = T3.PRODUCTCODE
               AND T.MARKDAY = V_MARKDAY_LY
               AND T1.IMONTH = I_MONTH
               AND T3.BU = 'OTC'
               AND T3.BAKVERSION = V_BAKVERSION)
     GROUP BY H1,
              W1,
              N1,
              H2,
              W2,
              N2,
              H3,
              W3,
              N3,
              H4,
              W4,
              N4,
              H5,
              W5,
              N5,
              H6,
              W6,
              N6,
              HIER7,
              H7,
              REPLACE(W7, ','),
              N7;

  
  SELECT COUNT(1)
    INTO V_ROWNUM
    FROM INCENTIVE_HAND_OTC_CRS_H6HR T
   WHERE T.IMONTH = I_MONTH;

  IF V_ROWNUM =0 THEN
    /*INSERT INTO INCENTIVE_HAND_OTC_CRS_H6HR
      SELECT T.IMONTH, T.H6, T.H6, T3.POSITION,V_Q,T3.POSITION
        FROM (select distinct IMONTH, h6,w6,n6 from INCENTIVE_RT_SALES1_CSHQ) T,
             INCENTIVE_RT_HRDATA T2,
             (SELECT A1.*
                FROM INCENTIVE_HAND_OTC_CRS_H6HR A1
               WHERE A1.IMONTH = (SELECT MAX(IMONTH) FROM INCENTIVE_HAND_OTC_CRS_H6HR)) T3
       WHERE T.IMONTH = T2.IMONTH(+)
         AND T.W6 = T2.WWID(+)
         AND T.IMONTH = I_MONTH
         AND T2.IMONTH IS NULL
         AND T.H6 = T3.H6;*/

    INSERT INTO INCENTIVE_HAND_OTC_CRS_H6HR
      SELECT T.IMONTH, T.H6, T.H6, T2.POSITION,T2.Q,T2.POSITION
        FROM (select distinct IMONTH,h6,w6,n6 from INCENTIVE_RT_SALES1_CSHQ) T, INCENTIVE_RT_HRDATA T2
       WHERE T.IMONTH = T2.IMONTH
         AND T.W6 = T2.WWID
         AND T2.IMONTH = I_MONTH;
         
  END IF;
  
  
  
  -----------------------------------------------------------------------
  --过程结束
  COMMIT;
  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '成功', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, '失败', SQLERRM);

END P_INC2014_RT_SALES1;
/
