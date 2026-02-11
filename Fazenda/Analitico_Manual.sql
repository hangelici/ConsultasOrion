-- dw_fazenda.os_planejamento_atividades fonte

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW dw_fazenda.os_planejamento_atividades AS with base as (
select
    fa.OSAPONTA AS OSAPONTA,
    fa.SITUACAO AS SITUACAO,
    fa.COD_PRODUTOR AS COD_PRODUTOR,
    fa.COD_FAZENDA AS COD_FAZENDA,
    fa.OSPESSOA AS OSPESSOA,
    fa.COD_ATIVID AS COD_ATIVID,
    fa.DT_ABERTO AS DT_ABERTO,
    fac.OSTALHAO AS OSTALHAO,
    fac.HA_APLICADOS AS HA_APLICADOS
from
    (dw_fazenda.ft_apontamentos fa
join dw_fazenda.ft_apt_campos fac on
    ((fac.OSAPONTA = fa.OSAPONTA)))
where
    ((fa.COD_ATIVID in (18, 21, 20, 8, 5, 4, 86))
        and (fa.SITUACAO = 'Fechado'))
union all
select
    '' AS OSAPONTA,
    '' AS SITUACAO,
    dr.NUMEROCM AS COD_PRODUTOR,
    dr.SEQENDERECO AS COD_FAZENDA,
    concat(dr.NUMEROCM, '#', dr.SEQENDERECO) AS OSPESSOA,
    dr.CODIGOATV AS COD_ATIVID,
    dr.DTREPLANEJAMENTO AS DT_ABERTO,
    dr.OSTALHAO AS OSTALHAO,
    0 AS HA_APLICADOS
from
    dw_fazenda.dm_replanejamento dr
where
    (dr.CODIGOATV in (89, 24, 88, 71))),
plantio_ref as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b21.DT_ABERTO) AS DT_REPLANTIO
from
    (base b18
left join base b21 on
    (((b18.OSTALHAO = b21.OSTALHAO)
        and (b21.COD_ATIVID = 21)
            and (b18.DT_ABERTO <= b21.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
prox_ativ as (
select
    b1.OSAPONTA AS OSAPONTA_BASE,
    min((case when ((b1.COD_ATIVID = 18) and (b2.COD_ATIVID = 20) and (b2.DT_ABERTO >= b1.DT_ABERTO)) then b2.DT_ABERTO when ((b1.COD_ATIVID = 20) and (b2.COD_ATIVID = 8) and (b2.DT_ABERTO >= b1.DT_ABERTO)) then b2.DT_ABERTO when ((b1.COD_ATIVID = 24) and (b2.COD_ATIVID = 8) and (b2.DT_ABERTO >= b1.DT_ABERTO)) then b2.DT_ABERTO end)) AS DT_ABERTO_PROX_ATIV
from
    (base b1
left join base b2 on
    ((b2.OSTALHAO = b1.OSTALHAO)))
group by
    b1.OSAPONTA),
plantio_18 as (
select
    b18.OSAPONTA AS OSAPONTA_21,
    b18.OSTALHAO AS OSTALHAO,
    min(b20.DT_ABERTO) AS DT_1ADUB
from
    (base b20
left join base b18 on
    (((b18.OSTALHAO = b20.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b20.DT_ABERTO))))
where
    (b20.COD_ATIVID = 8)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_2adub as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b24.DT_ABERTO) AS DT_2ADUB
from
    (base b18
left join base b24 on
    (((b24.OSTALHAO = b18.OSTALHAO)
        and (b24.COD_ATIVID = 24)
            and (b18.DT_ABERTO <= b24.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_capina as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b5.DT_ABERTO) AS DT_1CAPINA
from
    (base b18
left join base b5 on
    (((b5.OSTALHAO = b18.OSTALHAO)
        and (b5.COD_ATIVID = 5)
            and (b18.DT_ABERTO <= b5.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_2_capina as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b4.DT_ABERTO) AS DT_2CAPINA
from
    (base b18
left join base b4 on
    (((b4.OSTALHAO = b18.OSTALHAO)
        and (b4.COD_ATIVID = 4)
            and (b18.DT_ABERTO <= b4.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_capina_cat as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b4.DT_ABERTO) AS DT_CAPCAT
from
    (base b18
left join base b4 on
    (((b4.OSTALHAO = b18.OSTALHAO)
        and (b4.COD_ATIVID = 86)
            and (b18.DT_ABERTO <= b4.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_3cap as (
select
    b18.OSTALHAO AS OSTALHAO,
    max(b18.DT_ABERTO) AS DT_3CAP_PLANTIO
from
    (base b18
left join base b21 on
    (((b18.OSTALHAO = b21.OSTALHAO)
        and (b21.COD_ATIVID = 89)
            and (b18.DT_ABERTO <= b21.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSTALHAO),
plantio_2captotal as (
select
    b18.OSTALHAO AS OSTALHAO,
    max(b18.DT_ABERTO) AS DT_2CAP_PLANTIO
from
    (base b18
left join base b21 on
    (((b18.OSTALHAO = b21.OSTALHAO)
        and (b21.COD_ATIVID = 88)
            and (b18.DT_ABERTO <= b21.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSTALHAO),
plantio_2adubplan as (
select
    b18.OSTALHAO AS OSTALHAO,
    max(b18.DT_ABERTO) AS DT_2ADUB_PLANTIO
from
    (base b18
left join base b21 on
    (((b18.OSTALHAO = b21.OSTALHAO)
        and (b21.COD_ATIVID = 24)
            and (b18.DT_ABERTO <= b21.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSTALHAO),
plantio_cap_71 as (
select
    b18.OSTALHAO AS OSTALHAO,
    max(b18.DT_ABERTO) AS DT_CAP_71_PLANTIO
from
    (base b18
left join base b21 on
    (((b18.OSTALHAO = b21.OSTALHAO)
        and (b21.COD_ATIVID = 71)
            and (b18.DT_ABERTO <= b21.DT_ABERTO))))
where
    (b18.COD_ATIVID = 18)
group by
    b18.OSTALHAO),
replan as (
select
    r.OSTALHAO AS OSTALHAO,
    min((case when (r.CODIGOATV = 8) then r.DTREPLANEJAMENTO else NULL end)) AS replan_1adub,
    min((case when (r.CODIGOATV = 5) then r.DTREPLANEJAMENTO else NULL end)) AS replan_1cap,
    min((case when (r.CODIGOATV = 4) then r.DTREPLANEJAMENTO else NULL end)) AS replan_2cap,
    min((case when (r.CODIGOATV = 24) then r.DTREPLANEJAMENTO else NULL end)) AS replan_2adub,
    min((case when (r.CODIGOATV = 21) then r.DTREPLANEJAMENTO else NULL end)) AS replan_replantio,
    min((case when (r.CODIGOATV = 20) then r.DTREPLANEJAMENTO else NULL end)) AS replan_coveta,
    min((case when (r.CODIGOATV = 18) then r.DTREPLANEJAMENTO else NULL end)) AS replan_plantio,
    min((case when (r.CODIGOATV = 86) then r.DTREPLANEJAMENTO else NULL end)) AS replan_capcat
from
    dw_fazenda.dm_replanejamento r
group by
    r.OSTALHAO)
select
    b.OSAPONTA AS OSAPONTA,
    b.SITUACAO AS SITUACAO,
    b.OSPESSOA AS OSPESSOA,
    b.COD_ATIVID AS COD_ATIVID,
    b.OSTALHAO AS OSTALHAO,
    b.HA_APLICADOS AS HA_APLICADOS,
    b.DT_ABERTO AS DT_ABERTO,
    p.DT_ABERTO_PROX_ATIV AS DT_ABERTO_PROX_ATIV,
    rf.DT_REPLANTIO AS DT_REPLANTIO,
    pl.DT_1ADUB AS DT_1ADUB,
    NULL AS DT_2ADUB,
    pc.DT_1CAPINA AS DT_1CAPINA,
    p2.DT_2CAPINA AS DT_2CAPINA,
    pcat.DT_CAPCAT AS DT_CAPCAT,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_plantio is not null)) then rp.replan_plantio
        when (b.COD_ATIVID = 18) then (b.DT_ABERTO + interval 5 day)
    end) AS DT_PLANJ_REPLANTIO,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_coveta is not null)) then rp.replan_coveta
        when (b.COD_ATIVID = 18) then (b.DT_ABERTO + interval 5 day)
    end) AS DT_PLANJ_COVETA,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_1adub is not null)) then rp.replan_1adub
        when (b.COD_ATIVID = 18) then (b.DT_ABERTO + interval 90 day)
    end) AS DT_PLANJ_1ADUB,
    (case
        when (b.COD_ATIVID = 24) then b.DT_ABERTO
        else NULL
    end) AS DT_PLANJ_2ADUB,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_1cap is not null)) then rp.replan_1cap
        when (b.COD_ATIVID = 18) then (b.DT_ABERTO + interval 90 day)
    end) AS DT_PLANJ_1CAPINA,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_2cap is not null)) then rp.replan_2cap
        when (b.COD_ATIVID = 18) then (b.DT_ABERTO + interval 180 day)
    end) AS DT_PLANJ_2CAPINA,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_capcat is not null)) then rp.replan_capcat
        when (b.COD_ATIVID = 18) then (b.DT_ABERTO + interval 270 day)
    end) AS DT_PLANJ_CAPCAT,
    (case
        when (b.COD_ATIVID = 89) then c3.DT_3CAP_PLANTIO
        else NULL
    end) AS DT_PLANTIO_3CAP,
    ad.DT_2ADUB_PLANTIO AS DT_2ADUB_PLANTIO,
    capt_2.DT_2CAP_PLANTIO AS DT_2CAP_PLANTIO,
    capt_71.DT_CAP_71_PLANTIO AS DT_CAP_71_PLANTIO,
    (case
        when (b.COD_ATIVID = 88) then b.DT_ABERTO
        else NULL
    end) AS DT_PLANJ_2CAPTOTAL,
    (case
        when (b.COD_ATIVID = 71) then b.DT_ABERTO
        else NULL
    end) AS DT_PLANJ_CAP_71
from
    ((((((((((((base b
left join prox_ativ p on
    ((p.OSAPONTA_BASE = b.OSAPONTA)))
left join plantio_18 pl on
    (((pl.OSAPONTA_21 = b.OSAPONTA)
        and (pl.OSTALHAO = b.OSTALHAO))))
left join plantio_ref rf on
    (((rf.OSAPONTA = b.OSAPONTA)
        and (rf.OSTALHAO = b.OSTALHAO))))
left join plantio_2adub pa on
    (((pa.OSAPONTA = b.OSAPONTA)
        and (pa.OSTALHAO = b.OSTALHAO))))
left join plantio_capina pc on
    (((pc.OSAPONTA = b.OSAPONTA)
        and (pc.OSTALHAO = b.OSTALHAO))))
left join plantio_2_capina p2 on
    (((p2.OSAPONTA = b.OSAPONTA)
        and (p2.OSTALHAO = b.OSTALHAO))))
left join plantio_capina_cat pcat on
    (((pcat.OSAPONTA = b.OSAPONTA)
        and (pcat.OSTALHAO = b.OSTALHAO))))
left join replan rp on
    ((rp.OSTALHAO = b.OSTALHAO)))
left join plantio_3cap c3 on
    ((c3.OSTALHAO = b.OSTALHAO)))
left join plantio_2adubplan ad on
    ((ad.OSTALHAO = b.OSTALHAO)))
left join plantio_2captotal capt_2 on
    ((capt_2.OSTALHAO = b.OSTALHAO)))
left join plantio_cap_71 capt_71 on
    ((capt_71.OSTALHAO = b.OSTALHAO)));