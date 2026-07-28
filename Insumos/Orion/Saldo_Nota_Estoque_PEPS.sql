with base as (
    select 
        m.estab,
        m.item,
        -- m.doc,
       nvl(m.doc,'A-'||row_number() over (order by m.estab,m.item)  )as doc,
        m.seq,
        nfcab.notaconf,
        nfcfg.descricao as config,
        t.tipoop,
        nfcab.numerocm,
        m.datamovim,
        m.horamovim,
        m.somadiminui,
        m.quantidade,
        nfitem.valorunitario,
        nfcab.prazopagto,
        max(p.dtvencto) as dtvencto
    from movitemagro m
    inner join u_tempresa u on u.estab = m.estab
    left join nfcab on
        nfcab.estab = m.estab
        and nfcab.seqnota = m.seq
    left join nfitem on
        nfitem.estab = m.estab
        and nfitem.seqnota = m.seq
        and nfitem.item = m.item
        and nfitem.seqnotaitem = to_number(regexp_substr(m.ordem_cronologica, '[^-]+$'))
    left join nfcfg on nfcfg.notaconf = nfcab.notaconf
    left join nfcfg_u n on n.notaconf = nfcfg.notaconf
    left join u_tipoop t on t.u_tipoop_id = n.u_tipoop_id
    left join nfcabagrfin on
        nfcabagrfin.estab = nfcab.estab
        and nfcabagrfin.seqnota = nfcab.seqnota
    left join agrfinduprec a on
        a.estab = nfcabagrfin.estab
        and a.seqpagamento = nfcabagrfin.seqpagamento
    left join pduprec p on
        p.empresa = a.estab
        and p.duprec = a.duprec
    where m.codigosaldo = 5
    and u.insumos = 'S'
    and (0 in (:ESTAB) or m.estab in (:ESTAB))
    and (0 in (:ITEM) or m.item in (:ITEM))
    and m.datamovim <= :DTFIM
    group by
    m.estab,m.item,m.doc,m.seq,nfcab.notaconf,
    nfcfg.descricao,t.tipoop,nfcab.numerocm,
    m.datamovim,m.horamovim,m.somadiminui,
    m.quantidade,nfcab.prazopagto,nfitem.valorunitario
),
-- consolida a nota (DOC pode ter mais de um SEQ)
notas as (
    select
        estab,
        item,
        doc,
        max(valorunitario) as valorunitario,
        prazopagto,
        dtvencto,
        max(somadiminui) as somadiminui,     -- assume 1 tipo (S ou D) por nota
        min(datamovim)   as datamovim,
        min(horamovim)   as horamovim,
        sum(quantidade)  as quantidade,
        sum(quantidade * valorunitario) as valor_total,
        case when sum(quantidade) <> 0
             then sum(quantidade * valorunitario) / sum(quantidade)
             else 0
        end as valorunitario_medio
    from base
    group by estab, item, doc, prazopagto, dtvencto
),
-- total consumido (soma de todas as saídas do item/filial)
totais as (
    select
        estab,
        item,
        sum(case when somadiminui = 'D' then quantidade else 0 end) as total_diminui
    from notas
    group by estab, item
),
-- acumulado das entradas em ordem cronológica
creditos as (
    select
        n.*,
        sum(quantidade) over (
            partition by estab, item
            order by datamovim, horamovim, doc
            rows between unbounded preceding and current row
        ) as cum_credito
    from notas n
    where somadiminui = 'S'
),
dados as (
select
    cidade.uf,
    c.estab,
    filial.reduzido as filial,
    f.reduzido as filial_consolidado,
    c.item,
    itemagro.descricao as produto,
    u_agrprod.descagrupa AS agrup,
    itemmarca.descricao as fornecedor,
    itemgrupo.descricao as subgrupo,
    u_gestoque.descricao as grupo,
    c.doc,
    valorunitario,
    somadiminui,
    nvl(dtvencto,prazopagto) as dtvenc,
    c.datamovim,
    c.horamovim,
    nvl(itemagro.pesoliquido,1) as kglt,
    c.quantidade as qtd_nota,
    c.quantidade * nvl(itemagro.pesoliquido,1) as qtd_kglt,
    t.total_diminui,
    c.cum_credito,
    least(c.quantidade, greatest(0, c.cum_credito - t.total_diminui)) as saldo,
    least(c.quantidade, greatest(0, c.cum_credito - t.total_diminui)) * c.valorunitario_medio as saldo_valor
from creditos c
join totais t on t.estab = c.estab and t.item = c.item
join filial on filial.estab = c.estab
join cidade on cidade.cidade = filial.cidade
join u_tempresa on u_tempresa.estab = filial.estab
left join filial f on f.estab = u_tempresa.estabc
join itemagro on itemagro.item = c.item
left join itemagro_u on itemagro_u.item = itemagro.item
left join itemmarca on itemmarca.marca = itemagro.marca
left join itemgrupo on itemgrupo.grupo = itemagro.grupo
left join itemgrupo_u on itemgrupo_u.grupo = itemgrupo.grupo
left join u_gestoque ON u_gestoque.u_gestoque_id = itemgrupo_u.u_gestoque_id
left join u_agrprod on u_agrprod.u_agrprod_id = itemagro_u.u_agrprod_id
order by c.datamovim, c.horamovim, c.doc
)
select
    uf,
    estab,
    filial,
    filial_consolidado,
    item,
    produto,
    agrup,
    fornecedor,
    subgrupo,
    grupo,
    doc,
    valorunitario,
    --somadiminui,
    dtvenc,
    datamovim,
    --horamovim,
    kglt,
    qtd_nota,
    qtd_kglt,
    --total_diminui,
    --cum_credito,
    saldo,
    saldo_valor
from dados