CREATE OR REPLACE PROCEDURE P_INC2014_RT_SALES4_MONTH(I_MONTH VARCHAR2) IS
  /*****************************************
  --功能：RETAIL 奖金——MONTH,
  --时间：2013-01-28
  --作者：谭超
  ******************************************/

  V_LOG_ID      NUMBER;
  V_PROC_NAME   VARCHAR2(100);
  V_PARM_VALUS  VARCHAR2(100);
  V_ACH_DC      NUMBER(18, 4);
  V_RK_LEVEL    VARCHAR2(20);
  V_SALES       NUMBER;
  V_TARGET      NUMBER;
  V_SALES_CSHQ  NUMBER;
  V_TARGET_CSHQ NUMBER;
  V_SALES_COM   NUMBER;
  V_TARGET_COM  NUMBER;
  V_SALES_NEW   NUMBER;
  V_TARGET_NEW  NUMBER;
  V_BASE_DC     NUMBER;
  V_INC_DC      NUMBER;
  V_INC_TTL     NUMBER;
  V_ABSENCE     NUMBER;
  V_TERMINATION NUMBER;
  V_MAX_DC      NUMBER;
  V_RATIO_DC    NUMBER;
  V_INC_GROW    NUMBER;

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID
  V_PROC_NAME  := 'P_INC2014_RT_SALES4_MONTH'; --过程名
  V_PARM_VALUS := I_MONTH; --过程输入参数
  --插入日志
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --过程内容
  -----------------------------------------------------------------------
  DELETE INC2014_RT_SALES4_MONTH T WHERE T.IMONTH = I_MONTH;

  --DSR/SDSR(A），SSR（B）,KAE/S(C),TS/TM有CSHQ(D),TS/TM无CSHQ(E),DSM(F)/RSM(G)/RKAM(H)
  FOR C IN (SELECT *
              FROM INCENTIVE_RT_SALES2_YTD T
             WHERE T.IMONTH = I_MONTH
               AND T.POSITION IN ('DSR', 'DSR-W7')) LOOP
  
    V_SALES       := C.SALES;
    V_TARGET      := C.TARGET;
    V_SALES_CSHQ  := C.SALES_CSHQ;
    V_TARGET_CSHQ := C.TARGET_CSHQ;
    V_SALES_COM   := C.SALES_COM;
    V_TARGET_COM  := C.TARGET_COM;
    V_SALES_NEW   := C.SALES_NEW;
    V_TARGET_NEW  := C.TARGET_NEW;
    V_ACH_DC      := C.ACH_DC;
  
    --DC 奖金
    CASE
      WHEN C.POSITION = 'RSM' THEN
        V_RATIO_DC := 2;
      ELSE
        V_RATIO_DC := 1.5;
    END CASE;
    SELECT BASE, MAX(T.ACH_1)
      INTO V_BASE_DC, V_MAX_DC
      FROM INCENTIVE_BASE_DC_MONTH T
     WHERE T.BU = C.BU
       AND T.POSITION = C.POSITION
       AND T.IMONTH = C.IMONTH
     GROUP BY BASE;
    --奖金
    IF V_ACH_DC >= 1 AND V_ACH_DC < V_MAX_DC THEN
      V_INC_DC := V_BASE_DC * (1 + (V_ACH_DC - 1) * V_RATIO_DC);
    ELSE
      SELECT T.BASE * T.PAY_RATION
        INTO V_INC_DC
        FROM INCENTIVE_BASE_DC_MONTH T
       WHERE V_ACH_DC >= T.ACH_1
         AND V_ACH_DC < T.ACH_2
         AND T.BU = C.BU
         AND T.POSITION = C.POSITION
         AND T.IMONTH = C.IMONTH;
    END IF;
  
    --增长奖金
    SELECT CASE
             WHEN C.SALES_GROW <= 0 THEN
              0
             WHEN C.SALES_GROW * T.GROW_RATIO_1 >= T.MAX_GROW_INC THEN
              T.MAX_GROW_INC
             ELSE
              C.SALES_GROW * T.GROW_RATIO_1
           END,
           T.RK_LEVEL
      INTO V_INC_GROW, V_RK_LEVEL
      FROM INCENTIVE_BASE_GROW_MONTH T
     WHERE C.ACH_GROW > T.Grow_1
       AND C.ACH_GROW <= T.GROW_2
       AND T.BU = C.BU
       AND T.POSITION = C.POSITION
       AND T.IMONTH = C.IMONTH;
  
    --请假处理
    SELECT NVL(MIN(T.ABSENCE), 1), NVL(MIN(T.TERMINATION), 1)
      INTO V_ABSENCE, V_TERMINATION
      FROM INCENTIVE_HR_MONTH_RATIO T
     WHERE T.WWID = C.WWID
       AND T.IMONTH = I_MONTH;
  
    /*覆盖率*/
    --覆盖月数
    V_INC_DC   := V_INC_DC * (C.MONTH_NUM - C.COVER_NUM) /
                  (TO_NUMBER(SUBSTR(C.IMONTH, 6))) * V_TERMINATION;
    V_INC_GROW := V_INC_GROW * (C.MONTH_NUM - C.COVER_NUM) /
                  (TO_NUMBER(SUBSTR(C.IMONTH, 6))) * V_TERMINATION;
    V_INC_TTL  := 0;
  
    --插入
    INSERT INTO INC2014_RT_SALES4_MONTH
    VALUES
      (C.IMONTH,
       C.Q,
       C.WWID,
       C.WWNAME,
       C.MONTH_NUM,
       C.BU,
       C.POSITION,
       V_SALES,
       V_TARGET,
       C.SALES_LY,
       V_SALES_COM,
       V_TARGET_COM,
       C.RK_GROW,
       V_RK_LEVEL,
       V_ACH_DC,
       C.ACH_GROW,
       V_BASE_DC,
       V_INC_DC,
       V_INC_GROW,
       V_ABSENCE,
       V_TERMINATION,
       C.COVER_NUM,
       V_INC_TTL,
       0,
       0);
  END LOOP;
  
  --Q2以后不含grow 的奖金
  if I_MONTH < '2015-04' then
    MERGE INTO INC2014_RT_SALES4_MONTH A1
    USING (SELECT T.WWID,
                  T.BU,
                  T.POSITION,
                  MAX(T.INC_DC) + MAX(T.INC_GROW) INC
             FROM INC2014_RT_SALES4_MONTH T
            WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
              AND T.IMONTH <= I_MONTH
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE SET A1.INCENTIVE = A2.INC WHERE A1.IMONTH = I_MONTH;
  
    MERGE INTO INC2014_RT_SALES4_MONTH A1
    USING (SELECT S1.BU,
                  S1.POSITION,
                  S1.WWID,
                  S1.INC,
                  S1.INC - NVL(S2.INC_BEF, 0) INC_M
             FROM (SELECT T.WWID,
                          T.BU,
                          T.POSITION,
                          MAX(T.INC_DC) + MAX(T.INC_GROW) INC
                     FROM INC2014_RT_SALES4_MONTH T
                    WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
                      AND T.IMONTH <= I_MONTH
                    GROUP BY T.BU, T.POSITION, T.WWID) S1,
                  (SELECT T.WWID,
                          T.BU,
                          T.POSITION,
                          MAX(T.INC_DC) + MAX(T.INC_GROW) INC_BEF
                     FROM INC2014_RT_SALES4_MONTH T
                    WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
                      AND T.IMONTH < I_MONTH
                    GROUP BY T.BU, T.POSITION, T.WWID) S2
            WHERE S1.BU = S2.BU(+)
              AND S1.POSITION = S2.POSITION(+)
              AND S1.WWID = S2.WWID(+)) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INCENTIVE    = A2.INC,
             A1.INC_M_DEDUCT = A2.INC_M * (1 - A1.ABSENCE * A1.TERMINATION)
       WHERE A1.IMONTH = I_MONTH;
  
    MERGE INTO INC2014_RT_SALES4_MONTH A1
    USING (SELECT T.WWID, T.BU, T.POSITION, SUM(T.INC_M_DEDUCT) INC_M_DEDUCT
             FROM INC2014_RT_SALES4_MONTH T
            WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
              AND T.IMONTH <= I_MONTH
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INC_YTD_HR = A1.INCENTIVE - A2.INC_M_DEDUCT
       WHERE A1.IMONTH = I_MONTH;
  else
    MERGE INTO INC2014_RT_SALES4_MONTH A1
    USING (SELECT T.WWID, T.BU, T.POSITION, MAX(T.INC_DC) INC
             FROM INC2014_RT_SALES4_MONTH T
            WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
              AND T.IMONTH <= I_MONTH
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE SET A1.INCENTIVE = A2.INC WHERE A1.IMONTH = I_MONTH;
  
    MERGE INTO INC2014_RT_SALES4_MONTH A1
    USING (SELECT S1.BU,
                  S1.POSITION,
                  S1.WWID,
                  S1.INC,
                  S1.INC - NVL(S2.INC_BEF, 0) INC_M
             FROM (SELECT T.WWID, T.BU, T.POSITION, MAX(T.INC_DC) INC
                     FROM INC2014_RT_SALES4_MONTH T
                    WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
                      AND T.IMONTH <= I_MONTH
                    GROUP BY T.BU, T.POSITION, T.WWID) S1,
                  (SELECT T.WWID, T.BU, T.POSITION, MAX(T.INC_DC) INC_BEF
                     FROM INC2014_RT_SALES4_MONTH T
                    WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
                      AND T.IMONTH < I_MONTH
                    GROUP BY T.BU, T.POSITION, T.WWID) S2
            WHERE S1.BU = S2.BU(+)
              AND S1.POSITION = S2.POSITION(+)
              AND S1.WWID = S2.WWID(+)) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INCENTIVE    = A2.INC,
             A1.INC_M_DEDUCT = A2.INC_M * (1 - A1.ABSENCE * A1.TERMINATION)
       WHERE A1.IMONTH = I_MONTH;
  
    MERGE INTO INC2014_RT_SALES4_MONTH A1
    USING (SELECT T.WWID, T.BU, T.POSITION, SUM(T.INC_M_DEDUCT) INC_M_DEDUCT
             FROM INC2014_RT_SALES4_MONTH T
            WHERE SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
              AND T.IMONTH <= I_MONTH
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INC_YTD_HR = case
                               when A1.INCENTIVE - A2.INC_M_DEDUCT < 0 then
                                0
                               else
                                A1.INCENTIVE - A2.INC_M_DEDUCT
                             end
       WHERE A1.IMONTH = I_MONTH;
  end if;

  -----------------------------------------------------------------------
  --过程结束
  COMMIT;
  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '成功', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, '失败', SQLERRM);
  
END;
/
