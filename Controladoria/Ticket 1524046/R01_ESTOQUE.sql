with saldo_anterior as (
    select /*+ USE_NL(NFITEM) USE_NL(NFL) */
    filial.estab,
    filial.reduzido,
    m.local,
    m.item,
    coalesce(nfl.lote,itemprodlote.lote,'s/lote') as lote,
    coalesce(nfl.tipo,itemprodlote.tipo,'s/lote') as tipo,
    coalesce(nfl.seqlote,itemprodlote.seqlote,0) as seqlote,
    sum(case when m.somadiminui = 'S'  then coalesce(nfl.quantidade,itemprodlote.quantidade,m.quantidade) else -coalesce(nfl.quantidade,itemprodlote.quantidade,m.quantidade) end) as quantidade
    from movitemagro m
    inner join filial on filial.estab = m.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab
    left join nfitem on
        nfitem.estab = m.estab
        and nfitem.seqnota = m.seq
        and nfitem.seqnotaitem = to_number(substr(m.ordem_cronologica, instr(m.ordem_cronologica, '-', -1) + 1))
    left join nfitemloteagro nfl on
        nfl.estab = nfitem.estab
        and nfl.seqnota = nfitem.seqnota
        and nfl.seqnotaitem = nfitem.seqnotaitem
    left join itemprodlote on
        itemprodlote.estab = m.estab
        and itemprodlote.sequencia = m.seq
        and itemprodlote.item = m.item
        where m.codigosaldo = 2 and u_tempresa.insumos = 'S'
    and m.datamovim < :DTINI
    --and m.estab = 73
    and (m.item = :ITEM OR 0 = :ITEM)

    group by
    filial.estab,
    filial.reduzido,
    m.local,
    m.item,
    nfl.lote,itemprodlote.lote,
    nfl.tipo,itemprodlote.tipo,
    nfl.seqlote,itemprodlote.seqlote
),
base as (
    select /*+ USE_NL(NFITEM) USE_NL(NFL) */
    filial.estab,
    filial.reduzido,
    m.local,
    m.doc,
    m.seq,
    m.item,
    m.somadiminui,
    m.ordem_cronologica,
    to_number(substr(m.ordem_cronologica, instr(m.ordem_cronologica, '-', -1) + 1)) as ordem_item,
    m.datamovim,
    m.horamovim,
    m.natureza,
    coalesce(nfl.lote,itemprodlote.lote,'s/lote') as lote,
    coalesce(nfl.tipo,itemprodlote.tipo,'s/lote') as tipo,
    coalesce(nfl.seqlote,itemprodlote.seqlote,0) as seqlote,
    case when m.somadiminui = 'S'  then coalesce(nfl.quantidade,itemprodlote.quantidade,m.quantidade) else -coalesce(nfl.quantidade,itemprodlote.quantidade,m.quantidade) end as quantidade
    from movitemagro m
    inner join filial on filial.estab = m.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab
    left join nfitem on
        nfitem.estab = m.estab
        and nfitem.seqnota = m.seq
        and nfitem.seqnotaitem = to_number(substr(m.ordem_cronologica, instr(m.ordem_cronologica, '-', -1) + 1))
    left join nfitemloteagro nfl on
        nfl.estab = nfitem.estab
        and nfl.seqnota = nfitem.seqnota
        and nfl.seqnotaitem = nfitem.seqnotaitem
    left join itemprodlote on
        itemprodlote.estab = m.estab
        and itemprodlote.sequencia = m.seq
        and itemprodlote.item = m.item
        where m.codigosaldo = 2 and u_tempresa.insumos = 'S'
    and m.datamovim between :DTINI and :DTFIM
    --and m.estab = 73
    and (m.item = :ITEM OR 0 = :ITEM)
)
select
cod_loja,
nome_loja,
local,
nome_local,
titularidade,
localizacao_fisica,
cod_produto,
desc_produto,
grupo_produto,
controla_lote,
unidade,
lote,
data_fabricacao,
data_validade,
dias_para_vencer,
qtd,
saldoant,
qtd_saldo,
0 as qtd_reservada, --- revisar
0 as qtd_bloqueada, --- revisar
pcusto(cod_loja, cod_produto, 3, :DTFIM, null, null) as custo_unitario,
pcusto(cod_loja, cod_produto, 3, :DTFIM, null, null) * qtd_saldo as valor_saldo, 
null as data_ultima_saida, --- revisar
:DTFIM as data_hora_posicao
from(

select
dados.estab as cod_loja,
dados.reduzido as nome_loja,
dados.local,
localest.descricao as nome_local,
'PROPRIA' as titularidade,
'NA_LOJA' as localizacao_fisica,
dados.item as cod_produto,
itemagro.descricao as desc_produto,
u_gestoque.descricao as grupo_produto,
itemagro.lotectrl as controla_lote,
itemagro.unidade,
dados.lote,
la.datafabricacao as data_fabricacao,
la.validade as data_validade,
trunc(la.validade - cast(:DTFIM as date)) as dias_para_vencer,
sum(dados.quantidade) as qtd,
sum(dados.saldoant) as saldoant,
sum(dados.quantidade + nvl(dados.saldoant,0)) as qtd_saldo,
:DTFIM as data_hora_posicao
from (
    
select
base.estab,
base.reduzido,
base.local,
base.item,
base.lote,
base.tipo,
base.seqlote,
sum(base.quantidade) as quantidade,
0 as saldoant
from base

group by
base.estab,
base.reduzido,
base.local,
base.item,
base.lote,
base.tipo,
base.seqlote

union all

select
sa.estab,
sa.reduzido,
sa.local,
sa.item,
sa.lote,
sa.tipo,
sa.seqlote,
0 as quantidade,
sa.quantidade as saldoant
from saldo_anterior sa

)dados
inner join itemagro on itemagro.item = dados.item
inner join itemgrupo on itemgrupo.grupo = itemagro.grupo
left join itemgrupo_u on itemgrupo_u.grupo = itemgrupo.grupo
left join u_gestoque on u_gestoque.u_gestoque_id = itemgrupo_u.u_gestoque_id
left join localest on
    localest.estab = dados.estab
    and localest.local = dados.local
left join loteagro la on
    la.estab = dados.estab
    and la.item = dados.item
    and la.lote = dados.lote
    and la.seqlote = dados.seqlote
    and la.tipo = dados.tipo

group by
dados.estab ,
dados.reduzido ,
dados.local,
dados.item,
itemagro.descricao,
u_gestoque.descricao,
itemagro.unidade,
dados.lote,
la.datafabricacao,
la.validade,
localest.descricao,
itemagro.lotectrl

)dados1