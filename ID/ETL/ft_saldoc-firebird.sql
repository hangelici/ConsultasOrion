WITH PARAM AS (
    SELECT (SELECT TO_DATE('01/'||MES||'/'||ANO, 'DD/MM/YYYY')
              FROM VIASOFTCTB.U_PINTEGRACAO) AS DT_INI
      FROM DUAL
),
/* meses do calendário (de 01/2020 até hoje) dentro do período do filtro */
MESES AS (
    SELECT DISTINCT
           EXTRACT(MONTH FROM D.DDATA) AS MES,
           EXTRACT(YEAR  FROM D.DDATA) AS ANO
      FROM alldays(DATE '2020-01-01', current_date) D
     WHERE TO_DATE('01/'||EXTRACT(MONTH FROM D.DDATA)||'/'||EXTRACT(YEAR FROM D.DDATA), 'DD/MM/YYYY')
           BETWEEN (SELECT DT_INI FROM PARAM) AND SYSDATE
),
/* combinações existentes na U_LANCF */
CONTAS AS (
    SELECT DISTINCT
           U.OSESTAB,
           U.OSPLANO,
           U.REDUZIDA,
           U.COD_CC
      FROM VIASOFT.U_LANCF U
     WHERE U.OSESTAB = 1
),
/* meses SEM lançamento para cada combinação (mesma ordem de colunas da U_LANCF) */
FALTANTES AS (
    SELECT C.OSESTAB,
           C.OSPLANO,
           C.REDUZIDA,
           M.MES,
           M.ANO,
           C.COD_CC,
           NULL AS SALDO_INICIAL,
           NULL AS DEBITOS,
           NULL AS CREDITOS,
           NULL AS RDEBITOS,
           NULL AS RCREDITOS
      FROM CONTAS C
     CROSS JOIN MESES M
     WHERE NOT EXISTS (SELECT 1
                         FROM VIASOFT.U_LANCF F
                        WHERE F.OSESTAB = C.OSESTAB
                          AND F.COD_CC  = C.COD_CC
                          AND F.REDUZIDA = C.REDUZIDA
                          AND F.ANO = M.ANO
                          AND F.MES = M.MES
                          AND F.OSESTAB = 1)
)
select /*+ GATHER_PLAN_STATISTICS */
osestab,
osplano,
cod_cc,
reduzida,
ano,
mes,
coalesce(saldo_inicial, 
    (lag(saldo_inicial ignore nulls) over(partition by cod_cc,reduzida order by ano,mes))         
    -
    (lag(creditos ignore nulls) over(partition by cod_cc,reduzida order by ano,mes)) 
    +
    (lag(debitos ignore nulls) over(partition by cod_cc,reduzida order by ano,mes))
    -
    (lag(rcreditos ignore nulls) over(partition by cod_cc,reduzida order by ano,mes))
    +
    (lag(rdebitos ignore nulls) over(partition by cod_cc,reduzida order by ano,mes))
    
    )saldo_inicial,
COALESCE(creditos,0)creditos,
coalesce(debitos,0)debitos,
coalesce(rcreditos,0)rcreditos,
coalesce(rdebitos,0)rdebitos,
CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS DT_AT

from(

select
*
from viasoft.u_lancf u_lancf where u_lancf.osestab = 1

union all

select
*
from FALTANTES

)dados

where 

TO_DATE('01/'||MES||'/'||ANO, 'DD/MM/YYYY') BETWEEN 
       (SELECT TO_DATE('01/'||MES||'/'||ANO, 'DD/MM/YYYY') FROM VIASOFTCTB.U_PINTEGRACAO) AND SYSDATE