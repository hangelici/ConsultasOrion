-- R03_ENTRADAS
with base_nota as (
    select /*+ MATERIALIZE LEADING(NFCAB FILIAL U_TEMPRESA NFCFG NFITEM) USE_NL(NFITEM) INDEX(NFITEM NFITEM01) */
    nfcab.estab,
    filial.reduzido,
    nfcab.seqnota,
    nfcab.nota,
    nfcab.chaveacessonfe,
    nfcab.dtemissao,
    nfcab.dtentsai,
    nfcab.serie,
    nfcab.numerocm,
    nfcab.seqendereco,
    nfcab.pessentrega,
    nfitem.seqnotaitem,
    nfitem.item,
    nfcab.status,
    nfitem.cfop,
    nfitem.quantidade,
    nfitem.valortotal,
    nfitem.valorunitario
    from nfcab
    inner join filial on filial.estab = nfcab.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab
        and u_tempresa.insumos ='S'
    inner join nfcfg on 
        nfcfg.notaconf  = nfcab.notaconf
        and nfcfg.entradasaida = 'E'
    inner join nfitem on 
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota
    where nfcab.dtemissao between :DTINI and :DTFIM
),
pedidos as (
    select
    ped.estabnota,
    ped.seqnota,
    ped.seqnotaitem,
    sum(ped.quantidade) as qtd_recebida_pedido,
    min(ped.numero) as num_pedido,
    min(peditem.valorunitario) as preco_pedido
    from peditemnfitem ped
    inner join base_nota bn on
        bn.estab = ped.estabnota
        and bn.seqnota = ped.seqnota
        and bn.seqnotaitem = ped.seqnotaitem
    inner join peditem on
        peditem.estab = ped.estab
        and peditem.numero = ped.numero
        and peditem.seqpedite = ped.seqpedite
        and peditem.serie = ped.serie
    group by ped.estabnota, ped.seqnota, ped.seqnotaitem
)
select
bn.estab as cod_loja,
bn.reduzido as nome_loja,
bn.chaveacessonfe as chave_nfe,
bn.nota,
bn.serie,
case when bn.status <> 'C' then 'AUTORIZADA' else 'CANCELADA' end as status_nf,
bn.dtemissao as data_emissao,
bn.dtentsai as data_entrada,
nfcab_u.USER_ORIGEM as usuario_lancamento,
bn.numerocm as cod_fornecedor,
contamov.nome as nome_fornecedor,
nvl(endereco.cnpjf,contamov.cnpjf) as cnpj_fornecedor,
bn.PESSENTREGA,
bn.cfop,
bn.seqnotaitem as item_nf,
case when bn.seqnotaitem = 1 then 'S' else 'N' end as linha_principal_item,
bn.item as cod_produto,
itemagro.descricao as desc_produto,
itemagro.unidade as unidade,
itemagro.unidade as unidade_nf,
bn.quantidade as qtd_unidade_nf,
bn.quantidade * nvl(itemagro.pesoliquido,1) as qtd_unidade_nf,
bn.valorunitario as valor_unit_nf,
bn.valortotal as valor_total_item,
nfl.lote as lote, 
lt.validade as data_validade, 
nfl.quantidade as qtd_lote,
null as id_item_movimento, --revisar
pedidos.num_pedido,
bn.item as item_pedido, 
pedidos.qtd_recebida_pedido, 
pedidos.preco_pedido, 
pedidos.qtd_recebida_pedido
from base_nota bn
left join nfitemloteagro nfl on
    nfl.estab = bn.estab
    and nfl.seqnota = bn.seqnota
    and nfl.seqnotaitem = bn.seqnotaitem
left join loteagro lt on
    lt.estab = nfl.estab
    and lt.lote = nfl.lote
    and lt.item = nfl.item
    and lt.seqlote = nfl.seqlote
    and lt.tipo = nfl.tipo
left join nfcab_u on
    bn.estab = nfcab_u.estab
    and bn.seqnota = nfcab_u.seqnota
inner join contamov on contamov.numerocm = bn.numerocm
left join endereco on
    endereco.numerocm = bn.numerocm
    and endereco.seqendereco = bn.seqendereco
inner join itemagro on itemagro.item = bn.item
left join pedidos on
    pedidos.estabnota = bn.estab
    and pedidos.seqnota = bn.seqnota
    and pedidos.seqnotaitem = bn.seqnotaitem
