/* =====================================================================
   SALDO DAS NOTAS DE COMPRA x BAIXA PELAS NOTAS DE VENDA (FIFO)
   ---------------------------------------------------------------------
   Credito : C, CF, TE (somente de outro grupo), IS (implantacao de saldo,
             baixada primeiro) e SE (sobra de estoque)
   Debito  : V, VF e BP (baixa por perda)
   Regra   : FIFO por filial + item (mais antigas baixadas primeiro)

   Saida:
     BAIXA           -> venda que baixou (parte de) a compra
     SEM VENDA       -> compra sem nenhuma baixa
     VENDA SEM SALDO -> parte da venda sem compra para lastrear

   Parametros:
     :ESTAB -> filial(is); 0 = todas
     :DTINI -> data inicial, 'DD/MM/YYYY' (filtra so a exibicao)
     :DTFIM -> data final, 'DD/MM/YYYY' (exibicao + corte do calculo)
   ===================================================================== */
with

cfg as (
    select nfcfg_u.notaconf, tipo.tipoop
    from nfcfg_u
    inner join u_tipoop tipo on tipo.u_tipoop_id = nfcfg_u.u_tipoop_id
    where tipo.tipoop in ('C','CF','TE','IS','SE','V','VF','BP')
),

base as (
    select /*+ USE_HASH(nfitem) FULL(nfitem) */
        nfcab.estab,
        nfcab.seqnota,
        nfitem.seqnotaitem,
        nfcab.dtemissao,
        nfitem.hora,
        nfcab.notaconf,
        nfcab.nota,
        nfcab.numerocm,
        cfg.tipoop,
        nfitem.item,
        nfitem.quantidade,
        case when cfg.tipoop in ('V','VF','BP') then 'V' else 'C' end as natureza,
        case when cfg.tipoop = 'IS' then 0 else 1 end as prioridade_fifo
    from nfcab
    inner join u_tempresa on u_tempresa.estab = nfcab.estab
    inner join cfg on cfg.notaconf = nfcab.notaconf
    inner join nfitem on
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota
    where
        nvl(nfcab.status,'X') <> 'C'
        and u_tempresa.insumos = 'S'
        and nfitem.quantidade > 0
        and nfcab.estab not in (2)
        and (nfcab.estab in (:ESTAB) or 0 in (:ESTAB))
        -- sem corte de data inicial: o FIFO precisa do historico completo
        and nfcab.dtemissao < to_date(:DTFIM,'DD/MM/YYYY')
        -- TE: exclui transferencia vinda do proprio grupo (estabc)
        and (
            cfg.tipoop <> 'TE'
            or not exists (
                select 1
                from contamov cm
                inner join filial fc on fc.cnpj = cm.cnpjf
                inner join u_tempresa uc on uc.estab = fc.estab
                where cm.numerocm = nfcab.numerocm
                  and uc.estabc = nfcab.estab
            )
        )
),

-- posicao acumulada de cada nota na sua fila; unica por estab + item + natureza
fila as (
    select
        b.*,
        sum(b.quantidade) over (
            partition by b.estab, b.item, b.natureza
            order by b.prioridade_fifo, b.dtemissao, b.hora, b.seqnota, b.seqnotaitem
            rows unbounded preceding
        ) as pos
    from base b
),

-- linha do tempo: cada trecho (pos anterior, pos] pertence a proxima compra e a proxima venda
seg as (
    select
        estab, item, pos,
        pos - nvl(lead(pos) over (partition by estab, item
                                  order by pos desc, natureza desc, seqnota desc, seqnotaitem desc), 0) as qtd_seg,
        last_value(case when natureza = 'C' then pos end ignore nulls)
            over (partition by estab, item
                  order by pos desc, natureza desc, seqnota desc, seqnotaitem desc
                  rows between unbounded preceding and current row) as c_pos,
        last_value(case when natureza = 'V' then pos end ignore nulls)
            over (partition by estab, item
                  order by pos desc, natureza desc, seqnota desc, seqnotaitem desc
                  rows between unbounded preceding and current row) as v_pos,
        max(case when natureza = 'V' then pos end)
            over (partition by estab, item) as tot_v
    from fila
),

pares as (
    select
        s.estab, s.item, s.pos, s.qtd_seg, s.c_pos, s.v_pos,
        c.seqnota     as c_seqnota,  c.seqnotaitem as c_seqnotaitem, c.dtemissao as c_dt,
        c.notaconf    as c_notaconf, c.nota        as c_nota,        c.numerocm  as c_numerocm,
        c.tipoop      as c_tipoop,   c.quantidade  as c_qtd,
        v.seqnota     as v_seqnota,  v.seqnotaitem as v_seqnotaitem, v.dtemissao as v_dt,
        v.notaconf    as v_notaconf, v.nota        as v_nota,        v.numerocm  as v_numerocm,
        v.tipoop      as v_tipoop,   v.quantidade  as v_qtd,
        case when s.c_pos is not null
             then greatest(0, least(s.c_pos, nvl(s.tot_v,0)) - (s.c_pos - c.quantidade))
        end as c_qtd_baixada
    from seg s
    left join fila c on
        c.estab = s.estab and c.item = s.item and c.natureza = 'C' and c.pos = s.c_pos
    left join fila v on
        v.estab = s.estab and v.item = s.item and v.natureza = 'V' and v.pos = s.v_pos
    where s.qtd_seg > 0
),

filtrado as (
    select p.*
    from pares p
    where
        -- saldo restante de compra parcialmente baixada nao gera linha propria
        (p.c_pos is null or p.v_pos is not null or p.c_qtd_baixada = 0)
        and (   (p.c_dt >= to_date(:DTINI,'DD/MM/YYYY') and p.c_dt < to_date(:DTFIM,'DD/MM/YYYY'))
             or (p.v_dt >= to_date(:DTINI,'DD/MM/YYYY') and p.v_dt < to_date(:DTFIM,'DD/MM/YYYY')))
)

select
    case
        when f.c_pos is null then 'VENDA SEM SALDO'
        when f.v_pos is null then 'SEM VENDA'
        else 'BAIXA'
    end as tipo_linha,
    f.estab,
    f.item,
    case when f.c_pos is not null then f.estab end as compra_estab,
    f.c_seqnota       as compra_seqnota,
    f.c_seqnotaitem   as compra_seqnotaitem,
    f.c_dt            as compra_dtemissao,
    f.c_notaconf      as compra_notaconf,
    f.c_nota          as compra_nota,
    f.c_numerocm      as compra_numerocm,
    cmc.cnpjf         as compra_cnpjf,
    f.c_tipoop        as compra_tipoop,
    f.c_qtd           as compra_quantidade,
    f.c_qtd_baixada   as compra_qtd_baixada,
    f.c_qtd - f.c_qtd_baixada as compra_saldo,
    case when f.v_pos is not null then f.estab end as venda_estab,
    f.v_seqnota       as venda_seqnota,
    f.v_seqnotaitem   as venda_seqnotaitem,
    f.v_dt            as venda_dtemissao,
    f.v_notaconf      as venda_notaconf,
    f.v_nota          as venda_nota,
    f.v_numerocm      as venda_numerocm,
    cmv.cnpjf         as venda_cnpjf,
    f.v_tipoop        as venda_tipoop,
    f.v_qtd           as venda_quantidade,
    case when f.v_pos is not null then f.qtd_seg end as qtd_baixada,
    case when f.c_pos is not null and f.v_pos is not null
         then f.c_pos - f.pos end as saldo_compra_apos_venda,
    case when f.c_pos is not null and f.v_pos is not null
         then case when f.v_dt < f.c_dt then 'S' else 'N' end end as venda_anterior_compra
from filtrado f
left join contamov cmc on cmc.numerocm = f.c_numerocm
left join contamov cmv on cmv.numerocm = f.v_numerocm
order by
    f.estab, f.item,
    f.c_dt, f.c_seqnota, f.c_seqnotaitem,
    f.v_dt, f.v_seqnota, f.v_seqnotaitem
