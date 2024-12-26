 SELECT 
    OSESTAB,
    OSPLANO, 
    COD_CC,
    REDUZIDA,
    ANO, 
    MES,
    SUM(SALDO_INICIAL) as SALDO_INICIAL,
    SUM(CREDITOS) AS CREDITOS, 
    SUM(DEBITOS) AS DEBITOS, 
    SUM(RCREDITOS) AS RCREDITOS,
    SUM(RDEBITOS) AS RDEBITOS

FROM(

SELECT
    1 OSESTAB,
    '1#1' OSPLANO,
    cencusce.centrocus AS COD_CC,
    placonan.reduzida AS REDUZIDA,
    MESES.ano,
    MESES.mes,




    COALESCE(SALCONCE.saldoini, COALESCE((
                                    SELECT 
                                       ((s.saLdoini +s.debitos+s.rdebitos) - (s.creditos+s.rcreditos))
                                    FROM (
                                        SELECT 
                                            s.meS,
                                            s.anO,
                                            s.anALItIca,
                                            s.CentrOcUs,
                                            s.SALDOINI,
                                               s.debitos,
                                                s.creditos,
                                                s.rcreditos,
                                                s.rdebitos
                                        FROM SALCONCE s 
                                         where s.estab=1
                                        ORDER BY s.ANO DESC, s.MES DESC, s.anaLitiCA, S.centrocUS
                                    ) s 
                                    wheRe caSt('01.' || lpad(s.mes, 2,'0') || '.' || s.Ano as date) < caSt('01.' || lpad(MESES.mes, 2,'0') || '.' || MESES.Ano as date)
                                        AND s.ANALITICA = PLACONAN.REDUZIDA
                                        AND s.CENTROCUS = CENCUSCE.CEntrOCus
                                        AND PLACONAN.PLANO = 1 
                                        AND ROWNUM = 1
                                        


                                ), 0)
    ) AS SALDO_INICIAL,

    COALESCE(SALCONCE.debitos, 0) AS debitos,
    COALESCE(SALCONCE.creditos, 0) AS creditos,
    COALESCE(SALCONCE.rdebitos, 0)rdebitos,
    COALESCE(SALCONCE.rcreditos, 0)rcreditos

     
    FROM (SELECT DISTINCT
            EXTRACT(MONTH FROM ALLDAYS.DDATA) AS MES,
            EXTRACT(YEAR FROM ALLDAYS.DDATA) AS ANO
            FROM TABLE(ALLDAYS(CAST('01/12/2019' AS DATE),CURRENT_DATE)) ALLDAYS
        ) MESES 
INNER JOIN PLACONAN 
    ON PLACONAN.PLANO = 1 

INNER JOIN CENCUSCE 
    ON LENGTH(CENCUSCE.centrocus) = 9
    AND CENCUSCE.CENCUSCOD = 2

LEFT JOIN SALCONCE 
    ON SALCONCE.MES = MESES.MES 
    AND SALCONCE.ANO = MESES.ANO 
    AND SALCONCE.ANALITICA = PLACONAN.REDUZIDA
    AND SALCONCE.CENTROCUS = CENCUSCE.CENTROCUS
    AND SALCONCE.ESTAB = 1

--WHERE PLACONAN.REDUZIDA = 11101
--AND CENCUSCE.CENTROCUS = 010103

 order by  CENCUSCE.CENTROCUS,ano,mes
) DADOS 

where 

ano >= 2023

GROUP BY  
    OSESTAB,
    OSPLANO, 
    COD_CC,
    REDUZIDA,
    ANO, 
    MES


   union all
    
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

ano >= 2023
