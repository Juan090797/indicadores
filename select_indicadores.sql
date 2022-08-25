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
            (select pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno FROM trabajadores t where o.comercial = t.cod_ascinsa ) nombre_comercial,
            (select t.jefe_inmediato FROM trabajadores t where o.comercial = t.cod_ascinsa) dni_jefe_comercial,
            (select pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno FROM trabajadores t where t.ctrabajador = (select jefe_inmediato  FROM trabajadores r where o.comercial = r.cod_ascinsa )) jefe_comercial,
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
        inner join orden_iteraciones_prod oi on oi.ano_prese=O.ano_prese AND oi.empresa=O.empresa AND trim(oi.codi_aduan)=trim(O.codi_aduan) AND trim(oi.codi_regi)=trim(O.codi_regi) AND oi.nume_orden=O.nume_orden
        WHERE O.EMPRESA = '001' AND O.FECHA_INICIO_PRODUCCION IS NOT NULL
        AND TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN to_date('1/01/2022','dd/mm/yyyy') AND to_date('31/12/2022','dd/mm/yyyy')
        AND oi.fec_iteracion = (select max(fec_iteracion) FROM orden_iteraciones_prod WHERE nume_orden = oi.nume_orden AND empresa = oi.empresa AND ano_prese = oi.ano_prese)
        ORDER BY NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) asc)
        WHERE nro_series > 0
----PRODUCTIVIDAD---------------------------------------------------------------

select tabesc.linea,tabesc.comercial,
(select rason_social from clientes where codigoant=ordenX.codi_clie and rownum=1) cliente,
to_char(fecha, 'Month') mes,
to_char(fecha,'DD/MM/YYYY') FECHA_COMPLETA,
count(*) CANT_ORDENES,
(select peso from clientes where codigoant=ordenX.codi_clie and empresa='001') peso,
F_TOTALXPESO(ordenX.codi_clie,count(*)) cantxpeso
from (select nvl(fec_numeracion_w, fec_numeracion) fecha,codi_clie, ano_prese, codi_regi,flag_parcial_deposito from orden where fec_numeracion is not null ) ordenX left outer join
(select t.pnombre||' '||t.apaterno comercial, tc.codigoant codi_clie, lr.cod_linea_tra||'-'||lr.nombre linea
 from trabajador_cliente tc join linea_trabajador lt on (tc.empresa=lt.empresa and tc.ctrabajador = lt.ctrabajador)
      join linea_trabajo lr on (lr.cod_linea_tra = lt.cod_linea_tra)
      join trabajadores t on(tc.ctrabajador = t.ctrabajador and t.cargo='16')
      where t.est_trabajador='S' AND t.ctrabajador not in ('25861057','45172841','10880162','70490898')
) tabesc on (ordenX.codi_clie = tabesc.codi_clie)
where ano_prese='2022' and codi_regi <>'40' and flag_parcial_deposito = '0' and tabesc.linea is not null
group by tabesc.linea,tabesc.comercial,ordenX.codi_clie, to_char(fecha, 'Month'),to_char(fecha,'DD/MM/YYYY')
order by tabesc.linea, tabesc.comercial, ordenX.codi_clie, mes

---DEVOLUCIONES----------------------------------------------------------------------------------------------
SELECT 
DECODE (O.FLAG_TIPO_LINEA,1, 'RAPIDA',2, 'NORMAL') "LINEA",
OE.nume_orden,OE.codi_regi,OE.codi_aduan,OE.ano_prese,o.cliente,  
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
RESPONSABLE_ERROR Ejecutivo,
oe.nombre_responsable Nombre_Ejecutivo,
(select pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno from trabajadores t where t.ctrabajador = (select jefe_inmediato  from trabajadores r where o.comercial = r.cod_ascinsa )) jefe_comercial
FROM ORDEN_ERRORES OE 
inner JOIN  ORDEN  O ON o.ano_prese=oe.ano_prese AND trim(o.codi_regi)=trim(oe.codi_regi) AND trim(o.codi_aduan)=trim(oe.codi_aduan) AND o.nume_orden=oe.nume_orden and o.empresa=oe.empresa 
left join orden_etapas et on Oe.empresa=et.empresa and oe.etapa=et.codigo 
WHERE (OE.COD_ACTIVIDAD_ORDEN IN  ('161','165','97','163','162') OR OE.COD_TAREA_ORDEN in ('643','645','649','3181','641')) AND (( OE.OBSERVACION IS NOT NULL)OR( OE.DESCRIPCION_ERROR IS NOT NULL))
and (NVL(oe.tipo_responsable,'COM')='COM')  and  (O.FLAG_TIPO_LINEA=1 or O.FLAG_TIPO_LINEA=2)
and oe.empresa='001' and TRUNC(oe.fecha_registro )  BETWEEN to_date('1/07/2022','dd/mm/yyyy') AND to_date('31/07/2022','dd/mm/yyyy')
order by OE.nume_orden, oe.fecha_registro




---LLEGADA-VS-ENVIOS---------------------------------------------------------

SELECT nume_orden,regimen,aduana,año,cliente,tipo_cliente,NRO_SERIES,FECHA_INGRESO_PRODUCCION,eta,
      CASE WHEN  fecha_numeracion is null then 'x'
           ELSE 'OK'
      END VERIFICADOR1,
      fecha_numeracion,fecha_llegada,
      NVL(F_OBTENER_TIPO_DIA(fecha_llegada),'NO DEFINIDO') Desc_Dia_Llegada,
      NVL(F_VALIDAR_COR_HOR_LABORAL(CLIENTE,FECHA_LLEGADA,ADUANA,1),'NO DEFINIDO') CORTE_LLEGADA,
      FECHA_ULTIMO_ENVIO,
      NVL(F_OBTENER_TIPO_DIA(FECHA_ULTIMO_ENVIO),'NO DEFINIDO') Desc_Dia_envio,
      NVL(F_VALIDAR_COR_HOR_LABORAL(CLIENTE,FECHA_ULTIMO_ENVIO,ADUANA,2),'NO DEFINIDO') CORTE_ULT_ENV,
      F_DIAS_HABILES(trunc(FECHA_LLEGADA),trunc(FECHA_ULTIMO_ENVIO)) DIFERENCIA_DIAS,
      CASE  WHEN MODALIDAD = 'Anticipado' THEN  'REVISAR INDICADOR'
            ELSE 'FUERA DE ALCANCE'
      END VERIFICADOR2,
      MODALIDAD
FROM (SELECT oi.nume_orden,oi.codi_regi REGIMEN,oi.codi_aduan ADUANA,oi.ano_prese AÑO,o.cliente,O.FECHA_INICIO_PRODUCCION FECHA_INGRESO_PRODUCCION,
      F_TIPO_CLIENTE(o.cliente,oi.codi_aduan) TIPO_CLIENTE,
      (SELECT COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) NRO_SERIES,
     oi.fec_iteracion FECHA_ULTIMO_ENVIO,
     F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN) ETA,
     NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) FECHA_NUMERACION,
     NVL(F_FECHA_LLEGADA(o.EMPRESA,o.ANO_MANIFIESTO,o.CODI_ADUAN,o.NRO_MANIFIESTO), o.FECHA_LLEGADA) FECHA_LLEGADA,
     et.descripcion,oi.iteracion,
	 decode(O.CODI_TDESP,'1-0','Anticipado','0-0','Excepcional','0-1','Urgente','') MODALIDAD,
	 O.FLAG_TIPO_LINEA
     FROM orden_iteraciones_prod oi inner join orden o ON oi.ano_prese=o.ano_prese AND oi.empresa=o.empresa AND trim(oi.codi_aduan)=trim(o.codi_aduan) AND trim(oi.codi_regi)=trim(o.codi_regi) AND oi.nume_orden=o.nume_orden
     left join orden_etapas et ON oi.empresa=et.empresa AND oi.etapa=et.codigo 
     WHERE (O.FLAG_TIPO_LINEA=1 OR O.FLAG_TIPO_LINEA=2)
     AND oi.empresa='001' AND TRUNC(oi.fec_iteracion ) BETWEEN to_date('1/01/2022','dd/mm/yyyy') AND to_date('31/07/2022','dd/mm/yyyy') 
     AND oi.fec_iteracion = (select max(fec_iteracion) FROM orden_iteraciones_prod WHERE nume_orden = oi.nume_orden AND empresa = oi.empresa AND ano_prese = oi.ano_prese)
     order by oi.fec_iteracion, oi.nume_orden) 
WHERE nume_orden ='005963'