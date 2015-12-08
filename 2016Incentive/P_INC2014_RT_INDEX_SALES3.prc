CREATE OR REPLACE PROCEDURE P_INC2014_RT_INDEX_SALES3(I_Q        VARCHAR2,
                                                      I_POSITION VARCHAR2) IS
  /*****************************************
  --���ܣ���ת��
  --ʱ�䣺2013-01-14
  --���ߣ�̷��
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --��ȡ��־ID
  V_PROC_NAME  := 'P_INC2014_RT_INDEX_SALES3'; --������
  V_PARM_VALUS := I_Q || ',' || I_POSITION; --�����������
  --������־
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --��������
  -----------------------------------------------------------------------
  --�������
  DELETE FROM INC2014_RT_INDEX_SALES3 T
   WHERE T.Q = I_Q
     AND T.POSITION = I_POSITION;

  INSERT INTO INC2014_RT_INDEX_SALES3
    SELECT Q,
           WWID,
           WWNAME,
           BU,
           POSITION,
           MONTH_NUM,
           COVER_NUM,
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
                   T.POSITION,
                   SUM(COUNT(1)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY Q) MONTH_NUM,
                   SUM(COUNT(DISTINCT T2.WWID)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY Q) COVER_NUM,
                   SUM(SUM(T.SALES)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY Q) SALES,
                   SUM(SUM(T.TARGET)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY Q) TARGET,
                   SUM(SUM(T.SALES_LY)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY Q) SALES_LY,
                   SUM(SUM(T.SALES_CSHQ)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY Q) SALES_CSHQ,
                   SUM(SUM(T.TARGET_CSHQ)) OVER(PARTITION BY T.WWID, BU, POSITION, SUBSTR(T.Q, 1, 4) ORDER BY Q) TARGET_CSHQ,
                   AVG(T.INCENTIVE / T.W8_NUM) INCENTIVE_AVG
              FROM INC2014_RT_INDEX_SALES2 T,
                   (SELECT A1.WWID,A1.IMONTH
                      FROM INCENTIVE_HAND_RT_COVERAGE_M A1
                     WHERE A1.COVERAGE = 'N') T2
             WHERE T.POSITION = I_POSITION
               AND T.IMONTH = T2.IMONTH(+)
               AND T.WWID = T2.WWID(+)
             GROUP BY T.Q, T.WWID, T.BU, T.POSITION) S1
     WHERE S1.Q = I_Q;

  -----------------------------------------------------------------------
  --���̽���
  COMMIT;

  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '�ɹ�', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, 'ʧ��', SQLERRM);

END;
/
