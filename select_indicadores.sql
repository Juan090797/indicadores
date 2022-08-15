select 
        ANO_PRESE,
        CODI_ADUAN,
        CODI_REGI,
        NUME_ORDEN,
        CLIENTE,
        NRO_SERIES,
        INGRESO_PRODUCCION,
        ETA,
        fec_numerac FECHA_NUMERACION,
        to_char(fec_numerac,'DD/MM/YYYY') MES_NUMERACION,
        to_char(fec_numerac,'HH24:MI') HORA_NUMERACION,
        CASE    WHEN to_char(fec_numerac,'DD/MM/YYYY') = to_char(Fecha_Hora_Ult_Produccion,'DD/MM/YYYY') THEN 'Mismo dia'
                WHEN trunc(fec_numerac) - trunc(Fecha_Hora_Ult_Produccion) = 1 and to_char(fec_numerac,'HH24:MI') < '08:00:00'  and DESC_CORTE = 'fuera del corte' THEN 'Mismo dia, madrugada'
                ELSE 'Distintos dias'
        END ANALISIS_NUM_ENVIO,
        Fecha_Hora_Ult_Produccion FECHA_ULT_PROD,
        to_char(Fecha_Hora_Ult_Produccion,'DD/MM/YYYY') MES_ULT_PROD,
        to_char(Fecha_Hora_Ult_Produccion,'HH24:MI') HORA_ULT_PROD,
        CASE    WHEN to_number(INICIO_DESC_HORA) < 9 THEN INICIO_DESC_HORA || '-' || '0' || (to_number(INICIO_DESC_HORA) + 1)
                ELSE INICIO_DESC_HORA || '-' || (to_number(INICIO_DESC_HORA) + 1)
        END DESC_HORA_T,
        INICIO_DESC_HORA INICIO_HORA,
        DESC_CORTE,
        Modalidad,
        NOMBRE_COMERCIAL,
        jefe_comercial,
        ANALISTA,
        LIQUIDADOR,
        REVISOR,
        TIEMPO_ETA_NUMERACION,
        TIEMPO_IPRODUC_NUMERACION
        
        from(SELECT O.ANO_PRESE, O.CODI_ADUAN, O.CODI_REGI, O.NUME_ORDEN, O.CLIENTE, 
            (SELECT COUNT(1) FROM ORDEN_DETALLE OD WHERE OD.EMPRESA = O.EMPRESA AND OD.ANO_PRESE = O.ANO_PRESE AND OD.CODI_ADUAN = O.CODI_ADUAN AND TRIM(OD.CODI_REGI)=TRIM(O.CODI_REGI) AND OD.NUME_ORDEN = O.NUME_ORDEN) NRO_SERIES,
            O.FECHA_INICIO_PRODUCCION INGRESO_PRODUCCION,
            to_char(F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),'DD/MM/YYYY') ETA,
            NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) fec_numerac,
            oi.fec_iteracion Fecha_Hora_Ult_Produccion,
            --to_number(to_char(oi.fec_iteracion,'HH24') ) || '-' || (to_number( to_char(oi.fec_iteracion,'HH24'))+1) Desc_Hora,
            to_char(oi.fec_iteracion,'HH24') Inicio_Desc_Hora,
            decode(O.CODI_TDESP,'1-0','Anticipado','0-0','Excepcional','0-1','Urgente','') Modalidad,
            O.COMERCIAL,
            (select pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno from trabajadores t where o.comercial = t.cod_ascinsa ) nombre_comercial,
            (select t.jefe_inmediato from trabajadores t where o.comercial = t.cod_ascinsa) dni_jefe_comercial,
            (select pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno from trabajadores t where t.ctrabajador = (select jefe_inmediato  from trabajadores r where o.comercial = r.cod_ascinsa )) jefe_comercial,
            O.REVISOR ANALISTA,
            O.DIGITADOR LIQUIDADOR,
            O.USUARIO_VB_DIGITACION REVISOR,
          case when F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN)<NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) 
               then  f_tiemposy(f_restar_fechas( F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION),1,3,0),13) 
               else  f_tiemposy(f_restar_fechas(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION), F_FECHA_ETA_VBF(O.EMPRESA,O.ANO_PRESE,O.CODI_ADUAN,TRIM(O.CODI_REGI),O.NUME_ORDEN),1,3,0),13) 
          end TIEMPO_ETA_NUMERACION,
          f_tiemposy(f_restar_fechas(O.FECHA_INICIO_PRODUCCION,   NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION),1,3,0),13)   TIEMPO_IPRODUC_NUMERACION,
          CASE  WHEN (O.CODI_ADUAN = '235' or O.CLIENTE='SAMSUNG' or O.CLIENTE='KOMATSU' or O.CLIENTE='INGRAM' or O.CLIENTE='DCP' or O.CLIENTE='SAGA') and to_char(oi.fec_iteracion,'HH24:MI') >= '08:00' and to_char(oi.fec_iteracion,'HH24:MI') <= '19:00' THEN  'dentro del corte'
                WHEN to_char(oi.fec_iteracion,'HH24:MI') >= '08:00' and to_char(oi.fec_iteracion,'HH24:MI') <= '17:00' THEN  'dentro del corte'
                ELSE 'fuera del corte'
          END Desc_Corte
        FROM ORDEN O
        inner join orden_iteraciones_prod oi on oi.ano_prese=O.ano_prese and oi.empresa=O.empresa and trim(oi.codi_aduan)=trim(O.codi_aduan) and trim(oi.codi_regi)=trim(O.codi_regi) and oi.nume_orden=O.nume_orden
        WHERE O.EMPRESA = '001' AND O.FECHA_INICIO_PRODUCCION IS NOT NULL
        AND TRUNC(NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION)) BETWEEN to_date('1/07/2022','dd/mm/yyyy') AND to_date('31/07/2022','dd/mm/yyyy')
        and oi.fec_iteracion = (select max(fec_iteracion) from orden_iteraciones_prod where nume_orden = oi.nume_orden and empresa = oi.empresa and ano_prese = oi.ano_prese)
        ORDER BY NVL(O.FEC_NUMERACION_W, O.FEC_NUMERACION) asc)
        WHERE nro_series > 0

----PRODUCTIVIDAD---------------------------------------------------------------

        select  
        LINEA,
        COMERCIAL,
        CLIENTE_NOMBRE,
        N_ORDENES,
        PESO,
        (PESO*N_ORDENES) TOTAL_PESO
FROM(select tabesc.linea,
tabesc.comercial,
(select rason_social from clientes where codigoant=orden.codi_clie and rownum=1) cliente, 
orden.cliente cliente_nombre,
case 
    when :meses = 1 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =1 and :meses>=1 then 1 else 0 end) 
    when :meses = 2 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =2 and :meses>=2 then 1 else 0 end) 
    when :meses = 3 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =3 and :meses>=3 then 1 else 0 end) 
    when :meses = 4 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =4 and :meses>=4 then 1 else 0 end) 
    when :meses = 5 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =5 and :meses>=5 then 1 else 0 end) 
    when :meses = 6 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =6 and :meses>=6 then 1 else 0 end) 
    when :meses = 7 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =7 and :meses>=7 then 1 else 0 end) 
    when :meses = 8 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =8 and :meses>=8 then 1 else 0 end) 
    when :meses = 9 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =9 and :meses>=9 then 1 else 0 end) 
    when :meses = 10 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =10 and :meses>=10 then 1 else 0 end) 
    when :meses = 11 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =11 and :meses>=11 then 1 else 0 end) 
    when :meses = 12 then sum(case when extract(month from nvl(fec_numeracion_w, fec_numeracion)) =12 and :meses>=12 then 1 else 0 end) 
    end N_ORDENES,
(select peso from clientes where codigoant=orden.codi_clie and empresa='001') peso
from orden left outer join
(select t.pnombre||' '||t.apaterno comercial, tc.codigoant codi_clie, lr.cod_linea_tra||'-'||lr.nombre linea
 from trabajador_cliente tc 
      join linea_trabajador lt on (tc.empresa=lt.empresa and tc.ctrabajador = lt.ctrabajador)
      join linea_trabajo lr on (lr.cod_linea_tra = lt.cod_linea_tra)
      join trabajadores t on(tc.ctrabajador = t.ctrabajador and t.cargo='16')
      where t.est_trabajador='S' AND t.ctrabajador not in ('25861057','45172841','10880162','70490898')
  ) tabesc
on (orden.codi_clie = tabesc.codi_clie)
where ano_prese='2022' and 
      codi_regi <>'40' and 
      flag_parcial_deposito = '0' and
      fec_numeracion is not null and
      tabesc.linea is not null
group by tabesc.linea, 
tabesc.comercial,
orden.codi_clie,
orden.cliente
order by tabesc.linea, tabesc.comercial, orden.codi_clie)

---DEVOLUCIONES----------------------------------------------------------------------------------------------
SELECT OE.nume_orden,OE.codi_regi,OE.codi_aduan,OE.ano_prese,
      o.cliente,  O.NRO_SERIES_PRENUME,decode(oe.codigo_error,1,'Documentos con error',2,'Despacho Avanzado',3,'Faltan Docs y/o Datos',4,'Devolución',null) Tipo_Complejidad,
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
      (select pnombre || ' ' || apaterno|| ' ' ||amaterno|| ' ' || apaterno from trabajadores t where t.ctrabajador = (select jefe_inmediato  from trabajadores r where o.comercial = r.cod_ascinsa )) jefe_comercial,
	  DECODE (O.FLAG_TIPO_LINEA,1, 'RAPIDA',2, 'NORMAL') "LINEA"
      FROM ORDEN_ERRORES OE 
      inner JOIN  ORDEN  O ON o.ano_prese=oe.ano_prese AND trim(o.codi_regi)=trim(oe.codi_regi) AND trim(o.codi_aduan)=trim(oe.codi_aduan) AND o.nume_orden=oe.nume_orden and o.empresa=oe.empresa 
      left join orden_etapas et on Oe.empresa=et.empresa and oe.etapa=et.codigo 
      WHERE (OE.COD_ACTIVIDAD_ORDEN IN  ('161','165','97','163','162') OR OE.COD_TAREA_ORDEN in ('643','645','649','3181','641')) AND (( OE.OBSERVACION IS NOT NULL)OR( OE.DESCRIPCION_ERROR IS NOT NULL))
      and (NVL(oe.tipo_responsable,'COM')='COM')  and  (O.FLAG_TIPO_LINEA=1 or O.FLAG_TIPO_LINEA=2)
      and oe.empresa='001' and TRUNC(oe.fecha_registro )  BETWEEN to_date('1/07/2022','dd/mm/yyyy') AND to_date('31/07/2022','dd/mm/yyyy')
	order by OE.nume_orden, oe.fecha_registro