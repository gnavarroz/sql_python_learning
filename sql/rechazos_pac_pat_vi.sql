 /*
Consulta: Rechazos_PAC_PAT_Vida_Individual
Autor: Gustavo Navarro
Descripción: Reporte de rechazos reintentables y reintentables de PAC-PAT Vida Individual
Última actualización: 2026-06-23
*/

DECLARE imputacion_desde DATE;
DECLARE imputacion_hasta DATE;

SET imputacion_desde = DATE('AAAA-MM-DD');
SET imputacion_hasta = DATE('AAAA-MM-DD');

WITH ROLES AS (
  SELECT
    r.scertype,
    r.nbranch,
    r.nproduct,
    r.npolicy,
    r.ncertif,
    CONCAT(MAX(IF(r.nrole = 1, PARSE_NUMERIC(cl.sclient), NULL)), MAX(IF(r.nrole = 1, cl.sdigit, NULL))) AS RUT_CLIENTE,
    MAX(IF(r.nrole = 1, INITCAP(TRIM(cl.scliename)), NULL)) AS NOMBRE_CLIENTE,
    CONCAT(MAX(IF(r.nrole = 13, PARSE_NUMERIC(cl.sclient), NULL)), MAX(IF(r.nrole = 13, cl.sdigit, NULL))) AS RUT_INTERMED,
    MAX(IF(r.nrole = 13, INITCAP(TRIM(cl.scliename)), NULL)) AS NOMBRE_INTERMEDIARIO,
  
  FROM `DS_VT_INSUDB.ROLES` r
  
  LEFT JOIN `DS_VT_INSUDB.CLIENT` cl
    ON r.sclient = cl.sclient
  
  WHERE r.scertype = '2'
    AND r.nbranch = 8
    AND r.nrole IN (1, 13)
    AND r.dnulldate IS NULL
  
  GROUP BY
    r.scertype,
    r.nbranch,
    r.nproduct,
    r.npolicy,
    r.ncertif
),

VP_POLIZAS AS (
  SELECT
    c.npolicy,
    REPLACE(CAST(SUM(acc.nbalance) AS STRING), '.', ',') AS VALOR_POLIZA

  FROM `DS_VT_INSUDB.CERTIFICAT` c
  
  LEFT JOIN `DS_VT_INSUDB.UL_SAVING_ACC_POL` acc
    ON c.scertype = acc.scertype
    AND c.nbranch = acc.nbranch
    AND c.nproduct = acc.nproduct
    AND c.npolicy = acc.npolicy
    AND c.ncertif = acc.ncertif
  
  WHERE c.scertype = '2'
    AND c.nbranch = 8
    AND c.nway_pay IN (1, 2)
  
  GROUP BY
    c.npolicy
)

SELECT
  p.npolicy AS POLIZA,
  TRIM(pro.sdescript) AS PRODUCTO,
  pro.spreffix || LPAD(CAST(p.npolicy AS STRING), 7, '0') AS POLIZA_ENTERA,
  DATE(c.ddate_origi) AS ORIGEN_POLIZA,
  TRIM(t181.sdescript) AS ESTADO_POLIZA,
  TRIM(t36.sdescript) AS FRECUENCIA_PAGO,
  c.nbill_day AS DIA_PAGO,
  p.nreceipt AS RECIBO,
  mo.nbulletins AS BOLETIN,
  TRUNC(mo.npremium * mo.nexchange) AS PRIMA_PESOS,
  REPLACE(CAST(mo.npremium AS STRING),'.',',') AS PRIMA_UF,
  DATE(p.deffecdate) AS PERIODO_INI,
  DATE(p.dexpirdat) AS PERIODO_FIN,
  DATE(p.dlimitdate) AS FECHA_COBRO,
  DATE(mo.dledgerdat) AS FECHA_CONTABLE,
  TRIM(t19.sdescript) AS ESTADO_RECIBO,
  TRIM(t6.sdescript) AS MOVIMIENTO_RECIBO,
  TRIM(t24.sdescript) AS ORIGEN_RECIBO,
  CASE
    WHEN p.nway_pay = 1 THEN 'PAC'
    WHEN p.nway_pay = 2 THEN 'PAT'
  END AS VIA_COBRO,
  CASE
    WHEN p.nway_pay = 1 AND mo.nbank_code <> 27 THEN 'MULTIBANCO'
    WHEN p.nway_pay = 1 AND mo.nbank_code = 27 THEN 'CORPBANCA'
    WHEN p.nway_pay = 2 THEN 'TRANSBANK'
  END AS RECAUDADOR,
  TRIM(rc.sdescript) AS CAUSAL_RECHAZO,
  CASE
    WHEN p.nway_pay = 1 AND mo.npayreject IN (1, 200, 700, 800) 
      THEN 'REINTENTABLE' --PAC REINTENTABLES
    WHEN p.nway_pay = 1 AND mo.npayreject IN (21, 100, 500, 600) 
      THEN 'NO REINTENTABLE' --PAC NO REINTENTABLES
    WHEN p.nway_pay = 2 AND mo.npayreject IN (11, 16, 51, 76, 107, 301) 
      THEN 'REINTENTABLE' --PAT REINTENTABLES
    WHEN p.nway_pay = 2 AND mo.npayreject IN (12, 13, 15, 74, 114, 115, 118, 200, 903, 909) 
      THEN 'NO REINTENTABLE' --PAT NO REINTENTABLES
    ELSE 'NO CLASIFICADO'
  END AS CLASIFICACION_CAUSAL,
  r.RUT_CLIENTE,
  r.NOMBRE_CLIENTE,
  r.RUT_INTERMED,
  r.NOMBRE_INTERMEDIARIO,
  vp.VALOR_POLIZA


FROM `DS_VT_INSUDB.PREMIUM` p

LEFT JOIN `DS_VT_INSUDB.CERTIFICAT` c
  ON p.scertype = c.scertype
  AND p.nbranch = c.nbranch
  AND p.nproduct = c.nproduct
  AND p.npolicy = c.npolicy
  AND p.ncertif = c.ncertif

LEFT JOIN `DS_VT_INSUDB.PREMIUM_MO` mo
  ON p.scertype = mo.scertype
  AND p.nbranch = mo.nbranch
  AND p.nproduct = mo.nproduct
  AND p.nreceipt = mo.nreceipt

LEFT JOIN `DS_VT_INSUDB.PRODMASTER` pro
  ON p.nbranch = pro.nbranch
  AND p.nproduct = pro.nproduct

LEFT JOIN `DS_VT_INSUDB.REJECT_CAUSE` rc
  ON (rc.nrejectcause = mo.npayreject)
  AND (rc.nway_pay = p.nway_pay)
  AND (rc.nbank_code = COALESCE(mo.nbank_code, 0))

LEFT JOIN ROLES r
  ON p.scertype = r.scertype
  AND p.nbranch = r.nbranch
  AND p.nproduct = r.nproduct
  AND p.npolicy = r.npolicy
  AND p.ncertif = r.ncertif

LEFT JOIN VP_POLIZAS vp
  ON p.npolicy = vp.npolicy

LEFT JOIN `DS_VT_INSUDB.TABLE6` t6 
  ON mo.ntype = t6.ntype_tran

LEFT JOIN `DS_VT_INSUDB.TABLE19` t19
  ON p.nstatus_pre = t19.nstatus_pre

LEFT JOIN `DS_VT_INSUDB.TABLE24` t24
  ON p.ntratypei = t24.ntratypei

LEFT JOIN `DS_VT_INSUDB.TABLE36` t36
  ON c.npayfreq = t36.npayfreq

LEFT JOIN `DS_VT_INSUDB.TABLE181` t181
  ON c.sstatusva = t181.sstatusva

WHERE p.nbranch = 8
  AND mo.ntype = 22
  AND p.ntratypei IN (1, 2, 13, 16)
  AND mo.dledgerdat BETWEEN imputacion_desde AND imputacion_hasta

