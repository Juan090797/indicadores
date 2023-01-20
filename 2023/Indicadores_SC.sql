---------------PRODUCTIVIDAD...IMPORTACIONES................

---------VISTA--------
CREATE OR REPLACE FORCE VIEW "SIG"."V_PRODUCTIVIDAD" ("CLIENTE", "PESO", "MES", "COMERCIAL", "JEFE_INMEDIATO", "TOTAL", "CANTXPESO") AS 
SELECT (SELECT RASON_SOCIAL from CLIENTES where CODIGOANT = O.CODI_CLIE AND ROWNUM=1) CLIENTE,
(SELECT PESO FROM CLIENTES WHERE CODIGOANT IS NOT NULL AND CODIGOANT = O.CODI_CLIE AND EMPRESA='001') PESO,
TO_CHAR(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION),'MM/YYYY') MES,
(SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO  FROM TRABAJADORES WHERE COD_ASCINSA = JM.COMERCIAL AND ROWNUM = 1) COMERCIAL,
(SELECT PNOMBRE || ' ' || SNOMBRE|| ' ' ||APATERNO|| ' ' || AMATERNO FROM TRABAJADORES T WHERE T.CTRABAJADOR = (SELECT JEFE_INMEDIATO  FROM TRABAJADORES R WHERE JM.COMERCIAL = R.COD_ASCINSA )) JEFE_INMEDIATO ,
COUNT(*) TOTAL,
F_TOTALXPESO(O.CODI_CLIE,COUNT(*)) CANTXPESO
FROM ORDEN O
LEFT JOIN ORDEN_INDICADOR_JM JM ON (JM.ANO_PRESE = O.ANO_PRESE AND JM.NUME_ORDEN = O.NUME_ORDEN AND JM.CODI_REGI = O.CODI_REGI AND JM.CODI_ADUAN = O.CODI_ADUAN)
WHERE TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))
AND O.FEC_NUMERACION IS NOT NULL AND O.CODI_REGI <>'40' AND O.flag_parcial_deposito = '0'
GROUP BY O.CLIENTE,O.CODI_CLIE,TO_CHAR(nvl(O.fec_numeracion_w, O.fec_numeracion),'MM/YYYY'),JM.COMERCIAL
ORDER BY O.CLIENTE,O.CODI_CLIE,TO_CHAR(nvl(O.fec_numeracion_w, O.fec_numeracion),'MM/YYYY'),JM.COMERCIAL;

--AND O.FEC_NUMERACION IS NOT NULL AND O.CODI_REGI <>'40' AND O.flag_parcial_deposito = '0'



SELECT CLIENTE,COMERCIAL,JEFE_INMEDIATO,
'01' ||'/'|| MES  FECHA,PESO,TOTAL,CANTXPESO
FROM V_PRODUCTIVIDAD ;

---------------PRODUCTIVIDAD...EXPORTACIONES................

---------VISTA--------

CREATE OR REPLACE FORCE VIEW "SIG"."V_PRODUCTIVIDAD_EXPO" ("CLIENTE", "PESO", "MES", "COMERCIAL", "JEFE_INMEDIATO", "TOTAL", "CANTXPESO") AS 
SELECT 
(SELECT RASON_SOCIAL from CLIENTES WHERE CODIGOANT = O.CODI_CLIE AND ROWNUM=1) CLIENTE,
(SELECT PESO_EXPO FROM CLIENTES WHERE CODIGOANT IS NOT NULL AND CODIGOANT = O.CODI_CLIE AND EMPRESA='001') PESO,
TO_CHAR(O.FECHA_NUME_PROVI,'MM/YYYY') MES,
(SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO  FROM TRABAJADORES T WHERE T.COD_ASCINSA = JM.COMERCIAL AND ROWNUM = 1) COMERCIALSC,
(SELECT PNOMBRE || ' ' || SNOMBRE|| ' ' ||APATERNO|| ' ' || AMATERNO FROM TRABAJADORES T WHERE T.CTRABAJADOR = (SELECT JEFE_INMEDIATO  FROM TRABAJADORES R WHERE JM.COMERCIAL = R.COD_ASCINSA )) JEFE_INMEDIATO, 
COUNT(*) TOTAL,
F_TOTALXPESO_EXPO(O.CODI_CLIE,COUNT(*)) CANTXPESO
FROM ORDEN O
LEFT JOIN ORDEN_INDICADOR_JM JM ON (JM.ANO_PRESE = O.ANO_PRESE AND JM.NUME_ORDEN = O.NUME_ORDEN AND JM.CODI_REGI = O.CODI_REGI AND JM.CODI_ADUAN = O.CODI_ADUAN)
WHERE TRUNC(FECHA_NUME_PROVI) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))
AND O.CODI_REGI = '40' AND O.flag_parcial_deposito = '0' AND O.FECHA_NUME_PROVI IS NOT NULL   
GROUP BY O.CODI_CLIE,TO_CHAR(O.FECHA_NUME_PROVI,'MM/YYYY'),JM.COMERCIAL
ORDER BY O.CODI_CLIE,TO_CHAR(O.FECHA_NUME_PROVI,'MM/YYYY'),JM.COMERCIAL;

--WHERE TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN TO_DATE('1/10/2022','DD/MM/YYYY') AND TRUNC(SYSDATE)


SELECT CLIENTE,COMERCIAL,JEFE_INMEDIATO,
'01' ||'/'|| MES FECHA,PESO,TOTAL,CANTXPESO
FROM V_PRODUCTIVIDAD_EXPO

-----------------NUMERACION------------------------------------------------

SELECT
ANO_PRESE,CODI_ADUAN,CODI_REGI,NUME_ORDEN,CLIENTE,PESO,NRO_SERIES,INGRESO_PRODUCCION,ETA,
 fec_numerac FECHA_NUMERACION,
        CASE    WHEN to_char(fec_numerac,'DD/MM/YYYY') = to_char(Fecha_Hora_Ult_Produccion,'DD/MM/YYYY') THEN 'Mismo dia'
                WHEN trunc(fec_numerac) - trunc(Fecha_Hora_Ult_Produccion) = 1 AND to_char(fec_numerac,'HH24:MI') < '08:00:00' AND DESC_CORTE = 'fuera del corte' THEN 'Mismo dia, madrugada'
                ELSE 'Distintos dias'
        END ANALISIS_NUM_ENVIO,
        Fecha_Hora_Ult_Produccion FECHA_ULT_PROD,
        CASE   WHEN TO_NUMBER(INICIO_DESC_HORA) < 9 THEN INICIO_DESC_HORA || '-' || '0' || (TO_NUMBER(INICIO_DESC_HORA) + 1)
               ELSE INICIO_DESC_HORA || '-' || (TO_NUMBER(INICIO_DESC_HORA) + 1)
        END DESC_HORA_T,
        INICIO_DESC_HORA INICIO_HORA,
        DESC_CORTE,MODALIDAD,NOMBRE_COMERCIAL,JEFE_COMERCIAL,ANALISTA,LIQUIDADOR,REVISOR
        FROM(SELECT O.ANO_PRESE, O.CODI_ADUAN, O.CODI_REGI, O.NUME_ORDEN, 
            (SELECT RASON_SOCIAL FROM CLIENTES WHERE O.CODI_CLIE = CODIGOANT AND EMPRESA = '001' AND ROWNUM = 1) CLIENTE, 
            (SELECT COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) NRO_SERIES,
            O.FECHA_INICIO_PRODUCCION INGRESO_PRODUCCION,
            TO_CHAR(F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),'DD/MM/YYYY') ETA,
            NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) fec_numerac,
            NVL(OI.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION) Fecha_Hora_Ult_Produccion,
            TO_CHAR(NVL(OI.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION),'HH24') Inicio_Desc_Hora,
            DECODE(O.CODI_TDESP,'1-0','Anticipado','0-0','Excepcional','0-1','Urgente','') MODALIDAD,
            O.COMERCIAL,
            (SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T where JM.COMERCIAL = T.COD_ASCINSA ) NOMBRE_COMERCIAL,
            (SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T where t.ctrabajador = (select jefe_inmediato  FROM TRABAJADORES R where JM.COMERCIAL = R.COD_ASCINSA )) JEFE_COMERCIAL,
            O.REVISOR ANALISTA,
            O.DIGITADOR LIQUIDADOR,
            O.USUARIO_VB_DIGITACION REVISOR,
            (SELECT PESO FROM CLIENTES WHERE O.CODI_CLIE = CODIGOANT AND EMPRESA = '001' AND ROWNUM = 1) PESO,
          CASE  WHEN (O.CLIENTE='SAMSUNG' or O.CLIENTE='KOMATSU' or O.CLIENTE='INGRAM' or O.CLIENTE='DCP' or O.CLIENTE='SAGA') AND O.CODI_ADUAN = '235' AND TO_CHAR(OI.FEC_ITERACION,'HH24:MI') >= '08:00' AND TO_CHAR(OI.fec_iteracion,'HH24:MI') <= '19:00' THEN  'dentro del corte'
                WHEN TO_CHAR(OI.FEC_ITERACION,'HH24:MI') >= '08:00' AND TO_CHAR(OI.FEC_ITERACION,'HH24:MI') <= '17:00' THEN  'dentro del corte'
                ELSE 'fuera del corte'
          END Desc_Corte
        FROM ORDEN O
        LEFT OUTER JOIN V_INCIDENCIAS_JM OI ON (OI.ANO_PRESE = O.ANO_PRESE AND TRIM(OI.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(OI.CODI_REGI) = TRIM(O.CODI_REGI) AND OI.NUME_ORDEN = O.NUME_ORDEN)
        LEFT JOIN ORDEN_INDICADOR_JM JM ON ( JM.ANO_PRESE = O.ANO_PRESE AND JM.EMPRESA = O.EMPRESA AND TRIM(JM.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(JM.CODI_REGI) = TRIM(O.CODI_REGI) AND JM.NUME_ORDEN = O.NUME_ORDEN)
        WHERE O.EMPRESA = '001' 
        AND O.FECHA_INICIO_PRODUCCION IS NOT NULL
        AND TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))
        ORDER BY NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) ASC)
        WHERE NRO_SERIES > 0;        
        

-------------------------------ENVIO VS LLEGADA-----------------------------------------------------------------

CREATE OR REPLACE FORCE VIEW VISTA_REPORTE_ENVIO_LLEGADA  AS 
SELECT NUME_ORDEN,PAIS,PUERTO,REGIMEN,ADUANA,AÑO,CLIENTE,TIPO_CLIENTE,NRO_SERIES,FECHA_INGRESO_PRODUCCION,ETA,
      CASE WHEN  FECHA_NUMERACION IS NULL THEN 'x'
           ELSE 'OK'
      END VERIFICADOR1,
      FECHA_NUMERACION,FECHA_LLEGADA,
      NVL(DE_DIA_LLEGADA,'NO DEFINIDO') DESC_DIA_LLEGADA,
      NVL(VALIDAR_LABORAL_LLEGADA,'NO DEFINIDO') CORTE_LLEGADA,
      FECHA_ULTIMO_ENVIO,
      NVL(DE_DIA_ENVIO,'NO DEFINIDO') DESC_DIA_ENVIO,
      NVL(VALIDAR_LABORAL_ULTIMO,'NO DEFINIDO') CORTE_ULT_ENV,
      NVL(F_VERIFICADOR3(DE_DIA_LLEGADA,VALIDAR_LABORAL_LLEGADA,DE_DIA_ENVIO,VALIDAR_LABORAL_ULTIMO),'NO ENCONTRADOV3') VERIFICADOR3,
      DIFERENCIA_DIAS,
      CASE  WHEN MODALIDAD = 'Anticipado' THEN  'REVISAR INDICADOR'
            ELSE 'FUERA DE ALCANCE'
      END VERIFICADOR2,
      F_DIF_LLEGADA_ULTENVIO(FECHA_LLEGADA,FECHA_ULTIMO_ENVIO,TIPO_CLIENTE,DIFERENCIA_DIAS,F_VERIFICADOR3(DE_DIA_LLEGADA,VALIDAR_LABORAL_LLEGADA,DE_DIA_ENVIO,VALIDAR_LABORAL_ULTIMO)) ANALISIS,
      MODALIDAD,NOMBRE_COMERCIAL,JEFE_COMERCIAL
FROM (SELECT OI.NUME_ORDEN,OI.CODI_REGI REGIMEN,OI.CODI_ADUAN ADUANA,OI.ANO_PRESE AÑO,O.CLIENTE,O.FECHA_INICIO_PRODUCCION FECHA_INGRESO_PRODUCCION,F_TIPO_CLIENTE(O.CLIENTE,OI.CODI_ADUAN) TIPO_CLIENTE,
      (SELECT pnombre || ' ' || snombre|| ' ' || apaterno|| ' ' ||amaterno FROM TRABAJADORES T where JM.COMERCIAL = T.cod_ascinsa ) NOMBRE_COMERCIAL,
      (SELECT pnombre || ' ' || snombre|| ' ' || apaterno|| ' ' ||amaterno FROM TRABAJADORES T where T.ctrabajador = (SELECT jefe_inmediato  FROM TRABAJADORES R WHERE JM.COMERCIAL = R.COD_ASCINSA )) JEFE_COMERCIAL,
      O.TOTAL_SERIES  NRO_SERIES,
      F_VALIDAR_COR_HOR_LABORAL(CLIENTE,NVL(F_FECHA_LLEGADA(O.EMPRESA,O.ANO_MANIFIESTO,O.CODI_ADUAN,O.NRO_MANIFIESTO), O.FECHA_LLEGADA),OI.CODI_ADUAN,1) VALIDAR_LABORAL_LLEGADA,
      F_VALIDAR_COR_HOR_LABORAL(CLIENTE,NVL(VJM.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION),OI.CODI_ADUAN,2)VALIDAR_LABORAL_ULTIMO,
      F_OBTENER_TIPO_DIA(NVL(VJM.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION)) DE_DIA_ENVIO,
      F_OBTENER_TIPO_DIA( NVL(F_FECHA_LLEGADA(O.EMPRESA,O.ANO_MANIFIESTO,O.CODI_ADUAN,O.NRO_MANIFIESTO), O.FECHA_LLEGADA)) DE_DIA_LLEGADA,
     NVL(VJM.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION) FECHA_ULTIMO_ENVIO,
     F_DIAS_HABILES_JMV(TRUNC(NVL(VJM.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION)),TRUNC(NVL(F_FECHA_LLEGADA(O.EMPRESA,O.ANO_MANIFIESTO,O.CODI_ADUAN,O.NRO_MANIFIESTO), O.FECHA_LLEGADA))) DIFERENCIA_DIAS,
     F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN) ETA,
     NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) FECHA_NUMERACION,
     NVL(F_FECHA_LLEGADA(O.EMPRESA,O.ANO_MANIFIESTO,O.CODI_ADUAN,O.NRO_MANIFIESTO), O.FECHA_LLEGADA) FECHA_LLEGADA,
     ET.DESCRIPCION,OI.ITERACION,
	 DECODE(O.CODI_TDESP,'1-0','Anticipado','0-0','Excepcional','0-1','Urgente','') MODALIDAD,
     CASE WHEN (OD.PUERTO_EMBARQUE IS NOT NULL ) THEN
        NVL(F_OBTE_PAIS_PUERTO_EMB(OD.PUERTO_EMBARQUE),OD.PAIS_ORIGEN)
     END AS PAIS,
     OD.PUERTO_EMBARQUE AS PUERTO
     FROM ORDEN_ITERACIONES_PROD OI
     INNER JOIN ORDEN O ON (OI.ANO_PRESE = O.ANO_PRESE AND OI.EMPRESA = O.EMPRESA AND TRIM(OI.codi_aduan)=TRIM(O.CODI_ADUAN) AND TRIM(OI.CODI_REGI) = TRIM(O.CODI_REGI) AND OI.NUME_ORDEN = O.NUME_ORDEN)
     LEFT JOIN V_INCIDENCIAS_JM VJM ON (VJM.ANO_PRESE = O.ANO_PRESE AND TRIM(VJM.codi_aduan)=TRIM(O.CODI_ADUAN) AND TRIM(VJM.CODI_REGI) = TRIM(O.CODI_REGI) AND VJM.NUME_ORDEN = O.NUME_ORDEN)
     LEFT JOIN ORDEN_ETAPAS ET ON (OI.EMPRESA = ET.EMPRESA AND OI.ETAPA = ET.CODIGO)
     INNER JOIN ORDEN_DETALLE OD ON (O.EMPRESA = OD.EMPRESA AND O.ANO_PRESE = OD.ANO_PRESE AND O.CODI_REGI = OD.CODI_REGI AND O.CODI_ADUAN = OD.CODI_ADUAN AND O.NUME_ORDEN = OD.NUME_ORDEN)
     LEFT JOIN ORDEN_INDICADOR_JM JM ON (O.EMPRESA = JM.EMPRESA AND O.ANO_PRESE = JM.ANO_PRESE AND O.CODI_REGI = JM.CODI_REGI AND O.CODI_ADUAN = JM.CODI_ADUAN AND O.NUME_ORDEN = JM.NUME_ORDEN)
     WHERE 
     O.FLAG_TIPO_LINEA IN (1,2) 
     AND OI.EMPRESA='001' 
     AND TRUNC(OI.FEC_ITERACION) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))
     AND OI.FEC_ITERACION = (SELECT MAX(FEC_ITERACION) FROM ORDEN_ITERACIONES_PROD WHERE NUME_ORDEN = OI.NUME_ORDEN AND EMPRESA = OI.EMPRESA AND ANO_PRESE = OI.ANO_PRESE)
     AND OD.SERIE = O.TOTAL_SERIES 
     AND NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) IS NOT NULL
     ORDER BY OI.FEC_ITERACION, OI.NUME_ORDEN);    


SELECT /*+ result_cache */ NUME_ORDEN,PAIS,PUERTO,REGIMEN,ADUANA,AÑO,CLIENTE,TIPO_CLIENTE,NRO_SERIES,FECHA_INGRESO_PRODUCCION,ETA,VERIFICADOR1,FECHA_NUMERACION,FECHA_LLEGADA,DESC_DIA_LLEGADA,CORTE_LLEGADA,
FECHA_ULTIMO_ENVIO,DESC_DIA_ENVIO,CORTE_ULT_ENV,VERIFICADOR3,DIFERENCIA_DIAS,VERIFICADOR2,ANALISIS,MODALIDAD,
F_DESC_ANALISIS1(VERIFICADOR2,ANALISIS)DESC_ANALISIS1,F_DESC_ANALISIS2(VERIFICADOR2,ANALISIS) DESC_ANALISIS2,NOMBRE_COMERCIAL,JEFE_COMERCIAL
FROM VISTA_REPORTE_ENVIO_LLEGADA;


------------------DEVOLUCIONES-----------------------------------------------------------------------

SELECT 
OE.nume_orden,OE.codi_regi,OE.codi_aduan,OE.ANO_PRESE,o.cliente,  
O.NRO_SERIES_PRENUME,decode(oe.codigo_error,1,'Documentos con error',2,'Despacho Avanzado',3,'Faltan Docs y/o Datos',4,'Devolución',null) Tipo_Complejidad,
oe.ETAPA,et.descripcion,
F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN) ETA,
oe.fec_ingreso_produccion Fecha_Ingreso_Produccion, 
oe.FEC_ASIGNACION Fecha_Asignacion,
oe.fecha_registro Fecha_Rechazo,
nvl( oe.OBSERVACION,oe.DESCRIPCION_ERROR) MOTIVO, 
oe.usuario_registro  Usuario_Produccion,
oe.nombre_usuario_registro Nombre_Produccion,
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno  from trabajadores r where JM.comercial = r.cod_ascinsa ) Nombre_Ejecutivo,
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno from trabajadores t where t.ctrabajador = (SELECT jefe_inmediato  FROM trabajadores r where JM.COMERCIAL = r.cod_ascinsa )) JEFE_COMERCIAL
FROM ORDEN_ERRORES OE 
INNER JOIN  ORDEN O ON o.ANO_PRESE = oe.ANO_PRESE AND trim(o.codi_regi) = trim(oe.codi_regi) AND trim(o.codi_aduan) = trim(oe.codi_aduan) AND o.NUME_ORDEN = oe.NUME_ORDEN and o.EMPRESA = oe.EMPRESA 
LEFT JOIN orden_etapas et on Oe.empresa=et.empresa and oe.etapa=et.codigo 
LEFT JOIN ORDEN_INDICADOR_JM JM ON (O.ANO_PRESE = JM.ANO_PRESE AND trim(o.codi_regi) = trim(JM.codi_regi) AND trim(o.codi_aduan) = trim(JM.codi_aduan) AND o.NUME_ORDEN = JM.NUME_ORDEN and o.EMPRESA = JM.EMPRESA)
WHERE 
(OE.COD_ACTIVIDAD_ORDEN IN  ('161','165','97','163','162') OR OE.COD_TAREA_ORDEN in ('643','645','649','3181','641')) AND (( OE.OBSERVACION IS NOT NULL)OR( OE.DESCRIPCION_ERROR IS NOT NULL))
AND (NVL(oe.tipo_responsable,'COM')='COM')  and  (O.FLAG_TIPO_LINEA=1 or O.FLAG_TIPO_LINEA=2)
AND oe.empresa='001' and TRUNC(oe.fecha_registro ) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))
order by OE.NUME_ORDEN, oe.fecha_registro


-----------------------------DEVOLUCIONES ERRONEAS--------------------------------------------------------------------------------------------

SELECT 
A.ANO_PRESE AÑO,A.NUME_ORDEN ORDEN,A.CODI_REGI REGIMEN, A.CODI_ADUAN ADUANA,
(SELECT  RASON_SOCIAL FROM CLIENTES C WHERE C.CODIGOANT = O.CODI_CLIE AND ROWNUM=1) CLIENTE,
(SELECT COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) SERIES,
A.NUME_REGI SECUENCIA, A.FCH_INC FECHA_INCIDENCIA,
NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) FECHA_NUMERA,
A.CODI_INC COD_INC,A.INCIDENCIA,
(SELECT  PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T WHERE T.COD_ASCINSA = JM.COMERCIAL) NOMBRE_COMERCIAL,
(SELECT PNOMBRE || ' ' || SNOMBRE|| ' ' ||APATERNO|| ' ' || AMATERNO FROM TRABAJADORES T where t.ctrabajador = (select jefe_inmediato  FROM trabajadores R where JM.COMERCIAL = R.cod_ascinsa )) JEFE_COMERCIAL
FROM ADU014 A 
LEFT JOIN  ORDEN O ON (O.ANO_PRESE = A.ANO_PRESE AND O.CODI_REGI = A.CODI_REGI AND O.CODI_ADUAN = A.CODI_ADUAN AND O.NUME_ORDEN = A.NUME_ORDEN)
LEFT JOIN ORDEN_INDICADOR_JM JM ON (JM.ANO_PRESE = A.ANO_PRESE AND JM.CODI_REGI = A.CODI_REGI AND JM.CODI_ADUAN = JM.CODI_ADUAN AND JM.NUME_ORDEN = A.NUME_ORDEN)
WHERE A.CODI_INC = 'F02' AND TRUNC(A.FCH_INC) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))





-----------------------------NUEVO INDICADOR---------------------------------------------------------

SELECT 
O.ANO_PRESE,
O.NUME_ORDEN,
O.CODI_ADUAN,
O.CODI_REGI,
DECODE(O.CODI_TDESP,'1-0','Anticipado','0-0','Excepcional','0-1','Urgente','') TIPO_DESPACHO_ORDEN,
O.CLIENTE,
O.TOTAL_SERIES,
DECODE(O.ETAPA,'1','NUMERAR','2','AVANZAR/NUME DIA','3','AVANZAR','4','SIN ACCION','5','POST-NUMERACION','6','POR REVISAR')  ETAPA,
NVL(OI.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION) FECHA_ULTIMO_ENVIO_SIG,
NVL(VJM.FEC_ITERACION, O.FECHA_INICIO_PRODUCCION) FECHA_ULTIMO_ENVIO_JM,
O.FECHA_NUMERAR FEC_MAX_NUMERACION,
(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) FECHA_NUMERACION,
O.ETA,
O.COMERCIAL,
O.REVISOR ANALISTA,
O.DIGITADOR LIQUIDADOR,
O.USUARIO_VB_DIGITACION REVISOR
FROM ORDEN O
LEFT OUTER JOIN V_INCIDENCIAS_JM OI ON (OI.ANO_PRESE = O.ANO_PRESE AND TRIM(OI.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(OI.CODI_REGI) = TRIM(O.CODI_REGI) AND OI.NUME_ORDEN = O.NUME_ORDEN)
LEFT JOIN V_INCIDENCIAS_JM VJM ON (VJM.ANO_PRESE = O.ANO_PRESE AND TRIM(VJM.codi_aduan)=TRIM(O.CODI_ADUAN) AND TRIM(VJM.CODI_REGI) = TRIM(O.CODI_REGI) AND VJM.NUME_ORDEN = O.NUME_ORDEN)
WHERE   
TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN TO_DATE('01/01/2022','dd/mm/yyyy') AND TO_DATE('31/12/2022','dd/mm/yyyy');

















































-----------------------------------ORDEN NUMERADAS USO PARA DEVOLUCIONES-----------------------------------------------------------------------------------------------------------

SELECT ANO_PRESE ||''|| NUME_ORDEN CLAVE,
ANO_PRESE,CODI_ADUAN,CODI_REGI,NUME_ORDEN,CLIENTE,fec_numerac FECHA_NUMERACION,NOMBRE_COMERCIAL,JEFE_COMERCIAL
FROM(SELECT O.ANO_PRESE, O.CODI_ADUAN, O.CODI_REGI, O.NUME_ORDEN, 
 (SELECT RASON_SOCIAL FROM CLIENTES WHERE O.CODI_CLIE = CODIGOANT AND EMPRESA = '001' AND ROWNUM = 1) CLIENTE, 
 (SELECT COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) NRO_SERIES,
    NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) fec_numerac,
    (SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T where JM.COMERCIAL = T.COD_ASCINSA ) NOMBRE_COMERCIAL,
    (SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T where t.ctrabajador = (select jefe_inmediato  FROM TRABAJADORES R where JM.COMERCIAL = R.COD_ASCINSA )) JEFE_COMERCIAL
    FROM ORDEN O
    LEFT JOIN ORDEN_INDICADOR_JM JM ON ( JM.ANO_PRESE = O.ANO_PRESE AND JM.EMPRESA = O.EMPRESA AND TRIM(JM.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(JM.CODI_REGI) = TRIM(O.CODI_REGI) AND JM.NUME_ORDEN = O.NUME_ORDEN)
    WHERE O.EMPRESA = '001' AND O.FECHA_INICIO_PRODUCCION IS NOT NULL
    AND TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))
    ORDER BY NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) ASC)
    WHERE NRO_SERIES > 0;    

----------------------------------ORDEN DEVOLUCIONES-----------------------------------------------------------------------------------------                                            

SELECT 
OE.ANO_PRESE|| '' ||OE.nume_orden ID_DEVOLUCIONES,
OE.nume_orden,OE.codi_regi,OE.codi_aduan,OE.ANO_PRESE,o.cliente,  
O.NRO_SERIES_PRENUME,decode(oe.codigo_error,1,'Documentos con error',2,'Despacho Avanzado',3,'Faltan Docs y/o Datos',4,'Devolución',null) Tipo_Complejidad,
oe.ETAPA,et.descripcion,
F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN) ETA,
oe.fec_ingreso_produccion Fecha_Ingreso_Produccion, 
oe.FEC_ASIGNACION Fecha_Asignacion,
oe.fecha_registro Fecha_Rechazo,
nvl( oe.OBSERVACION,oe.DESCRIPCION_ERROR) MOTIVO, 
oe.usuario_registro  Usuario_Produccion,
oe.nombre_usuario_registro Nombre_Produccion,
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno  from trabajadores r where JM.comercial = r.cod_ascinsa ) Nombre_Ejecutivo,
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno from trabajadores t where t.ctrabajador = (SELECT jefe_inmediato  FROM trabajadores r where JM.COMERCIAL = r.cod_ascinsa )) JEFE_COMERCIAL
FROM ORDEN_ERRORES OE 
INNER JOIN  ORDEN O ON o.ANO_PRESE = oe.ANO_PRESE AND trim(o.codi_regi) = trim(oe.codi_regi) AND trim(o.codi_aduan) = trim(oe.codi_aduan) AND o.NUME_ORDEN = oe.NUME_ORDEN and o.EMPRESA = oe.EMPRESA 
LEFT JOIN orden_etapas et on Oe.empresa=et.empresa and oe.etapa=et.codigo 
LEFT JOIN ORDEN_INDICADOR_JM JM ON (O.ANO_PRESE = JM.ANO_PRESE AND trim(o.codi_regi) = trim(JM.codi_regi) AND trim(o.codi_aduan) = trim(JM.codi_aduan) AND o.NUME_ORDEN = JM.NUME_ORDEN and o.EMPRESA = JM.EMPRESA)
WHERE (OE.COD_ACTIVIDAD_ORDEN IN  ('161','165','97','163','162') OR OE.COD_TAREA_ORDEN in ('643','645','649','3181','641')) AND (( OE.OBSERVACION IS NOT NULL)OR( OE.DESCRIPCION_ERROR IS NOT NULL))
AND (NVL(oe.tipo_responsable,'COM')='COM')  and  (O.FLAG_TIPO_LINEA=1 or O.FLAG_TIPO_LINEA=2)
AND oe.empresa='001' and TRUNC(oe.fecha_registro ) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))
order by OE.NUME_ORDEN, oe.fecha_registro


------------------------------------ORDEN DEVOLUCIONE ERRONEAS---------------------------------------------------------------------------------------------------



SELECT 
A.ANO_PRESE|| '' ||A.NUME_ORDEN ID_DEV_ERRONEAS,
A.ANO_PRESE AÑO,A.NUME_ORDEN ORDEN,A.CODI_REGI REGIMEN, A.CODI_ADUAN ADUANA,
(SELECT  RASON_SOCIAL FROM CLIENTES C WHERE C.CODIGOANT = O.CODI_CLIE AND ROWNUM=1) CLIENTE,
(SELECT COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) SERIES,
A.NUME_REGI SECUENCIA, A.FCH_INC FECHA_INCIDENCIA,
NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) FECHA_NUMERA,
A.CODI_INC COD_INC,A.INCIDENCIA,
(SELECT  PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T WHERE T.COD_ASCINSA = JM.COMERCIAL) NOMBRE_COMERCIAL,
(SELECT PNOMBRE || ' ' || SNOMBRE|| ' ' ||APATERNO|| ' ' || AMATERNO FROM TRABAJADORES T where t.ctrabajador = (select jefe_inmediato  FROM trabajadores R where JM.COMERCIAL = R.cod_ascinsa )) JEFE_COMERCIAL
FROM ADU014 A 
LEFT JOIN  ORDEN O ON (O.ANO_PRESE = A.ANO_PRESE AND O.CODI_REGI = A.CODI_REGI AND O.CODI_ADUAN = A.CODI_ADUAN AND O.NUME_ORDEN = A.NUME_ORDEN)
LEFT JOIN ORDEN_INDICADOR_JM JM ON (JM.ANO_PRESE = A.ANO_PRESE AND JM.CODI_REGI = A.CODI_REGI AND JM.CODI_ADUAN = JM.CODI_ADUAN AND JM.NUME_ORDEN = A.NUME_ORDEN)
WHERE A.CODI_INC = 'F02' AND TRUNC(A.FCH_INC) BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-4) AND LAST_DAY(TRUNC(SYSDATE))