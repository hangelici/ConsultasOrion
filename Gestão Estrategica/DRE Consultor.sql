with base_venda as (
    select /*+ MATERIALIZE  */
    nfcab.estab,
    nfcab.represent,
    nfcab.seqnota,
    nfitem.seqnotaitem,
    trunc(nfcab.dtemissao,'MM') as data,
    nfitem.quantidade,
    u_gestoque.descricao as grupo,
    u_tipoop.tipoop,
    (nfitem.valortotal - (divide(nfitem.valortotal, nfcab.valorprodbruto) * nvl(desconto.valor,0))) as valor,
    nfitem.custocmvp,
    nfitem.custocmv
    from nfcab
    inner join filial on filial.estab = nfcab.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab and u_tempresa.insumos = 'S' 
    left join (
            select nfdesc.estab,
            nfdesc.seqnota,
            sum(nfdesc.valordesconto) valor
            from nfdesc
            group by  nfdesc.estab,nfdesc.seqnota
        )desconto on
        desconto.estab = nfcab.estab
        and desconto.seqnota = nfcab.seqnota
    inner join nfitem on
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    inner join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
    inner join itemagro on itemagro.item = nfitem.item
    inner join itemgrupo on itemgrupo.grupo = itemagro.grupo
    inner join itemgrupo_u on itemgrupo_u.grupo = itemgrupo.grupo
    inner join u_gestoque on u_gestoque.u_gestoque_id = itemgrupo_u.u_gestoque_id

    where nfcab.status <> 'C'
    and u_tipoop.tipoop in ('VF','V','RF','DF-V','DV')
    and nfcab.dtemissao between :DTINI and :DTFIM
    --and nfcab.represent = 44821
    --and itemgrupo_u.u_gestoque_id = 4
),
base_devol as (
    select
    nfi.estab,
    nfi.seqnota,
    nfi.seqnotaitem,
    bv.custocmvp as custocmvp_ori,
    bv.custocmv as custocmv_ori
    from nfitemapartirde nfi
    --- notas de venda e remessa
    inner join base_venda bv on
        bv.estab = nfi.estaborigem
        and bv.seqnota = nfi.seqnotaorigem
        and bv.seqnotaitem = nfi.seqnotaitemorigem
        and bv.tipoop in ('VF','V','RF')
    --- desfazimento e devolução
    inner join base_venda dev on
        dev.estab = nfi.estab
        and dev.seqnota = nfi.seqnota
        and dev.seqnotaitem = nfi.seqnotaitem
        and dev.tipoop in ('DF-V','DV')
)
select
b.estab,
b.represent,
b.data,
b.grupo,
--tipoop,
sum(b.valor) as valor,
sum(b.custocmvp) as custocmvp,
sum(b.custocmv) as custocmv,
sum(d.custocmv_ori) as custocmv_ori,
sum(d.custocmvp_ori) as custocmvp_ori,
sum(case
    when tipoop in ('VF','V') then valor
    when tipoop in ('DF-V','DV') then -valor
    else 0 
end) as v_vf,
sum(case
    when tipoop in ('RF','V') then valor
    when tipoop in ('DV') then -valor
    else 0 
end) as v_rf,
sum(case
    when tipoop in ('VF','V') then custocmvp
    when tipoop in ('DF-V','DV') and (custocmvp_ori is not null and custocmvp_ori <> 0) then -custocmvp_ori
    when tipoop in ('DF-V','DV') and (custocmv_ori is not null and custocmv_ori <> 0) then -custocmv_ori
    else 0 
end*quantidade) as custo_vvf,
sum(case
    when tipoop in ('RF','V') then custocmv
    when tipoop in ('DV') and (custocmv_ori is not null and custocmv_ori <> 0) then -custocmv_ori
    else 0 
end*quantidade) as custo_vrf

from base_venda b
left join base_devol d on
    d.estab = b.estab
    and d.seqnota = b.seqnota
    and d.seqnotaitem = b.seqnotaitem

group by
b.estab,
b.represent,
b.data,
b.grupo