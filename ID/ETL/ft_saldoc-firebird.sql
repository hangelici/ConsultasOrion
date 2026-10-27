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
coalesce(rdebitos,0)rdebitos,
CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS DT_AT

from(

select
*
from viasoft.u_lancf u_lancf where u_lancf.osestab = 1

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
where u_lancf.osestab = 1

)dados
left join viasoft.u_lancf f on
    f.osestab = dados.osestab
    and f.cod_cc = dados.cod_cc
    and f.reduzida = dados.reduzida
    and f.ano = dados.ano
    and f.mes = dados.mes
	and f.osestab = 1
    
    where f.osestab is null

    
)dados

where 

TO_DATE('01/'||MES||'/'||ANO, 'DD/MM/YYYY') BETWEEN 
       (SELECT TO_DATE('01/'||MES||'/'||ANO, 'DD/MM/YYYY') FROM VIASOFTCTB.U_PINTEGRACAO) AND SYSDATE