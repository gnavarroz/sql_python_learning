/*
Consulta: LV_Full_Hipotecario
Autor: Gustavo Navarro Zapata
Descripción: Obtiene las primas imputadas del producto Full Hipotecario
Última actualización: 2026-09-21
*/

SELECT
  p.npolicy AS POLIZA,
  p.ncertif AS CERTIFICADO,
  TRIM(pro.sdescript) AS PRODUCTO,
  TRIM(t181.sdescript) AS ESTADO,
  TRIM(p.nreceipt) AS RECIBO,
  DATE(mo.dledgerdat) AS FECHA_IMPUTACION,
  mo.namount AS PRIMA_UF,
  ROUND(mo.namount * mo.nexchange) AS PRIMA_PESOS,
  PARSE_NUMERIC(cl.sclient) AS RUT_CLIENTE,
  cl.sdigit AS DV,
  INITCAP(TRIM(cl.scliename)) AS NOMBRE_CLIENTE,
  mo.nbordereaux AS REL_COBRO,
  TRIM(t182.sdescript) AS VIA_COBRO,
  u.nusercode AS COD_USUARIO,
  TRIM(u.sinitials) AS USUARIO

FROM `DS_VT_INSUDB.PREMIUM` p

LEFT JOIN `DS_VT_INSUDB.CERTIFICAT` c
  ON (p.scertype = c.scertype)
  AND (p.nbranch = c.nbranch)
  AND (p.nproduct = c.nproduct)
  AND (p.npolicy = c.npolicy)
  AND (p.ncertif = c.ncertif)

LEFT JOIN `DS_VT_INSUDB.PRODMASTER` pro
  ON (p.nbranch = pro.nbranch)
  AND (p.nproduct = pro.nproduct)

LEFT JOIN `DS_VT_INSUDB.PREMIUM_MO` mo
  ON (p.nreceipt = mo.nreceipt)

LEFT JOIN `DS_VT_INSUDB.CLIENT` cl
  ON (c.sclient = cl.sclient)

LEFT JOIN `DS_VT_INSUDB.USERS` u
  ON (mo.nusercode = u.nusercode)

LEFT JOIN `DS_VT_INSUDB.TABLE181` t181
  ON (c.sstatusva = t181.sstatusva)

LEFT JOIN `DS_VT_INSUDB.TABLE182` t182
  ON (mo.spay_form = t182.spay_form)

WHERE p.scertype = '2'
  AND p.nbranch = 7
  AND mo.ntype = 2
  AND p.nproduct = 29
  AND mo.dledgerdat = 'YYYY-MM-DD'
