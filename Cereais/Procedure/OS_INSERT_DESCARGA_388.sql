create or replace PROCEDURE OS_INSERT_DESCARGA_388 AS 
BEGIN
for valores in (
with produtor as (
    -- ticket 1283093
    select
    p.estab,
    p.seqnota,
    nf.chaveacessonfe as chave388,
    nf.nota as nota388,
    nf.seqnota as seq388,
    p.chaveacessonfp as chave387,
    nf.numerocm
    from nfcabprodutor p
    inner join nfcab nf on 
        nf.estab   = p.estab
        and nf.seqnota = p.seqnota
        and nf.notaconf = 388
    inner join nfcab nf387 on 
        nf387.chaveacessonfe = p.chaveacessonfp
        and nf387.estab = p.estab
        and nf387.notaconf = 387

    where (nf.status <> 'c' or nf.status is null)
    and (nf387.status <> 'c' or nf387.status is null)
    and nf.dtemissao    >= date '2026-01-01'
    and nf387.dtemissao >= date '2026-01-01'

    group by
    p.estab,
    p.seqnota,
    nf.chaveacessonfe,
    nf.nota,
    nf.seqnota,
    p.chaveacessonfp,
    nf.numerocm
    having count(*) = 1
),
partirde as (
    select
        nf.estab,
        nf.seqnota
    from produtor p
    inner join nfcab nf on 
        nf.estab = p.estab
        and nf.seqnota = p.seq388
        and nf.notaconf = 388
    inner join nfitem i on 
        i.estab = nf.estab
        and i.seqnota = nf.seqnota
    inner join nfitemapartirde ap on 
        ap.estaborigem = i.estab
        and ap.seqnotaorigem = i.seqnota
        and ap.seqnotaitemorigem = i.seqnotaitem
    inner join nfcab nf384 on 
        nf384.estab = ap.estab
        and nf384.seqnota = ap.seqnota
        and nf384.notaconf = 384
    group by nf.estab,nf.seqnota,i.seqnotaitem,i.quantidade
    having sum(ap.quantidade) = i.quantidade
),
base as (
    select
    p.chave387,
    p.chave388,
    p.nota388,
    u.estab,
    u.data,
    u.codterminal,
    u.seq_end_termina,
    u.coditem,
    u.placa,
    u.porigem,
    u.pliquido,
    u.retencao,
    trunc(current_date) as dtinclusao,
    u.estab as codfornecedor
    from u_descarga_trading u
    inner join produtor p on 
        p.chave387 = u.chaveacesso
        and p.estab    = u.estab

    where u.dt_inclusao is not null
    and not exists (
            select 1
            from u_descarga_trading x
            where x.estab = p.estab
              and x.chaveacesso = p.chave388
        )
    and not exists (
            select 1
            from partirde pd
            where pd.estab   = p.estab
              and pd.seqnota = p.seq388
        )
)
select * from base where chave388 is not null and chave387 is not null
)
loop
insert into u_descarga_trading (
    u_descarga_trading_id,
    ref,
    nf,
    chaveacesso,
    estab,
    data,
    codterminal,
    seq_end_termina,
    coditem,
    placa,
    porigem,
    pliquido,
    retencao,
    dt_inclusao,
    codfornecedor,
    status
    ) values (
        (select max(u_descarga_trading_id) +1 from u_descarga_trading),
        (select max(ref) +1 from u_descarga_trading),
        valores.nota388,
        valores.chave388,
        valores.estab,
        valores.data,
        valores.codterminal,
        valores.seq_end_termina,
        valores.coditem,
        valores.placa,
        valores.porigem,
        valores.pliquido,
        valores.retencao,
        valores.dtinclusao,
        valores.codfornecedor,
        25
    );

    insert into U_INSERT_DESCARGA_388 (
        CHAVE387,
        CHAVE388,
        NOTA388,
        ESTAB,
        DATA,
        CODTERMINAL ,
        SEQ_END_TERMINA,
        CODITEM ,
        PLACA ,
        PORIGEM ,
        PLIQUIDO ,
        RETENCAO ,
        DTINCLUSAO ,
        CODFORNECEDOR
    ) values (
        valores.chave387,
        valores.chave388,
        valores.nota388,
        valores.estab,
        valores.data,
        valores.codterminal,
        valores.seq_end_termina,
        valores.coditem,
        valores.placa,
        valores.porigem,
        valores.pliquido,
        valores.retencao,
        valores.dtinclusao,
        valores.codfornecedor
    );
end loop;
commit;
end;