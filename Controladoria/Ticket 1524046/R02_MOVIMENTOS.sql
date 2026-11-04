-- R02_MOVIMENTOS
with base as (
    select
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
    case when m.somadiminui = 'S'  then m.quantidade else -m.quantidade end as quantidade
    from movitemagro m
    inner join filial on filial.estab = m.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab
    where m.codigosaldo = 2 and u_tempresa.insumos = 'S'
    and m.datamovim between :DTINI and :DTFIM
)
select /*+ USE_NL(NFITEM) USE_NL(NFL) */
b.estab as cod_estab,
b.reduzido as nome_loja,
b.local as cod_local,
b.doc as id_movimento,
b.seq, -- retirar depois
b.ordem_item as id_item_movimento, -- revisar
b.datamovim||' '||b.horamovim as data_hora_movimento,
b.datamovim||' '||b.horamovim as data_hora_digitacao,
'N' as retroativo,
'S' as no_periodo,
2 as cod_tipo_movimento,
'fisico' as desc_tipo_movimento,
case when b.somadiminui = 'S' then 'E' else 'S' end as entrada_saida,
b.item as cod_produto,
itemagro.descricao as desc_produto,
itemagro.unidade,
nfl.lote,
nvl(nfl.quantidade,b.quantidade) as qtd,
nfitem.custocmv as custo_unitario,
nvl(nfl.quantidade*nfitem.valorunitario,nfitem.valortotal) as valor,
b.natureza as tipo_doc_origem,
b.doc as num_doc_origem,
null as id_movimento_estornado, --revisar
null as motivo,
null as observacao,
null as usuario,
null as aprovador
from base b
inner join itemagro on itemagro.item = b.item
left join nfitem on
    nfitem.estab = b.estab
    and nfitem.seqnota = b.seq
    and nfitem.seqnotaitem = b.ordem_item
left join nfitemloteagro nfl on
    nfl.estab = nfitem.estab
    and nfl.seqnota = nfitem.seqnota
    and nfl.seqnotaitem = nfitem.seqnotaitem