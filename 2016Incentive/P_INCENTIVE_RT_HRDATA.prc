CREATE OR REPLACE PROCEDURE P_INCENTIVE_RT_HRDATA(I_Q IN VARCHAR2) IS
  /*****************************************
  --功能：RETAIL HR信息，请先更新 hospital HR信息,
  --时间：2013-02-29
  --作者：谭超
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);
  V_MONTH1     VARCHAR2(20);
  V_MONTH2     VARCHAR2(20);
  V_MONTH3     VARCHAR2(20);
  --V_ROW_NUM    NUMBER;
BEGIN
  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID
  V_PROC_NAME  := 'P_INCENTIVE_RT_HRDATA'; --过程名
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

  /*运行医院的HR信息*/

  /*hr表处理*/
  DELETE FROM INCENTIVE_RT_HRDATA T WHERE T.Q = I_Q;

  INSERT INTO INCENTIVE_RT_HRDATA
    (IMONTH, Q, WWID, WWNAME, BU, POSITION)
    SELECT IMONTH, I_Q, WWID, WNAME, T2.BU, T2.POSITION
      FROM INC_HR_ACTIVE_MONTH    T,
           INCENTIVE_BASE_MAPPING T2
     WHERE T.NEWPOSITION = T2.NEWPOSITION
       AND T.NEWBU = T2.NEWBU
       AND SUBSTR(T.IMONTH, 1, 4) = T2.IYEAR
       AND T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
       AND T2.BU IN ('RETAIL', 'OTC CRS')
     ORDER BY IMONTH, WWID, WNAME, T2.BU, T2.POSITION;

  DELETE FROM INCENTIVE_RT_HRDATA A1
   WHERE A1.IMONTH || A1.WWID IN
         (SELECT IMONTH || WWID
            FROM INC_HR_ACTIVE_MONTH    T,
                 INCENTIVE_BASE_MAPPING T2
           WHERE T.NEWPOSITION = T2.NEWPOSITION
             AND T.NEWBU = T2.NEWBU
             AND SUBSTR(T.IMONTH, 1, 4) = T2.IYEAR
             AND SUBSTR(T2.POSITIONNAME, 1, 2) = 'MT'
             AND T2.BU IN ('RETAIL', 'OTC CRS')
             AND NOT EXISTS
           (SELECT 1
                    FROM INCENTIVE_BASE_MT_HR T5
                   WHERE SUBSTR(T.IMONTH, 1, 4) || 'Q' ||
                         TO_CHAR(TO_DATE(T.IMONTH, 'YYYY-MM'), 'Q') = T5.Q
                     AND T.WWID = T5.WWID));

  --去空格
  UPDATE INCENTIVE_RT_HRDATA T
     SET T.WWID   = REPLACE(T.WWID, ' ', ''),
         T.WWNAME = REPLACE(T.WWNAME, ' ', '');

  -- 删除产假
  DELETE FROM INCENTIVE_RT_HRDATA T
   WHERE IMONTH > = V_MONTH1
     AND IMONTH || '+' || WWID IN
         (SELECT IMONTH || '+' || WWID
            FROM INC_HR_MATERNITY_MONTH);
  COMMIT;

  /*月假期 */
  --临时假期
  DELETE FROM INCENTIVE_HR_MONTH_RATIO_TEMP1;
  INSERT INTO INCENTIVE_HR_MONTH_RATIO_TEMP1
    SELECT IMONTH, WWID, SUM(DAYS) DAYS, MIN(TERMINATION) TERMINATION
      FROM (SELECT T.IMONTH, T.WWID, 0 DAYS, 0 TERMINATION
              FROM INC_HR_TERMINATION_MONTH T
            UNION ALL
            SELECT T2.IMONTH, T2.WWID, DAYS, 1
              FROM INC_HR_ABSENCE_MONTH T2)
     WHERE IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
     GROUP BY IMONTH, WWID;
  --月假期
  DELETE FROM INCENTIVE_HR_MONTH_RATIO WHERE Q = I_Q;
  INSERT INTO INCENTIVE_HR_MONTH_RATIO
    SELECT IMONTH,
           I_Q,
           T.WWID,
           DAYS,
           CASE
             WHEN DAYS > 10 THEN
              0
             WHEN DAYS > 5 AND DAYS <= 10 THEN
              0.5
             WHEN DAYS <= 5 THEN
              1
           END RATIO,
           TERMINATION
      FROM INCENTIVE_HR_MONTH_RATIO_TEMP1 T;

  /*处理离职又入职 */
  DELETE FROM INCENTIVE_RT_HRDATA T
   WHERE EXISTS (SELECT 1
            FROM (SELECT DISTINCT T1.WWID, T2.STARTDATE
                    FROM INC_HR_ACTIVE_MONTH      T1,
                         INC_HR_TERMINATION_MONTH T2
                   WHERE T1.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
                     AND T2.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
                     AND T1.WWID = T2.WWID
                     AND T1.ACTION = '入职'
                     AND T1.STARTDATE > T2.STARTDATE) T3
           WHERE T.WWID = T3.WWID
             AND T.IMONTH || '-15' <= T3.STARTDATE
             AND T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3));

  --HR 架构信息
  DELETE FROM INCENTIVE_SFE_RT_WWID T WHERE IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3);

  INSERT INTO INCENTIVE_SFE_RT_WWID
    SELECT IMONTH, BU, BUTYPE, WWID, MAX(WWNAME) WWNAME, MIN(WLEVEL) WLEVEL
      FROM (SELECT T.IMONTH,
                   'OTC CRS' BU,
                   'DS' BUTYPE,
                   W1 WWID,
                   N1 WWNAME,
                   1 WLEVEL
              FROM ODS_RT_OOD_HIER01 T
            UNION
            SELECT T.IMONTH, 'OTC CRS', 'DS', W2 WWID, N2 WWNAME, 2
              FROM ODS_RT_OOD_HIER01 T
            UNION
            SELECT T.IMONTH, 'OTC CRS', 'DS', W3 WWID, N3 WWNAME, 3
              FROM ODS_RT_OOD_HIER01 T
            UNION
            SELECT T.IMONTH, 'OTC CRS', 'DS', W4 WWID, N4 WWNAME, 4
              FROM ODS_RT_OOD_HIER01 T
            UNION
            SELECT T.IMONTH, 'OTC CRS', 'DS', W5 WWID, N5 WWNAME, 5
              FROM ODS_RT_OOD_HIER01 T
            UNION
            SELECT T.IMONTH, 'OTC CRS', 'DS', W6 WWID, N6 WWNAME, 6
              FROM ODS_RT_OOD_HIER01 T
            UNION
            SELECT T.IMONTH,
                   'OTC CRS',
                   'DS',
                   REPLACE(W7, ',') WWID,
                   REPLACE(N7, ',') WWNAME,
                   7
              FROM ODS_RT_OOD_HIER01 T
            UNION
            SELECT T.IMONTH, 'OTC CRS', 'KA', W6 WWID, E6 WWNAME, 6
              FROM ODS_RT_ORG_CSHQ_HIER T) A1
     WHERE IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
       AND A1.WWID NOT IN ('*', '000000')
     GROUP BY IMONTH, BU, BUTYPE, WWID;

  MERGE INTO INCENTIVE_RT_HRDATA T
  USING (SELECT IMONTH, WWID, MIN(WLEVEL) WLEVEL
           FROM (SELECT IMONTH, W3 WWID, 3 WLEVEL
                   FROM ODS_RT_OOD_HIER01
                 UNION ALL
                 SELECT IMONTH, W4, 4
                   FROM ODS_RT_OOD_HIER01
                 UNION ALL
                 SELECT IMONTH, W5, 5
                   FROM ODS_RT_OOD_HIER01
                 UNION ALL
                 SELECT IMONTH, W6, 6
                   FROM ODS_RT_OOD_HIER01
                 UNION ALL
                 SELECT IMONTH, REPLACE(W7, ','), 7 FROM ODS_RT_OOD_HIER01)
          GROUP BY IMONTH, WWID) T2
  ON (T.WWID = T2.WWID AND T.IMONTH = T2.IMONTH)
  WHEN MATCHED THEN
    UPDATE
       SET T.WLEVEL = T2.WLEVEL
     WHERE T.BU = 'OTC CRS'
       AND T.Q = I_Q;

  MERGE INTO INCENTIVE_RT_HRDATA T
  USING (SELECT IMONTH, WWID, MIN(WLEVEL) WLEVEL
           FROM (SELECT IMONTH, W3 WWID, 3 WLEVEL
                   FROM ODS_RT_ORG_CSHQ_HIER
                 UNION ALL
                 SELECT IMONTH, W4, 4
                   FROM ODS_RT_ORG_CSHQ_HIER
                 UNION ALL
                 SELECT IMONTH, W5, 5
                   FROM ODS_RT_ORG_CSHQ_HIER
                 UNION ALL
                 SELECT IMONTH, W6, 6
                   FROM ODS_RT_ORG_CSHQ_HIER
                 UNION ALL
                 SELECT IMONTH, REPLACE(W7, ','), 7 FROM ODS_RT_ORG_CSHQ_HIER)
          GROUP BY IMONTH, WWID) T2
  ON (T.WWID = T2.WWID AND T.IMONTH = T2.IMONTH)
  WHEN MATCHED THEN
    UPDATE
       SET T.WLEVEL = T2.WLEVEL
     WHERE T.BU = 'OTC CRS'
       AND T.Q = I_Q
       AND T.POSITION IN ('MT', 'AS', 'AM', 'AE');
  --验证 HR_RATIO 是否刷新过来
  --SELECT COUNT(1) INTO V_ROW_NUM FROM INCENTIVE_HR_RATIO T WHERE T.Q = I_Q;

  -----------------------------------------------------------------------
  --过程结束
  COMMIT;
  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '成功', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, '失败', SQLERRM);

END;
/
