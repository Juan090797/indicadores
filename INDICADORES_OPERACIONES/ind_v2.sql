SELECT NUME_ORDEN,CODI_ADUAN,CODI_REGI,CODI_TDESP,NVL(T_DESPACHO,'SIN T_DESPACHO') AS T_DESPACHO,ANO_PRESE,CLIENTE_RAZON_SOCIAL,FEC_USUA_CREA,
NVL(TO_CHAR(FEC_DESPACHO,'DD/MM/YYYY'),'NO HAY FECHA DE PROGRAMACION') FECHA_DESPACHO,
HORARIO_DESPACHO,
NVL(TO_CHAR(FEC_DESPACHO,'MONTH'),'NO HAY FECHA DE PROGRAMACION') AS MES_FECHA_DESPACHO,
FEC_RETIRO,DOC_COMPLETA,
NVL(TO_CHAR(FEC_DOC_COMPLETA,'DD/MM/YYYY HH24:MI:SS'),'NO HAY FECHA DE DOCUMENTACION') AS FECHA_DOC_COMPLETA,
NVL(TO_CHAR(FEC_DOC_COMPLETA,'MONTH'),'NO HAY FECHA DE DOCUMENTACION') AS MES_DOC_COMPLETA,
COD_TERMINAL,NOMBRE_ALMACEN,TIPO_DIRECCIONAMIENTO,
DIA_PROGRAMACION AS DIA_PROGRAMAC,
CANT_FERIADO,
CASE WHEN FEC_DESPACHO IS NOT NULL THEN TO_CHAR(F_PROG_CORREGIDA(1,FEC_DESPACHO),'DD/MM/YYYY')
     ELSE 'NO HAY FECHA DE PROGRAMACION'
END FECHA_PROG_CORREGIDA,
CASE WHEN DIA_FECHA_COM = 'SÁBADO   ' AND TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI:SS') > '12:00:00'  THEN 'VERDADERO'
     ELSE 'FALSO'
END SABADO_MAS_DE_LAS_12,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN TO_CHAR(F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA),'DD/MM/YYYY') 
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END FECHA_DOC_CORREGIDA,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN DIA_FECHA_COM
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END DIA_FECHA_DOC_COM,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN MES_FECHA_COM
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END MES_FECHA_DOC_COM,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN MES_FECHA_COM
     ELSE TO_CHAR(FEC_RETIRO,'MONTH')
END MES_FINAL,
CASE WHEN TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) > TRUNC(F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA)) THEN TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) - TRUNC(F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA))
     ELSE 0
END DIFERENCIA_DIAS,
CASE WHEN (CODI_ADUAN = '118' AND NOMBRE_ALMACEN ='DP WORLD CALLAO S.R.L.') OR (CODI_ADUAN = '118' AND NOMBRE_ALMACEN ='APM TERMINALS CALLAO S.A.') OR CODI_ADUAN <> '118' THEN 'NO APLICA'
     ELSE 'APLICA'
END VERIFICADOR2,
F_INDICADOR2_MAYRA_JM(FEC_DESPACHO,FEC_DOC_COMPLETA) AS INDICADOR2
FROM(SELECT O.NUME_ORDEN,O.CODI_ADUAN,O.CODI_REGI,O.CODI_TDESP,
    (SELECT DESCRIPCION  FROM TIPO_ANTICIPADO WHERE ADUANA = O.CODI_ADUAN  AND CODIGO = O.TIPO_DESPACHO) AS T_DESPACHO,
    O.ANO_PRESE,
    (SELECT RASON_SOCIAL FROM CLIENTES WHERE CODIGOANT = O.CODI_CLIE AND ROWNUM = 1) CLIENTE_RAZON_SOCIAL,
    A.FEC_USUA_CREA,A.FEC_DESPACHO,
    (SELECT DES_HORARIO FROM HORARIO WHERE COD_HORARIO = A.hor_prog) HORARIO_DESPACHO,
    O.FEC_RETIRO,A.DOC_COMPLETA,
    A.FEC_DOC_COMPLETA,
    O.COD_TERMINAL,O.NOMBRE_ALMACEN,
    (SELECT TIPO_DIRECCIONAMIENTO FROM SOLICITUD_VB LEFT JOIN SOLICITUD_VB_ORDEN S ON (S.ANIO_SOLICITUD = SOLICITUD_VB.ANIO_SOLICITUD AND S.NRO_SOLICITUD = SOLICITUD_VB.NRO_SOLICITUD AND S.ORDEN_MADRE = 1) WHERE (SOLICITUD_VB.EMPRESA = '001') AND (S.ANO_PRESE = A.ANO_PRESE) AND (S.NUME_ORDEN = O.NUME_ORDEN) AND ROWNUM = 1) TIPO_DIRECCIONAMIENTO,
    CASE WHEN A.FEC_DOC_COMPLETA IS NOT NULL THEN  TO_CHAR(A.FEC_DESPACHO,'DAY')
         ELSE 'NO HAY FECHA DE PROGRAMACION'
     END DIA_PROGRAMACION,
    F_DIA_FERIADO(A.FEC_DESPACHO) CANT_FERIADO,
    TO_CHAR(A.FEC_DOC_COMPLETA,'DAY') DIA_FECHA_COM,
    TO_CHAR(A.FEC_DOC_COMPLETA,'MONTH') MES_FECHA_COM
    FROM ORDEN O 
    INNER JOIN PROG_DESPACHO_CAB A ON (O.EMPRESA = A.EMPRESA AND O.NUME_ORDEN = A.NUME_ORDEN AND O.CODI_REGI = A.CODI_REGI AND O.CODI_ADUAN = A.CODI_ADUAN AND O.ANO_PRESE = A.ANO_PRESE)
    WHERE TRUNC(O.FEC_RETIRO) BETWEEN TRUNC(TO_DATE('01/01/2022')) AND TRUNC(TO_DATE('31/12/2022')))
ORDER BY NUME_ORDEN ASC;

------------INDICADOR2--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT NUME_ORDEN,CODI_ADUAN,CODI_REGI,CODI_TDESP,NVL(T_DESPACHO,'SIN T_DESPACHO') AS T_DESPACHO,ANO_PRESE,CLIENTE_RAZON_SOCIAL,FEC_USUA_CREA,
NVL(TO_CHAR(FEC_DESPACHO,'DD/MM/YYYY'),'NO HAY FECHA DE PROGRAMACION') FECHA_DESPACHO,
HORARIO_DESPACHO,
NVL(TO_CHAR(FEC_DESPACHO,'MONTH'),'NO HAY FECHA DE PROGRAMACION') AS MES_FECHA_DESPACHO,
FEC_RETIRO,DOC_COMPLETA,
NVL(TO_CHAR(FEC_DOC_COMPLETA,'DD/MM/YYYY HH24:MI:SS'),'NO HAY FECHA DE DOCUMENTACION') AS FECHA_DOC_COMPLETA,
NVL(TO_CHAR(FEC_DOC_COMPLETA,'MONTH'),'NO HAY FECHA DE DOCUMENTACION') AS MES_DOC_COMPLETA,
COD_TERMINAL,NOMBRE_ALMACEN,TIPO_DIRECCIONAMIENTO,
DIA_PROGRAMACION AS DIA_PROGRAMAC,
CANT_FERIADO,
CASE WHEN FEC_DESPACHO IS NOT NULL THEN TO_CHAR(F_PROG_CORREGIDA(1,FEC_DESPACHO),'DD/MM/YYYY')
     ELSE 'NO HAY FECHA DE PROGRAMACION'
END FECHA_PROG_CORREGIDA,
CASE WHEN DIA_FECHA_COM = 'SÁBADO   ' AND TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI:SS') > '12:00:00'  THEN 'VERDADERO'
     ELSE 'FALSO'
END SABADO_MAS_DE_LAS_12,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN TO_CHAR(F_PROG_CORREGIDA(3,FEC_DOC_COMPLETA),'DD/MM/YYYY') 
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END FECHA_DOC_CORREGIDA,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN DIA_FECHA_COM
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END DIA_FECHA_DOC_COM,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN MES_FECHA_COM
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END MES_FECHA_DOC_COM,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN MES_FECHA_COM
     ELSE TO_CHAR(FEC_RETIRO,'MONTH')
END MES_FINAL,
CASE WHEN TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) > TRUNC(F_PROG_CORREGIDA(3,FEC_DOC_COMPLETA)) THEN TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) - TRUNC(F_PROG_CORREGIDA(3,FEC_DOC_COMPLETA))
     ELSE 0
END DIFERENCIA_DIAS,
CASE WHEN (CODI_ADUAN = '118' AND NOMBRE_ALMACEN ='DP WORLD CALLAO S.R.L.') OR (CODI_ADUAN = '118' AND NOMBRE_ALMACEN ='APM TERMINALS CALLAO S.A.') THEN 'APLICA'
     ELSE 'NO APLICA'
END VERIFICADOR2,
F_INDICADOR1_MAYRA_JM(FEC_DESPACHO,FEC_DOC_COMPLETA) AS INDICADOR2
FROM(SELECT O.NUME_ORDEN,O.CODI_ADUAN,O.CODI_REGI,O.CODI_TDESP,
    (SELECT DESCRIPCION  FROM TIPO_ANTICIPADO WHERE ADUANA = O.CODI_ADUAN  AND CODIGO = O.TIPO_DESPACHO) AS T_DESPACHO,
    O.ANO_PRESE,
    (SELECT RASON_SOCIAL FROM CLIENTES WHERE CODIGOANT = O.CODI_CLIE AND ROWNUM = 1) CLIENTE_RAZON_SOCIAL,
    A.FEC_USUA_CREA,A.FEC_DESPACHO,
    (SELECT DES_HORARIO FROM HORARIO WHERE COD_HORARIO = A.hor_prog) HORARIO_DESPACHO,
    O.FEC_RETIRO,A.DOC_COMPLETA,
    A.FEC_DOC_COMPLETA,
    O.COD_TERMINAL,O.NOMBRE_ALMACEN,
    (SELECT TIPO_DIRECCIONAMIENTO FROM SOLICITUD_VB LEFT JOIN SOLICITUD_VB_ORDEN S ON (S.ANIO_SOLICITUD = SOLICITUD_VB.ANIO_SOLICITUD AND S.NRO_SOLICITUD = SOLICITUD_VB.NRO_SOLICITUD AND S.ORDEN_MADRE = 1) WHERE (SOLICITUD_VB.EMPRESA = '001') AND (S.ANO_PRESE = A.ANO_PRESE) AND (S.NUME_ORDEN = O.NUME_ORDEN) AND ROWNUM = 1) TIPO_DIRECCIONAMIENTO,
    CASE WHEN A.FEC_DOC_COMPLETA IS NOT NULL THEN  TO_CHAR(A.FEC_DESPACHO,'DAY')
         ELSE 'NO HAY FECHA DE PROGRAMACION'
     END DIA_PROGRAMACION,
    F_DIA_FERIADO(A.FEC_DESPACHO) CANT_FERIADO,
    TO_CHAR(A.FEC_DOC_COMPLETA,'DAY') DIA_FECHA_COM,
    TO_CHAR(A.FEC_DOC_COMPLETA,'MONTH') MES_FECHA_COM
    FROM ORDEN O 
    INNER JOIN PROG_DESPACHO_CAB A ON (O.EMPRESA = A.EMPRESA AND O.NUME_ORDEN = A.NUME_ORDEN AND O.CODI_REGI = A.CODI_REGI AND O.CODI_ADUAN = A.CODI_ADUAN AND O.ANO_PRESE = A.ANO_PRESE)
    WHERE TRUNC(O.FEC_RETIRO) BETWEEN TRUNC(TO_DATE('01/01/2022')) AND TRUNC(TO_DATE('31/12/2022')) AND O.ANO_PRESE = '2022')
ORDER BY NUME_ORDEN ASC;


------------INDICADOR3--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW VISTA_INDICADOR3_MAYRA AS 
SELECT NUME_ORDEN,CODI_ADUAN,CODI_REGI,CODI_TDESP,NVL(T_DESPACHO,'SIN T_DESPACHO') AS T_DESPACHO,ANO_PRESE,CLIENTE_RAZON_SOCIAL,FEC_USUA_CREA,
NVL(TO_CHAR(FEC_DESPACHO,'DD/MM/YYYY'),'NO HAY FECHA DE PROGRAMACION') FECHA_DESPACHO,
HORARIO_DESPACHO,
NVL(TO_CHAR(FEC_DESPACHO,'MONTH'),'NO HAY FECHA DE PROGRAMACION') AS MES_FECHA_DESPACHO,
FEC_RETIRO,DOC_COMPLETA,
NVL(TO_CHAR(FEC_DOC_COMPLETA,'DD/MM/YYYY HH24:MI:SS'),'NO HAY FECHA DE DOCUMENTACION') AS FECHA_DOC_COMPLETA,
NVL(TO_CHAR(FEC_DOC_COMPLETA,'MONTH'),'NO HAY FECHA DE DOCUMENTACION') AS MES_DOC_COMPLETA,
COD_TERMINAL,NOMBRE_ALMACEN,TIPO_DIRECCIONAMIENTO,
DIA_PROGRAMACION AS DIA_PROGRAMAC,
CANT_FERIADO,
CASE WHEN FEC_DESPACHO IS NOT NULL THEN TO_CHAR(F_PROG_CORREGIDA(1,FEC_DESPACHO),'DD/MM/YYYY')
     ELSE 'NO HAY FECHA DE PROGRAMACION'
END FECHA_PROG_CORREGIDA,
RPAD(SUBSTR(HORARIO_DESPACHO,1,5),8,':00') HORA_PROGRA,
HORA_A,
TO_CHAR((TO_DATE(HORA_A,'HH24:MI:SS')+INTERVAL '2' HOUR),'HH24:MI:SS') HORA_A_MAS1,
CASE WHEN DIA_FECHA_COM = 'SÁBADO   ' AND TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI:SS') > '12:00:00'  THEN 'VERDADERO'
     ELSE 'FALSO'
END SABADO_MAS_DE_LAS_12,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN TO_CHAR(F_PROG_CORREGIDA(3,FEC_DOC_COMPLETA),'DD/MM/YYYY') 
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END FECHA_DOC_CORREGIDA,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN DIA_FECHA_COM
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END DIA_FECHA_DOC_COM,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN MES_FECHA_COM
     ELSE 'NO HAY FECHA DE DOCUMENTACION'
END MES_FECHA_DOC_COM,
CASE WHEN FEC_DOC_COMPLETA IS NOT NULL THEN MES_FECHA_COM
     ELSE TO_CHAR(FEC_RETIRO,'MONTH')
END MES_FINAL,
CASE WHEN TRUNC(FECHA_DOC_CORREGIDA) > TRUNC(FECHA_PROG_CORREGIDA) THEN 'SI'
     ELSE 'NO'
END FECHA3_MAYOR,
CASE WHEN TO_CHAR(F_PROG_CORREGIDA(3,FEC_DOC_COMPLETA),'DD/MM/YYYY') = TO_CHAR(F_PROG_CORREGIDA(1,FEC_DESPACHO),'DD/MM/YYYY') THEN 'SI'
     ELSE 'NO'
END FECHA3_DIAS,
CASE WHEN (TO_DATE(TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI:SS'), 'HH24:MI:SS') > TO_DATE(HORA_A, 'HH24:MI:SS')) THEN 'NO'
     ELSE 'SI'
END FECHA3,
TO_DATE(TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI:SS'), 'HH24:MI:SS') FECHA1,
TO_DATE(HORA_A, 'HH24:MI:SS') FECHA2,
TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI:SS') HORA_MIN_SEG,
CASE WHEN CODI_ADUAN = '235'  THEN 'APLICA'
     ELSE 'NO APLICA'
END VERIFICADOR3
FROM(SELECT O.NUME_ORDEN,O.CODI_ADUAN,O.CODI_REGI,O.CODI_TDESP,
    (SELECT DESCRIPCION  FROM TIPO_ANTICIPADO WHERE ADUANA = O.CODI_ADUAN  AND CODIGO = O.TIPO_DESPACHO) AS T_DESPACHO,
    O.ANO_PRESE,
    (SELECT RASON_SOCIAL FROM CLIENTES WHERE CODIGOANT = O.CODI_CLIE AND ROWNUM = 1) CLIENTE_RAZON_SOCIAL,
    A.FEC_USUA_CREA,A.FEC_DESPACHO,
    (SELECT DES_HORARIO FROM HORARIO WHERE COD_HORARIO = A.HOR_PROG) HORARIO_DESPACHO,
    O.FEC_RETIRO,A.DOC_COMPLETA,
    A.FEC_DOC_COMPLETA,
    O.COD_TERMINAL,O.NOMBRE_ALMACEN,
    (SELECT TIPO_DIRECCIONAMIENTO FROM SOLICITUD_VB LEFT JOIN SOLICITUD_VB_ORDEN S ON (S.ANIO_SOLICITUD = SOLICITUD_VB.ANIO_SOLICITUD AND S.NRO_SOLICITUD = SOLICITUD_VB.NRO_SOLICITUD AND S.ORDEN_MADRE = 1) WHERE (SOLICITUD_VB.EMPRESA = '001') AND (S.ANO_PRESE = A.ANO_PRESE) AND (S.NUME_ORDEN = O.NUME_ORDEN) AND ROWNUM = 1) TIPO_DIRECCIONAMIENTO,
    CASE WHEN A.FEC_DOC_COMPLETA IS NOT NULL THEN  TO_CHAR(A.FEC_DESPACHO,'DAY')
         ELSE 'NO HAY FECHA DE PROGRAMACION'
     END DIA_PROGRAMACION,
    F_DIA_FERIADO(A.FEC_DESPACHO) CANT_FERIADO,
    TO_CHAR(A.FEC_DOC_COMPLETA,'DAY') DIA_FECHA_COM,
    TO_CHAR(A.FEC_DOC_COMPLETA,'MONTH') MES_FECHA_COM,
    F_PROG_CORREGIDA(3,FEC_DOC_COMPLETA) FECHA_DOC_CORREGIDA,
    F_PROG_CORREGIDA(1,FEC_DESPACHO) FECHA_PROG_CORREGIDA,
    CASE WHEN (TO_NUMBER(SUBSTR((SELECT DES_HORARIO FROM HORARIO WHERE COD_HORARIO = A.HOR_PROG),1,2)) - 1) < 10 THEN LPAD(RPAD(TO_NUMBER(SUBSTR((SELECT DES_HORARIO FROM HORARIO WHERE COD_HORARIO = A.HOR_PROG),1,2)) - 1,7,':00:00'),8,'0')
         ELSE RPAD(TO_NUMBER(SUBSTR((SELECT DES_HORARIO FROM HORARIO WHERE COD_HORARIO = A.HOR_PROG),1,2)) - 1,8,':00:00')
    END HORA_A
    FROM ORDEN O 
    INNER JOIN PROG_DESPACHO_CAB A ON (O.EMPRESA = A.EMPRESA AND O.NUME_ORDEN = A.NUME_ORDEN AND O.CODI_REGI = A.CODI_REGI AND O.CODI_ADUAN = A.CODI_ADUAN AND O.ANO_PRESE = A.ANO_PRESE)
    WHERE TRUNC(O.FEC_RETIRO) BETWEEN TRUNC(TO_DATE('01/01/2022')) AND TRUNC(TO_DATE('31/12/2022')))
ORDER BY NUME_ORDEN ASC;

--------SELECT INDICADOR 3--------

SELECT NUME_ORDEN,CODI_ADUAN,CODI_REGI,CODI_TDESP,T_DESPACHO,ANO_PRESE AS AÑO,CLIENTE_RAZON_SOCIAL,FEC_USUA_CREA,FECHA_DESPACHO,HORARIO_DESPACHO,MES_FECHA_DESPACHO,FEC_RETIRO,
DOC_COMPLETA,FECHA_DOC_COMPLETA,MES_DOC_COMPLETA,COD_TERMINAL,NOMBRE_ALMACEN,DIA_PROGRAMAC,FECHA_PROG_CORREGIDA,HORA_PROGRA,HORA_A,SABADO_MAS_DE_LAS_12,FECHA_DOC_CORREGIDA,
DIA_FECHA_DOC_COM,MES_FECHA_DOC_COM,MES_FINAL,FECHA3_MAYOR,FECHA3_DIAS AS FECHA3_DIAS_IGUALES,FECHA3 AS FECHA3_COMPARAR_HORAS,
F_OBTENER_FECHA3(HORA_MIN_SEG,HORA_PROGRA,FECHA_DOC_COMPLETA) FECHA_3,
HORA_MIN_SEG,VERIFICADOR3,
F_INDICADOR3_MAYRA(FECHA_DESPACHO,FECHA_DOC_COMPLETA,FECHA3_MAYOR,FECHA3_DIAS,FECHA3) INDICADOR3
FROM VISTA_INDICADOR3_MAYRA





