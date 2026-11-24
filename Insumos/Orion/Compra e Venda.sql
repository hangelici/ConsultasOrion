/* =====================================================================
   SALDO DAS NOTAS DE COMPRA x BAIXA PELAS NOTAS DE VENDA (FIFO)
   ---------------------------------------------------------------------
   Compras (credito) : tipoop C, CF, TE (TE somente vinda de outro grupo)
                       e IS (implantacao de saldo - compras anteriores a
                       troca de ERP; entra na fila antes das demais)
                       e SE (sobra de estoque; ordem cronologica normal)
   Vendas  (debito)  : tipoop V, VF e BP (baixa por perda - registros antigos)
   Regra             : as vendas baixam as compras mais antigas primeiro
                       (FIFO), por FILIAL (nfcab.estab) + ITEM.
   CF/VF (futuras) e C/V (diretas) sao operacoes independentes,
   sem contagem dupla.

   Tecnica: "faixas acumuladas". Cada nota recebe uma faixa
   [acum_ini, acum_fim) na fila de compras e na fila de vendas do mesmo
   grupo/item. A quantidade que uma venda baixa de uma compra e a
   sobreposicao entre as duas faixas.

   Saida (uma linha por par compra x venda):
     TIPO_LINHA = 'BAIXA'           -> venda que baixou (parte de) a compra
     TIPO_LINHA = 'SEM VENDA'       -> compra ainda sem nenhuma baixa
     TIPO_LINHA = 'VENDA SEM SALDO' -> parte da venda sem compra para lastrear

   Parametros:
     :ESTAB -> filial(is); 0 = todas
     :DTINI -> data inicial do periodo (filtra so a exibicao)
     :DTFIM -> data final do periodo (exibicao + corte do calculo; saldos = posicao em :DTFIM)
   ===================================================================== */
with base as (
    select
        nfcab.estab,
        nfcab.seqnota,
        nfitem.seqnotaitem,
        nfcab.dtemissao,
        nfitem.hora,
        nfcab.notaconf,
        nfcab.nota,
        nfcab.numerocm,
        contamov.cnpjf,
        tipo.tipoop,
        nfitem.item,
        nfitem.quantidade,
        case when tipo.tipoop in ('V','VF','BP') then 'V' else 'C' end as natureza,   -- V, VF, BP = debito | C, CF, TE, IS, SE = credito
        case when tipo.tipoop = 'IS' then 0 else 1 end as prioridade_fifo        -- IS (saldo de abertura) e baixado primeiro
    from nfcab
    inner join filial on filial.estab = nfcab.estab
    inner join u_tempresa on u_tempresa.estab = filial.estab
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    inner join u_tipoop tipo on tipo.u_tipoop_id = nfcfg_u.u_tipoop_id
    inner join nfitem on
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota

    /* ### TRANSFERENCIA
    1. Pegar CNPJ da origem
    2. Verificar se e uma filial
    3. Busca a Filial Consolidada
    */
    left join contamov on contamov.numerocm = nfcab.numerocm ----- 1 (left: notas sem numerocm, ex. IS, entram na contagem)
    left join filial fc on fc.cnpj = contamov.cnpjf ----- 2
    left join u_tempresa uc on uc.estab = fc.estab ----- 3

    where
    nvl(nfcab.status,'X') <> 'C'          -- status nulo (comum em IS) nao pode excluir a nota
    and u_tempresa.insumos = 'S'
    and nfitem.quantidade > 0
    and nfcab.estab not in  (2)
    and (nfcab.estab in (:ESTAB) or 0 in (:ESTAB))                         -- filial (0 = todas); seguro filtrar aqui, o FIFO e por filial
    and (
           tipo.tipoop in ('V','VF','C','CF')
        or tipo.tipoop in ('IS','SE','BP')                                   -- IS (implantacao de saldo), SE (sobra de estoque) e BP (baixa por perda): sem validacao de estabc
        or (tipo.tipoop = 'TE' and nvl(uc.estabc,0) <> nfcab.estab)          -- TE: somente vinda de outro grupo
    )
    -- Data INICIAL nao pode ser filtrada aqui: o FIFO precisa do historico completo (IS, compras antigas).
    -- Data FINAL pode: ignora movimentos posteriores e os saldos passam a ser "posicao na data final".
    and nfcab.dtemissao <= :DTFIM                                           -- data final do periodo
    -- O filtro de periodo (BETWEEN) e aplicado na exibicao, no final do script.
),

/* Fila de compras: IS primeiro, depois ordem cronologica dentro de filial + item */
compras as (
    select
        b.*,
        sum(b.quantidade) over (
            partition by b.estab, b.item
            order by b.prioridade_fifo, b.dtemissao, b.hora, b.estab, b.seqnota, b.seqnotaitem
            rows unbounded preceding
        ) as acum_fim
    from base b
    where b.natureza = 'C'
),

/* Fila de vendas: mesma ordenacao */
vendas as (
    select
        b.*,
        sum(b.quantidade) over (
            partition by b.estab, b.item
            order by b.dtemissao, b.hora, b.estab, b.seqnota, b.seqnotaitem
            rows unbounded preceding
        ) as acum_fim
    from base b
    where b.natureza = 'V'
),

tot_compras as (
    select estab, item, sum(quantidade) as qtd_total
    from base where natureza = 'C'
    group by estab, item
),

tot_vendas as (
    select estab, item, sum(quantidade) as qtd_total
    from base where natureza = 'V'
    group by estab, item
),

/* Saldo final de cada item de compra */
compras_saldo as (
    select
        c.*,
        c.acum_fim - c.quantidade as acum_ini,
        greatest(0, least(c.acum_fim, nvl(tv.qtd_total,0)) - (c.acum_fim - c.quantidade)) as qtd_baixada_total,
        c.quantidade
          - greatest(0, least(c.acum_fim, nvl(tv.qtd_total,0)) - (c.acum_fim - c.quantidade)) as saldo_compra
    from compras c
    left join tot_vendas tv on tv.estab = c.estab and tv.item = c.item
),

/* Cruzamento FIFO: sobreposicao das faixas acumuladas */
alocacao as (
    select
        c.estab, c.item,
        c.estab as c_estab, c.seqnota as c_seqnota, c.seqnotaitem as c_seqnotaitem,
        v.estab        as v_estab,
        v.seqnota      as v_seqnota,
        v.seqnotaitem  as v_seqnotaitem,
        v.dtemissao    as v_dtemissao,
        v.notaconf     as v_notaconf,
        v.nota         as v_nota,
        v.numerocm     as v_numerocm,
        v.cnpjf        as v_cnpjf,
        v.tipoop       as v_tipoop,
        v.quantidade   as v_quantidade,
        least(c.acum_fim, v.acum_fim) - greatest(c.acum_fim - c.quantidade, v.acum_fim - v.quantidade) as qtd_baixada,
        c.acum_fim - least(c.acum_fim, v.acum_fim) as saldo_compra_apos_venda,
        case when v.dtemissao < c.dtemissao then 'S' else 'N' end as venda_anterior_compra
    from compras c
    inner join vendas v on
        v.estab = c.estab
        and v.item = c.item
        and (v.acum_fim - v.quantidade) < c.acum_fim
        and v.acum_fim > (c.acum_fim - c.quantidade)
),

resultado as (
/* ---------- 1) Compras (com ou sem baixa) ---------- */
select
    case when a.v_seqnota is null then 'SEM VENDA' else 'BAIXA' end as tipo_linha,
    cs.estab,
    cs.item,
    -- Compra
    cs.estab          as compra_estab,
    cs.seqnota        as compra_seqnota,
    cs.seqnotaitem    as compra_seqnotaitem,
    cs.dtemissao      as compra_dtemissao,
    cs.notaconf       as compra_notaconf,
    cs.nota           as compra_nota,
    cs.numerocm       as compra_numerocm,
    cs.cnpjf          as compra_cnpjf,
    cs.tipoop         as compra_tipoop,
    cs.quantidade     as compra_quantidade,
    cs.qtd_baixada_total as compra_qtd_baixada,
    cs.saldo_compra   as compra_saldo,
    -- Venda que baixou
    a.v_estab         as venda_estab,
    a.v_seqnota       as venda_seqnota,
    a.v_seqnotaitem   as venda_seqnotaitem,
    a.v_dtemissao     as venda_dtemissao,
    a.v_notaconf      as venda_notaconf,
    a.v_nota          as venda_nota,
    a.v_numerocm      as venda_numerocm,
    a.v_cnpjf         as venda_cnpjf,
    a.v_tipoop        as venda_tipoop,
    a.v_quantidade    as venda_quantidade,
    a.qtd_baixada,
    a.saldo_compra_apos_venda,
    a.venda_anterior_compra
from compras_saldo cs
left join alocacao a on
    a.c_estab = cs.estab
    and a.c_seqnota = cs.seqnota
    and a.c_seqnotaitem = cs.seqnotaitem

union all

/* ---------- 2) Vendas sem lastro de compra (excedente) ---------- */
select
    'VENDA SEM SALDO' as tipo_linha,
    v.estab,
    v.item,
    null, null, null, null, null, null, null, null, null, null, null, null,
    v.estab,
    v.seqnota,
    v.seqnotaitem,
    v.dtemissao,
    v.notaconf,
    v.nota,
    v.numerocm,
    v.cnpjf,
    v.tipoop,
    v.quantidade,
    v.acum_fim - greatest(v.acum_fim - v.quantidade, nvl(tc.qtd_total,0)) as qtd_baixada,  -- qtd sem lastro
    null,
    null
from vendas v
left join tot_compras tc on tc.estab = v.estab and tc.item = v.item
where v.acum_fim > nvl(tc.qtd_total,0)
)

/* ---------- Exibicao: filtro de periodo aplicado APOS o calculo FIFO ----------
   Mostra a linha se a compra OU a venda estiver no periodo. Assim uma venda
   recente continua mostrando a compra antiga (ou IS) que a lastreou, e os
   saldos (compra_saldo, saldo_compra_apos_venda) consideram todo o historico. */
select *
from resultado r
where
    (   r.compra_dtemissao between :DTINI and :DTFIM
     or r.venda_dtemissao  between :DTINI and :DTFIM)
    -- and r.compra_saldo > 0          -- (opcional) somente compras com saldo em aberto
order by
    r.estab, r.item,
    r.compra_dtemissao, r.compra_seqnota, r.compra_seqnotaitem,
    r.venda_dtemissao, r.venda_seqnota, r.venda_seqnotaitem
