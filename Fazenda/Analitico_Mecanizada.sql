-- dw_fazenda.os_planejamento_mecanizada fonte

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW dw_fazenda.os_planejamento_mecanizada AS with base as (
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
    ((fa.COD_ATIVID in (18, 67, 68, 37, 38, 78, 80, 79, 87))
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
    (dr.CODIGOATV = 84)),
plantio_67 as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b67.DT_ABERTO) AS DT_MEC_1PRE
from
    (base b67
left join base b18 on
    (((b18.OSTALHAO = b67.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b67.DT_ABERTO))))
where
    (b67.COD_ATIVID = 67)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_68 as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b68.DT_ABERTO) AS DT_MEC_2PRE
from
    (base b68
left join base b18 on
    (((b18.OSTALHAO = b68.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b68.DT_ABERTO))))
where
    (b68.COD_ATIVID = 68)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_37 as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b37.DT_ABERTO) AS DT_MEC_1CAP
from
    (base b37
left join base b18 on
    (((b18.OSTALHAO = b37.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b37.DT_ABERTO))))
where
    (b37.COD_ATIVID = 37)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_38 as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b38.DT_ABERTO) AS DT_MEC_2CAP
from
    (base b38
left join base b18 on
    (((b18.OSTALHAO = b38.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b38.DT_ABERTO))))
where
    (b38.COD_ATIVID = 38)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_79 as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b79.DT_ABERTO) AS DT_MEC_1ADUB
from
    (base b79
left join base b18 on
    (((b18.OSTALHAO = b79.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b79.DT_ABERTO))))
where
    (b79.COD_ATIVID = 79)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_80 as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b80.DT_ABERTO) AS DT_MEC_2ADUB
from
    (base b80
left join base b18 on
    (((b18.OSTALHAO = b80.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b80.DT_ABERTO))))
where
    (b80.COD_ATIVID = 80)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
plantio_87 as (
select
    b18.OSAPONTA AS OSAPONTA,
    b18.OSTALHAO AS OSTALHAO,
    min(b87.DT_ABERTO) AS DT_MEC_CAP
from
    (base b87
left join base b18 on
    (((b18.OSTALHAO = b87.OSTALHAO)
        and (b18.COD_ATIVID = 18)
            and (b18.DT_ABERTO <= b87.DT_ABERTO))))
where
    (b87.COD_ATIVID = 87)
group by
    b18.OSAPONTA,
    b18.OSTALHAO),
replan as (
select
    r.OSTALHAO AS OSTALHAO,
    min((case when (r.CODIGOATV = 67) then r.DTREPLANEJAMENTO else NULL end)) AS replan_mec_1pre,
    min((case when (r.CODIGOATV = 68) then r.DTREPLANEJAMENTO else NULL end)) AS replan_mec_2pre,
    min((case when (r.CODIGOATV = 37) then r.DTREPLANEJAMENTO else NULL end)) AS replan_mec_1cap,
    min((case when (r.CODIGOATV = 38) then r.DTREPLANEJAMENTO else NULL end)) AS replan_mec_2cap,
    min((case when (r.CODIGOATV = 79) then r.DTREPLANEJAMENTO else NULL end)) AS replan_mec_1adub,
    min((case when (r.CODIGOATV = 80) then r.DTREPLANEJAMENTO else NULL end)) AS replan_mec_2adub,
    min((case when (r.CODIGOATV = 87) then r.DTREPLANEJAMENTO else NULL end)) AS replan_mec_cap
from
    dw_fazenda.dm_replanejamento r
group by
    r.OSTALHAO)
select
    b.OSAPONTA AS OSAPONTA,
    b.OSPESSOA AS OSPESSOA,
    b.DT_ABERTO AS DT_ABERTO,
    b.COD_ATIVID AS COD_ATIVID,
    b.OSTALHAO AS OSTALHAO,
    b.HA_APLICADOS AS HA_APLICADOS,
    (case
        when (b.COD_ATIVID = 84) then (b.DT_ABERTO + interval 20 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_1pre is null)) then (b.DT_ABERTO + interval 20 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_1pre is not null)) then rp.replan_mec_1pre
    end) AS dt_plan_mec1pre,
    (case
        when (b.COD_ATIVID = 84) then (b.DT_ABERTO + interval 70 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_2pre is null)) then (b.DT_ABERTO + interval 70 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_2pre is not null)) then rp.replan_mec_2pre
    end) AS dt_plan_mec2pre,
    (case
        when (b.COD_ATIVID = 84) then (b.DT_ABERTO + interval 90 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_1cap is null)) then (b.DT_ABERTO + interval 90 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_1cap is not null)) then rp.replan_mec_1cap
    end) AS dt_plan_mec1cap,
    (case
        when (b.COD_ATIVID = 84) then (b.DT_ABERTO + interval 180 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_2cap is null)) then (b.DT_ABERTO + interval 180 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_2cap is not null)) then rp.replan_mec_2cap
    end) AS dt_plan_mec2cap,
    (case
        when (b.COD_ATIVID = 84) then (b.DT_ABERTO + interval 90 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_1adub is null)) then (b.DT_ABERTO + interval 90 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_1adub is not null)) then rp.replan_mec_1adub
    end) AS dt_plan_mec1adub,
    (case
        when (b.COD_ATIVID = 84) then (b.DT_ABERTO + interval 270 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_2adub is null)) then (b.DT_ABERTO + interval 270 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_2adub is not null)) then rp.replan_mec_2adub
    end) AS dt_plan_mec2adub,
    (case
        when (b.COD_ATIVID = 84) then (b.DT_ABERTO + interval 270 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_cap is null)) then (b.DT_ABERTO + interval 270 day)
        when ((b.COD_ATIVID = 18)
            and (rp.replan_mec_cap is not null)) then rp.replan_mec_cap
    end) AS dt_plan_meccap,
    p67.DT_MEC_1PRE AS DT_MEC_1PRE,
    p68.DT_MEC_2PRE AS DT_MEC_2PRE,
    p37.DT_MEC_1CAP AS DT_MEC_1CAP,
    p38.DT_MEC_2CAP AS DT_MEC_2CAP,
    p79.DT_MEC_1ADUB AS DT_MEC_1ADUB,
    p80.DT_MEC_2ADUB AS DT_MEC_2ADUB,
    p87.DT_MEC_CAP AS DT_MEC_CAP
from
    ((((((((base b
left join replan rp on
    ((rp.OSTALHAO = b.OSTALHAO)))
left join plantio_67 p67 on
    (((p67.OSAPONTA = b.OSAPONTA)
        and (p67.OSTALHAO = b.OSTALHAO))))
left join plantio_68 p68 on
    (((p68.OSAPONTA = b.OSAPONTA)
        and (p68.OSTALHAO = b.OSTALHAO))))
left join plantio_37 p37 on
    (((p37.OSAPONTA = b.OSAPONTA)
        and (p37.OSTALHAO = b.OSTALHAO))))
left join plantio_38 p38 on
    (((p38.OSAPONTA = b.OSAPONTA)
        and (p38.OSTALHAO = b.OSTALHAO))))
left join plantio_79 p79 on
    (((p79.OSAPONTA = b.OSAPONTA)
        and (p79.OSTALHAO = b.OSTALHAO))))
left join plantio_80 p80 on
    (((p80.OSAPONTA = b.OSAPONTA)
        and (p80.OSTALHAO = b.OSTALHAO))))
left join plantio_87 p87 on
    (((p87.OSAPONTA = b.OSAPONTA)
        and (p87.OSTALHAO = b.OSTALHAO))));