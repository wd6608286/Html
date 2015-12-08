CREATE OR REPLACE PROCEDURE P_INC2015_RT_INDEX2_SALES2(I_Q        VARCHAR2,
                                                       I_POSITION VARCHAR2) IS
  /*****************************************
  --���ܣ���ת��
  --ʱ�䣺2013-01-14
  --���ߣ�̷��
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);
  V_MONTH1     VARCHAR2(20);
  V_MONTH2     VARCHAR2(20);
  V_MONTH3     VARCHAR2(20);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --��ȡ��־ID
  V_PROC_NAME  := 'P_INC2014_RT_INDEX2_SALES2'; --������
  V_PARM_VALUS := I_Q || ',' || I_POSITION; --�����������
  --������־
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --��������
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

  --�������
  --EXECUTE IMMEDIATE  'TRUNCATE TABLE INC2014_RT_INDEX_SALES2_TP01'
  
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
           (SELECT A1.IMONTH,
                   A1.WWID,
                   COUNT(DISTINCT SUBORDINATE) W8_NUM,
                   SUM(A1.INCENTIVE) INCENTIVE
              FROM (SELECT DISTINCT T3.IMONTH,
                                    T3.WWID,
                                    T2.POSITION,
                                    T2.WWID SUBORDINATE,
                                    INCENTIVE
                      FROM INCENTIVE_RT_SALES1_DC  T,
                           INC2014_RT_INDEX_SALES4 T2,
                           INCENTIVE_RT_HRDATA     T3,
                           INCENTIVE_HAND_RT_TMGROUP  T4
                     WHERE T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
                       AND T.IMONTH = T3.IMONTH
                       AND T.W4 = T3.WWID
                       AND T3.WLEVEL = 4
                       AND T3.POSITION = I_POSITION
                       AND T.IMONTH = T4.IMONTH
                       AND T.H6 = T4.H6
                       AND T4.TMW6 = T2.WWID
                       AND T2.Q = I_Q
                       AND T2.POSITION LIKE '%W6'
                       UNION 
                       SELECT DISTINCT T3.IMONTH,
                                    T3.WWID,
                                    T2.POSITION,
                                    T2.WWID SUBORDINATE,
                                    INCENTIVE
                      FROM INCENTIVE_RT_SALES1_CSHQ  T,
                           INC2014_RT_SALES4 T2,
                           INCENTIVE_RT_HRDATA     T3
                     WHERE T.IMONTH IN (V_MONTH1, V_MONTH2, V_MONTH3)
                       AND T.IMONTH = T3.IMONTH
                       AND T.W4 = T3.WWID
                       AND T3.WLEVEL = 4
                       AND T3.POSITION = I_POSITION
                       AND T2.Q = I_Q
                       AND T2.POSITION LIKE '%W6'
                       AND T.H6=T2.WWID) A1
             GROUP BY A1.IMONTH, A1.WWID) S2
     WHERE S1.IMONTH = S2.IMONTH
       AND S1.WWID = S2.WWID;
       
  -----------------------------------------------------------------------
  --���̽���
  COMMIT;

  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '�ɹ�', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, 'ʧ��', SQLERRM);

END;
/
