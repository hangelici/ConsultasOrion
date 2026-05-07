WITH MESES AS (
    SELECT DISTINCT
        EXTRACT(MONTH FROM ALLDAYS.DDATA) AS MES,
        EXTRACT(YEAR FROM ALLDAYS.DDATA) AS ANO
    FROM TABLE(ALLDAYS(CAST('01/12/2019' AS DATE), CURRENT_DATE)) ALLDAYS
    
    --where
   -- EXTRACT(YEAR FROM ALLDAYS.DDATA)  >= 2024 --and EXTRACT(MONTH FROM ALLDAYS.DDATA) = 11
),
SALCONCE_INTERMEDIARIO AS (
    SELECT 
        s.mes,
        s.ano,
        s.analitica,
        s.centrocus,
        s.saldoini,
        s.debitos,
        s.creditos,
        s.rdebitos,
        s.rcreditos,
        (s.saldoini + s.debitos + s.rdebitos) - (s.creditos + s.rcreditos) AS saldo_calculado
    FROM SALCONCE s 
    WHERE s.estab = 1 --and mes= 11 and ano = 2024 
),
SALDO_CALCULADO AS (
    SELECT 
        MESES.ano,
        MESES.mes,
        CENCUSCE.centrocus AS COD_CC,
        PLACONAN.reduzida AS REDUZIDA,
        COALESCE(SALCONCE_INTERMEDIARIO.saldoini, COALESCE((
            SELECT saldo_calculado
            FROM SALCONCE_INTERMEDIARIO s
            WHERE CAST('01.' || LPAD(s.mes, 2,'0') || '.' || s.ano AS DATE) < 
                  CAST('01.' || LPAD(MESES.mes, 2,'0') || '.' || MESES.ano AS DATE)
              AND s.analitica = PLACONAN.reduzida
              AND s.centrocus = CENCUSCE.centrocus
            ORDER BY s.ano DESC, s.mes DESC
            FETCH FIRST 1 ROWS ONLY
        ), 0)) AS SALDO_INICIAL,
        COALESCE(SALCONCE_INTERMEDIARIO.debitos, 0) AS DEBITOS,
        COALESCE(SALCONCE_INTERMEDIARIO.creditos, 0) AS CREDITOS,
        COALESCE(SALCONCE_INTERMEDIARIO.rdebitos, 0) AS RDEBITOS,
        COALESCE(SALCONCE_INTERMEDIARIO.rcreditos, 0) AS RCREDITOS
    FROM MESES
    INNER JOIN PLACONAN ON PLACONAN.PLANO = 1
    INNER JOIN CENCUSCE 
        ON LENGTH(CENCUSCE.centrocus) = 9
        AND CENCUSCE.CENCUSCOD = 2
    LEFT JOIN SALCONCE_INTERMEDIARIO 
        ON SALCONCE_INTERMEDIARIO.mes = MESES.mes 
        AND SALCONCE_INTERMEDIARIO.ano = MESES.ano 
        AND SALCONCE_INTERMEDIARIO.analitica = PLACONAN.reduzida
        AND SALCONCE_INTERMEDIARIO.centrocus = CENCUSCE.centrocus
)
select
 1 AS OSESTAB,
    '1#1' AS OSPLANO,
    COD_CC,
    REDUZIDA,
    ANO, 
    MES,
    (SALDO_INICIAL) AS SALDO_INICIAL,
    (CREDITOS) AS CREDITOS, 
    (DEBITOS) AS DEBITOS, 
    (RCREDITOS) AS RCREDITOS,
    (RDEBITOS) AS RDEBITOS
from SALDO_CALCULADO 

where ano =2024

   
union

 select
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
coalesce(rdebitos,0)rdebitos

from(

select
*
from viasoft.u_lancf u_lancf

union all

select
dados.*
from(

select distinct
    osestab,
    osplano,
    reduzida,
    extract(month from ddata) mes,
    extract(year from ddata) ano,
    cod_cc,
    null as saldo_inicial,
    null as debitos,
    null as creditos,
    null as rdebitos,
    null as rcreditos
from 
alldays(cast('01/01/2020' as date), current_date) 

left join viasoft.u_lancf u_lancf on 0=0 

)dados
left join viasoft.u_lancf f on
    f.osestab = dados.osestab
    and f.cod_cc = dados.cod_cc
    and f.reduzida = dados.reduzida
    and f.ano = dados.ano
    and f.mes = dados.mes
    
    where f.osestab is null

    
)dados

where 

ano = 2024


