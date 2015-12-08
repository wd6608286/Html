CREATE OR REPLACE PROCEDURE P_INC2014_RT_INDEX_SALES2(I_Q        VARCHAR2,
                                                      I_POSITION VARCHAR2) IS
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
  V_PROC_NAME  := 'P_INC2014_RT_INDEX_SALES2'; --过程名
  V_PARM_VALUS := I_Q || ',' || I_POSITION; --过程输入参数
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
     AND T.POSITION = I_POSITION;

  INSERT INTO INC2014_RT_INDEX_SALES2
    SELECT S1.IMONTH,
           S1.Q,
           S1.WWID,
           S1.WWNAME,
           S1.BU,
           S1.POSITION,
           S1.WLEVELS,
           S1.SALES,
           S1.TARGET,
           S1.SALES_LY,
           S1.SALES_CSHQ,
           S1.TARGET_CSHQ,
           S2.W8_NUM,
           S2.INCENTIVE
      FROM INCENTIVE_RT_SALES2 S1,
           (SELECT T3.IMONTH,
                   T3.WWID,
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
                   INCENTIVE_RT_HRDATA T3
             WHERE T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
               AND T.IMONTH = T3.IMONTH
               AND T.W6 = T3.WWID
               AND T3.WLEVEL = 6
               AND T3.POSITION = I_POSITION
               AND T.HIER7 = T2.WWID
               AND T2.Q = I_Q
               AND T2.POSITION = 'DSR-W7'
             GROUP BY T3.IMONTH, T3.WWID) S2
     WHERE S1.IMONTH = S2.IMONTH
       AND S1.WWID = S2.WWID;

  INSERT INTO INC2014_RT_INDEX_SALES2
    SELECT S1.IMONTH,
           S1.Q,
           S1.WWID,
           S1.WWNAME,
           S1.BU,
           S1.POSITION,
           S1.WLEVELS,
           S1.SALES,
           S1.TARGET,
           S1.SALES_LY,
           S1.SALES_CSHQ,
           S1.TARGET_CSHQ,
           S2.W8_NUM,
           S2.INCENTIVE
      FROM INCENTIVE_RT_SALES2 S1,
           (SELECT T3.IMONTH,
                   T3.WWID,
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
                   INCENTIVE_RT_HRDATA T3
             WHERE T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
               AND T.IMONTH = T3.IMONTH
               AND T.W6 = T3.WWID
               AND T3.WLEVEL = 7
               AND T3.POSITION = I_POSITION
               AND T.HIER7 = T2.WWID
               AND T2.Q = I_Q
               AND T2.POSITION = 'DSR-W7'
             GROUP BY T3.IMONTH, T3.WWID) S2
     WHERE S1.IMONTH = S2.IMONTH
       AND S1.WWID = S2.WWID;

  -----------------------------------------------------------------------
  --过程结束
  COMMIT;

  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '成功', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, '失败', SQLERRM);

END;
/
