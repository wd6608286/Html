CREATE OR REPLACE PROCEDURE P_INC2014_RT_W6_INDEX_SALES3(I_Q VARCHAR2) IS
  /*****************************************
  --功能：行转列
  --时间：2013-01-14
  --作者：谭超
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);
  V_MONTH1     VARCHAR2(20);
  V_MONTH2     VARCHAR2(20);
  V_MONTH3     VARCHAR2(20);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID
  V_PROC_NAME  := 'P_INC2014_RT_W6_INDEX_SALES3'; --过程名
  V_PARM_VALUS := I_Q; --过程输入参数
  --插入日志
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --过程内容
  -----------------------------------------------------------------------
  IF SUBSTR(I_Q, 5, 2) = 'Q1' THEN
    V_MONTH1 := SUBSTR(I_Q, 1, 4) || '-01';
    V_MONTH2 := SUBSTR(I_Q, 1, 4) || '-02';
    V_MONTH3 := SUBSTR(I_Q, 1, 4) || '-03';
  END IF;

  IF SUBSTR(I_Q, 5, 2) = 'Q2' THEN
    V_MONTH1 := SUBSTR(I_Q, 1, 4) || '-04';
    V_MONTH2 := SUBSTR(I_Q, 1, 4) || '-05';
    V_MONTH3 := SUBSTR(I_Q, 1, 4) || '-06';
  END IF;

  IF SUBSTR(I_Q, 5, 2) = 'Q3' THEN
    V_MONTH1 := SUBSTR(I_Q, 1, 4) || '-07';
    V_MONTH2 := SUBSTR(I_Q, 1, 4) || '-08';
    V_MONTH3 := SUBSTR(I_Q, 1, 4) || '-09';
  END IF;

  IF SUBSTR(I_Q, 5, 2) = 'Q4' THEN
    V_MONTH1 := SUBSTR(I_Q, 1, 4) || '-10';
    V_MONTH2 := SUBSTR(I_Q, 1, 4) || '-11';
    V_MONTH3 := SUBSTR(I_Q, 1, 4) || '-12';
  END IF;

  --清楚数据
  DELETE FROM INC2014_RT_INDEX_SALES2 T
   WHERE T.Q = I_Q
     AND T.POSITION LIKE '%W6';

  DELETE FROM INCENTIVE_RT_DC_HRDATA T
   WHERE T.WLEVEL = 6
     AND T.Q = I_Q;

  INSERT INTO INCENTIVE_RT_DC_HRDATA
    SELECT DISTINCT T.IMONTH,
                    I_Q,
                    T3.TMW6 WWID,
                    T3.TMW6 WWNAME,
                    NVL(T2.BU, 'OTC CRS'),
                    NVL(T2.POSITION, 'TM') || '-W6',
                    6 WLEVEL
      FROM INCENTIVE_RT_SALES1_DC T,
           (SELECT * FROM INCENTIVE_RT_HRDATA A1 WHERE A1.WLEVEL = 6 AND A1.POSITION IN('TM','TS')) T2,
           INCENTIVE_HAND_RT_TMGROUP T3
     WHERE T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
       AND T.IMONTH = T2.IMONTH(+)
       AND T.W6 = T2.WWID(+)
       AND T.IMONTH = T3.IMONTH
       AND T.H6 = T3.H6;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE  INC2014_RT_INDEX_SALES2_TP01';
  INSERT INTO INC2014_RT_INDEX_SALES2_TP01
    SELECT S1.IMONTH,
           S3.Q,
           S4.TMW6,
           S4.TMW6,
           S3.BU,
           S3.POSITION,
           S3.WLEVEL,
           SUM(S1.SALES),
           SUM(S1.TARGET),
           SUM(S1.SALES_LY),
           S2.W8_NUM,
           S2.INCENTIVE
      FROM INCENTIVE_RT_SALES1_DC S1,
           (SELECT T.IMONTH,
                   T3.TMW6,
                   COUNT(DISTINCT T2.WWID) W8_NUM,
                   SUM(T2.INCENTIVE) INCENTIVE
              FROM INCENTIVE_RT_SALES1_DC T,
                   (SELECT A1.Q,
                           A1.BU,
                           A1.POSITION,
                           A1.WWID,
                           MAX(A1.INCENTIVE) INCENTIVE
                      FROM INC2014_RT_SALES4_MONTH A1
                     GROUP BY A1.Q, A1.BU, A1.POSITION, A1.WWID) T2,
                   INCENTIVE_HAND_RT_TMGROUP T3
             WHERE T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
               AND T.HIER7 = T2.WWID
               AND T2.Q = I_Q
               AND T2.POSITION = 'DSR-W7'
               AND T.IMONTH = T3.IMONTH
               AND T.H6 = T3.H6
             GROUP BY T.IMONTH, T3.TMW6) S2,
           INCENTIVE_RT_DC_HRDATA S3,
           INCENTIVE_HAND_RT_TMGROUP S4
     WHERE S1.IMONTH = S2.IMONTH
       AND S1.IMONTH = S4.IMONTH
       AND S1.H6 = S4.H6
       AND S4.TMW6 = S2.TMW6
       AND S3.WLEVEL = 6
       AND S1.IMONTH = S3.IMONTH
       AND S4.TMW6 = S3.WWID
     GROUP BY S1.IMONTH,
              S3.Q,
              S4.TMW6,
              S3.BU,
              S3.POSITION,
              S3.WLEVEL,
              S2.W8_NUM,
              S2.INCENTIVE;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE  INC2014_RT_INDEX_SALES2_TP02';

  INSERT INTO INC2014_RT_INDEX_SALES2_TP02
    SELECT T3.IMONTH,
           T3.Q,
           T3.WWID,
           T3.WWNAME,
           T3.BU,
           T3.POSITION,
           T3.WLEVEL,
           SUM(T.SALES_CSHQ) SALES_CSHQ,
           SUM(T.TARGET_CSHQ) TARGET_CSHQ
      FROM INCENTIVE_RT_SALES1_CSHQ  T,
           INCENTIVE_HAND_RT_TMGROUP_KA T2,
           INCENTIVE_RT_DC_HRDATA    T3
     WHERE T.IMONTH = T2.IMONTH
       AND T.IMONTH = T3.IMONTH
       AND T.H6 = T2.H6
       AND T2.TMW6 = T3.WWID
       AND T3.WLEVEL = 6
     GROUP BY T3.IMONTH,
              T3.Q,
              T3.WWID,
              T3.WWNAME,
              T3.BU,
              T3.POSITION,
              T3.WLEVEL;

  INSERT INTO INC2014_RT_INDEX_SALES2
    SELECT T.IMONTH,
           T.Q,
           T.WWID,
           T.WWNAME,
           T.BU,
           T.POSITION,
           T.WLEVEL,
           T.SALES,
           T.TARGET,
           T.SALES_LY,
           T2.SALES_CSHQ,
           T2.TARGET_CSHQ,
           T.W8_NUM,
           T.INCENTIVE
      FROM INC2014_RT_INDEX_SALES2_TP01 T, INC2014_RT_INDEX_SALES2_TP02 T2
      WHERE T.IMONTH= T2.IMONTH
      AND T.WWID=T2.WWID;


  DELETE FROM INC2014_RT_INDEX_SALES3 T
   WHERE T.Q = I_Q
     AND T.POSITION IN ('TM-W6', 'TS-W6');

  INSERT INTO INC2014_RT_INDEX_SALES3
    SELECT Q,
           WWID,
           WWNAME,
           BU,
           POSITION,
           MONTH_NUM,
           0,
           SALES,
           TARGET,
           SALES_LY,
           SALES_CSHQ,
           TARGET_CSHQ,
           DECODE(TARGET, 0, 0, SALES / TARGET),
           DECODE(TARGET_CSHQ,0,0,SALES_CSHQ/TARGET_CSHQ),
           INCENTIVE_AVG
      FROM (SELECT T.Q,
                   T.WWID,
                   MAX(T.WWNAME) WWNAME,
                   T.BU,
                   MAX(T.POSITION) KEEP(DENSE_RANK LAST ORDER BY IMONTH) POSITION,
                   SUM(COUNT(1)) OVER(PARTITION BY WWID, BU, SUBSTR(T.Q, 1, 4) ORDER BY Q) MONTH_NUM,
                   SUM(SUM(T.SALES)) OVER(PARTITION BY WWID, BU, SUBSTR(T.Q, 1, 4) ORDER BY Q) SALES,
                   SUM(SUM(T.TARGET)) OVER(PARTITION BY WWID, BU, SUBSTR(T.Q, 1, 4) ORDER BY Q) TARGET,
                   SUM(SUM(T.SALES_LY)) OVER(PARTITION BY WWID, BU, SUBSTR(T.Q, 1, 4) ORDER BY Q) SALES_LY,
                   SUM(SUM(T.SALES_CSHQ)) OVER(PARTITION BY T.WWID, BU, SUBSTR(T.Q, 1, 4) ORDER BY Q) SALES_CSHQ,
                   SUM(SUM(T.TARGET_CSHQ)) OVER(PARTITION BY T.WWID, BU, SUBSTR(T.Q, 1, 4) ORDER BY Q) TARGET_CSHQ,
                   AVG(T.INCENTIVE / T.W8_NUM) INCENTIVE_AVG
              FROM INC2014_RT_INDEX_SALES2 T
             WHERE T.POSITION IN ('TM-W6', 'TS-W6')
             GROUP BY T.Q, T.WWID, T.BU) S1
     WHERE S1.Q = I_Q;
  -----------------------------------------------------------------------
  --过程结束
  COMMIT;

  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '成功', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, '失败', SQLERRM);

END;
/
