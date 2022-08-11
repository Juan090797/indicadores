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
        DESC_HORA,
        to_number(INICIO_DESC_HORA) INICIO_HORA,
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
            to_number(to_char(oi.fec_iteracion,'HH24') ) || '-' || (to_number( to_char(oi.fec_iteracion,'HH24'))+1) Desc_Hora,
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