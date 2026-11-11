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
    --and nfcab.represent = 48837
    --and itemgrupo_u.u_gestoque_id = 1
),
base_devol as (
    select
    nfi.estab,
    nfi.seqnota,
    nfi.seqnotaitem,
    case
        when u_tipoop.tipoop = 'RF' and nvl(nfori.custocmvp,0) <> 0 then nfori.custocmvp
        when u_tipoop.tipoop <> 'RF' and nvl(nfitem.custocmvp,0) <> 0 then nfitem.custocmvp
        when u_tipoop.tipoop = 'RF' and nvl(nfori.custocmvp,0) = 0 then nfori.custocmv
        when u_tipoop.tipoop <> 'RF' and nvl(nfitem.custocmvp,0) = 0 then nfitem.custocmv 
        else 0 
    end as custocmvp_ori,
    case
        when u_tipoop.tipoop = 'RF' and nvl(nfori.custocmv,0) <> 0 then nfori.custocmv
        when u_tipoop.tipoop <> 'RF' and nvl(nfitem.custocmv,0) <> 0 then nfitem.custocmv
        else 0 
    end as custocmv_ori/*
    nfitem.custocmvp as cmvp_vf_v,
    nfitem.custocmv as cmv_vf_v,
    nfori.custocmvp as cmvp_rf,
    nfori.custocmv as cmv_rf*/
    from nfitemapartirde nfi
    --- notas de desfazimento/devolução
    inner join base_venda dev on
        dev.estab = nfi.estab
        and dev.seqnota = nfi.seqnota
        and dev.seqnotaitem = nfi.seqnotaitem
        and dev.tipoop in ('DF-V','DV')
    --- DV -> Venda ou RF | DF - > VF
    -- Custo de NFITEM se Origem = VF e V
    left join nfitem on
        nfitem.estab = nfi.estaborigem
        and nfitem.seqnota = nfi.seqnotaorigem
        and nfitem.seqnotaitem = nfi.seqnotaitemorigem
    inner join nfcab on
        nfcab.estab = nfitem.estab
        and nfcab.seqnota = nfitem.seqnota
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    inner join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
    --- Se for RF, precisa pegar custo da VF
    left join nfitemapartirde nf on
        nf.estab = nfitem.estab
        and nf.seqnota = nfitem.seqnota
        and nf.seqnotaitem = nfitem.seqnotaitem
    left join nfitem nfori on
        nfori.estab = nf.estaborigem
        and nfori.seqnota = nf.seqnota
        and nfori.seqnotaitem = nf.seqnotaitem
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
    when tipoop in ('DF-V','DV') and custocmvp_ori = 0 then -custocmvp
    when tipoop in ('DF-V','DV') and custocmvp_ori is null and custocmv_ori is null and custocmvp <> 0 then -custocmvp
    when tipoop in ('DF-V','DV') and custocmvp_ori is null and custocmv_ori is null and custocmv <> 0 then -custocmv
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