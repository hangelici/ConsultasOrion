with saldo_anterior as (
    select
    m.estab,
    m.item,
    m.local,
    sum(case when m.somadiminui = 'S' then m.quantidade else -m.quantidade end) saldoant
    from movitemagro m
    inner join u_tempresa on u_tempresa.estab = m.estab and u_tempresa.graos = 'S'
    where
    m.datamovim < :DTINI 
    and m.codigosaldo = 2
    group by m.estab, m.item, m.local
),
base as (
    select
    m.estab,
    m.item,
    m.local,
    sum(case when m.somadiminui = 'S' then m.quantidade else -m.quantidade end) saldo_atual
    from movitemagro m
    inner join u_tempresa on u_tempresa.estab = m.estab and u_tempresa.graos = 'S'
    where
    m.datamovim between :DTINI and :DTFIM
    and m.codigosaldo = 2
    group by m.estab, m.item, m.local
)
select
dados.estab as cod_unidade,
dados.item,
itemagro.descricao as desc_produto,
localest.descricao as titularidade,
itemagro.unidade as unidade_saldo,
sum(saldo_atual + saldoant) as qtd_saldo,
sum(saldo_atual + saldoant) as qtd_saldo_kg,
:DTFIM as data_hora_posicao
--sum(saldo_atual) as saldo_atual,
--sum(saldoant) as saldoant
from( 

select
base.estab,
base.item,
base.local,
base.saldo_atual,
0 as saldoant
from base

union all

select
sa.estab,
sa.item,
sa.local,
0 as saldo_atual,
sa.saldoant
from saldo_anterior sa

)dados

inner join itemagro on itemagro.item = dados.item
inner join filial on filial.estab = dados.estab
inner join localest on
    localest.estab = dados.estab
    and localest.local = dados.local

group by
dados.estab,
dados.item,
itemagro.descricao,
localest.descricao,
itemagro.unidade