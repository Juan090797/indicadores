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



-------PRODUCTIVIDADV2------
SELECT 
(select rason_social from clientes where codigoant=codi_clie AND ROWNUM=1) CLIENTE,
(SELECT PESO FROM CLIENTES WHERE CODIGOANT IS NOT NULL AND CODIGOANT = CODI_CLIE AND EMPRESA='001') PESO,
TO_CHAR(nvl(fec_numeracion_w, fec_numeracion),'MONTH') MES,
(SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO  FROM TRABAJADORES WHERE COD_ASCINSA = COMERCIAL AND ROWNUM=1) COMERCIAL,
(select PNOMBRE || ' ' || SNOMBRE|| ' ' ||APATERNO|| ' ' || AMATERNO FROM TRABAJADORES t WHERE t.ctrabajador = (SELECT jefe_inmediato  FROM trabajadores r WHERE COMERCIAL = r.cod_ascinsa )) JEFE_INMEDIATO, 
COUNT(*) TOTAL,
F_TOTALXPESO(CODI_CLIE,COUNT(*)) CANTXPESO
FROM ORDEN WHERE ANO_PRESE = TO_CHAR(sysdate,'YYYY') AND fec_numeracion IS NOT NULL AND codi_regi <>'40' AND flag_parcial_deposito = '0'
GROUP BY CLIENTE,CODI_CLIE,TO_CHAR(nvl(fec_numeracion_w, fec_numeracion),'MONTH'),COMERCIAL
ORDER BY CLIENTE,CODI_CLIE,TO_CHAR(nvl(fec_numeracion_w, fec_numeracion),'MONTH'),COMERCIAL

-------PRODUCTIVIDADV3------

CREATE OR REPLACE VIEW V_PRODUCTIVIDAD AS 
SELECT 
(select rason_social from clientes where codigoant=codi_clie AND ROWNUM=1) CLIENTE,
(SELECT PESO FROM CLIENTES WHERE CODIGOANT IS NOT NULL AND CODIGOANT = CODI_CLIE AND EMPRESA='001') PESO,
TO_CHAR(nvl(fec_numeracion_w, fec_numeracion),'MM') MES,
(SELECT PNOMBRE ||' '|| SNOMBRE ||' '|| APATERNO ||' '|| AMATERNO  FROM TRABAJADORES WHERE COD_ASCINSA = COMERCIAL AND ROWNUM=1) COMERCIAL,
(select PNOMBRE || ' ' || SNOMBRE|| ' ' ||APATERNO|| ' ' || AMATERNO FROM TRABAJADORES t WHERE t.ctrabajador = (SELECT jefe_inmediato  FROM trabajadores r WHERE COMERCIAL = r.cod_ascinsa )) JEFE_INMEDIATO, 
COUNT(*) TOTAL,
F_TOTALXPESO(CODI_CLIE,COUNT(*)) CANTXPESO
FROM ORDEN WHERE ANO_PRESE = TO_CHAR(sysdate,'YYYY') AND fec_numeracion IS NOT NULL AND codi_regi <>'40' AND flag_parcial_deposito = '0'
GROUP BY CLIENTE,CODI_CLIE,TO_CHAR(nvl(fec_numeracion_w, fec_numeracion),'MM'),COMERCIAL
ORDER BY CLIENTE,CODI_CLIE,TO_CHAR(nvl(fec_numeracion_w, fec_numeracion),'MM'),COMERCIAL;


SELECT CLIENTE,COMERCIAL,JEFE_INMEDIATO,
'01' ||'/'|| MES ||'/'|| TO_CHAR(SYSDATE,'YYYY')  FECHA,PESO,TOTAL,CANTXPESO
FROM V_PRODUCTIVIDAD 


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
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno  from trabajadores r where o.comercial = r.cod_ascinsa ) Nombre_Ejecutivo,
(select pnombre || ' ' || snombre|| ' ' ||apaterno|| ' ' || amaterno from trabajadores t where t.ctrabajador = (select jefe_inmediato  from trabajadores r where o.comercial = r.cod_ascinsa )) jefe_comercial
FROM ORDEN_ERRORES OE 
inner JOIN  ORDEN  O ON o.ano_prese=oe.ano_prese AND trim(o.codi_regi)=trim(oe.codi_regi) AND trim(o.codi_aduan)=trim(oe.codi_aduan) AND o.nume_orden=oe.nume_orden and o.empresa=oe.empresa 
left join orden_etapas et on Oe.empresa=et.empresa and oe.etapa=et.codigo 
WHERE (OE.COD_ACTIVIDAD_ORDEN IN  ('161','165','97','163','162') OR OE.COD_TAREA_ORDEN in ('643','645','649','3181','641')) AND (( OE.OBSERVACION IS NOT NULL)OR( OE.DESCRIPCION_ERROR IS NOT NULL))
and (NVL(oe.tipo_responsable,'COM')='COM')  and  (O.FLAG_TIPO_LINEA=1 or O.FLAG_TIPO_LINEA=2)
and oe.empresa='001' and TRUNC(oe.fecha_registro )  BETWEEN to_date('01/01/2022','dd/mm/yyyy') AND to_date('31/12/2022','dd/mm/yyyy')
order by OE.nume_orden, oe.fecha_registro

---LLEGADA-VS-ENVIOS-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT NUME_ORDEN,REGIMEN,ADUANA,AÑO,CLIENTE,TIPO_CLIENTE,NRO_SERIES,FECHA_INGRESO_PRODUCCION,ETA,VERIFICADOR1,FECHA_NUMERACION,FECHA_LLEGADA,DESC_DIA_LLEGADA,CORTE_LLEGADA,FECHA_ULTIMO_ENVIO,CORTE_ULT_ENV,VERIFICADOR3,DIFERENCIA_DIAS,VERIFICADOR2,ANALISIS,MODALIDAD,
F_DESC_ANALISIS1(VERIFICADOR2,ANALISIS)DESC_ANALISIS1,F_DESC_ANALISIS2(VERIFICADOR2,ANALISIS) DESC_ANALISIS2,
(SELECT pnombre || ' ' || snombre|| ' ' || apaterno|| ' ' ||amaterno FROM trabajadores t where COMERCIAL = t.cod_ascinsa ) NOM_COMERCIAL,
(SELECT pnombre || ' ' || snombre|| ' ' || apaterno|| ' ' ||amaterno FROM trabajadores t where t.ctrabajador = (SELECT jefe_inmediato  FROM trabajadores r where COMERCIAL = r.cod_ascinsa )) JEFE_COMERCIAL
FROM VISTA_REPORTEENVIOLLEGADA;
-----LLEGADA-VS-ENVIOSV2------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT /*+ result_cache */ NUME_ORDEN,REGIMEN,ADUANA,AÑO,CLIENTE,TIPO_CLIENTE,NRO_SERIES,FECHA_INGRESO_PRODUCCION,ETA,VERIFICADOR1,FECHA_NUMERACION,FECHA_LLEGADA,DESC_DIA_LLEGADA,CORTE_LLEGADA,FECHA_ULTIMO_ENVIO,CORTE_ULT_ENV,VERIFICADOR3,DIFERENCIA_DIAS,VERIFICADOR2,ANALISIS,MODALIDAD,
F_DESC_ANALISIS1(VERIFICADOR2,ANALISIS)DESC_ANALISIS1,F_DESC_ANALISIS2(VERIFICADOR2,ANALISIS) DESC_ANALISIS2,NOMBRE_COMERCIAL,JEFE_COMERCIAL
FROM VISTA_REPORTE_ENVIO_LLEGADA;



-------------INDICADORES MAYRA--------------------------------------------------------------------------------------------------------------------------------------

-------------ANALISIS_FACTURAS_VINCULADAS-----------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
        RUC_PROVEEDOR,RAZON_SOCIAL,TIPO_DOCUMENTO,NRO_DOC,FECHA_EMISION,FECHA_SUBIDA_FACTURA,TO_CHAR(FECHA_SUBIDA_FACTURA,'MONTH') MES,ORDEN_VINCULADA,FECHA_VINCULO_ORDEN,USUARIO_VINCULO_ORDEN,FORMA_SUBIDA_FACTURA,
        FEC_SUBIDA,FEC_VINCULACION,
        (TRUNC(FEC_VINCULACION) - TRUNC(FEC_SUBIDA)) DIAS_SIN_FDS,
        F_VALIDAR_REPORT(TRUNC(FEC_VINCULACION) - TRUNC(FEC_SUBIDA)) FILTRO_SIN_FDS,
        (F_DIAS_HABILES_JMV(FEC_SUBIDA,FEC_VINCULACION) - 1) DIFERENCIA_DIAS_UTILES,
        F_VALIDAR_REPORT(F_DIAS_HABILES_JMV(FEC_SUBIDA,FEC_VINCULACION) - 1) INDICADOR,
        CASE WHEN F_VALIDAR_REPORT(TRUNC(FEC_VINCULACION) - TRUNC(FEC_SUBIDA)) = F_VALIDAR_REPORT(F_DIAS_HABILES_JMV(FEC_SUBIDA,FEC_VINCULACION) - 1) THEN 'IGUAL'
             ELSE 'DIFERENTE'
        END VALIDACION
FROM(SELECT  RUC_PROVEEDOR,
        razon_social,
        ruc_adquirente,
        razon_social_adquirente,
        decode(TIPO_DOCUMENTO,'01','FACTURA','07','NOTA CREDITO','08','NOTA DEBITO','NO ESPECIFICADO')TIPO_DOCUMENTO,
        serie || '-'|| numero_documento nro_doc,
        fecha_emision,
        fecha_registro AS FECHA_SUBIDA_FACTURA,        
        nume_orden ORDEN_VINCULADA,
        f_cargar_orden AS FECHA_VINCULO_ORDEN,
        usuario_cargar_orden AS USUARIO_VINCULO_ORDEN,
        DECODE(version_ubl,'2.1','AUTOMATICO','MANUAL') FORMA_SUBIDA_FACTURA,
        CASE WHEN '18:00' > TO_CHAR(fecha_registro,'HH24:MI') THEN TRUNC(fecha_registro)
             ELSE (TRUNC(fecha_registro)+1)
        END FEC_SUBIDA,
        TRUNC(f_cargar_orden) FEC_VINCULACION
        FROM face_facturamz 
        WHERE FECHA_EMISION BETWEEN ('01/01/2022') AND ('31/12/2022') AND TIPO_DOCUMENTO = '01' AND RUC_PROVEEDOR NOT IN ('20100246768','20100457629') AND dar_baja_flag IS NULL AND nume_orden IS NOT NULL AND version_ubl = '2.1')
ORDER BY ORDEN_VINCULADA ASC

----------------CUMPLIMIENTO DEL PLAZO DE OBTENCION DEL PERMISO DE RETIRO EN TA MARITIMO------------------------------

SELECT 
NUME_ORDEN,CODI_ADUAN,CODI_REGI,CODI_TDESP,T_DESPACHO,ANO_PRESE,CLIENTE,CODI_CLIE,FEC_USUA_CREA,FEC_DESPACHO,HORARIO_DESPACHO,FEC_RETIRO,DOC_COMPLETA,FEC_DOC_COMPLETA,COD_TERMINAL,NOMBRE_ALMACEN,TIPO_DIRECCIONAMIENTO,DIA_PROGRAMACION,CANT_FERIADO,
F_PROG_CORREGIDA(1,FEC_DESPACHO) FECHA_PROG_CORREGIDA,
CASE WHEN DIA_FECHA_COM = 'SÁBADO   ' AND TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI') > '12:00'  THEN 'VERDADERO'
     ELSE 'FALSO'
END SABADO_MAS_DE_LAS_12,
F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA) FECHA_DOC_CORREGIDA,
DIA_FECHA_COM,MES_FECHA_COM,
(TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) - TRUNC(F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA))) DIFERENCIA_DIAS,
CASE WHEN (CODI_ADUAN = '118' AND (NOMBRE_ALMACEN ='DP WORLD CALLAO S.R.L.' OR NOMBRE_ALMACEN ='APM TERMINALS INLAND SERVICES S.A.')) OR CODI_ADUAN <> '118' THEN 'NO APLICA'
     ELSE 'APLICA'
END VERIFICADOR2,
CASE WHEN HORARIO_DESPACHO IS NULL  THEN 'NO HAY FECHA DE PROGRAMACION'
     ELSE 
        CASE WHEN FEC_DOC_COMPLETA IS NULL THEN 'NO HAY FECHA DE DOCUMENTACION'
        ELSE
            CASE WHEN (TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) - TRUNC(F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA)))>=1 THEN 'SI CUMPLE'
            ELSE 'NO CUMPLE'
            END
        END
END INDICADOR2
FROM(select o.nume_orden,o.codi_aduan,o.codi_regi,o.codi_tdesp,
--o.tipo_despacho,
(SELECT DESCRIPCION  FROM TIPO_ANTICIPADO  where ADUANA = o.codi_aduan  and codigo=o.tipo_despacho) as t_despacho,
o.ano_prese,o.cliente,o.codi_clie,a.fec_usua_crea,a.fec_despacho,
(select des_horario from horario where cod_horario=a.hor_prog)horario_despacho,
--a.hor_prog,
o.fec_retiro,a.doc_completa,a.fec_doc_completa,o.cod_terminal,o.nombre_almacen,
(select TIPO_DIRECCIONAMIENTO FROM SOLICITUD_VB LEFT JOIN  solicitud_vb_orden S ON (S.anio_Solicitud=SOLICITUD_VB.ANIO_SOLICITUD and S.nro_solicitud=SOLICITUD_VB.NRO_SOLICITUD and S.orden_madre=1) WHERE (SOLICITUD_VB.EMPRESA = '001') and (s.ano_prese = a.ano_prese) and (s.nume_orden = o.nume_orden) and rownum=1) tipo_direccionamiento,
TO_CHAR(a.fec_despacho,'DAY') DIA_PROGRAMACION,
F_DIA_FERIADO(a.fec_despacho) CANT_FERIADO,
TO_CHAR(a.fec_doc_completa,'DAY') DIA_FECHA_COM,
TO_CHAR(a.fec_doc_completa,'MONTH') MES_FECHA_COM
from orden O 
inner join prog_despacho_cab A on o.empresa=a.empresa and  o.nume_orden=a.nume_orden and o.codi_regi=a.codi_regi and o.codi_aduan=a.codi_aduan and o.ano_prese=a.ano_prese
where TRUNC(o.fec_retiro) BETWEEN TRUNC(to_date('01/01/2022')) AND TRUNC(to_date('31/12/2022')))
WHERE FEC_DOC_COMPLETA is null
ORDER BY NUME_ORDEN ASC
--WHERE NUME_ORDEN ='008497'
-----------------INDICADOR2--------------------------------------
SELECT NUME_ORDEN,CODI_ADUAN,CODI_REGI,CODI_TDESP,T_DESPACHO,ANO_PRESE,CLIENTE,CODI_CLIE,FEC_USUA_CREA,FEC_DESPACHO,HORARIO_DESPACHO,FEC_RETIRO,DOC_COMPLETA,FEC_DOC_COMPLETA,COD_TERMINAL,NOMBRE_ALMACEN,TIPO_DIRECCIONAMIENTO,DIA_PROGRAMACION,CANT_FERIADO,
F_PROG_CORREGIDA(1,FEC_DESPACHO) FECHA_PROG_CORREGIDA,
CASE WHEN DIA_FECHA_COM = 'SÁBADO   ' AND TO_CHAR(FEC_DOC_COMPLETA,'HH24:MI') > '12:00'  THEN 'VERDADERO'
     ELSE 'FALSO'
END SABADO_MAS_DE_LAS_12,
F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA) FECHA_DOC_CORREGIDA,DIA_FECHA_COM,MES_FECHA_COM,
(TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) - TRUNC(F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA))) DIFERENCIA_DIAS,
CASE WHEN (CODI_ADUAN = '118' AND (NOMBRE_ALMACEN ='DP WORLD CALLAO S.R.L.' OR NOMBRE_ALMACEN ='APM TERMINALS INLAND SERVICES S.A.')) OR CODI_ADUAN <> '118' THEN 'NO APLICA'
     ELSE 'APLICA'
END VERIFICADOR2,
CASE WHEN HORARIO_DESPACHO IS NULL  THEN 'NO HAY FECHA DE PROGRAMACION'
     ELSE 
        CASE WHEN FEC_DOC_COMPLETA IS NULL THEN 'NO HAY FECHA DE DOCUMENTACION'
        ELSE
            CASE WHEN (TRUNC(F_PROG_CORREGIDA(1,FEC_DESPACHO)) - TRUNC(F_PROG_CORREGIDA(2,FEC_DOC_COMPLETA)))>=1 THEN 'SI CUMPLE'
            ELSE 'NO CUMPLE'
            END
        END
END INDICADOR2
FROM(select o.nume_orden,o.codi_aduan,o.codi_regi,o.codi_tdesp,
(SELECT DESCRIPCION  FROM TIPO_ANTICIPADO  where ADUANA = o.codi_aduan  and codigo=o.tipo_despacho) as t_despacho,
o.ano_prese,o.cliente,o.codi_clie,a.fec_usua_crea,a.fec_despacho,
(select des_horario from horario where cod_horario=a.hor_prog)horario_despacho,
o.fec_retiro,a.doc_completa,a.fec_doc_completa,o.cod_terminal,o.nombre_almacen,
(select TIPO_DIRECCIONAMIENTO FROM SOLICITUD_VB LEFT JOIN solicitud_vb_orden S ON (S.anio_Solicitud=SOLICITUD_VB.ANIO_SOLICITUD and S.nro_solicitud=SOLICITUD_VB.NRO_SOLICITUD and S.orden_madre=1) WHERE (SOLICITUD_VB.EMPRESA = '001') and (s.ano_prese = a.ano_prese) and (s.nume_orden = o.nume_orden) and rownum=1) tipo_direccionamiento,
TO_CHAR(a.fec_despacho,'DAY') DIA_PROGRAMACION,
F_DIA_FERIADO(a.fec_despacho) CANT_FERIADO,
TO_CHAR(a.fec_doc_completa,'DAY') DIA_FECHA_COM,
TO_CHAR(a.fec_doc_completa,'MONTH') MES_FECHA_COM
from orden O 
inner join prog_despacho_cab A on o.empresa=a.empresa and  o.nume_orden=a.nume_orden and o.codi_regi=a.codi_regi and o.codi_aduan=a.codi_aduan and o.ano_prese=a.ano_prese
WHERE TO_CHAR(o.fec_retiro,'YYYY') = TO_CHAR(SYSDATE,'YYYY') )
--TRUNC(o.fec_retiro) BETWEEN TRUNC(to_date('01/01/2022')) AND TRUNC(to_date('31/12/2022')))
--WHERE FEC_DOC_COMPLETA is not null
ORDER BY NUME_ORDEN ASC
--WHERE NUME_ORDEN ='008497'


F002-879685
