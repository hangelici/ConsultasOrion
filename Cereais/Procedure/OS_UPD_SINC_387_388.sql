create or replace PROCEDURE OS_UPD_SINC_387_388 AS
begin 
for valores in (
WITH vinculo AS (
        SELECT
        -- ticket 1282992
            p.estab,
            p.seqnota,
            nf.numerocm
        FROM nfcabprodutor p
        INNER JOIN nfcab nf
            ON nf.estab = p.estab
           AND nf.seqnota = p.seqnota
        INNER JOIN nfcab nf387
            ON nf387.chaveacessonfe = p.chaveacessonfp
           AND nf387.estab = p.estab
        WHERE nf.notaconf = 388
          AND nf387.notaconf = 387
        GROUP BY
            p.estab,
            p.seqnota,
            nf.numerocm
        HAVING COUNT(*) = 1
    ),
    produtor AS (
        SELECT
            p.estab,
            nf.seqnota AS seq388,
            nf387.seqnota AS seq387
        FROM nfcabprodutor p
        INNER JOIN vinculo v
            ON v.estab = p.estab
           AND v.seqnota = p.seqnota
        INNER JOIN nfcab nf
            ON nf.estab = p.estab
           AND nf.seqnota = p.seqnota
        INNER JOIN nfcab nf387
            ON nf387.chaveacessonfe = p.chaveacessonfp
           AND nf387.estab = p.estab
        WHERE nf.notaconf = 388
          AND nf387.notaconf = 387
          AND NVL(nf.status,'X') <> 'C'
          AND NVL(nf387.status,'X') <> 'C'
          and nf.dtemissao >= '01/01/2026'
          and nf387.dtemissao >= '01/01/2026'
    )
    SELECT
        t.estab,
        t.seq388 AS seqnota,
        1 AS seqnotaitem,
        388 as notaconf,
        r388.pesodescarregamento,
        GREATEST(
            NVL(r388.pesodescarregamento,0),
            NVL(r387.pesodescarregamento,0)
        ) AS novo_peso_desc,
        r388.pesoretencao,
        GREATEST(
            NVL(r388.pesoretencao,0),
            NVL(r387.pesoretencao,0)
        ) AS novo_peso_ret

    FROM produtor t

    INNER JOIN retenporto r388
        ON r388.estab = t.estab
       AND r388.seqnota = t.seq388
       AND r388.seqnotaitem = 1

    INNER JOIN retenporto r387
        ON r387.estab = t.estab
       AND r387.seqnota = t.seq387
       AND r387.seqnotaitem = 1

    WHERE
    NVL(r388.pesodescarregamento,0) < NVL(r387.pesodescarregamento,0)
    OR 
    NVL(r388.pesoretencao,0) < NVL(r387.pesoretencao,0)
    OR
    (NVL(r388.pesodescarregamento,0) = 0 and NVL(r387.pesodescarregamento,0) <> 0)
    OR
    (NVL(r388.pesoretencao,0) = 0 and NVL(r387.pesoretencao,0) <> 0)

    UNION ALL

    SELECT
        t.estab,
        t.seq387,
        1 as seqnotaitem,
        387 as notaconf,
        r387.pesodescarregamento,
        GREATEST(
            NVL(r388.pesodescarregamento,0),
            NVL(r387.pesodescarregamento,0)
        ) as novo_peso_desc,
        r387.pesoretencao,
        GREATEST(
            NVL(r388.pesoretencao,0),
            NVL(r387.pesoretencao,0)
        ) as novo_peso_ret

    FROM produtor t

    INNER JOIN retenporto r388
        ON r388.estab = t.estab
       AND r388.seqnota = t.seq388
       AND r388.seqnotaitem = 1

    INNER JOIN retenporto r387
        ON r387.estab = t.estab
       AND r387.seqnota = t.seq387
       AND r387.seqnotaitem = 1

    WHERE
    NVL(r387.pesodescarregamento,0) < NVL(r388.pesodescarregamento,0)
    OR 
    NVL(r387.pesoretencao,0) < NVL(r388.pesoretencao,0)
    OR
    (NVL(r387.pesodescarregamento,0) = 0 and NVL(r388.pesodescarregamento,0) <> 0)
    OR
    (NVL(r387.pesoretencao,0) = 0 and NVL(r388.pesoretencao,0) <> 0)

)
LOOP
update retenporto r set
    r.pesodescarregamento = valores.novo_peso_desc,
    r.pesoretencao = valores.novo_peso_ret
where r.estab = valores.estab
and r.seqnota = valores.seqnota
and r.seqnotaitem = 1;

insert into U_LOG_SINC_388_387 (
    ESTAB,
    SEQNOTA,
    SEQNOTAITEM,
    NOTACONF,
    PESODESCARREGAMENTO,
    NOVO_PESO_DESC,
    PESORETENCAO,
    NOVO_PESO_RET,
    DATA 
    ) values (
    valores.ESTAB,
    valores.SEQNOTA,
    valores.SEQNOTAITEM,
    valores.NOTACONF,
    valores.PESODESCARREGAMENTO ,
    valores.NOVO_PESO_DESC ,
    valores.PESORETENCAO ,
    valores.NOVO_PESO_RET ,
    current_timestamp
    );

end loop;
commit;
end;
