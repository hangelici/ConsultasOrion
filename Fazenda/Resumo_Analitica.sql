-- dw_fazenda.os_planejamento_resumo fonte

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW dw_fazenda.os_planejamento_resumo AS with base as (
select
    fa.OSAPONTA AS OSAPONTA,
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
    (dr.CODIGOATV in (89, 24, 88, 83, 71))),
area_talhao as (
select
    cad.OSTALHAO AS OSTALHAO,
    sum(dtv.AREA_TOTAL) AS AREA_TOTAL
from
    (dw_fazenda.dm_talhao_varied dtv
join dw_fazenda.dm_cadtalhao cad on
    ((cad.OSCAMPO = dtv.OSCAMPO)))
group by
    cad.OSTALHAO),
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
    r.OSTALHAO),
campos as (
select
    b.OSAPONTA AS OSAPONTA,
    b.OSPESSOA AS OSPESSOA,
    b.COD_ATIVID AS COD_ATIVID,
    b.OSTALHAO AS OSTALHAO,
    b.HA_APLICADOS AS HA_APLICADOS,
    b.DT_ABERTO AS DT_ABERTO,
    p.DT_ABERTO_PROX_ATIV AS DT_ABERTO_PROX_ATIV,
    rf.DT_REPLANTIO AS DT_REPLANTIO,
    pl.DT_1ADUB AS DT_1ADUB,
    pa.DT_2ADUB AS DT_2ADUB,
    pc.DT_1CAPINA AS DT_1CAPINA,
    p2.DT_2CAPINA AS DT_2CAPINA,
    pcat.DT_CAPCAT AS DT_CAPCAT,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_plantio is not null)) then rp.replan_plantio
        when (b.COD_ATIVID in (18, 83)) then (b.DT_ABERTO + interval 5 day)
    end) AS DT_PLANJ_REPLANTIO,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_1adub is not null)) then rp.replan_1adub
        when (b.COD_ATIVID in (18, 83)) then (b.DT_ABERTO + interval 90 day)
    end) AS DT_PLANJ_1ADUB,
    (case
        when (b.COD_ATIVID = 24) then b.DT_ABERTO
        else NULL
    end) AS DT_PLANJ_2ADUB,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_1cap is not null)) then rp.replan_1cap
        when (b.COD_ATIVID in (18, 83)) then (b.DT_ABERTO + interval 90 day)
    end) AS DT_PLANJ_1CAPINA,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_2cap is not null)) then rp.replan_2cap
        when (b.COD_ATIVID in (18, 83)) then (b.DT_ABERTO + interval 180 day)
    end) AS DT_PLANJ_2CAPINA,
    (case
        when ((b.COD_ATIVID = 18)
            and (rp.replan_capcat is not null)) then rp.replan_capcat
        when (b.COD_ATIVID in (18, 83)) then (b.DT_ABERTO + interval 270 day)
    end) AS DT_PLANJ_CAPCAT,
    (case
        when (b.COD_ATIVID = 83) then b.DT_ABERTO
    end) AS DT_PLANJ_PLANTIO,
    at.AREA_TOTAL AS AREA_TOTAL,
    (case
        when (b.COD_ATIVID = 89) then b.DT_ABERTO
        else NULL
    end) AS DT_PLANJ_3CAP,
    (case
        when (b.COD_ATIVID = 88) then b.DT_ABERTO
        else NULL
    end) AS DT_PLANJ_2CAP_88,
    (case
        when (b.COD_ATIVID = 71) then b.DT_ABERTO
        else NULL
    end) AS DT_PLANJ_CAP_71
from
    (((((((((base b
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
left join area_talhao at on
    ((at.OSTALHAO = b.OSTALHAO)))
left join plantio_capina_cat pcat on
    (((pcat.OSAPONTA = b.OSAPONTA)
        and (pcat.OSTALHAO = b.OSTALHAO))))
left join replan rp on
    ((rp.OSTALHAO = b.OSTALHAO)))),
calc_replantio as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 21)),
calc_coveta as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 20)),
calc_1adub as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 8)),
calc_2adub as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 24)),
calc_1cap as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 5)),
calc_2cap as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 4)),
calc_plant_plan as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 83)),
calc_capcat as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 86)),
calc_3cap as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 89)),
calc_2cap_88 as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 88)),
calc_cap_71 as (
select
    cd.HORASHA AS HORASHA
from
    dw_fazenda.dm_cadatividade cd
where
    (cd.COD_ATIVID = 71))
select
    c.OSAPONTA AS OSAPONTA,
    c.OSPESSOA AS OSPESSOA,
    c.OSTALHAO AS OSTALHAO,
    c.COD_ATIVID AS COD_ATIVID,
    c.DT_ABERTO AS DT_ABERTO,
    c.DT_ABERTO_PROX_ATIV AS DT_ABERTO_PROX_ATIV,
    c.DT_REPLANTIO AS DT_REPLANTIO,
    c.DT_1ADUB AS DT_1ADUB,
    c.DT_2ADUB AS DT_2ADUB,
    c.DT_1CAPINA AS DT_1CAPINA,
    c.DT_2CAPINA AS DT_2CAPINA,
    c.DT_CAPCAT AS DT_CAPCAT,
    c.DT_PLANJ_REPLANTIO AS DT_PLANJ_REPLANTIO,
    c.DT_PLANJ_1ADUB AS DT_PLANJ_1ADUB,
    c.DT_PLANJ_2ADUB AS DT_PLANJ_2ADUB,
    c.DT_PLANJ_1CAPINA AS DT_PLANJ_1CAPINA,
    c.DT_PLANJ_2CAPINA AS DT_PLANJ_2CAPINA,
    c.DT_PLANJ_PLANTIO AS DT_PLANJ_PLANTIO,
    c.DT_PLANJ_CAPCAT AS DT_PLANJ_CAPCAT,
    c.DT_PLANJ_3CAP AS DT_PLANJ_3CAP,
    c.DT_PLANJ_2CAP_88 AS DT_PLANJ_2CAP_88,
    c.DT_PLANJ_CAP_71 AS DT_PLANJ_CAP_71,
    c.AREA_TOTAL AS AREA_TOTAL,
    (case
        when ((c.DT_REPLANTIO is null)
            and (c.COD_ATIVID = 18)
                and (c.DT_ABERTO_PROX_ATIV is null)) then round(((c.AREA_TOTAL * calc_replantio.HORASHA) / 8), 2)
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_replantio.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_replantio,
    (case
        when ((c.DT_ABERTO_PROX_ATIV is null)
            and (c.COD_ATIVID = 18)) then round(((c.AREA_TOTAL * calc_coveta.HORASHA) / 8), 2)
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_coveta.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_coveta,
    (case
        when ((c.DT_1ADUB is null)
            and (c.COD_ATIVID = 18)) then round(((c.AREA_TOTAL * calc_1adub.HORASHA) / 8), 2)
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_1adub.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_1adub,
    (case
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_2adub.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_2adub,
    (case
        when (c.COD_ATIVID = 24) then round(((c.AREA_TOTAL * calc_2adub.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_2adub_r,
    (case
        when ((c.DT_1CAPINA is null)
            and (c.COD_ATIVID = 18)) then round(((c.AREA_TOTAL * calc_1cap.HORASHA) / 8), 2)
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_1cap.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_1cap,
    (case
        when ((c.DT_2CAPINA is null)
            and (c.COD_ATIVID = 18)) then round(((c.AREA_TOTAL * calc_2cap.HORASHA) / 8), 2)
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_2cap.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_2cap,
    (case
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_plant_plan.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_plant_plan,
    (case
        when ((c.DT_CAPCAT is null)
            and (c.COD_ATIVID = 18)) then round(((c.AREA_TOTAL * calc_capcat.HORASHA) / 8), 2)
        when (c.COD_ATIVID = 83) then round(((c.AREA_TOTAL * calc_capcat.HORASHA) / 8), 2)
        else NULL
    end) AS diaria_capcat,
    (case
        when (c.COD_ATIVID = 89) then round(((c.AREA_TOTAL * calc_3cap.HORASHA) / 8), 2)
    end) AS diaria_3cap,
    (case
        when (c.COD_ATIVID = 88) then round(((c.AREA_TOTAL * calc_2cap_88.HORASHA) / 8), 2)
    end) AS diaria_2cap_88,
    (case
        when (c.COD_ATIVID = 71) then round(((c.AREA_TOTAL * calc_cap_71.HORASHA) / 8), 2)
    end) AS diaria_cap_71
from
    (((((((((((campos c
left join calc_replantio on
    ((0 = 0)))
left join calc_coveta on
    ((0 = 0)))
left join calc_1adub on
    ((0 = 0)))
left join calc_2adub on
    ((0 = 0)))
left join calc_1cap on
    ((0 = 0)))
left join calc_2cap on
    ((0 = 0)))
left join calc_plant_plan on
    ((0 = 0)))
left join calc_capcat on
    ((0 = 0)))
left join calc_3cap on
    ((0 = 0)))
left join calc_2cap_88 on
    ((0 = 0)))
left join calc_cap_71 on
    ((0 = 0)))
where
    (c.COD_ATIVID in (18, 83, 89, 24, 88, 71));