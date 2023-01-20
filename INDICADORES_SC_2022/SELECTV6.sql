-----NUMERACION***-----------
SELECT /*+ result_cache */ 
        ANO_PRESE,CODI_ADUAN,CODI_REGI,NUME_ORDEN,CLIENTE,PESO,NRO_SERIES,INGRESO_PRODUCCION,ETA,
        fec_numerac FECHA_NUMERACION,
        CASE    WHEN to_char(fec_numerac,'DD/MM/YYYY') = to_char(Fecha_Hora_Ult_Produccion,'DD/MM/YYYY') THEN 'Mismo dia'
                WHEN trunc(fec_numerac) - trunc(Fecha_Hora_Ult_Produccion) = 1 AND to_char(fec_numerac,'HH24:MI') < '08:00:00' AND DESC_CORTE = 'fuera del corte' THEN 'Mismo dia, madrugada'
                ELSE 'Distintos dias'
        END ANALISIS_NUM_ENVIO,
        Fecha_Hora_Ult_Produccion FECHA_ULT_PROD,
        CASE    WHEN to_number(INICIO_DESC_HORA) < 9 THEN INICIO_DESC_HORA || '-' || '0' || (to_number(INICIO_DESC_HORA) + 1)
                ELSE INICIO_DESC_HORA || '-' || (to_number(INICIO_DESC_HORA) + 1)
        END DESC_HORA_T,
        INICIO_DESC_HORA INICIO_HORA,
        DESC_CORTE,MODALIDAD,NOMBRE_COMERCIAL,JEFE_COMERCIAL,ANALISTA,LIQUIDADOR,REVISOR
        FROM(SELECT /*+ result_cache */ O.ANO_PRESE, O.CODI_ADUAN, O.CODI_REGI, O.NUME_ORDEN, 
            (SELECT RASON_SOCIAL FROM CLIENTES WHERE O.CODI_CLIE = CODIGOANT AND EMPRESA = '001' AND ROWNUM = 1) CLIENTE, 
            (SELECT /*+ result_cache */ COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) NRO_SERIES,
            O.FECHA_INICIO_PRODUCCION INGRESO_PRODUCCION,
            TO_CHAR(F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),'DD/MM/YYYY') ETA,
            NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) fec_numerac,
            OI.FEC_ITERACION Fecha_Hora_Ult_Produccion,
            TO_CHAR(OI.FEC_ITERACION,'HH24') Inicio_Desc_Hora,
            DECODE(O.CODI_TDESP,'1-0','Anticipado','0-0','Excepcional','0-1','Urgente','') MODALIDAD,
            O.COMERCIAL,
            (SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T where JM.COMERCIAL = T.COD_ASCINSA ) NOMBRE_COMERCIAL,
            (SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO FROM TRABAJADORES T where t.ctrabajador = (select jefe_inmediato  FROM trabajadores R where JM.COMERCIAL = R.cod_ascinsa )) JEFE_COMERCIAL,
            O.REVISOR ANALISTA,
            O.DIGITADOR LIQUIDADOR,
            O.USUARIO_VB_DIGITACION REVISOR,
            (SELECT PESO FROM CLIENTES WHERE O.CODI_CLIE = CODIGOANT AND EMPRESA = '001' AND ROWNUM = 1) PESO,
          CASE  WHEN (O.CLIENTE='SAMSUNG' or O.CLIENTE='KOMATSU' or O.CLIENTE='INGRAM' or O.CLIENTE='DCP' or O.CLIENTE='SAGA') AND O.CODI_ADUAN = '235' AND TO_CHAR(OI.FEC_ITERACION,'HH24:MI') >= '08:00' AND TO_CHAR(OI.fec_iteracion,'HH24:MI') <= '19:00' THEN  'dentro del corte'
                WHEN TO_CHAR(OI.FEC_ITERACION,'HH24:MI') >= '08:00' AND TO_CHAR(OI.FEC_ITERACION,'HH24:MI') <= '17:00' THEN  'dentro del corte'
                ELSE 'fuera del corte'
          END Desc_Corte
        FROM ORDEN O
        LEFT OUTER JOIN ORDEN_ITERACIONES_PROD OI ON (OI.ANO_PRESE = O.ANO_PRESE AND OI.EMPRESA=O.EMPRESA AND TRIM(OI.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(OI.CODI_REGI) = TRIM(O.CODI_REGI) AND OI.NUME_ORDEN = O.NUME_ORDEN)
        LEFT JOIN ORDEN_INDICADOR_JM JM ON ( JM.ANO_PRESE = O.ANO_PRESE AND JM.EMPRESA = O.EMPRESA AND TRIM(JM.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(JM.CODI_REGI) = TRIM(O.CODI_REGI) AND JM.NUME_ORDEN = O.NUME_ORDEN)
        WHERE O.EMPRESA = '001' AND O.FECHA_INICIO_PRODUCCION IS NOT NULL
        AND TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN TO_DATE('1/01/2022','dd/mm/yyyy') AND TO_DATE('31/12/2022','dd/mm/yyyy')
        AND OI.FEC_ITERACION = (SELECT MAX(FEC_ITERACION) FROM ORDEN_ITERACIONES_PROD WHERE NUME_ORDEN = OI.NUME_ORDEN AND EMPRESA = OI.EMPRESA AND ANO_PRESE = OI.ANO_PRESE)
        ORDER BY NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) ASC)
        WHERE NRO_SERIES > 0;

----------PRODUCTIVIDAD_IMPOV6----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT CLIENTE,COMERCIAL,JEFE_INMEDIATO,
'01' ||'/'|| MES ||'/'|| TO_CHAR(SYSDATE,'YYYY')  FECHA,PESO,TOTAL,CANTXPESO
FROM V_PRODUCTIVIDAD ;

----------PRODUCTIVIDAD_EXPOV6----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT CLIENTE,COMERCIAL,JEFE_INMEDIATO,
'01' ||'/'|| MES ||'/'|| TO_CHAR(SYSDATE,'YYYY')  FECHA,PESO,TOTAL,CANTXPESO
FROM V_PRODUCTIVIDAD_EXPO

----------DEVOLUCIONESV6----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT 
OE.nume_orden,OE.codi_regi,OE.codi_aduan,OE.ANO_PRESE,
(SELECT RASON_SOCIAL FROM CLIENTES WHERE O.CODI_CLIE = CODIGOANT AND EMPRESA = '001' AND ROWNUM = 1) CLIENTE,  
O.NRO_SERIES_PRENUME,decode(oe.codigo_error,1,'Documentos con error',2,'Despacho Avanzado',3,'Faltan Docs y/o Datos',4,'Devolución',null) Tipo_Complejidad,
OE.ETAPA,et.descripcion,
F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN) ETA,
OE.fec_ingreso_produccion Fecha_Ingreso_Produccion, 
OE.FEC_ASIGNACION Fecha_Asignacion,
OE.fecha_registro Fecha_Rechazo,
nvl( OE.OBSERVACION,oe.DESCRIPCION_ERROR) MOTIVO, 
OE.usuario_registro  Usuario_Produccion,
OE.nombre_usuario_registro Nombre_Produccion,
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno  from trabajadores r where JM.comercial = r.cod_ascinsa ) Nombre_Ejecutivo,
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno from trabajadores t where t.ctrabajador = (select jefe_inmediato  from trabajadores r where JM.comercial = r.cod_ascinsa )) jefe_comercial
FROM ORDEN_ERRORES OE 
INNER JOIN  ORDEN O ON o.ANO_PRESE = oe.ANO_PRESE AND trim(o.codi_regi) = trim(oe.codi_regi) AND trim(o.codi_aduan) = trim(oe.codi_aduan) AND o.NUME_ORDEN = oe.NUME_ORDEN and o.EMPRESA = oe.EMPRESA 
LEFT JOIN orden_etapas et on Oe.empresa=et.empresa and oe.etapa=et.codigo 
LEFT JOIN ORDEN_INDICADOR_JM JM ON (O.ANO_PRESE = JM.ANO_PRESE AND trim(o.codi_regi) = trim(JM.codi_regi) AND trim(o.codi_aduan) = trim(JM.codi_aduan) AND o.NUME_ORDEN = JM.NUME_ORDEN and o.EMPRESA = JM.EMPRESA)
WHERE (OE.COD_ACTIVIDAD_ORDEN IN  ('161','165','97','163','162') OR OE.COD_TAREA_ORDEN in ('643','645','649','3181','641')) AND (( OE.OBSERVACION IS NOT NULL)OR( OE.DESCRIPCION_ERROR IS NOT NULL))
AND (NVL(oe.tipo_responsable,'COM')='COM')  and  (O.FLAG_TIPO_LINEA=1 or O.FLAG_TIPO_LINEA=2)
AND oe.empresa='001' and TRUNC(oe.fecha_registro )  BETWEEN to_date('01/01/2022','dd/mm/yyyy') AND to_date('31/12/2022','dd/mm/yyyy')
order by OE.NUME_ORDEN, oe.fecha_registro


-----------DEVOLUCIONES_ERRONEASV6--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
WHERE A.CODI_INC = 'F02' AND A.ANO_PRESE = TO_CHAR(SYSDATE,'YYYY') 

----------ENVIOS_VS_LLEGADAV6***--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT /*+ result_cache */ NUME_ORDEN,PAIS,PUERTO,REGIMEN,ADUANA,AÑO,CLIENTE,TIPO_CLIENTE,NRO_SERIES,FECHA_INGRESO_PRODUCCION,ETA,VERIFICADOR1,FECHA_NUMERACION,FECHA_LLEGADA,DES_DIA_LLEGADA,CORTE_LLEGADA,
FECHA_ULTIMO_ENVIO,DES_DIA_ENVIO,CORTE_ULT_ENV,VERIFICADOR3,DIFERENCIA_DIAS,VERIFICADOR2,ANALISIS,MODALIDAD,
F_DESC_ANALISIS1(VERIFICADOR2,ANALISIS)DESC_ANALISIS1,F_DESC_ANALISIS2(VERIFICADOR2,ANALISIS) DESC_ANALISIS2,NOMBRE_COMERCIAL,JEFE_COMERCIAL
FROM VISTA_REPORTE_ENVIO_LLEGADA;


