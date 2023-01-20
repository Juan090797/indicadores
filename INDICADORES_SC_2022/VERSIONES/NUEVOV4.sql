SELECT ANO_PRESE,CODI_ADUAN,CODI_REGI,NUME_ORDEN,CLIENTE,NRO_SERIES,INGRESO_PRODUCCION,ETA,
        fec_numerac FECHA_NUMERACION,
        to_char(fec_numerac,'DD/MM/YYYY') MES_NUMERACION,
        to_char(fec_numerac,'HH24:MI') HORA_NUMERACION,
        CASE    WHEN to_char(fec_numerac,'DD/MM/YYYY') = to_char(Fecha_Hora_Ult_Produccion,'DD/MM/YYYY') THEN 'Mismo dia'
                WHEN trunc(fec_numerac) - trunc(Fecha_Hora_Ult_Produccion) = 1 AND to_char(fec_numerac,'HH24:MI') < '08:00:00' AND DESC_CORTE = 'fuera del corte' THEN 'Mismo dia, madrugada'
                ELSE 'Distintos dias'
        END ANALISIS_NUM_ENVIO,
        Fecha_Hora_Ult_Produccion FECHA_ULT_PROD,
        to_char(Fecha_Hora_Ult_Produccion,'DD/MM/YYYY') MES_ULT_PROD,
        to_char(Fecha_Hora_Ult_Produccion,'HH24:MI') HORA_ULT_PROD,
        CASE    WHEN to_number(INICIO_DESC_HORA) < 9 THEN INICIO_DESC_HORA || '-' || '0' || (to_number(INICIO_DESC_HORA) + 1)
                ELSE INICIO_DESC_HORA || '-' || (to_number(INICIO_DESC_HORA) + 1)
        END DESC_HORA_T,
        INICIO_DESC_HORA INICIO_HORA,
        DESC_CORTE,Modalidad,NOMBRE_COMERCIAL,JEFE_COMERCIAL,ANALISTA,LIQUIDADOR,REVISOR,TIEMPO_ETA_NUMERACION,TIEMPO_IPRODUC_NUMERACION
        FROM(SELECT O.ANO_PRESE, O.CODI_ADUAN, O.CODI_REGI, O.NUME_ORDEN, O.CLIENTE, 
            (SELECT COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) NRO_SERIES,
            O.FECHA_INICIO_PRODUCCION INGRESO_PRODUCCION,
            to_char(F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),'DD/MM/YYYY') ETA,
            NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) fec_numerac,
            oi.fec_iteracion Fecha_Hora_Ult_Produccion,
            to_char(oi.fec_iteracion,'HH24') Inicio_Desc_Hora,
            decode(O.CODI_TDESP,'1-0','Anticipado','0-0','Excepcional','0-1','Urgente','') Modalidad,
            O.COMERCIAL,
            (SELECT pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno FROM trabajadores T where JM.COMERCIAL = T.COD_ASCINSA ) NOMBRE_COMERCIAL,
            --(select t.jefe_inmediato FROM trabajadores t where o.comercial = t.cod_ascinsa) dni_jefe_comercial,
            (SELECT pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno FROM trabajadores t where t.ctrabajador = (select jefe_inmediato  FROM trabajadores r where JM.COMERCIAL = r.cod_ascinsa )) JEFE_COMERCIAL,
            O.REVISOR ANALISTA,
            O.DIGITADOR LIQUIDADOR,
            O.USUARIO_VB_DIGITACION REVISOR,
          case when F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN)<NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) 
               then  f_tiemposy(f_restar_fechas( F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION),1,3,0),13) 
               else  f_tiemposy(f_restar_fechas(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION), F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),1,3,0),13) 
          end TIEMPO_ETA_NUMERACION,
          f_tiemposy(f_restar_fechas(O.FECHA_INICIO_PRODUCCION,   NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION),1,3,0),13)   TIEMPO_IPRODUC_NUMERACION,
          CASE  WHEN (O.CLIENTE='SAMSUNG' or O.CLIENTE='KOMATSU' or O.CLIENTE='INGRAM' or O.CLIENTE='DCP' or O.CLIENTE='SAGA') AND O.CODI_ADUAN = '235' AND to_char(oi.fec_iteracion,'HH24:MI') >= '08:00' AND to_char(oi.fec_iteracion,'HH24:MI') <= '19:00' THEN  'dentro del corte'
                WHEN to_char(oi.fec_iteracion,'HH24:MI') >= '08:00' AND to_char(oi.fec_iteracion,'HH24:MI') <= '17:00' THEN  'dentro del corte'
                ELSE 'fuera del corte'
          END Desc_Corte
        FROM ORDEN O
        INNER JOIN orden_iteraciones_prod OI ON OI.ANO_PRESE=O.ANO_PRESE AND oi.EMPRESA=O.EMPRESA AND TRIM(oi.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(oi.CODI_REGI) = TRIM(O.CODI_REGI) AND oi.NUME_ORDEN = O.NUME_ORDEN
        LEFT JOIN ORDEN_INDICADOR_JM JM ON ( JM.ANO_PRESE = O.ANO_PRESE AND JM.EMPRESA = O.EMPRESA AND TRIM(JM.CODI_ADUAN) = TRIM(O.CODI_ADUAN) AND TRIM(JM.CODI_REGI) = TRIM(O.CODI_REGI) AND JM.NUME_ORDEN = O.NUME_ORDEN)
        WHERE O.EMPRESA = '001' AND O.FECHA_INICIO_PRODUCCION IS NOT NULL
        AND TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN to_date('1/01/2022','dd/mm/yyyy') AND to_date('31/12/2022','dd/mm/yyyy')
        AND oi.fec_iteracion = (select max(fec_iteracion) FROM orden_iteraciones_prod WHERE nume_orden = oi.nume_orden AND empresa = oi.empresa AND ano_prese = oi.ano_prese)
        ORDER BY NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) asc)
        WHERE nro_series > 0

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--CREATE OR REPLACE VIEW V_PRODUCTIVIDAD AS 
SELECT 
(SELECT RASON_SOCIAL from CLIENTES where CODIGOANT = O.CODI_CLIE AND ROWNUM=1) CLIENTE,
(SELECT PESO FROM CLIENTES WHERE CODIGOANT IS NOT NULL AND CODIGOANT = O.CODI_CLIE AND EMPRESA='001') PESO,
TO_CHAR(nvl(O.fec_numeracion_w, O.fec_numeracion),'MM') MES,
(SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO  FROM TRABAJADORES WHERE COD_ASCINSA = JM.COMERCIAL AND ROWNUM = 1) COMERCIAL,
(SELECT PNOMBRE || ' ' || SNOMBRE|| ' ' ||APATERNO|| ' ' || AMATERNO FROM TRABAJADORES T WHERE T.CTRABAJADOR = (SELECT JEFE_INMEDIATO  FROM TRABAJADORES R WHERE JM.COMERCIAL = R.COD_ASCINSA )) JEFE_INMEDIATO ,
COUNT(*) TOTAL,
F_TOTALXPESO(O.CODI_CLIE,COUNT(*)) CANTXPESO
FROM ORDEN O
LEFT JOIN ORDEN_INDICADOR_JM JM ON (JM.ANO_PRESE = O.ANO_PRESE AND JM.NUME_ORDEN = O.NUME_ORDEN AND JM.CODI_REGI = O.CODI_REGI AND JM.CODI_ADUAN = O.CODI_ADUAN)
WHERE O.ANO_PRESE = TO_CHAR(sysdate,'YYYY') AND O.fec_numeracion IS NOT NULL AND O.codi_regi <>'40' AND O.flag_parcial_deposito = '0'
GROUP BY O.CLIENTE,O.CODI_CLIE,TO_CHAR(nvl(O.fec_numeracion_w, O.fec_numeracion),'MM'),JM.COMERCIAL
ORDER BY O.CLIENTE,O.CODI_CLIE,TO_CHAR(nvl(O.fec_numeracion_w, O.fec_numeracion),'MM'),JM.COMERCIAL;


SELECT CLIENTE,COMERCIAL,JEFE_INMEDIATO,
'01' ||'/'|| MES ||'/'|| TO_CHAR(SYSDATE,'YYYY')  FECHA,PESO,TOTAL,CANTXPESO
FROM V_PRODUCTIVIDAD ;

-------DEVOLUCIONES----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
DECODE (O.FLAG_TIPO_LINEA,1, 'RAPIDA',2, 'NORMAL') "LINEA",
OE.nume_orden,OE.codi_regi,OE.codi_aduan,OE.ANO_PRESE,o.cliente,  
O.NRO_SERIES_PRENUME,decode(oe.codigo_error,1,'Documentos con error',2,'Despacho Avanzado',3,'Faltan Docs y/o Datos',4,'Devolución',null) Tipo_Complejidad,
oe.ETAPA,et.descripcion,
F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN) ETA,
oe.fec_ingreso_produccion Fecha_Ingreso_Produccion, 
oe.cod_actividad_orden, 
oe.FEC_ASIGNACION Fecha_Asignacion,
oe.fecha_registro Fecha_Rechazo,
nvl( oe.OBSERVACION,oe.DESCRIPCION_ERROR) MOTIVO, 
oe.usuario_registro  Usuario_Produccion,
oe.nombre_usuario_registro Nombre_Produccion,
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


-------------LLEGADA-VS-ENVIOS-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT /*+ result_cache */ NUME_ORDEN,PAIS,PUERTO,REGIMEN,ADUANA,AÑO,CLIENTE,TIPO_CLIENTE,NRO_SERIES,FECHA_INGRESO_PRODUCCION,ETA,VERIFICADOR1,FECHA_NUMERACION,FECHA_LLEGADA,DESC_DIA_LLEGADA,CORTE_LLEGADA,FECHA_ULTIMO_ENVIO,CORTE_ULT_ENV,VERIFICADOR3,DIFERENCIA_DIAS,VERIFICADOR2,ANALISIS,MODALIDAD,
F_DESC_ANALISIS1(VERIFICADOR2,ANALISIS)DESC_ANALISIS1,F_DESC_ANALISIS2(VERIFICADOR2,ANALISIS) DESC_ANALISIS2,NOMBRE_COMERCIAL,JEFE_COMERCIAL
FROM VISTA_REPORTE_ENVIO_LLEGADA;

--------------------------

SELECT CLIENTE,COMERCIAL,JEFE_INMEDIATO,
'01' ||'/'|| MES ||'/'|| TO_CHAR(SYSDATE,'YYYY')  FECHA,PESO,TOTAL,CANTXPESO
FROM V_PRODUCTIVIDAD_EXPO

