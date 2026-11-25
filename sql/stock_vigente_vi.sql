/*
Consulta: Stock vigente Vida Individual
Autor: Gustavo Navarro Zapata
Descripción: Obtener el stock vigente de los productos de Vida Individual
Última actualización: 2026-11-25
*/

SELECT
  c.npolicy AS POLIZA,
  c.ncertif AS CERTIF,
  c.nproduct AS COD_PROD,
  TRIM(pro.sdescript) AS PRODUCTO,
  TRIM(t181.sdescript) AS ESTADO_POLIZA,
  DATE(c.ddate_origi) AS ORIGEN_POLIZA,
  DATE(c.dstartdate) AS INICIO_VIGENCIA,
  DATE(c.dexpirdat) AS FIN_VIGENCIA,
  c.nbill_day AS DIA_PAGO,
  TRIM(t5002.sdescript) AS VIA_PAGO,
  TRIM(t36.sdescript) AS FREC_PAGO,
  PARSE_NUMERIC(cl.sclient) AS RUT,
  cl.sdigit AS DV,
  INITCAP(TRIM(cl.scliename)) AS NOMBRE_CONTRATANTE
  
FROM `DS_VT_INSUDB.CERTIFICAT` c

LEFT JOIN `DS_VT_INSUDB.PRODMASTER` pro
  ON pro.nbranch = c.nbranch
  AND pro.nproduct = c.nproduct

LEFT JOIN `DS_VT_INSUDB.CLIENT` cl
  ON cl.sclient = c.sclient

LEFT JOIN `DS_VT_INSUDB.TABLE36` t36
  ON t36.npayfreq = c.npayfreq

LEFT JOIN `DS_VT_INSUDB.TABLE181` t181
  ON t181.sstatusva = c.sstatusva

LEFT JOIN `DS_VT_INSUDB.TABLE5002` t5002
  ON t5002.nway_pay = c.nway_pay

WHERE c.scertype = '2'
  AND c.nbranch = 8
  AND c.sstatusva IN ('4', '5')
  AND (DATE(c.dexpirdat) >= CURRENT_DATE() OR c.dexpirdat IS NULL)
