CREATE OR REPLACE PROCEDURE P_INC2015_RT_SALES2(I_Q        VARCHAR2,
                                                  I_POSITION VARCHAR2) IS
  /*****************************************
  --功能：OTC 取数据汇总到人
  --时间：2013-01-14
  --作者：谭超
  ******************************************/

  V_LOG_ID        NUMBER;
  V_PROC_NAME     VARCHAR2(100);
  V_PARM_VALUS    VARCHAR2(100);
  V_MONTH         VARCHAR2(10);
  V_WWID          VARCHAR2(50);
  V_WWNAME        VARCHAR2(50);
  V_WLEVELS       NUMBER;
  V_SALES         NUMBER;
  V_TARGET        NUMBER;
  V_ROW_NUM       NUMBER;
  V_FINDWWID      VARCHAR2(7);
  V_SALES_CSHQ    NUMBER;
  V_TARGET_CSHQ   NUMBER;
  V_TYPE          VARCHAR2(10);
  V_CSHQ_YES      VARCHAR2(7);
  V_DC_YES        VARCHAR2(7);
  V_POP_DC        NUMBER;
  V_SALES_COM     NUMBER;
  V_TARGET_COM    NUMBER;
  V_SALES_LY      NUMBER;
  V_SALES_LY_CSHQ NUMBER;
  V_BAKVERSION VARCHAR2(10);

  CURSOR CUR_1 IS
    SELECT IMONTH, WWID, WWNAME
      FROM INCENTIVE_RT_HRDATA
     WHERE POSITION = I_POSITION
       AND Q=I_Q
     ORDER BY IMONTH, WWID ASC;

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --获取日志ID

  V_PROC_NAME  := 'P_INC2014_RT_SALES2'; --过程名
  V_PARM_VALUS := I_Q||I_POSITION; --过程输入参数
  --插入日志
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --过程内容
  -----------------------------------------------------------------------
  /*清空数据*/
  DELETE FROM INCENTIVE_RT_SALES2
   WHERE Q = I_Q
     AND POSITION = I_POSITION;
  COMMIT;
  /*
  cursor cur_1 is
  select iMonth,wwid,wwname from  inc2012_MS_HRdata
  where BU = 'MS' and POSITION = 'MR' and (imonth = vmmonth1 or imonth = vmmonth2 or imonth = vmmonth3)
  order by iMonth,wwid asc;
  */


  OPEN CUR_1;
  FETCH CUR_1
    INTO V_MONTH, V_WWID, V_WWNAME;
  WHILE CUR_1 %FOUND LOOP

    V_FINDWWID       := 'N';
    V_SALES          := 0;
    V_TARGET         := 0;
    V_SALES_CSHQ     := 0;
    V_TARGET_CSHQ    := 0;
    V_POP_DC         := 0;
    V_SALES_LY       := 0;
    V_SALES_LY_CSHQ  := 0;
    V_CSHQ_YES       := 'N';
    V_DC_YES         := 'N';
    V_SALES_COM      := 0;
    V_TARGET_COM     := 0;

    -- 查询 （级别 3）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N' THEN
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_CRS
       WHERE IMONTH = V_MONTH
         AND W3 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS  := 3;
        V_FINDWWID := 'Y';
        V_DC_YES   := 'Y';
        SELECT NVL(SUM(SALES), 0),
               NVL(SUM(TARGET), 0),
               SUM(SALES_LY)
          INTO V_SALES, V_TARGET,V_SALES_LY
          FROM INCENTIVE_RT_SALES1_CRS
         WHERE IMONTH = V_MONTH
           AND W3 = V_WWID;

       SELECT AVG(T.POP)
         INTO V_POP_DC
         FROM INCENTIVE_HAND_RT_DS_POP T, ODS_RT_ORG_CRS_HIER T2
        WHERE T.IMONTH = T2.IMONTH
          AND T.DID = T2.HID
          AND T2.IMONTH= V_MONTH
          AND W3 = V_WWID;

        --HR信息补充
        UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_DC T
             WHERE T.IMONTH = V_MONTH
               AND W3 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    -- 查询 （级别 4）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N' THEN
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_CRS
       WHERE IMONTH = V_MONTH
         AND W4 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS := 4;
        V_FINDWWID := 'Y';
        V_DC_YES   := 'Y';
        SELECT NVL(SUM(SALES), 0),
               NVL(SUM(TARGET), 0),
               SUM(SALES_LY)
          INTO V_SALES, V_TARGET,V_SALES_LY
          FROM INCENTIVE_RT_SALES1_CRS
         WHERE IMONTH = V_MONTH
           AND W4 = V_WWID;

       SELECT AVG(T.POP)
         INTO V_POP_DC
         FROM INCENTIVE_HAND_RT_DS_POP T, ODS_RT_ORG_CRS_HIER T2
        WHERE T.IMONTH = T2.IMONTH
          AND T.DID = T2.HID
          AND T2.IMONTH= V_MONTH
          AND W4 = V_WWID;

        --HR信息补充
        UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_DC T
             WHERE T.IMONTH = V_MONTH
               AND W4 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    -- 查询 （级别 5）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N' THEN
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_DC
       WHERE IMONTH = V_MONTH
         AND W5 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS := 5;
        V_FINDWWID := 'Y';
        V_DC_YES   := 'Y';
        SELECT NVL(SUM(SALES), 0),
               NVL(SUM(TARGET), 0),
               SUM(SALES_LY)
          INTO V_SALES, V_TARGET,V_SALES_LY
          FROM INCENTIVE_RT_SALES1_DC
         WHERE IMONTH = V_MONTH
           AND W5 = V_WWID;

        SELECT AVG(T.POP)
         INTO V_POP_DC
         FROM INCENTIVE_HAND_RT_DS_POP T, ODS_RT_OOD_HIER03 T2
        WHERE T.IMONTH = T2.IMONTH
          AND T.DID = T2.HID
          AND T2.IMONTH= V_MONTH
          AND W5 = V_WWID;

        --HR信息补充
        UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_DC T
             WHERE T.IMONTH = V_MONTH
               AND W5 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    -- 查询 DSM （级别 6）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N' THEN
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_DC
       WHERE IMONTH = V_MONTH
         AND W6 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS := 6;
        V_FINDWWID := 'Y';
        V_DC_YES   := 'Y';
        SELECT NVL(SUM(SALES), 0),
               NVL(SUM(TARGET), 0),
               SUM(SALES_LY)
          INTO V_SALES, V_TARGET,V_SALES_LY
          FROM INCENTIVE_RT_SALES1_DC
         WHERE IMONTH = V_MONTH
           AND W6 = V_WWID;

        SELECT AVG(T.POP)
         INTO V_POP_DC
         FROM INCENTIVE_HAND_RT_DS_POP T, ODS_RT_OOD_HIER03 T2
        WHERE T.IMONTH = T2.IMONTH
          AND T.DID = T2.HID
          AND T2.IMONTH= V_MONTH
          AND W6 = V_WWID;

        --HR信息补充
        UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_DC T
             WHERE T.IMONTH = V_MONTH
               AND W6 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    -- 查询 HS （级别 7）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N' THEN
      --如果在 DSM 架构中没找到，则在HS架构中继续找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_DC
       WHERE IMONTH = V_MONTH
         AND W7 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS  := 7;
        V_DC_YES   := 'Y';
        SELECT NVL(SUM(SALES), 0),
               NVL(SUM(TARGET), 0),
               SUM(SALES_LY)
          INTO V_SALES, V_TARGET,V_SALES_LY
          FROM INCENTIVE_RT_SALES1_DC
         WHERE IMONTH = V_MONTH
           AND W7 = V_WWID;

        SELECT AVG(T.POP)
         INTO V_POP_DC
         FROM INCENTIVE_HAND_RT_DS_POP T, ODS_RT_OOD_HIER03 T2
        WHERE T.IMONTH = T2.IMONTH
          AND T.DID = T2.HID
          AND T2.IMONTH= V_MONTH
          AND REPLACE(W7,',') = V_WWID;

        --HR信息补充
        UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_DC T
             WHERE T.IMONTH = V_MONTH
               AND W7 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    --在CSHQ里查找
    --查询级别3
    V_FINDWWID := 'N';
    IF V_FINDWWID = 'N' THEN-- AND I_POSITION='RKAM',
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_CSHQ
       WHERE IMONTH = V_MONTH
         AND W3 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS := 3;
        V_FINDWWID := 'Y';
        V_CSHQ_YES := 'Y';
        SELECT NVL(SUM(SALES_CSHQ), 0),
               NVL(SUM(TARGET_CSHQ), 0),
               SUM(SALES_LY_CSHQ)
          INTO V_SALES_CSHQ, V_TARGET_CSHQ,V_SALES_LY_CSHQ
          FROM INCENTIVE_RT_SALES1_CSHQ
         WHERE IMONTH = V_MONTH
           AND W3 = V_WWID;

        IF V_DC_YES ='N' THEN

          UPDATE INCENTIVE_RT_HRDATA A
             SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
             (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
                FROM INCENTIVE_RT_SALES1_CSHQ T
               WHERE T.IMONTH = V_MONTH
                 AND w3 = V_WWID)
           WHERE A.WWID = V_WWID
             AND A.IMONTH = V_MONTH;
         END IF;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    --查询级别4
    IF V_FINDWWID = 'N'  THEN
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_CSHQ
       WHERE IMONTH = V_MONTH
         AND W4 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS  := 4;
        V_FINDWWID := 'Y';
        V_CSHQ_YES := 'Y';
        SELECT NVL(SUM(SALES_CSHQ), 0),
               NVL(SUM(TARGET_CSHQ), 0),
               SUM(SALES_LY_CSHQ)
          INTO V_SALES_CSHQ, V_TARGET_CSHQ,V_SALES_LY_CSHQ
          FROM INCENTIVE_RT_SALES1_CSHQ
         WHERE IMONTH = V_MONTH
           AND W4 = V_WWID;
        IF V_DC_YES ='N' THEN

         UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_CSHQ T
             WHERE T.IMONTH = V_MONTH
               AND w4 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
         END IF;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    -- 查询 （级别 5）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N'  THEN
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_CSHQ
       WHERE IMONTH = V_MONTH
         AND W5 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_WLEVELS := 5;
        V_FINDWWID := 'Y';
        V_CSHQ_YES := 'Y';
        SELECT NVL(SUM(SALES_CSHQ), 0),
               NVL(SUM(TARGET_CSHQ), 0),
               SUM(SALES_LY_CSHQ)
          INTO V_SALES_CSHQ, V_TARGET_CSHQ,V_SALES_LY_CSHQ
          FROM INCENTIVE_RT_SALES1_CSHQ
         WHERE IMONTH = V_MONTH
           AND W5 = V_WWID;
        IF V_DC_YES ='N' THEN

           UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_CSHQ T
             WHERE T.IMONTH = V_MONTH
               AND w5 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
         END IF;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    -- 查询 DSM （级别 6）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N'  THEN
      --首先在 DSM 架构中找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_CSHQ
       WHERE IMONTH = V_MONTH
         AND W6 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_FINDWWID := 'Y';
        V_CSHQ_YES := 'Y';
        SELECT NVL(SUM(SALES_CSHQ), 0),
               NVL(SUM(TARGET_CSHQ), 0),
               SUM(SALES_LY_CSHQ)
          INTO V_SALES_CSHQ, V_TARGET_CSHQ,V_SALES_LY_CSHQ
          FROM INCENTIVE_RT_SALES1_CSHQ
         WHERE IMONTH = V_MONTH
           AND W6 = V_WWID;
        IF V_DC_YES ='N' THEN

          V_WLEVELS  := 6;
          SELECT AVG(T.POP)
            INTO V_POP_DC
            FROM INCENTIVE_HAND_RT_DS_POP T, INC_RT_OOD_CSHQ_HIER02 T2
           WHERE T.IMONTH = T2.IMONTH
             AND T.DID = T2.DID
             AND T2.IMONTH= V_MONTH
             AND W6 = V_WWID;

           UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_CSHQ T
             WHERE T.IMONTH = V_MONTH
               AND w6 = V_WWID)
         WHERE A.WWID = V_WWID
           AND A.IMONTH = V_MONTH;
         END IF;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    -- 查询 HS （级别 7）是否有该 wwid ，有则取该月架构数据  关键字段：V_MONTH,V_WWID
    IF V_FINDWWID = 'N' THEN
      --如果在 DSM 架构中没找到，则在HS架构中继续找
      V_ROW_NUM := 0;
      SELECT COUNT(1)
        INTO V_ROW_NUM
        FROM INCENTIVE_RT_SALES1_CSHQ
       WHERE IMONTH = V_MONTH
         AND W7 = V_WWID;
      IF V_ROW_NUM > 0 THEN
        -- 在架构中找到
        V_FINDWWID := 'Y';
        V_CSHQ_YES := 'Y';
        SELECT NVL(SUM(SALES_CSHQ), 0),
               NVL(SUM(TARGET_CSHQ), 0),
               SUM(SALES_LY_CSHQ)
          INTO V_SALES_CSHQ, V_TARGET_CSHQ,V_SALES_LY_CSHQ
          FROM INCENTIVE_RT_SALES1_CSHQ
         WHERE IMONTH = V_MONTH
           AND W7 = V_WWID;
        IF V_DC_YES ='N' THEN
          V_WLEVELS := 7;

         --POP CSHQ补充
         SELECT AVG(T.POP)
            INTO V_POP_DC
            FROM INCENTIVE_HAND_RT_DS_POP T, INC_RT_OOD_CSHQ_HIER02 T2
           WHERE T.IMONTH = T2.IMONTH
             AND T.DID = T2.DID
             AND T2.IMONTH= V_MONTH
             AND REPLACE(W7,',') = V_WWID;

          UPDATE INCENTIVE_RT_HRDATA A
           SET (WLEVEL,H2,W2,N2,H3, W3, N3, H4, W4, N4, H5, W5, N5, H6, W6, N6, H7, W7, N7, HIER7) =
           (SELECT V_WLEVELS,MAX(H2),MAX(W2),MAX(N2),MAX(H3),MAX(W3),MAX(N3),MAX(H4),MAX(W4),MAX(N4),MAX(H5),MAX(W5),MAX(N5),MAX(H6),MAX(W6),MAX(N6),MAX(H7),MAX(W7),MAX(N7),MAX(HIER7)
              FROM INCENTIVE_RT_SALES1_CSHQ T
             WHERE T.IMONTH = V_MONTH
               AND w7 = V_WWID)
          WHERE A.WWID = V_WWID
            AND A.IMONTH = V_MONTH;
         END IF;
      END IF; --if V_ROW_NUM > 0 then  -- 在架构中找到
    END IF;

    CASE
      WHEN I_POSITION = 'SDSR' OR I_POSITION = 'DSR'  THEN
        V_TYPE := 'A';
      WHEN I_POSITION = 'SSR' THEN
        V_TYPE := 'B';
      WHEN I_POSITION = 'KAE' OR I_POSITION ='KAS' THEN
        V_TYPE := 'C';
      WHEN (I_POSITION ='TS' OR I_POSITION='TM' OR I_POSITION = 'KAM') AND V_CSHQ_YES='Y' THEN
        V_TYPE := 'D';
      WHEN (I_POSITION ='TS' OR I_POSITION='TM' OR I_POSITION = 'KAM') AND V_CSHQ_YES='N'  THEN
        V_TYPE := 'E';
      WHEN I_POSITION ='DSM' THEN
        V_TYPE := 'F';
      WHEN I_POSITION ='RSM' THEN
        V_TYPE := 'G';
      WHEN I_POSITION ='RKAM' THEN
        V_TYPE := 'H';
      ELSE V_TYPE :='其他';
    END CASE;

    /*创建框架*/
    IF V_CSHQ_YES = 'Y' OR V_DC_YES = 'Y' THEN
       --产品版本
       SELECT T.BAKVERSION
         INTO V_BAKVERSION
         FROM INCENTIVE_VERSION_PRODUCT T
        WHERE V_MONTH >= T.STARTDATE
          AND V_MONTH <= T.ENDDATE;

      IF  I_POSITION <>'RSM' THEN
        --商业数据
        SELECT SUM(T2.SALES), SUM(T2.TARGET)
          INTO V_SALES_COM, V_TARGET_COM
          FROM INCENTIVE_HP_COMMERCIAL T2
         WHERE T2.BRANDID IN (SELECT DISTINCT T.BRANDCODE
                                FROM INCENTIVE_BU_PRODUCT T
                               WHERE T.BU = 'OTC'
                                  AND T.BAKVERSION = V_BAKVERSION )
           AND T2.IMONTH = V_MONTH;
      ELSE
        V_SALES_COM  :=0;
        V_TARGET_COM :=0;
      END IF;
      -- 如果在该月份找到 wwid 则插入一条记录
      INSERT INTO INCENTIVE_RT_SALES2
      VALUES
        (V_MONTH,
         I_Q,
         V_WWID,
         V_WWNAME,
         'OTC CRS',
         I_POSITION,
         V_WLEVELS,
         V_TYPE,
         V_CSHQ_YES,
         0,
         V_POP_DC,
         0,
         V_SALES,
         V_TARGET,
         V_SALES_CSHQ,
         V_TARGET_CSHQ,
         V_SALES_COM,
         V_TARGET_COM,
         0,
         0,
         V_SALES_LY,
         V_SALES_LY_CSHQ);
      COMMIT;
    END IF;
    FETCH CUR_1
      INTO V_MONTH, V_WWID, V_WWNAME;
  END LOOP;
  CLOSE CUR_1;


  IF I_POSITION = 'RSM' THEN
    UPDATE INCENTIVE_RT_SALES2 T
       SET (T.SALES_COM, T.TARGET_COM) =
           (SELECT T2.SALES_COM, T2.TARGET_COM
              FROM INCENTIVE_RT_RSM_COMMERCIAL T2
             WHERE T.WWID = T2.WWID
               AND T.IMONTH = T2.IMONTH
               AND T2.Q = I_Q)
     WHERE EXISTS (SELECT 1
              FROM INCENTIVE_RT_RSM_COMMERCIAL T2
             WHERE T.WWID = T2.WWID
               AND T.IMONTH = T2.IMONTH
               AND T2.Q = I_Q);
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
