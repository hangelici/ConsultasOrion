-- dw_fazenda.os_planejamento_pre_manual fonte
CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW dw_fazenda.os_planejamento_pre_manual AS with base as (
select
    fa.OSAPONTA AS OSAPONTA,
    fa.COD_PRODUTOR AS COD_PRODUTOR,
    fa.COD_FAZENDA AS COD_FAZENDA,
    fa.OSPESSOA AS OSPESSOA,
    fa.COD_ATIVID AS COD_ATIVID,
    fa.DT_ABERTO AS DT_ABERTO,
    fac.OSTALHAO AS OSTALHAO,
    fac.HA_APLICADOS AS HA_APLICADOS,
    fa.TIPOPLANTIO
from
    (dw_fazenda.ft_apontamentos fa
join dw_fazenda.ft_apt_campos fac on
    ((fac.OSAPONTA = fa.OSAPONTA)))
where
    ((fa.COD_ATIVID in (13, 74, 57, 73, 65, 75, 9,18))
        and (fa.SITUACAO = 'Fechado'))),
plantio_74 as (
select
    b13.OSAPONTA AS OSAPONTA,
    b13.OSTALHAO AS OSTALHAO,
    min(b74.DT_ABERTO) AS DT_DEFPRE
from
    (base b74
left join base b13 on
    (((b13.OSTALHAO = b74.OSTALHAO)
        and (b13.COD_ATIVID = 13)
            and (b13.DT_ABERTO <= b74.DT_ABERTO))))
where
    (b74.COD_ATIVID = 74)
group by
    b13.OSAPONTA,
    b13.OSTALHAO),
plantio_57 as (
select
    b13.OSAPONTA AS OSAPONTA,
    b13.OSTALHAO AS OSTALHAO,
    min(b57.DT_ABERTO) AS DT_DSP
from
    (base b57
left join base b13 on
    (((b13.OSTALHAO = b57.OSTALHAO)
        and (b13.COD_ATIVID = 13)
            and (b13.DT_ABERTO <= b57.DT_ABERTO))))
where
    (b57.COD_ATIVID = 57)
group by
    b13.OSAPONTA,
    b13.OSTALHAO),
plantio_73 as (
select
    b13.OSAPONTA AS OSAPONTA,
    b13.OSTALHAO AS OSTALHAO,
    min(b73.DT_ABERTO) AS DT_SUCAMENTO
from
    (base b73
left join base b13 on
    (((b13.OSTALHAO = b73.OSTALHAO)
        and (b13.COD_ATIVID = 13)
            and (b13.DT_ABERTO <= b73.DT_ABERTO))))
where
    (b73.COD_ATIVID = 73)
group by
    b13.OSAPONTA,
    b13.OSTALHAO),
plantio_65 as (
select
    b13.OSAPONTA AS OSAPONTA,
    b13.OSTALHAO AS OSTALHAO,
    min(b65.DT_ABERTO) AS DT_SDP
from
    (base b65
left join base b13 on
    (((b13.OSTALHAO = b65.OSTALHAO)
        and (b13.COD_ATIVID = 13)
            and (b13.DT_ABERTO <= b65.DT_ABERTO))))
where
    (b65.COD_ATIVID = 65)
group by
    b13.OSAPONTA,
    b13.OSTALHAO),
plantio_75 as (
select
    b13.OSAPONTA AS OSAPONTA,
    b13.OSTALHAO AS OSTALHAO,
    min(b75.DT_ABERTO) AS DT_DESSECAMENTO
from
    (base b75
left join base b13 on
    (((b13.OSTALHAO = b75.OSTALHAO)
        and (b13.COD_ATIVID = 13)
            and (b13.DT_ABERTO <= b75.DT_ABERTO))))
where
    (b75.COD_ATIVID = 75)
group by
    b13.OSAPONTA,
    b13.OSTALHAO),
plantio_9 as (
select
    b13.OSAPONTA AS OSAPONTA,
    b13.OSTALHAO AS OSTALHAO,
    min(b9.DT_ABERTO) AS DT_MONITORAMENTO
from
    (base b9
left join base b13 on
    (((b13.OSTALHAO = b9.OSTALHAO)
        and (b13.COD_ATIVID = 13)
            and (b13.DT_ABERTO <= b9.DT_ABERTO))))
where
    (b9.COD_ATIVID = 9)
group by
    b13.OSAPONTA,
    b13.OSTALHAO),
plantio_18 as (
select
    b13.OSAPONTA AS OSAPONTA,
    b13.OSTALHAO AS OSTALHAO,
    b13.TIPOPLANTIO,
    min(b18.DT_ABERTO) AS DT_PLANTIO
from
    (base b18
left join base b13 on
    (((b13.OSTALHAO = b18.OSTALHAO)
        and (b13.COD_ATIVID = 13)
            and (b13.DT_ABERTO <= b18.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b13.OSAPONTA,
    b13.OSTALHAO,
    b13.TIPOPLANTIO
),
prox_ativ as (
select
    b1.OSAPONTA AS OSAPONTA_BASE,
    min((case when ((b1.COD_ATIVID = 13) and (b2.COD_ATIVID = 74) and (b2.DT_ABERTO >= b1.DT_ABERTO)) then b2.DT_ABERTO when ((b1.COD_ATIVID = 74) and (b2.COD_ATIVID = 9) and (b2.DT_ABERTO >= b1.DT_ABERTO)) then b2.DT_ABERTO end)) AS DT_ABERTO_PROX_ATIV
from
    (base b1
left join base b2 on
    ((b2.OSTALHAO = b1.OSTALHAO)))
group by
    b1.OSAPONTA),
replan as (
select
    r.OSTALHAO AS OSTALHAO,
    min((case when (r.CODIGOATV = 74) then r.DTREPLANEJAMENTO else NULL end)) AS replan_defpre,
    min((case when (r.CODIGOATV = 9) then r.DTREPLANEJAMENTO else NULL end)) AS replan_monitoramento,
    min((case when (r.CODIGOATV = 57) then r.DTREPLANEJAMENTO else NULL end)) AS replan_dsp,
    min((case when (r.CODIGOATV = 73) then r.DTREPLANEJAMENTO else NULL end)) AS replan_sucamento,
    min((case when (r.CODIGOATV = 65) then r.DTREPLANEJAMENTO else NULL end)) AS replan_sdp,
    min((case when (r.CODIGOATV = 75) then r.DTREPLANEJAMENTO else NULL end)) AS replan_dessecamento,
    min((case when (r.CODIGOATV = 18) then r.DTREPLANEJAMENTO else NULL end)) AS replan_plantio
from
    dw_fazenda.dm_replanejamento r
group by
    r.OSTALHAO)
select
    b.OSAPONTA AS OSAPONTA,
    b.COD_PRODUTOR AS COD_PRODUTOR,
    b.COD_FAZENDA AS COD_FAZENDA,
    b.OSPESSOA AS OSPESSOA,
    b.COD_ATIVID AS COD_ATIVID,
    b.DT_ABERTO AS DT_ABERTO,
    p.DT_ABERTO_PROX_ATIV AS DT_ABERTO_PROX_ATIV,
    b.OSTALHAO AS OSTALHAO,
    b.HA_APLICADOS AS HA_APLICADOS,
    p74.DT_DEFPRE AS DT_DEFPRE,
    p9.DT_MONITORAMENTO AS DT_MONITORAMENTO,
    p57.DT_DSP AS DT_DSP,
    p73.DT_SUCAMENTO AS DT_SUCAMENTO,
    p75.DT_DESSECAMENTO AS DT_DESSECAMENTO,
    p65.DT_SDP AS DT_SDP,
    p18.DT_PLANTIO,
    p18.TIPOPLANTIO,
    (case
        when ((b.COD_ATIVID = 13)
            and (rp.replan_defpre is null)) then (b.DT_ABERTO + interval 10 day)
        when ((b.COD_ATIVID = 13)
            and (rp.replan_defpre is not null)) then rp.replan_defpre
    end) AS DT_PLAN_DEFPRE,
    (case
        when ((b.COD_ATIVID = 13)
            and (rp.replan_monitoramento is null)) then (b.DT_ABERTO + interval 15 day)
        when ((b.COD_ATIVID = 13)
            and (rp.replan_monitoramento is not null)) then rp.replan_monitoramento
    end) AS DT_PLAN_MONITORAMENTO,
    (case
        when ((b.COD_ATIVID = 13)
            and (rp.replan_dsp is null)) then (b.DT_ABERTO + interval 20 day)
        when ((b.COD_ATIVID = 13)
            and (rp.replan_dsp is not null)) then rp.replan_dsp
    end) AS DT_PLAN_DSP,
    (case
        when ((b.COD_ATIVID = 13)
            and (rp.replan_sucamento is null)) then (b.DT_ABERTO + interval 5 day)
        when ((b.COD_ATIVID = 13)
            and (rp.replan_sucamento is not null)) then rp.replan_sucamento
    end) AS DT_PLAN_SUCAMENTO,
    (case
        when ((b.COD_ATIVID = 13)
            and (rp.replan_sdp is null)) then (b.DT_ABERTO + interval 20 day)
        when ((b.COD_ATIVID = 13)
            and (rp.replan_sdp is not null)) then rp.replan_sdp
    end) AS DT_PLAN_SDP,
    (case
        when ((b.COD_ATIVID = 13)
            and (rp.replan_dessecamento is null)) then (b.DT_ABERTO + interval 5 day)
        when ((b.COD_ATIVID = 13)
            and (rp.replan_dessecamento is not null)) then rp.replan_dessecamento
    end) AS DT_PLAN_DESSECAMENTO,
   (case
        when ((b.COD_ATIVID = 13)
            and (rp.replan_plantio is null)) then (b.DT_ABERTO + interval 20 day)
        when ((b.COD_ATIVID = 13)
            and (rp.replan_plantio is not null)) then rp.replan_plantio
    end) AS DT_PLAN_PLANTIO
from
    base b
left join prox_ativ p on
    p.OSAPONTA_BASE = b.OSAPONTA
left join plantio_74 p74 on
    p74.OSAPONTA = b.OSAPONTA
        and p74.OSTALHAO = b.OSTALHAO
left join plantio_9 p9 on
    p9.OSAPONTA = b.OSAPONTA
        and p9.OSTALHAO = b.OSTALHAO
left join plantio_57 p57 on
    p57.OSAPONTA = b.OSAPONTA
        and p57.OSTALHAO = b.OSTALHAO
left join replan rp on
    rp.OSTALHAO = b.OSTALHAO
left join plantio_73 p73 on
    p73.OSAPONTA = b.OSAPONTA
        and p73.OSTALHAO = b.OSTALHAO
left join plantio_65 p65 on
    p65.OSAPONTA = b.OSAPONTA
        and p65.OSTALHAO = b.OSTALHAO
left join plantio_75 p75 on
    p75.OSAPONTA = b.OSAPONTA
        and p75.OSTALHAO = b.OSTALHAO
left join plantio_18 p18 on
    p18.OSAPONTA = b.OSAPONTA
        and p18.OSTALHAO = b.OSTALHAO
       ;