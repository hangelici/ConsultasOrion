create or replace PROCEDURE OS_UPD_DESCARGA_387 AS 
begin
for valores in (
with vinculo as (
    -- ticket 1283092
    select
    p.estab,
    p.seqnota,
    nf.numerocm,
    count(p.nfprodutor)
    from nfcabprodutor p
    --- notas config 388
    inner join nfcab nf ON
        nf.estab = p.estab
        and nf.seqnota = p.seqnota
    -- notas config 387
    inner join nfcab ON
        nfcab.CHAVEACESSONFE = p.CHAVEACESSONFP
        and nfcab.estab =  p.estab
    where nf.notaconf = 388
    and nfcab.notaconf = 387
    group BY
    p.estab,
    p.seqnota,
    nf.numerocm
    having count(p.nfprodutor) = 1
),
produtor as (
    SELECT
    p.estab, p.seqnota, 
    nf.chaveacessonfe as chave388,
    p.chaveacessonfp as chave387, 
    v.numerocm
    from nfcabprodutor p
    inner join vinculo v ON
        v.estab = p.estab
        and v.seqnota = p.seqnota
     --- notas config 388
    inner join nfcab nf ON
        nf.estab = p.estab
        and nf.seqnota = p.seqnota
    -- notas config 387
    inner join nfcab ON
        nfcab.CHAVEACESSONFE = p.CHAVEACESSONFP
        and nfcab.estab =  p.estab
    where nf.notaconf = 388
    and nfcab.notaconf = 387
    and nfcab.dtemissao >= '01/01/2026'
    and nf.dtemissao >= '01/01/2026'
)
    select 
    produtor.CHAVE387,
    u.estab,
    u.data,
    u.pliquido,
    u.retencao,
    u.dt_inclusao,
    produtor.chave388,
    u388.data as data388,
    nvl(u388.pliquido,0) as pliquido388,
    nvl(u388.retencao,0) as retencao388,
    case when u.data is null then u388.data else u.data end data_nova,
    case when (u.pliquido is null or u.pliquido = 0) then nvl(u388.pliquido,0) else nvl(u.pliquido,0) end pliq_novo,
    case when (u.retencao is null or u.retencao = 0) then nvl(u388.retencao,0) else nvl(u.retencao,0) end ret_novo,
    case 
        when u.data is null or (u.pliquido is null or u.pliquido = 0) or (u.retencao is null or u.retencao = 0) then trunc(current_date)
        else u.dt_inclusao
    end dtinclusao_nova
    from U_DESCARGA_TRADING u
    inner join produtor ON
        produtor.CHAVE387 = u.chaveacesso
        and produtor.estab = u.estab
    inner join U_DESCARGA_TRADING u388 on
        u388.chaveacesso = produtor.chave388
        and u388.estab = produtor.estab
    where
    (u.data is NULL
    OR
    (u.pliquido is null or u.pliquido = 0)
    OR
    (u.retencao is null or u.retencao = 0))
    and u.dt_inclusao is not NULL
    and nvl(u.status,'0') <> '23'
    and not exists (
        select 1
        from U_DESCARGA_TRADING x
        where x.estab = produtor.estab
        and x.chaveacesso = produtor.chave388
        group by x.estab, x.chaveacesso
        having count(*) > 1
    )
)
loop
update u_descarga_trading d set
    d.PLIQUIDO = valores.PLIQ_NOVO,
    d.DATA = valores.DATA_NOVA,
    d.RETENCAO = valores.RET_NOVO,
    d.dt_inclusao = valores.dtinclusao_nova
where d.chaveacesso = valores.CHAVE387
and d.estab = valores.estab;

insert into u_log_upd_387 (
    chave387 ,
    estab,
    data,
    pliquido ,
    retencao  ,
    chave388,
    data388 ,
    pliquido388 ,
    retencao388 ,
    data_nova ,
    pliq_novo ,
    ret_novo,
    dt_inclusao,
    dt_inclusao_nova
    ) values (
        valores.chave387 ,
        valores.estab,
        valores.data,
        valores.pliquido ,
        valores.retencao  ,
        valores.chave388,
        valores.data388 ,
        valores.pliquido388 ,
        valores.retencao388 ,
        valores.data_nova ,
        valores.pliq_novo ,
        valores.ret_novo,
        valores.dt_inclusao,
        valores.dtinclusao_nova
    );
end loop;
commit;
end;