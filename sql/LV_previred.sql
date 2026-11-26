/*
Consulta: LV Convenio
Autor: Gustavo Navarro Zapata
Descripción: LV personalizado para cuadratura de proceso Previred y detectar primas cruzadas
Última actualización: 2026-11-26
*/

DECLARE fecha_inicio DATE DEFAULT '2026-11-01';
DECLARE fecha_fin DATE DEFAULT '2026-11-30';

WITH STOCK_VIDA AS (
  SELECT
  c.scertype,  
  c.nbranch,
  c.nproduct,
  TRIM(pro.sdescript) AS PRODUCTO,
  c.npolicy,
  c.ncertif,
  TRIM(t181.sdescript) AS ESTADO_POLIZA,
  TRIM(t13.sdescript) AS CAUSAL_TERMINO,
  TRIM(t5002.sdescript) AS VIA_PAGO,
  TRIM(t36.sdescript) AS FRECUENCIA_PAGO
  
  FROM `DS_VT_INSUDB.CERTIFICAT` c

  LEFT JOIN `DS_VT_INSUDB.PRODMASTER` pro
    ON c.nbranch = pro.nbranch
    AND c.nproduct = pro.nproduct
  
  LEFT JOIN `DS_VT_INSUDB.TABLE13` t13
    ON c.nnullcode = t13.nnullcode
  
  LEFT JOIN `DS_VT_INSUDB.TABLE36` t36
    ON c.npayfreq = t36.npayfreq

  LEFT JOIN `DS_VT_INSUDB.TABLE181` t181
    ON c.sstatusva = t181.sstatusva
  
  LEFT JOIN `DS_VT_INSUDB.TABLE5002` t5002
    ON c.nway_pay = t5002.nway_pay
  
  WHERE c.scertype = '2'
    AND c.nbranch = 8
),

USUARIOS AS (
  SELECT
    u.nusercode,
    u.sclient,
    TRIM(cl.scliename) AS USUARIO
  
  FROM `DS_VT_INSUDB.USERS` u

  LEFT JOIN `DS_VT_INSUDB.CLIENT` cl
    ON u.sclient = cl.sclient
  
  WHERE u.sstatregt = '1'
)

SELECT
  fecha_inicio AS FECHA_INICIO,
  fecha_fin AS FECHA_FIN,
  DATE(mo.dledgerdat) AS FECHA_CONTABLE,
  p.nproduct AS COD_PROD,
  sv.PRODUCTO,
  p.npolicy AS POLIZA,
  p.ncertif AS CERTIFICADO,
  sv.ESTADO_POLIZA,
  sv.CAUSAL_TERMINO,
  sv.VIA_PAGO,
  PARSE_NUMERIC(cl.sclient) AS RUT_ASEGURADO,
  TRIM(cl.scliename) AS NOMBRE_ASEGURADO,
  p.nreceipt AS RECIBO,
  TRIM(t19.sdescript) AS ESTADO_RECIBO,
  mo.namount AS PRIMA_UF,
  CAST(mo.namount * mo.nexchange AS INT64) AS PRIMA_PESOS,
  mo.nbordereaux AS RELACION_COBRO,
  us.USUARIO,
  TRIM(t24.sdescript) AS ORIGEN_CARGO,
  sv.FRECUENCIA_PAGO

FROM `DS_VT_INSUDB.PREMIUM` p

LEFT JOIN STOCK_VIDA sv
  ON p.scertype = sv.scertype
  AND p.nbranch = sv.nbranch
  AND p.nproduct = sv.nproduct
  AND p.npolicy = sv.npolicy
  AND p.ncertif = sv.ncertif

LEFT JOIN `DS_VT_INSUDB.PREMIUM_MO` mo
  ON p.scertype = mo.scertype
  AND p.nbranch = mo.nbranch
  AND p.nproduct = mo.nproduct
  AND p.nreceipt = mo.nreceipt

LEFT JOIN USUARIOS us
  ON mo.nusercode = us.nusercode

LEFT JOIN `DS_VT_INSUDB.CLIENT` cl
  ON p.sclient = cl.sclient

LEFT JOIN `DS_VT_INSUDB.TABLE19` t19
  ON p.nstatus_pre = t19.nstatus_pre

LEFT JOIN `DS_VT_INSUDB.TABLE24` t24
  ON p.ntratypei = t24.ntratypei

WHERE p.scertype = '2'
  AND p.nbranch = 8
  AND p.nstatus_pre IN (2, 5) --(2) Recaudado (5) Domiciliado Cobrado
  AND mo.ntype = 2 --(2) Abono
  AND mo.spay_form IN ('44') --(44) Previred
  AND mo.dledgerdat BETWEEN fecha_inicio AND fecha_fin
  QUALIFY ROW_NUMBER() OVER (PARTITION BY p.nreceipt ORDER BY mo.dledgerdat DESC) = 1

