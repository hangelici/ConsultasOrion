-- Uma única leitura de MOVITEMAGRO: saldo anterior + movimento do período = tudo até :DTFIM.
-- Saldo anterior e movimento ficam separados por agregação condicional (sem UNION ALL / 2º full scan).
with dados as (
    select
    m.estab,
    m.item,
    m.local,
    sum(case when m.datamovim <  to_date(:DTINI, 'DD/MM/YYYY')
             then case when m.somadiminui = 'S' then m.quantidade else -m.quantidade end
             else 0 end) saldoant,
    sum(case when m.datamovim >= to_date(:DTINI, 'DD/MM/YYYY')
             then case when m.somadiminui = 'S' then m.quantidade else -m.quantidade end
             else 0 end) saldo_atual
    from movitemagro m
    inner join u_tempresa on u_tempresa.estab = m.estab and u_tempresa.graos = 'S'
    where
    m.datamovim < to_date(:DTFIM, 'DD/MM/YYYY') 
    and m.codigosaldo = 2
    group by m.estab, m.item, m.local
)
select
dados.estab as cod_unidade,
dados.item,
itemagro.descricao as desc_produto,
localest.descricao as titularidade,
itemagro.unidade as unidade_saldo,
sum(dados.saldo_atual + dados.saldoant) as qtd_saldo,
sum(dados.saldo_atual + dados.saldoant) as qtd_saldo_kg,
:DTFIM as data_hora_posicao
--sum(dados.saldo_atual) as saldo_atual,
--sum(dados.saldoant) as saldoant
from dados
inner join itemagro on itemagro.item = dados.item
inner join localest on
    localest.estab = dados.estab
    and localest.local = dados.local
where exists (select 1 from filial where filial.estab = dados.estab)
group by
dados.estab,
dados.item,
itemagro.descricao,
localest.descricao,
itemagro.unidade;
