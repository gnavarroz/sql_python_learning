/*
Consulta: Carga Mailling Rechazos PAC-PAT No Reintentables
Autor: Gustavo Navarro Zapata
Descripción: Reporte que entrega el formato para la carga de mailling de rechazos PAC-PAT no reintentables
Última actualización: 2026-09-02
*/

SELECT DISTINCT
  CASE
    WHEN p.nway_pay = 1 THEN 'PAC'
    WHEN p.nway_pay = 2 THEN 'PAT'
  END AS MEDIO_PAGO,
  TRIM(pro.sdescript) AS PRODUCTO,
  pro.spreffix || LPAD(CAST(p.npolicy AS STRING), 7, '0') AS POLIZA,
  TRIM(rc.sdescript) AS ESTADO

FROM `DS_VT_INSUDB.PREMIUM` p

LEFT JOIN `DS_VT_INSUDB.PREMIUM_MO` mo
  ON p.scertype = mo.scertype
  AND p.nbranch = mo.nbranch
  AND p.nproduct = mo.nproduct
  AND p.nreceipt = mo.nreceipt

LEFT JOIN `DS_VT_INSUDB.CERTIFICAT` c
  ON p.scertype = c.scertype
  AND p.nbranch = c.nbranch
  AND p.nproduct = c.nproduct
  AND p.npolicy = c.npolicy
  AND p.ncertif = c.ncertif

LEFT JOIN `DS_VT_INSUDB.PRODMASTER` pro
  ON p.nbranch = pro.nbranch
  AND p.nproduct = pro.nproduct

LEFT JOIN `DS_VT_INSUDB.REJECT_CAUSE` rc
  ON mo.npayreject = rc.nrejectcause
  AND p.nway_pay = rc.nway_pay
  AND COALESCE(mo.nbank_code, 0) = rc.nbank_code

LEFT JOIN `DS_VT_INSUDB.TABLE181` t181
  ON c.sstatusva = t181.sstatusva

WHERE p.nbranch = 8
  AND mo.ntype = 22
  AND c.sstatusva IN ('4', '5')
  AND p.nstatus_pre IN (1, 3, 4)
  AND p.ntratypei IN (1, 2, 13, 16)
  AND ((mo.npayreject IN (21, 500, 600) AND p.nway_pay = 1) OR (mo.npayreject IN (4, 8, 12, 13, 74, 115, 200, 903, 909) AND p.nway_pay = 2))
  AND mo.dledgerdat BETWEEN 'AAAA-MM-DD' AND 'AAAA-MM-DD'
