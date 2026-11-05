--- R07_CANCEL_DEVOL  
with basecanc as (
    -- notas canceladass
    select
    nfc.estab,
    nfc.nota,
    nfc.chaveacesso,
    nfc.dtcancelamento as data_hora_evento,
    nfc.useridcanc as usuario_evento,
    null as num_doc_original,
    nvl(nfcab.numerocm,hn.numerocm) as numerocm,
    nfc.justcancnfe as motivo,
    hn.quantidade,
    hn.cfop,
    hn.valortotal,
    hn.item,
    hn.seqnotaitem,
    nvl(nfcab.dtemissao,hn.dtemissao) as dtemissao
    from nfcancelamento nfc
    left  join nfcab on
        nfcab.estab = nfc.estab
        and nfcab.seqnota = nfc.seqnota      
    left join os_hist_notas_canceladas hn on
        hn.estab = nfc.estab
        and hn.seqnota = nfc.seqnota
    inner join u_tempresa on u_tempresa.estab = nfc.estab

    where u_tempresa.insumos = 'S'  and hn.dtemissao between :DTINI and :DTFIM
),
basedev as (
    -- notas de devolução de compra e venda
    select
    nfcab.estab,
    nfcab.nota,
    nfcab.seqnota,
    nfitem.seqnotaitem,
    nfcab.chaveacessonfe,
    nfcab.numerocm,
    nfcab.seqendereco,
    nfitem.cfop,
    nfcab.dtemissao,
    nfitem.item,
    nfitem.quantidade,
    nfitem.valortotal,
    u_tipoop.tipoop
    from nfcab
    inner join u_tempresa on
        u_tempresa.estab = nfcab.estab
        and u_tempresa.insumos = 'S'
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    inner join u_tipoop on
        u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
        and u_tipoop.tipoop IN ('DV','DV-C')
    inner join nfitem on
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota
    where nfcab.dtemissao between :DTINI and :DTFIM
),
apartir as (
    select /*+ LEADING(BASEDEV NFI NF) USE_NL(NFI) */ --  notas de remessa que são origem da devolução
    basedev.estab, basedev.seqnota, basedev.seqnotaitem,
    nfi.estaborigem,nfi.seqnotaorigem,nfi.seqnotaitemorigem,
    (nf.nota) as doc_ori,
    (nf.dtemissao) as dtemissao_ori
    from nfitemapartirde nfi
    inner join basedev on 
        basedev.estab = nfi.estab
        and basedev.seqnota = nfi.seqnota
        and basedev.seqnotaitem = nfi.seqnotaitem
    inner join nfcab nf on
        nf.estab = nfi.estaborigem
        and nf.seqnota = nfi.seqnotaorigem
),
lote_ori as (
    select /*+ LEADING(APARTIR NL) USE_NL(NL) INDEX(NL IDX_NFITEMLOTEAGRO11) */
    apartir.estab,
    apartir.seqnota,
    apartir.seqnotaitem,
    nl.item,
    min(nl.lote) as loteori
    from nfitemloteagro nl
    inner join apartir on
        apartir.estaborigem = nl.estab
        and apartir.seqnotaorigem = nl.seqnota
        and apartir.seqnotaitemorigem = nl.seqnotaitem
    group by apartir.estab, apartir.seqnota, apartir.seqnotaitem, nl.item
),
apartir_soma as (
    select
    apartir.estab, apartir.seqnota, apartir.seqnotaitem,
    min(doc_ori) as doc_ori,
    min(dtemissao_ori) as dtemissao_ori
    from apartir
    group by apartir.estab, apartir.seqnota, apartir.seqnotaitem
)
select /*+ GATHER_PLAN_STATISTICS */
dados.estab as cod_loja,
filial.reduzido as nome_loja,
dados.tipo_evento,
dados.num_doc_evento,
dados.chave_nfe_evento,
dados.situacao_nf,
dados.item_doc,
dados.linha_principal_item,
dados.cfop,
dados.data_hora_evento,
dados.usuario_evento,
dados.num_doc_original,
dados.data_doc_original,
dados.cod_parceiro,
contamov.nome as nome_parceiro,
nvl(endereco.cnpjf,contamov.cnpjf) as cpf_cnpj_parceiro,
dados.item as cod_produto,
itemagro.descricao as desc_produto,
itemagro.unidade,
dados.qtd_item,
dados.valor,
dados.lote,
dados.lote_doc_original,
dados.qtd_lote,
dados.id_item_movimento
from(

select
--- notas de devolução
bd.estab,
case when bd.tipoop = 'DV' then 'DEVOLUCAO_CLIENTE' else 'DEVOLUCAO_FORNECEDOR' end as tipo_evento,
bd.nota as num_doc_evento,
bd.chaveacessonfe as chave_nfe_evento,
'AUTORIZADA' as situacao_nf,
bd.seqnotaitem as item_doc,
case when bd.seqnotaitem = 1 then 'S' else 'N' end linha_principal_item,
bd.cfop,
bd.dtemissao,
nfcab_u.user_origem as usuario_evento,
ap.doc_ori as num_doc_original,
ap.dtemissao_ori as data_doc_original,
bd.numerocm as cod_parceiro,
bd.seqendereco,
bd.item,
bd.quantidade as qtd_item,
bd.valortotal as valor,
nfl.lote,
lote_ori.loteori as lote_doc_original,
nfl.quantidade as qtd_lote,
null as id_item_movimento,
bd.dtemissao as data_hora_evento
from basedev bd
left join nfcab_u on
    nfcab_u.estab = bd.estab
    and nfcab_u.seqnota = bd.seqnota

left join apartir_soma ap on
    ap.estab = bd.estab
    and ap.seqnota = bd.seqnota
    and ap.seqnotaitem = bd.seqnotaitem

left join nfitemloteagro nfl on
    nfl.estab = bd.estab
    and nfl.seqnota = bd.seqnota
    and nfl.seqnotaitem = bd.seqnotaitem

left join lote_ori on
    lote_ori.estab = bd.estab
    and lote_ori.seqnota = bd.seqnota
    and lote_ori.seqnotaitem = bd.seqnotaitem
    and lote_ori.item = bd.item

union all

select
-- notas canceladas
bc.estab,
'NF_CANCELADA' as tipo_evento,
bc.nota as num_doc_evento,
bc.chaveacesso as chave_nfe_evento,
'CANCELADA' as situacao_nf,
bc.seqnotaitem as item_doc,
case when bc.seqnotaitem = 1 then 'S' else 'N' end linha_principal_item,
bc.cfop,
bc.dtemissao,
bc.usuario_evento,
null as num_doc_original,
null as  data_doc_original,
bc.numerocm as cod_parceiro,
null as seqendereco,
bc.item,
bc.quantidade as qtd_item,
bc.valortotal as valor,
null as lote,
null as lote_doc_original,
null as qtd_lote,
null as id_item_movimento,
bc.data_hora_evento
from basecanc bc 

union all

select
--- pedidos cancelados
pedcab.estab,
'PEDIDO_CANCELADO' as tipo_evento,
pedcab.numero as num_doc_evento,
null as chave_nfe_evento,
'CANCELADA' as situacao_nf,
hp.seqpedite as item_doc,
case when hp.seqpedite = 1 then 'S' else 'N' end linha_principal_item,
null as cfop,
pedcab.dtemissao,
nvl(hp.userid_hist,pedcab.userid) as usuario_evento,
null as num_doc_original,
null as  data_doc_original,
pedcab.pessoa as cod_parceiro,
pedcab.seqendereco as seqendereco,
peditem.item,
peditem.quantidade as qtd_item,
peditem.valor as valor,
ped.lote,
null as lote_doc_original,
ped.quantidade as qtd_lote,
null as id_item_movimento,
hp.datahora_hist as data_hora_evento
from pedcab
inner join u_tempresa on u_tempresa.estab = pedcab.estab and u_tempresa.insumos = 'S'
inner join peditem on
    peditem.estab = pedcab.estab
    and peditem.serie = pedcab.serie
    and peditem.numero = pedcab.numero
left join os_hist_peditem_canc hp on
    hp.estab = peditem.estab
    and hp.serie = peditem.serie
    and hp.numero = peditem.numero
    and hp.seqpedite = peditem.seqpedite
left join peditemlote ped on
    ped.estab = peditem.estab
    and ped.serie = peditem.serie
    and ped.numero = peditem.numero
    and ped.seqpedite = peditem.seqpedite

where pedcab.status = 'C'
  and pedcab.dtemissao between :DTINI and :DTFIM

)dados
inner join filial on filial.estab = dados.estab
inner join contamov on contamov.numerocm = dados.cod_parceiro
left join endereco on
    endereco.numerocm = dados.cod_parceiro
    and endereco.seqendereco = dados.seqendereco
inner join itemagro on itemagro.item = dados.item