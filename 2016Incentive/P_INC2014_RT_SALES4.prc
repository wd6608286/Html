CREATE OR REPLACE PROCEDURE P_INC2014_RT_SALES4(I_Q VARCHAR2) IS
  /*****************************************
  --功能：RETAIL 奖金—-次政策是适用于 AM,AS,AE
  --时间：2013-01-28
  --作者：谭超
  ******************************************/

  V_LOG_ID       NUMBER;
  V_PROC_NAME    VARCHAR2(100);
  V_PARM_VALUS   VARCHAR2(100);
  V_ACH_DC       NUMBER;
  V_ACH_COM      NUMBER;
  V_SALES        NUMBER;
  V_TARGET       NUMBER;
  V_SALES_CSHQ   NUMBER;
  V_TARGET_CSHQ  NUMBER;
  V_SALES_COM    NUMBER;
  V_TARGET_COM   NUMBER;
  V_SALES_NEW    NUMBER;
  V_TARGET_NEW   NUMBER;
  V_BASE_DC      NUMBER;
  V_BASE_LOC_COM NUMBER;
  V_INC_DC       NUMBER(18, 4);
  V_INC_LOC_COM  NUMBER(18, 4);
  V_INC_TTL      NUMBER;
  V_ABSENCE      NUMBER;
  V_TERMINATION  NUMBER;
  V_COM_RATIO    NUMBER;
  V_MAX_DC       NUMBER;
  V_RATIO_DC     NUMBER;
  V_RATIO_COM    NUMBER;
  V_INC_GROW     NUMBER;
  --V_TEAM         VARCHAR2(40);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID
  V_PROC_NAME  := 'P_INC2014_RT_SALES4'; --过程名
  V_PARM_VALUS := I_Q; --过程输入参数
  --插入日志
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --过程内容
  -----------------------------------------------------------------------
  DELETE INC2014_RT_SALES4 T WHERE T.Q = I_Q;

  FOR C IN (SELECT *
              FROM INC2014_RT_SALES3 T
             WHERE T.Q = I_Q
               AND T.POSITION IN
                   ('AM', 'AE', 'AS', 'RSM', 'MT', 'AM-W6', 'AE-W6', 'AS-W6')) LOOP
  
    V_SALES       := C.SALES;
    V_TARGET      := C.TARGET;
    V_SALES_CSHQ  := C.SALES_CSHQ;
    V_TARGET_CSHQ := C.TARGET_CSHQ;
    V_SALES_COM   := C.SALES_COM;
    V_TARGET_COM  := C.TARGET_COM;
    V_SALES_NEW   := C.SALES_NEW;
    V_TARGET_NEW  := C.TARGET_NEW;
    V_ACH_DC      := C.ACH_DC;
  
    IF C.TARGET_COM = 0 THEN
      V_ACH_COM := 1;
    ELSE
      V_ACH_COM := C.SALES_COM / C.TARGET_COM;
    END IF;
  
    --DC 奖金
    CASE
      WHEN C.POSITION = 'RSM' AND SUBSTR(C.Q, 1, 4) = '2014' THEN
        V_RATIO_DC  := 2;
        V_RATIO_COM := 2;
      WHEN C.POSITION <> 'RSM' AND SUBSTR(C.Q, 1, 4) = '2014' THEN
        V_RATIO_DC  := 1.5;
        V_RATIO_COM := 2;
      ELSE
        V_RATIO_DC  := 1.5;
        V_RATIO_COM := 2;
    END CASE;
  
    SELECT BASE, MAX(T.ACH_1)
      INTO V_BASE_DC, V_MAX_DC
      FROM INCENTIVE_BASE_DC T
     WHERE T.BU = C.BU
       AND T.POSITION = C.POSITION
       AND T.TEAM = 'DC'
       AND T.Q = C.Q
     GROUP BY BASE;
    --奖金
    IF V_ACH_DC >= 1 AND V_ACH_DC < V_MAX_DC THEN
      V_INC_DC := V_BASE_DC * (1 + (V_ACH_DC - 1) * V_RATIO_DC);
    ELSE
      SELECT T.BASE * T.PAY_RATIO
        INTO V_INC_DC
        FROM INCENTIVE_BASE_DC T
       WHERE V_ACH_DC >= T.ACH_1
         AND V_ACH_DC < T.ACH_2
         AND T.BU = C.BU
         AND T.POSITION = C.POSITION
         AND T.TEAM = 'DC'
         AND T.Q = C.Q;
    END IF;
  
    --商业部分 只有RSM有
    IF (C.POSITION IN ('RSM')) THEN
      SELECT BASE, MAX(T.ACH_1)
        INTO V_BASE_LOC_COM, V_MAX_DC
        FROM INCENTIVE_BASE_DC T
       WHERE T.BU = C.BU
         AND T.POSITION = C.POSITION
         AND T.Q = C.Q
         AND T.TEAM = 'RSM_COM'
       GROUP BY BASE;
      --奖金
      IF V_ACH_COM >= 1 AND V_ACH_COM < V_MAX_DC THEN
        V_INC_LOC_COM := V_BASE_LOC_COM *
                         (1 + (V_ACH_COM - 1) * V_RATIO_COM);
      ELSE
        SELECT T.BASE * T.PAY_RATIO
          INTO V_INC_LOC_COM
          FROM INCENTIVE_BASE_DC T
         WHERE V_ACH_COM >= T.ACH_1
           AND V_ACH_COM < T.ACH_2
           AND T.BU = C.BU
           AND T.POSITION = C.POSITION
           AND T.TEAM = 'RSM_COM'
           AND T.Q = C.Q;
      END IF;
    ELSE
      V_BASE_LOC_COM := 0;
      V_INC_LOC_COM  := 0;
    END IF;
  
    --增长奖金
    V_INC_GROW := 0;
    /*SELECT CASE
            WHEN C.SALES_GROW <= 0 THEN
             0
            WHEN C.SALES_GROW * T.GROW_RATIO_1 >= T.MAX_GROW_INC THEN
             T.MAX_GROW_INC
            ELSE
             C.SALES_GROW * T.GROW_RATIO_1
          END
     INTO V_INC_GROW
     FROM INCENTIVE_BASE_GROW_MONTH T
    WHERE C.ACH_GROW > T.Grow_1
      AND C.ACH_GROW <= T.GROW_2
      AND T.BU = C.BU
      AND T.POSITION = C.POSITION
      AND T.IMONTH = C.IMONTH;    */
  
    --请假处理
    SELECT NVL(MIN(T.ABSENCE), 1), NVL(MIN(T.TERMINATION), 1)
      INTO V_ABSENCE, V_TERMINATION
      FROM INCENTIVE_HR_RATIO T
     WHERE T.WWID = C.WWID
       AND T.Q = I_Q;
  
    /*覆盖率*/
    --覆盖月数
  
    V_INC_DC      := V_INC_DC * C.MONTH_NUM / (SUBSTR(C.Q, 6) * 3) *
                     V_TERMINATION;
    V_INC_LOC_COM := V_INC_LOC_COM * C.MONTH_NUM / (SUBSTR(C.Q, 6) * 3) *
                     V_TERMINATION;
    V_INC_TTL     := 0;
  
    --插入
    INSERT INTO INC2014_RT_SALES4
    VALUES
      (C.Q,
       C.WWID,
       C.WWNAME,
       C.MONTH_NUM,
       C.BU,
       C.POSITION,
       V_SALES,
       V_TARGET,
       C.SALES_LY,
       C.SALES_CSHQ,
       C.TARGET_CSHQ,
       V_SALES_COM,
       V_TARGET_COM,
       V_ACH_DC,
       V_ACH_COM,
       C.ACH_GROW,
       V_BASE_DC,
       V_BASE_LOC_COM,
       V_INC_DC,
       V_INC_LOC_COM,
       V_INC_GROW,
       V_ABSENCE,
       V_TERMINATION,
       V_COM_RATIO,
       C.COVER_NUM,
       V_INC_TTL,
       0,
       0);
  END LOOP;

  --由于2015年Q2政策有变，所以Q1和其它Q的奖金基数不一致需要分开处理
  if i_q in ('2015Q2', '2015Q3', '2015Q4') then
    --其它Q需要把Q1的奖金减半来处理
    MERGE INTO INC2014_RT_SALES4 A1
    USING (SELECT T.WWID,
                  T.BU,
                  T.POSITION,
                  MAX(T.INC_DC) + MAX(T.INC_COM) + MAX(T.INC_GROW) INC
             FROM (select WWID,
                          BU,
                          POSITION,
                          decode(position, 'RSM', INC_DC, INC_DC / 2) INC_DC,
                          decode(position, 'RSM', INC_COM, INC_COM / 2) INC_COM,
                          decode(position, 'RSM', INC_GROW, INC_GROW / 2) INC_GROW,
                          q
                     from INC2014_RT_SALES4
                    where q = '2015Q1'
                   union
                   select WWID, BU, POSITION, INC_DC, INC_COM, INC_GROW, q
                     from INC2014_RT_SALES4
                    where q > '2015Q1') T
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE SET A1.INCENTIVE = A2.INC WHERE A1.Q = I_Q;
  
    MERGE INTO INC2014_RT_SALES4 A1
    USING (SELECT S1.BU,
                  S1.POSITION,
                  S1.WWID,
                  S1.INC,
                  S1.INC - NVL(S2.INC_BEF, 0) INC_Q
             FROM (SELECT T.WWID,
                          T.BU,
                          T.POSITION,
                          MAX(T.INC_DC) + MAX(T.INC_COM) + MAX(T.INC_GROW) INC
                     FROM (select WWID,
                                  BU,
                                  POSITION,
                                  decode(position, 'RSM', INC_DC, INC_DC / 2) INC_DC,
                                  decode(position, 'RSM', INC_COM, INC_COM / 2) INC_COM,
                                  decode(position,
                                         'RSM',
                                         INC_GROW,
                                         INC_GROW / 2) INC_GROW,
                                  q
                             from INC2014_RT_SALES4
                            where q = '2015Q1'
                           union
                           select WWID,
                                  BU,
                                  POSITION,
                                  INC_DC,
                                  INC_COM,
                                  INC_GROW,
                                  q
                             from INC2014_RT_SALES4
                            where q > '2015Q1') T
                    WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
                      AND T.Q <= I_Q
                    GROUP BY T.BU, T.POSITION, T.WWID) S1,
                  (SELECT T.WWID,
                          T.BU,
                          T.POSITION,
                          MAX(T.INC_DC) + MAX(T.INC_COM) + MAX(T.INC_GROW) INC_BEF
                     FROM (select WWID,
                                  BU,
                                  POSITION,
                                  decode(position, 'RSM', INC_DC, INC_DC / 2) INC_DC,
                                  decode(position, 'RSM', INC_COM, INC_COM / 2) INC_COM,
                                  decode(position,
                                         'RSM',
                                         INC_GROW,
                                         INC_GROW / 2) INC_GROW,
                                  q
                             from INC2014_RT_SALES4
                            where q = '2015Q1'
                           union
                           select WWID,
                                  BU,
                                  POSITION,
                                  INC_DC,
                                  INC_COM,
                                  INC_GROW,
                                  q
                             from INC2014_RT_SALES4
                            where q > '2015Q1') T
                    WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
                      AND T.Q < I_Q
                    GROUP BY T.BU, T.POSITION, T.WWID) S2
            WHERE S1.BU = S2.BU(+)
              AND S1.POSITION = S2.POSITION(+)
              AND S1.WWID = S2.WWID(+)) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INCENTIVE    = A2.INC,
             A1.INC_Q_DEDUCT = A2.INC_Q * (1 - A1.ABSENCE * A1.TERMINATION)
       WHERE A1.Q = I_Q;
  
    MERGE INTO INC2014_RT_SALES4 A1
    USING (SELECT T.WWID, T.BU, T.POSITION, SUM(T.INC_Q_DEDUCT) INC_Q_DEDUCT
             FROM (select WWID,
                          BU,
                          POSITION,
                          INC_Q_DEDUCT / 2 INC_Q_DEDUCT,
                          q
                     from INC2014_RT_SALES4
                    where q = '2015Q1'
                   union
                   select WWID, BU, POSITION, INC_Q_DEDUCT, q
                     from INC2014_RT_SALES4
                    where q > '2015Q1') T
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INC_YTD_HR = A1.INCENTIVE - A2.INC_Q_DEDUCT
       WHERE A1.Q = I_Q;
  else
    --Q1的正常计算
    MERGE INTO INC2014_RT_SALES4 A1
    USING (SELECT T.WWID,
                  T.BU,
                  T.POSITION,
                  MAX(T.INC_DC) + MAX(T.INC_COM) + MAX(T.INC_GROW) INC
             FROM INC2014_RT_SALES4 T
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE SET A1.INCENTIVE = A2.INC WHERE A1.Q = I_Q;
  
    MERGE INTO INC2014_RT_SALES4 A1
    USING (SELECT S1.BU,
                  S1.POSITION,
                  S1.WWID,
                  S1.INC,
                  S1.INC - NVL(S2.INC_BEF, 0) INC_Q
             FROM (SELECT T.WWID,
                          T.BU,
                          T.POSITION,
                          MAX(T.INC_DC) + MAX(T.INC_COM) + MAX(T.INC_GROW) INC
                     FROM INC2014_RT_SALES4 T
                    WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
                      AND T.Q <= I_Q
                    GROUP BY T.BU, T.POSITION, T.WWID) S1,
                  (SELECT T.WWID,
                          T.BU,
                          T.POSITION,
                          MAX(T.INC_DC) + MAX(T.INC_COM) + MAX(T.INC_GROW) INC_BEF
                     FROM INC2014_RT_SALES4 T
                    WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
                      AND T.Q < I_Q
                    GROUP BY T.BU, T.POSITION, T.WWID) S2
            WHERE S1.BU = S2.BU(+)
              AND S1.POSITION = S2.POSITION(+)
              AND S1.WWID = S2.WWID(+)) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INCENTIVE    = A2.INC,
             A1.INC_Q_DEDUCT = A2.INC_Q * (1 - A1.ABSENCE * A1.TERMINATION)
       WHERE A1.Q = I_Q;
  
    MERGE INTO INC2014_RT_SALES4 A1
    USING (SELECT T.WWID, T.BU, T.POSITION, SUM(T.INC_Q_DEDUCT) INC_Q_DEDUCT
             FROM INC2014_RT_SALES4 T
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INC_YTD_HR = A1.INCENTIVE - A2.INC_Q_DEDUCT
       WHERE A1.Q = I_Q;
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
