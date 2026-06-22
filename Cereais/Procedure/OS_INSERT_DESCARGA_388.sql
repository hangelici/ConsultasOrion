create or replace PROCEDURE OS_INSERT_DESCARGA_388 AS 
BEGIN
for valores in (
with vinculo as (
    -- ticket 1283093
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
    nf.nota as nota388,
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
    and nvl(nf.status,'X') <> 'C'
    and nvl(nfcab.status,'X') <> 'C'
    and nfcab.dtemissao >= '01/01/2026'
    and nf.dtemissao >= '01/01/2026'
),
base as (
    select 
    produtor.chave387,
    produtor.chave388,
    produtor.nota388,
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
    from U_DESCARGA_TRADING u
    inner join produtor ON
        produtor.CHAVE387 = u.chaveacesso
        and produtor.estab = u.estab
    where
    u.dt_inclusao is not null and 
    not exists (
        select 1
        from U_DESCARGA_TRADING x
        where x.estab = produtor.estab
        and x.chaveacesso = produtor.chave388
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