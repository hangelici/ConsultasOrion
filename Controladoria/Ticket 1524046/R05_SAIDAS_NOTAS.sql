-- R05_SAIDAS_NOTAS
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
    nfcab.represent,
    nfcab.seqendereco,
    nfcab.pessentrega,
    nfitem.seqnotaitem,
    nfitem.item,
    nfcab.status,
    nfitem.cfop,
    nfitem.custocmv,
    nfitem.quantidade,
    nfitem.valortotal,
    nfitem.desctotal,
    nfitem.valorunitario,
    case when natitemsaldo.somadiminuinada_item <> 'N' then 'S' else 'N' end movimenta_estoque,
    natoperacao.descricao as natureza_operacao,
    natoperacao.naturezadaoperacao as nat,
    u_tipoop.descop as tipo_operacao
    from nfcab
    inner join filial on filial.estab = nfcab.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab
        and u_tempresa.insumos ='S'
    inner join nfcfg on 
        nfcfg.notaconf  = nfcab.notaconf
        and nfcfg.entradasaida = 'S'
    inner join natoperacao on 
        natoperacao.naturezadaoperacao = nfcfg.naturezadaoperacao
        and natoperacao.entradasaida = 'S'
    left join natitemsaldo on 
        natitemsaldo.naturezadaoperacao = natoperacao.naturezadaoperacao
        and natitemsaldo.entradasaida = 'S'
        and natitemsaldo.codigosaldo = 2
    left join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    left join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
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
    min(ped.numero) as num_pedido
    from peditemnfitem ped
    inner join base_nota bn on
        bn.estab = ped.estabnota
        and bn.seqnota = ped.seqnota
        and bn.seqnotaitem = ped.seqnotaitem
    group by ped.estabnota, ped.seqnota, ped.seqnotaitem
),
base_ori as (
    select /*+ LEADING(BN NFI NFCAB) USE_NL(NFCAB) */
    nfi.estab,
    nfi.seqnota,
    nfi.seqnotaitem,
    min(nfcab.nota) as nota_origem
    from nfitemapartirde nfi
    inner join base_nota bn on
        bn.estab = nfi.estab
        and bn.seqnota = nfi.seqnota
        and bn.seqnotaitem = nfi.seqnotaitem
    inner join nfcab on
        nfcab.estab =nfi.estaborigem
        and nfcab.seqnota = nfi.seqnotaorigem
    group by nfi.estab, nfi.seqnota, nfi.seqnotaitem
)
select
bn.estab as cod_loja,
bn.reduzido as nome_loja,
bn.chaveacessonfe as chave_nfe,
bn.nota as num_nf,
bn.serie as serie_nf,
bn.dtemissao as data_emissao,
nfcab_u.USER_ORIGEM as usuario_lancamento,
case when bn.status <> 'C' then 'AUTORIZADA' else 'CANCELADA' end as status_nf,
bn.cfop,
bn.natureza_operacao,
bn.tipo_operacao as tipo_saida,
bn.movimenta_estoque,
base_ori.nota_origem as nf_faturamento_vinculada,
pedidos.num_pedido,
bn.item as item_pedido,
bn.numerocm as cod_cliente,
contamov.nome as nome_cliente,
nvl(endereco.cnpjf,contamov.cnpjf) as cpf_cnpj_cliente,
ppescli.dtcadastro as dat_cadastro_cliente,
bn.represent as cod_vendedor,
rtv.nome as nome_vendedor,
bn.seqnotaitem as item_nf,
case when bn.seqnotaitem = 1 then 'S' else 'N' end as linha_principal_item,
bn.item as cod_produto,
itemagro.descricao as desc_produto,
itemgrupo.descricao as grupo_produto,
itemagro.unidade as unidade,
itemagro.unidade as unidade_nf,
bn.quantidade as qtd_unidade_nf,
bn.quantidade * nvl(itemagro.pesoliquido,1) as qtd_item,
bn.valorunitario as preco_unitario,
bn.desctotal as valor_desconto,
bn.valortotal as valor_liquido_item,
nfl.lote as lote, 
lt.validade as data_validade, 
nfl.quantidade as qtd_lote,
case when movimenta_estoque = 'S' then bn.custocmv else null end custo_unitario,
null as id_item_movimento --revisar
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
inner join itemgrupo on itemgrupo.grupo = itemagro.grupo
left join pedidos on
    pedidos.estabnota = bn.estab
    and pedidos.seqnota = bn.seqnota
    and pedidos.seqnotaitem = bn.seqnotaitem
left join ppescli on ppescli.cliente = bn.numerocm
left join contamov rtv on rtv.numerocm = bn.represent
left join base_ori on
    base_ori.estab = bn.estab
    and base_ori.seqnota = bn.seqnota
    and base_ori.seqnotaitem = bn.seqnotaitem