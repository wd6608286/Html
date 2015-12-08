CREATE OR REPLACE PROCEDURE P_INC2014_RT_SALES3(I_Q        VARCHAR2,
                                                I_POSITION VARCHAR2) IS
  /*****************************************
  --功能：行转列
  --时间：2013-01-14
  --作者：谭超
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID
  V_PROC_NAME  := 'P_INC2014_RT_SALES3'; --过程名
  V_PARM_VALUS := I_Q || ',' || I_POSITION; --过程输入参数
  --插入日志
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --过程内容
  -----------------------------------------------------------------------

  --清楚数据
  EXECUTE IMMEDIATE 'TRUNCATE TABLE INC2014_RT_SALES3_TP01';

  DELETE FROM INC2014_RT_SALES3 T
   WHERE T.Q = I_Q
     AND T.POSITION = I_POSITION;

  /*INSERT INTO INC2014_RT_SALES3_TP01
    SELECT I_Q,
           T.WWID,
           MAX(T.WWNAME),
           COUNT(1),
           T.BU,
           T.POSITION,
           AVG(POP),
           SUM(T.SALES),
           SUM(T.TARGET),
           SUM(T.SALES_CSHQ),
           SUM(T.TARGET_CSHQ),
           SUM(T.COM_SALES),
           SUM(T.COM_TARGET),
           SUM(T.SALES_NEW),
           SUM(T.TARGET_NEW),
           SUM(T.SALES_LY),
           SUM(T.SALES_LY_CSHQ),
           COUNT(T2.WWID)
      FROM INCENTIVE_RT_SALES2 T,
           (SELECT *
              FROM INCENTIVE_HAND_COVERAGE_MONTH A1
             WHERE A1.COVERAGE = 'N') T2
     WHERE T.Q <= I_Q
       AND T.POSITION = I_POSITION
       AND T.IMONTH = T2.IMONTH(+)
       AND T.WWID = T2.WWID(+)
       AND SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
     GROUP BY T.WWID, T.BU, T.POSITION;*/

  INSERT INTO INC2014_RT_SALES3_TP01
    SELECT *
      FROM (SELECT T.Q,
                   T.WWID,
                   MAX(T.WWNAME) WWNAME,
                   SUM(COUNT(1)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) MONTH_NUM,
                   T.BU,
                   T.POSITION,
                   AVG(POP) POP,
                   SUM(SUM(T.SALES)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) SALES,
                   SUM(SUM(T.TARGET)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) TARGET,
                   SUM(SUM(T.SALES_CSHQ)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) SALES_CSHQ,
                   SUM(SUM(T.TARGET_CSHQ)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) TARGET_CSHQ,
                   SUM(SUM(T.SALES_COM)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) COM_SALES,
                   SUM(SUM(T.TARGET_COM)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) COM_TARGET,
                   SUM(SUM(T.SALES_NEW)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) SALES_NEW,
                   SUM(SUM(T.TARGET_NEW)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) TARGET_NEW,
                   SUM(SUM(T.SALES_LY)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) SALES_LY,
                   SUM(SUM(T.SALES_LY_CSHQ)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) SALES_LY_CSHQ,
                   SUM(COUNT(T2.WWID)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY T.Q) MONTH_MRC
              FROM INCENTIVE_RT_SALES2 T,
                   (SELECT *
                      FROM INCENTIVE_HAND_RT_COVERAGE_M A1    ---?????
                     WHERE A1.COVERAGE = 'N') T2
             WHERE T.Q <= I_Q
               AND T.POSITION = I_POSITION
               AND T.IMONTH = T2.IMONTH(+)
               AND T.WWID = T2.WWID(+)
               AND SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
             GROUP BY T.WWID, T.BU, T.POSITION, T.Q) S
     WHERE S.Q = I_Q;


  IF I_POSITION IN ('AE', 'AM', 'AS', 'MT') THEN
    INSERT INTO INC2014_RT_SALES3
      SELECT Q,
             WWID,
             WWNAME,
             MONTH_NUM,
             COVER_NUM,
             BU,
             POSITION,
             POP,
             SALES,
             TARGET,
             SALES_CSHQ,
             TARGET_CSHQ,
             COM_SALES,
             COM_TARGET,
             SALES_NEW,
             TARGET_NEW,
             SALES_LY,
             SALES_LY_CSHQ,
             SALES - SALES_LY GROW,
             DECODE(T.TARGET_CSHQ, 0, 0, T.SALES_CSHQ / T.TARGET_CSHQ) ACH_DC,
             RANK() OVER(PARTITION BY BU, POSITION ORDER BY((T.SALES_CSHQ - T.SALES_LY_CSHQ) / MONTH_NUM) DESC) RK_GROW,
             RANK() OVER(PARTITION BY BU, POSITION ORDER BY((T.SALES_CSHQ - T.SALES_LY_CSHQ) / MONTH_NUM) DESC) / COUNT(1) OVER(PARTITION BY BU, POSITION) ACH_GROW
        FROM INC2014_RT_SALES3_TP01 T
       WHERE T.SALES_CSHQ <> 0
         AND T.TARGET_CSHQ <> 0;
  ELSE
    INSERT INTO INC2014_RT_SALES3
      SELECT Q,
             WWID,
             WWNAME,
             MONTH_NUM,
             COVER_NUM,
             BU,
             POSITION,
             POP,
             SALES,
             TARGET,
             SALES_CSHQ,
             TARGET_CSHQ,
             COM_SALES,
             COM_TARGET,
             SALES_NEW,
             TARGET_NEW,
             SALES_LY,
             SALES_LY_CSHQ,
             SALES - SALES_LY GROW,
             DECODE(T.TARGET, 0, 0, T.SALES / T.TARGET) ACH_DC,
             RANK() OVER(PARTITION BY BU, POSITION ORDER BY((SALES - SALES_LY) / MONTH_NUM) DESC) RK_GROW,
             RANK() OVER(PARTITION BY BU, POSITION ORDER BY((SALES - SALES_LY) / MONTH_NUM) DESC) / COUNT(1) OVER(PARTITION BY BU, POSITION) ACH_GROW
        FROM INC2014_RT_SALES3_TP01 T
       WHERE T.SALES <> 0
         AND T.TARGET <> 0;

  END IF;

  --保存历史排名，取最高排名，即最小数
  DELETE FROM INC2014_RT_SALES3_RANK T
   WHERE Q = I_Q
     AND T.UPDATETIME <=
         SUBSTR(I_Q, 1, 4) || '-' || LPAD(SUBSTR(I_Q, 6) * 3, 2, 0);

  DELETE FROM INC2014_RT_SALES3_RANK T
   WHERE T.UPDATETIME = TO_CHAR(SYSDATE, 'YYYY-MM')
     AND T.POSITION = I_POSITION
     AND T.Q = I_Q;

  INSERT INTO INC2014_RT_SALES3_RANK
    SELECT T.*, TO_CHAR(SYSDATE, 'YYYY-MM')
      FROM INC2014_RT_SALES3 T
     WHERE T.Q = I_Q
       AND T.POSITION = I_POSITION;

  MERGE INTO INC2014_RT_SALES3 T
  USING (SELECT A1.Q,
                A1.WWID,
                A1.BU,
                A1.POSITION,
                MIN(RK_GROW) RK_GROW,
                MIN(ACH_GROW) ACH_GROW
           FROM INC2014_RT_SALES3_RANK A1
          GROUP BY A1.Q, A1.WWID, A1.BU, A1.POSITION) T2
  ON ( T.Q=T2.Q AND T.WWID=T2.WWID AND T.BU=T2.BU AND T.POSITION= T2.POSITION )
  WHEN MATCHED THEN
    UPDATE SET T.RK_GROW= T2.RK_GROW ,T.ACH_GROW= T2.ACH_GROW;

  -----------------------------------------------------------------------
  --过程结束
  COMMIT;
  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '成功', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, '失败', SQLERRM);

END;
/
