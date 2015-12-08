CREATE OR REPLACE PROCEDURE P_INC2014_RT_W7_SALE3_MON(I_MONTH VARCHAR2,I_POSITION VARCHAR2) IS
  /*****************************************
  --���ܣ���ת��
  --ʱ�䣺2013-01-14
  --���ߣ�̷��
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);
  V_Q          VARCHAR2(20);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --��ȡ��־ID
  V_PROC_NAME  := 'P_INC2014_RT_W7_SALE3_MON'; --������
  V_PARM_VALUS := I_MONTH; --�����������
  --������־
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --��������
  -----------------------------------------------------------------------
  V_Q := SUBSTR(I_MONTH, 1, 4) || 'Q' ||
         TO_CHAR(TO_DATE(I_MONTH, 'YYYY-MM'), 'Q');

  --�������
  EXECUTE IMMEDIATE 'TRUNCATE TABLE INCENTIVE_RT_SALES2_YTD_TP01';

  DELETE FROM INCENTIVE_RT_SALES2_YTD T WHERE T.IMONTH = I_MONTH AND T.POSITION=I_POSITION;

  INSERT INTO INCENTIVE_RT_SALES2_YTD_TP01
    SELECT I_MONTH,
           V_Q,
           T.HIER7,
           MAX(T.H7),
           COUNT(1),
           'OTC CRS',
           I_POSITION,
           0,
           SUM(T.SALES),
           SUM(T.TARGET),
           0,
           0,
           0,
           0,
           SUM(T.SALES_NEW),
           SUM(T.TARGET_NEW),
           SUM(T.SALES_LY),
           0,
           0
      FROM INCENTIVE_RT_SALES1_DC T
     WHERE T.IMONTH <= I_MONTH
       AND SUBSTR(T.IMONTH, 1, 4) = SUBSTR(I_MONTH, 1, 4)
     GROUP BY T.HIER7;

  INSERT INTO INCENTIVE_RT_SALES2_YTD
    SELECT IMONTH,
           Q,
           WWID,
           WWNAME,
           MONTH_NUM,
           COVER_NUM,
           BU,
           POSITION,
           0,
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
           RANK() OVER(PARTITION BY IMONTH, BU, POSITION ORDER BY((SALES - SALES_LY) / MONTH_NUM) DESC) RK_GROW,
           RANK() OVER(PARTITION BY IMONTH, BU, POSITION ORDER BY((SALES - SALES_LY) / MONTH_NUM) DESC) / COUNT(1) OVER(PARTITION BY IMONTH, BU, POSITION) ACH_GROW
      FROM INCENTIVE_RT_SALES2_YTD_TP01 T;

  -----------------------------------------------------------------------
  --���̽���
  COMMIT;
  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '�ɹ�', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, 'ʧ��', SQLERRM);

END;
/
