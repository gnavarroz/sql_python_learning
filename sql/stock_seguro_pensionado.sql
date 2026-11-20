/*
Consulta: Stock Seguro Pensionado
Autor: Gustavo Navarro Zapata
Descripción: Obtiene el stock vigente de clientes para Seguro Pensionado
Última actualización: 2026-09-21
*/

SELECT 
  c.npolicy AS POLIZA,
  c.ncertif AS CERTIF,
  TRIM(pro.sdescript) AS PRODUCTO,
  TRIM(t181.sdescript) AS ESTADO_POLIZA,
  DATE(c.dstartdate) AS INI_VIGENCIA,
  DATE(c.dexpirdat) AS FIN_VIGENCIA,
  DATE(c.dnulldate) AS TERMINO_POLIZA,
  c.nbill_day AS DIA_PAGO,
  TRIM(t5002.sdescript) AS FORMA_PAGO,
  TRIM(t36.sdescript) AS FREC_PAGO,
  PARSE_NUMERIC(cl.sclient) AS RUT,
  cl.sdigit AS DV,
  INITCAP(TRIM(cl.scliename)) AS NOMBRE_CONTRATANTE

FROM `DS_VT_INSUDB.CERTIFICAT` AS c

LEFT JOIN `DS_VT_INSUDB.PRODMASTER` AS pro
  ON c.nbranch = pro.nbranch
  AND c.nproduct = pro.nproduct
  
LEFT JOIN `DS_VT_INSUDB.CLIENT` AS cl
  ON c.sclient = cl.sclient

LEFT JOIN `DS_VT_INSUDB.TABLE36` AS t36
  ON c.npayfreq = t36.npayfreq

LEFT JOIN `DS_VT_INSUDB.TABLE181` AS t181
  ON c.sstatusva = t181.sstatusva
  
LEFT JOIN `DS_VT_INSUDB.TABLE5002` AS t5002
  ON c.nway_pay = t5002.nway_pay

WHERE c.scertype = '2'
  AND c.nbranch = 7
  AND c.nproduct = 69
  AND c.sstatusva IN ('4', '5')
