-- R06_A_ENTREGAR
with base as (
    -- base de pedidos (igual à atual, + filtro de emissão que você incluiu)
    select /*+ LEADING(PEDCAB PEDITEM) USE_NL(PEDITEM) INDEX(PEDITEM IDX_FK_PEDCAB_PEDITEM) */
    pedcab.estab,
    pedcab.serie,
    pedcab.numero,
    peditem.seqpedite,
    pedcab.dtemissao,
    pedcab.pessoa,
    pedcab.seqendereco,
    pedcab.represent,
    pedcab.status,
    nvl(peditem.dtentrega,pedcab.dtprevisao) as data_prevista_entrega,
    peditem.quantidade,
    peditem.cancelado,
    peditem.item,
    peditem.valorunitario
    from pedcab
    inner join peditem on
        peditem.estab = pedcab.estab
        and peditem.serie = pedcab.serie
        and peditem.numero = pedcab.numero
    where pedcab.serie in ('PV','PVM')
    and pedcab.status <> 'C'
    and pedcab.estab in (4,13)
    and pedcab.dtemissao between :DTINI and :DTFIM
),
notas_ped as (
    -- notas que baixaram os pedidos, com o tipo da venda
    select /*+ MATERIALIZE */
    ped.estab,
    ped.serie,
    ped.numero,
    ped.seqpedite,
    ped.estabnota,
    ped.seqnota,
    ped.seqnotaitem,
    ped.quantidade as qtd_faturada,
    nfcab.dtemissao as dt_nota,
    case when u_tipoop.tipoop = 'VF' then 'VF' else 'V' end as tipo
    from peditemnfitem ped
    inner join base on
        base.estab = ped.estab
        and base.serie = ped.serie
        and base.numero = ped.numero
        and base.seqpedite = ped.seqpedite
    inner join nfcab on
        nfcab.estab = ped.estabnota
        and nfcab.seqnota = ped.seqnota
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    left join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    left join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
),
nivel1 as (
    -- destinos das notas do pedido: remessas (saída) ou desfazimento/devolução (entrada)
    select /*+ MATERIALIZE */
    np.estab,
    np.serie,
    np.numero,
    np.seqpedite,
    np.tipo,
    nfi.estab       as estab_dest,
    nfi.seqnota     as seqnota_dest,
    nfi.seqnotaitem as seqnotaitem_dest,
    nfi.quantidade,
    nfcfg.entradasaida,
    nf.dtemissao
    from nfitemapartirde nfi
    inner join notas_ped np on
        np.estabnota = nfi.estaborigem
        and np.seqnota = nfi.seqnotaorigem
        and np.seqnotaitem = nfi.seqnotaitemorigem
    inner join nfcab nf on
        nf.estab = nfi.estab
        and nf.seqnota = nfi.seqnota
    inner join nfcfg on nfcfg.notaconf = nf.notaconf
),
dev as (
    -- devoluções das remessas de venda futura
    select
    r.estab,
    r.serie,
    r.numero,
    r.seqpedite,
    sum(nd.quantidade) as qtd_devolvida_remessa
    from nfitemapartirde nd
    inner join nivel1 r on
        r.tipo = 'VF'
        and r.entradasaida = 'S'
        and r.estab_dest = nd.estaborigem
        and r.seqnota_dest = nd.seqnotaorigem
        and r.seqnotaitem_dest = nd.seqnotaitemorigem
    inner join nfcab nf2 on
        nf2.estab = nd.estab
        and nf2.seqnota = nd.seqnota
    inner join nfcfg c2 on
        c2.notaconf = nf2.notaconf
        and c2.entradasaida = 'E'
    group by r.estab, r.serie, r.numero, r.seqpedite
),
fat as (
    -- faturamento por item de pedido
    select
    estab, serie, numero, seqpedite,
    sum(qtd_faturada) as qtd_faturada,
    min(dt_nota)      as dt_primeiro_fat,
    max(dt_nota)      as dt_ultimo_fat,
    max(tipo)         as tipo          -- um pedido nunca mistura V e VF
    from notas_ped
    group by estab, serie, numero, seqpedite
),
mov as (
    -- destinos das notas por item de pedido
    select
    estab, serie, numero, seqpedite,
    sum(case when tipo = 'VF' and entradasaida = 'S' then quantidade else 0 end) as qtd_remessa,
    sum(case when tipo = 'VF' and entradasaida = 'E' then quantidade else 0 end) as qtd_desfeita,
    sum(case when tipo = 'V'  and entradasaida = 'E' then quantidade else 0 end) as qtd_devolvida_venda,
    max(case when tipo = 'VF' and entradasaida = 'S' then dtemissao end)         as dt_ultima_remessa
    from nivel1
    group by estab, serie, numero, seqpedite
)
select
filial.estab as cod_loja,
filial.reduzido as nome_loja,
contamov.numerocm as cod_cliente,
contamov.nome as nome_cliente,
nvl(endereco.cnpjf,contamov.cnpjf) as cpf_cnpjf_cliente,
base.numero as num_pedido,
base.seqpedite as item_pedido,
base.dtemissao as data_venda,
case 
    when base.status = 'B' then 'FATURADO' 
    when fat.qtd_faturada > 0 then 'PARCIAL'
    else 'NAO_FATURADO'
end as situacao_faturamento,
fat.dt_primeiro_fat as data_primeiro_faturamento,
base.represent as cod_vendedor,
itemagro.item as cod_produto,
itemagro.descricao as desc_produto,
itemagro.unidade,
base.quantidade as qtd_vendida,
base.cancelado as qtd_cancelada,
nvl(fat.qtd_faturada, 0) as qtd_faturada,
case 
    when fat.tipo = 'VF' then nvl(mov.qtd_remessa, 0)
    else nvl(fat.qtd_faturada, 0)
end as qtd_entregue,
case 
    when fat.tipo = 'VF' then nvl(dev.qtd_devolvida_remessa, 0)
    else nvl(mov.qtd_devolvida_venda, 0)
end as qtd_devolvida,
nvl(fat.qtd_faturada, 0) - nvl(mov.qtd_desfeita, 0) - 
    case 
        when fat.tipo = 'VF' then nvl(mov.qtd_remessa, 0)
        else nvl(fat.qtd_faturada, 0)
    end as qtd_saldo_entregar,
null as qtd_saldo_calculado, 
nvl(fat.qtd_faturada, 0) - nvl(mov.qtd_desfeita, 0) - 
    case 
        when fat.tipo = 'VF' then nvl(mov.qtd_remessa, 0)
        else nvl(fat.qtd_faturada, 0)
    end as qtd_faturada_nao_entregue,
(
    nvl(fat.qtd_faturada, 0) - nvl(mov.qtd_desfeita, 0) - 
    case 
        when fat.tipo = 'VF' then nvl(mov.qtd_remessa, 0)
        else nvl(fat.qtd_faturada, 0)
    end
) * base.valorunitario as valor_faturado_nao_entregue,
trunc(cast(:DTFIM as date) - base.dtemissao)  as dias_desde_venda,
case when fat.tipo = 'VF' then mov.dt_ultima_remessa else fat.dt_ultimo_fat end as data_ultima_entrega,
base.data_prevista_entrega
from base
inner join filial on filial.estab = base.estab
inner join contamov on contamov.numerocm = base.pessoa
left join endereco on
    endereco.numerocm = base.pessoa
    and endereco.seqendereco = base.seqendereco
inner join itemagro on itemagro.item = base.item
left join fat on
    fat.estab = base.estab
    and fat.serie = base.serie
    and fat.numero = base.numero
    and fat.seqpedite = base.seqpedite
left join mov on
    mov.estab = base.estab
    and mov.serie = base.serie
    and mov.numero = base.numero
    and mov.seqpedite = base.seqpedite
left join dev on
    dev.estab = base.estab
    and dev.serie = base.serie
    and dev.numero = base.numero
    and dev.seqpedite = base.seqpedite