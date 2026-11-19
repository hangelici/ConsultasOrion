with base as (
    select
    to_number(substr(m.ordem_cronologica, instr(m.ordem_cronologica, '-', -1) + 1)) as ordem_item,
    m.estab as cod_unidade,
    m.chave as id_movimento,
    m.seq as id_item_movimento,
    datamovim ||''|| horamovim as data_hora_efeito,
    datamovim ||''|| horamovim as data_hora_lancamento,
    2 as cod_tipo_movimento,
    'Fisico' as desc_tipo_movimento,
    m.item as cod_produto,
    itemagro.unidade as unidade_original,
    m.somadiminui,
    case when m.somadiminui = 'S' then m.quantidade else -m.quantidade end as qtd_sinal_kg,
    m.natureza as tipo_doc_origem,
    m.doc as id_doc_origem
    from movitemagro m
    inner join filial on filial.estab = m.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab and u_tempresa.graos = 'S'
    inner join itemagro on itemagro.item = m.item
    where m.datamovim between :DTINI and :DTFIM
    and (0 in (:ESTAB) or m.estab in (:ESTAB))
    and m.codigosaldo = 2
),
apartir as (
    select
    nf.estab,
    nf.seqnota,
    nf.seqnotaitem,
    max(nfcab.nota) as notaori,
    max(case when base.somadiminui = nfcfg.entradasaida then nf.seqnotaorigem else null end) as seqori,
    max(nat.descricao) as natop
    from nfitemapartirde nf
    inner join base on
        base.cod_unidade = nf.estab
        and base.id_item_movimento = nf.seqnota
        and base.ordem_item = nf.seqnotaitem
    inner join nfcab on
        nfcab.estab = nf.estaborigem
        and nfcab.seqnota = nf.seqnotaorigem
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    inner join natoperacao nat on
        nat.entradasaida = nfcfg.entradasaida
        and nat.naturezadaoperacao = nfcfg.naturezadaoperacao
    group by nf.estab, nf.seqnota, nf.seqnotaitem
)
select
cod_unidade,
id_movimento,
id_item_movimento,
data_hora_efeito,
data_hora_lancamento,
cod_tipo_movimento,
desc_tipo_movimento,
cod_produto,
unidade_original,
qtd_sinal_kg,
apartir.natop as tipo_doc_origem,
apartir.notaori as id_doc_origem,
seqori as id_movimento_estornado
from base
left join apartir on
    base.cod_unidade = apartir.estab
        and base.id_item_movimento = apartir.seqnota
        and base.ordem_item = apartir.seqnotaitem
