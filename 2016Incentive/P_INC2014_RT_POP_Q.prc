CREATE OR REPLACE PROCEDURE P_INC2014_RT_POP_Q(I_Q VARCHAR2) IS
  /*****************************************
  --���ܣ�RETAIL ����-�������������� AM,AS,AE
  --ʱ�䣺2013-01-28
  --���ߣ�̷��
  ******************************************/

  V_LOG_ID     NUMBER;
  V_PROC_NAME  VARCHAR2(100);
  V_PARM_VALUS VARCHAR2(100);

BEGIN

  V_LOG_ID     := F_INCENTIVE_LOG_ID; --��ȡ��־ID
  V_PROC_NAME  := 'P_INC2014_RT_POP_Q'; --������
  V_PARM_VALUS := I_Q; --�����������
  --������־
  P_INCENTIVE_LOG_INFO_INSERT(V_LOG_ID, V_PROC_NAME, V_PARM_VALUS);

  --��������
  -----------------------------------------------------------------------
  DELETE INCENTIVE_RT_POP_Q T WHERE T.Q = I_Q;

  INSERT INTO INCENTIVE_RT_POP_Q
    SELECT T.Q,
           T.WWID,
           T.WWNAME,
           T.BU,
           T.POSITION,
           T.MONTH_NUM,
           T.POP,
           T3.BASE BASE_POP,
           T3.BASE * T2.RATIO * MONTH_NUM / 3 * NVL(T4.TERMINATION, 1) INC_POP
      FROM (SELECT T.Q,
                   T.WWID,
                   T.WWNAME,
                   T.BU,
                   T.POSITION,
                   COUNT(1) MONTH_NUM,
                   ROUND(AVG(POP)) POP
              FROM INCENTIVE_RT_SALES2 T
             GROUP BY T.Q, T.WWID, T.WWNAME, T.BU, T.POSITION) T,
           INCENTIVE_BASE_POP_RATIO_Q T2,
           INCENTIVE_BASE_INC_PROCESS_Q T3,
           INCENTIVE_HR_RATIO T4
     WHERE T.POP >= T2.SCORE1
       AND T.POP < T2.SCORE2
       AND T2.POP_TYPE = 'POP'
       AND T3.BU='OTC CRS'
       AND T2.IYEAR = SUBSTR(I_Q, 1, 4)
       AND T.Q = I_Q
       and T.Q = T2.Q
       and T.Q = T3.Q
       AND T.POSITION = T3.POSITION2
       AND T2.IYEAR = T3.IYEAR
       AND T.Q = T4.Q(+)
       AND T.WWID = T4.WWID(+);

  -----------------------------------------------------------------------
  --���̽���
  COMMIT;
  P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 1, '�ɹ�', '');
EXCEPTION
  WHEN OTHERS THEN
    P_INCENTIVE_LOG_INFO_UPDATE(V_LOG_ID, 0, 'ʧ��', SQLERRM);

END;
/
