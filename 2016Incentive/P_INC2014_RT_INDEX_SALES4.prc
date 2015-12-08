CREATE OR REPLACE PROCEDURE P_INC2014_RT_INDEX_SALES4(I_Q        VARCHAR2,
                                                      I_POSITION VARCHAR2) IS
  /*****************************************
  --功能：行转列
  --时间：2013-01-14
  --作者：谭超
  ******************************************/

  V_LOG_ID      NUMBER;
  V_PROC_NAME   VARCHAR2(100);
  V_PARM_VALUS  VARCHAR2(100);
  V_INDEX       NUMBER; --管理系数
  V_INC_TTL     NUMBER;
  V_ABSENCE     NUMBER;
  V_TERMINATION NUMBER;
  V_COMPARED    NUMBER;
  V_INCENTIVE   NUMBER(18, 4);
  V_BASE_CSHQ   NUMBER;
  V_MAX_CSHQ    NUMBER;
  V_INC_CSHQ    NUMBER;

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID
  V_PROC_NAME  := 'P_INC2014_RT_INDEX_SALES4'; --过程名
  V_PARM_VALUS := I_Q || ',' || I_POSITION; --过程输入参数
  --插入日志
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --过程内容
  -----------------------------------------------------------------------
  DELETE INC2014_RT_INDEX_SALES4 T
   WHERE T.Q = I_Q
     AND T.POSITION = I_POSITION;

  FOR C IN (SELECT *
              FROM INC2014_RT_INDEX_SALES3 T
             WHERE T.Q = I_Q
               AND T.POSITION = I_POSITION) LOOP
    --管理系数 ,HS ,DSM
    SELECT MANAGEMENT_INDEX
      INTO V_INDEX
      FROM INCENTIVE_BASE_INDEX T
     WHERE T.IYEAR = SUBSTR(I_Q, 1, 4)
       AND T.POSITION = C.POSITION
       AND T.BU = C.BU;
  
    IF C.SALES_LY = 0 THEN
      V_COMPARED := 0;
    ELSE
      V_COMPARED := C.SALES / C.SALES_LY;
    END IF;
  
    --门槛 80%
    V_INC_TTL := C.INCENTIVE_AVG * V_INDEX;
    CASE
      WHEN C.ACH_DC < 0.8 THEN
        V_INC_TTL := 0;
      ELSE
        V_INC_TTL := V_INC_TTL;
    END CASE;
  
    V_INC_CSHQ := 0;
    --KA奖金=CSHQ
  
    IF I_POSITION <> 'DSM' THEN
      SELECT BASE, MAX(T.ACH_1)
        INTO V_BASE_CSHQ, V_MAX_CSHQ
        FROM INCENTIVE_BASE_DC T
       WHERE T.BU = C.BU
         AND T.POSITION = C.POSITION
         AND T.Q = C.Q
       GROUP BY BASE;
      --奖金
      IF C.ACH_CSHQ >= 1 AND C.ACH_CSHQ < V_MAX_CSHQ THEN
        V_INC_CSHQ := V_BASE_CSHQ * (1 + (C.ACH_CSHQ - 1) * 1.5);
      ELSE
        SELECT T.BASE * T.PAY_RATIO
          INTO V_INC_CSHQ
          FROM INCENTIVE_BASE_DC T
         WHERE C.ACH_CSHQ >= T.ACH_1
           AND C.ACH_CSHQ < T.ACH_2
           AND T.BU = C.BU
           AND T.POSITION = C.POSITION
           AND T.Q = C.Q;
      END IF;
    ELSE
      V_BASE_CSHQ := 0;
      V_INC_CSHQ  := 0;
    END IF;
  
    --邮件2015/10/12 (周一) 16:39 处理KA架构坑7一人多坑问题   王崇修改 
    --四川的92007913（黄琦）和92430172（刘鹏）8月开始 重庆的92013158（蒋雪平）和92014160（刘项欢）9月开始
    IF i_q = '2015Q4' AND
       c.wwid IN ('92430172', '92007913', '92014160', '92013158') THEN
      V_INC_CSHQ := 0;
    END IF;
    
    IF i_q = '2015Q3' AND c.wwid IN ('92014160', '92013158') THEN
      V_INC_CSHQ := V_INC_CSHQ * (c.month_num - 1) / 9;
    ELSIF i_q = '2015Q3' AND c.wwid IN ('92430172', '92007913') THEN
      V_INC_CSHQ := V_INC_CSHQ * (c.month_num - 2) / 9;
    END IF;
    
    V_INC_TTL := V_INC_TTL + V_INC_CSHQ;
  
    --请假处理
    SELECT NVL(MIN(T.ABSENCE), 1), NVL(MIN(T.TERMINATION), 1)
      INTO V_ABSENCE, V_TERMINATION
      FROM INCENTIVE_HR_RATIO T
     WHERE T.WWID = C.WWID
       AND T.Q = I_Q;
  
    --奖金
    V_INCENTIVE := V_INC_TTL * V_TERMINATION * (C.MONTH_NUM - C.COVER_NUM) /
                   (SUBSTR(C.Q, 6) * 3);
  
    INSERT INTO INC2014_RT_INDEX_SALES4
    VALUES
      (C.Q, C.WWID, C.WWNAME, C.BU, C.POSITION, C.MONTH_NUM, C.COVER_NUM, C.SALES, C.TARGET, C.SALES_LY, C.SALES_CSHQ, C.TARGET_CSHQ, C.INCENTIVE_AVG, C.ACH_DC, C.ACH_CSHQ, V_INC_CSHQ, V_COMPARED, V_ABSENCE, V_TERMINATION, V_INCENTIVE, 0, 0);
  
  END LOOP;

  --由于2015年Q2政策有变，所以Q1和其它Q的奖金基数不一致需要分开处理
  IF I_Q IN ('2015Q2', '2015Q3', '2015Q4') THEN
    --其它Q需要把Q1的奖金减半来处理
  
    MERGE INTO INC2014_RT_INDEX_SALES4 A1
    USING (SELECT T.WWID, T.BU, T.POSITION, MAX(nvl(T.AVG_INC, 0) *
                       t1.management_index) +
                   MAX(nvl(T.INC_CSHQ, 0)) INC
             FROM (SELECT WWID, BU, POSITION, CASE
                              WHEN POSITION LIKE 'TS%' OR POSITION LIKE 'TM%' THEN
                               nvl(AVG_INC, 0) / 3
                              ELSE
                               nvl(AVG_INC, 0) / 2
                            END AVG_INC, CASE
                              WHEN POSITION LIKE 'TS%' OR POSITION LIKE 'TM%' THEN
                               nvl(INC_CSHQ, 0)
                              ELSE
                               nvl(INC_CSHQ, 0) / 2
                            END INC_CSHQ, q
                      FROM INC2014_RT_INDEX_SALES4
                     WHERE q = '2015Q1'
                    UNION
                    SELECT WWID, BU, POSITION, AVG_INC, INC_CSHQ, q
                      FROM INC2014_RT_INDEX_SALES4
                     WHERE q > '2015Q1') T, INCENTIVE_BASE_INDEX T1
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
              AND T1.IYEAR = SUBSTR(I_Q, 1, 4)
              AND T1.POSITION = t.POSITION
              AND T1.BU = t.BU
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE SET A1.INCENTIVE = A2.INC WHERE A1.Q = I_Q;
  
    MERGE INTO INC2014_RT_INDEX_SALES4 A1
    USING (SELECT S1.BU, S1.POSITION, S1.WWID, S1.INC, S1.INC -
                   NVL(S2.INC_BEF, 0) INC_Q
             FROM (SELECT T.WWID, T.BU, T.POSITION, MAX(nvl(T.AVG_INC, 0) *
                                t1.management_index) +
                            MAX(nvl(T.INC_CSHQ, 0)) INC
                      FROM (SELECT WWID, BU, POSITION,CASE
                                      WHEN POSITION LIKE 'TS%' OR
                                           POSITION LIKE 'TM%' THEN
                                       nvl(AVG_INC, 0) / 3
                                      ELSE
                                       nvl(AVG_INC, 0) / 2
                                    END AVG_INC,CASE
                                      WHEN POSITION LIKE 'TS%' OR
                                           POSITION LIKE 'TM%' THEN
                                       nvl(INC_CSHQ, 0)
                                      ELSE
                                       nvl(INC_CSHQ, 0) / 2
                                    END INC_CSHQ, q
                               FROM INC2014_RT_INDEX_SALES4
                              WHERE q = '2015Q1'
                             UNION
                             SELECT WWID, BU, POSITION, AVG_INC, INC_CSHQ, q
                               FROM INC2014_RT_INDEX_SALES4
                              WHERE q > '2015Q1') T, INCENTIVE_BASE_INDEX T1
                     WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
                       AND T.Q <= I_Q
                       AND T1.IYEAR = SUBSTR(I_Q, 1, 4)
                       AND T1.POSITION = t.POSITION
                       AND T1.BU = t.BU
                     GROUP BY T.BU, T.POSITION, T.WWID) S1, (SELECT T.WWID, T.BU, T.POSITION, MAX(nvl(T.AVG_INC, 0) *
                                t1.management_index) +
                            MAX(nvl(T.INC_CSHQ, 0)) INC_BEF
                      FROM (SELECT WWID, BU, POSITION,CASE
                                      WHEN POSITION LIKE
                                           'TS%' OR
                                           POSITION LIKE
                                           'TM%' THEN
                                       nvl(AVG_INC, 0) / 3
                                      ELSE
                                       nvl(AVG_INC, 0) / 2
                                    END AVG_INC,CASE
                                      WHEN POSITION LIKE
                                           'TS%' OR
                                           POSITION LIKE
                                           'TM%' THEN
                                       nvl(INC_CSHQ, 0)
                                      ELSE
                                       nvl(INC_CSHQ, 0) / 2
                                    END INC_CSHQ, q
                               FROM INC2014_RT_INDEX_SALES4
                              WHERE q =
                                    '2015Q1'
                             UNION
                             SELECT WWID, BU, POSITION, AVG_INC, INC_CSHQ, q
                               FROM INC2014_RT_INDEX_SALES4
                              WHERE q >
                                    '2015Q1') T, INCENTIVE_BASE_INDEX T1
                     WHERE SUBSTR(T.Q, 1, 4) =
                           SUBSTR(I_Q, 1, 4)
                       AND T.Q < I_Q
                       AND T1.IYEAR =
                           SUBSTR(I_Q, 1, 4)
                       AND T1.POSITION =
                           t.POSITION
                       AND T1.BU = t.BU
                     GROUP BY T.BU, T.POSITION, T.WWID) S2
            WHERE S1.BU = S2.BU(+)
              AND S1.POSITION = S2.POSITION(+)
              AND S1.WWID = S2.WWID(+)) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INCENTIVE = A2.INC, A1.INC_Q_DEDUCT = A2.INC_Q *
                                (1 - A1.ABSENCE *
                                A1.TERMINATION)
       WHERE A1.Q = I_Q
         AND A1.POSITION = I_POSITION;
  
    MERGE INTO INC2014_RT_INDEX_SALES4 A1
    USING (SELECT T.WWID, T.BU, T.POSITION, SUM(T.INC_Q_DEDUCT) INC_Q_DEDUCT
             FROM (SELECT WWID, BU, POSITION, INC_Q_DEDUCT / 2 INC_Q_DEDUCT, q
                      FROM INC2014_RT_INDEX_SALES4
                     WHERE q = '2015Q1'
                    UNION
                    SELECT WWID, BU, POSITION, INC_Q_DEDUCT, q
                      FROM INC2014_RT_INDEX_SALES4
                     WHERE q > '2015Q1') T
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INC_YTD_HR = A1.INCENTIVE - A2.INC_Q_DEDUCT
       WHERE A1.Q = I_Q
         AND A1.POSITION = I_POSITION;
  
  ELSE
  
    MERGE INTO INC2014_RT_INDEX_SALES4 A1
    USING (SELECT T.WWID, T.BU, T.POSITION, MAX(T.INCENTIVE) INC
             FROM INC2014_RT_INDEX_SALES4 T
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE SET A1.INCENTIVE = A2.INC WHERE A1.Q = I_Q;
  
    MERGE INTO INC2014_RT_INDEX_SALES4 A1
    USING (SELECT S1.BU, S1.POSITION, S1.WWID, S1.INC, S1.INC -
                   NVL(S2.INC_BEF, 0) INC_Q
             FROM (SELECT T.WWID, T.BU, T.POSITION, MAX(T.INCENTIVE) INC
                      FROM INC2014_RT_INDEX_SALES4 T
                     WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
                       AND T.Q <= I_Q
                     GROUP BY T.BU, T.POSITION, T.WWID) S1, (SELECT T.WWID, T.BU, T.POSITION, MAX(T.INCENTIVE) INC_BEF
                      FROM INC2014_RT_INDEX_SALES4 T
                     WHERE SUBSTR(T.Q, 1, 4) =
                           SUBSTR(I_Q, 1, 4)
                       AND T.Q < I_Q
                     GROUP BY T.BU, T.POSITION, T.WWID) S2
            WHERE S1.BU = S2.BU(+)
              AND S1.POSITION = S2.POSITION(+)
              AND S1.WWID = S2.WWID(+)) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INCENTIVE = A2.INC, A1.INC_Q_DEDUCT = A2.INC_Q *
                                (1 - A1.ABSENCE *
                                A1.TERMINATION)
       WHERE A1.Q = I_Q
         AND A1.POSITION = I_POSITION;
  
    MERGE INTO INC2014_RT_INDEX_SALES4 A1
    USING (SELECT T.WWID, T.BU, T.POSITION, SUM(T.INC_Q_DEDUCT) INC_Q_DEDUCT
             FROM INC2014_RT_INDEX_SALES4 T
            WHERE SUBSTR(T.Q, 1, 4) = SUBSTR(I_Q, 1, 4)
              AND T.Q <= I_Q
            GROUP BY T.BU, T.POSITION, T.WWID) A2
    ON (A1.POSITION = A2.POSITION AND A1.WWID = A2.WWID)
    WHEN MATCHED THEN
      UPDATE
         SET A1.INC_YTD_HR = A1.INCENTIVE - A2.INC_Q_DEDUCT
       WHERE A1.Q = I_Q
         AND A1.POSITION = I_POSITION;
  END IF;
  -----------------------------------------------------------------------
  --过程结束
  COMMIT;

  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '成功', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, '失败', SQLERRM);
  
END;
/
