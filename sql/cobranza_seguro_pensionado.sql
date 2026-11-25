/*
Consulta: Cobranza Seguro Pensionado
Autor: Gustavo Navarro
Descripción: Generar la cobranza preliminar y definitiva del producto Seguro Pensionado
Última actualización: 2026-11-24
*/

DECLARE fecha_cobranza DATE;
DECLARE skey_cobranza STRING;
SET fecha_cobranza = '2026-10-31';
SET skey_cobranza = 'T2026110311503691972';

WITH PRIMA_PACTADA AS (
  SELECT
    cov.scertype,
    cov.nbranch,
    cov.nproduct,
    cov.npolicy,
    cov.ncertif,
    SUM(IFNULL(cov.npremium, 0) + IFNULL(cov.nrecamount, 0) + IFNULL(cov.ntaxamount, 0)) - SUM(IFNULL(cov.ndescamount, 0)) AS PRIMA_ANUAL

  FROM `DS_VT_INSUDB.COVER` cov

  WHERE cov.scertype = '2'
    AND cov.nbranch = 7
    AND cov.nproduct = 69
    AND cov.deffecdate <= '2026-10-31'
    AND (cov.dnulldate IS NULL OR cov.dnulldate > DATE('2026-10-31'))
  
  GROUP BY
    cov.scertype,
    cov.nbranch,
    cov.nproduct,
    cov.npolicy,
    cov.ncertif
)

SELECT
  CASE
    WHEN tmp.nbranch = 7 THEN "Banca Seguro"
    WHEN tmp.nbranch = 8 THEN "Vida Individual"
    ELSE "Otros"
  END AS RAMO,
  TRIM(pro.sdescript) AS PRODUCTO,
  CONCAT(tmp.nproduct, tmp.npolicy, tmp.ncertif) AS LLAVE,
  tmp.nproduct AS COD_PROD,
  tmp.npolicy AS POLIZA,
  tmp.ncertif AS CERTIF,
  TRIM(t181.sdescript) AS ESTADO_POLIZA,
  DATE(c.ddate_origi) AS ORIGEN_POLIZA,
  DATE(c.dstartdate) AS INICIO_VIGENCIA,
  DATE(c.dexpirdat) AS FIN_VIGENCIA,
  TRIM(t5002.sdescript) AS VIA_PAGO,
  TRIM(t36.sdescript) AS FREC_PAGO,
  tmp.nreceipt AS RECIBO,
  TRIM(t19.sdescript) AS ESTADO_RECIBO,
  TRIM(t24.sdescript) AS ORIGEN_RECIBO,
  TRIM(t6.sdescript) AS ULT_MOV_RECIBO,
  tmp.nbulletins AS BOLETIN,
  DATE(tmp.dcollec_date) AS FECHA_COBRANZA,
  DATE(tmp.dvaluedate) AS FECHA_VALORIZACION,
  DATE(tmp.dlimit_date) AS FECHA_COB_RECIBO,
  EXTRACT(DAY FROM tmp.dlimit_date) AS DIA_COBRO,
  tmp.skey AS SKEY,
  tmp.namount AS PRIMA_PESOS,
  tmp.npremium AS PRIMA_UF,
  (pp.PRIMA_ANUAL)/12 AS PRIMA_PACTADA,
  TRUNC(tmp.npremium - (pp.PRIMA_ANUAL)/12) AS DIFERENCIA

FROM `DS_VT_INSUDB.TMP_COLLECTION` tmp

LEFT JOIN `DS_VT_INSUDB.CERTIFICAT` c
  ON tmp.scertype = c.scertype
  AND tmp.nbranch = c.nbranch
  AND tmp.nproduct = c.nproduct
  AND tmp.npolicy = c.npolicy
  AND tmp.ncertif = c.ncertif

LEFT JOIN PRIMA_PACTADA pp
  ON tmp.scertype = pp.scertype
  AND tmp.nbranch = pp.nbranch
  AND tmp.nproduct = pp.nproduct
  AND tmp.npolicy = pp.npolicy
  AND tmp.ncertif = pp.ncertif

LEFT JOIN `DS_VT_INSUDB.PREMIUM` p
  ON tmp.nreceipt = p.nreceipt

LEFT JOIN `DS_VT_INSUDB.PRODMASTER` pro
  ON pro.nbranch = tmp.nbranch
  AND pro.nproduct = tmp.nproduct

LEFT JOIN `DS_VT_INSUDB.TABLE6` t6
  ON t6.ntype_tran = p.ntype

LEFT JOIN `DS_VT_INSUDB.TABLE19` t19
  ON t19.nstatus_pre = p.nstatus_pre

LEFT JOIN `DS_VT_INSUDB.TABLE24` t24
  ON t24.ntratypei = p.ntratypei

LEFT JOIN `DS_VT_INSUDB.TABLE36` t36
  ON t36.npayfreq = c.npayfreq

LEFT JOIN `DS_VT_INSUDB.TABLE181` t181
  ON t181.sstatusva = c.sstatusva

LEFT JOIN `DS_VT_INSUDB.TABLE5002` t5002
  ON t5002.nway_pay = tmp.nway_pay

WHERE tmp.scertype = '2'
  AND tmp.nbranch = 7
  AND tmp.nproduct = 69
  AND tmp.skey = skey_cobranza
  AND tmp.dcollec_date = fecha_cobranza

