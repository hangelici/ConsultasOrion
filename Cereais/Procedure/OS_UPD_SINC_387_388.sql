create or replace PROCEDURE OS_UPD_SINC_387_388 AS
BEGIN

FOR valores IN (

WITH vinculo AS (

    SELECT
        p.estab,
        p.seqnota,
        nf.numerocm
    FROM nfcabprodutor p
    INNER JOIN nfcab nf
        ON nf.estab = p.estab
       AND nf.seqnota = p.seqnota
    INNER JOIN nfcab nf_origem
        ON nf_origem.chaveacessonfe = p.chaveacessonfp
       AND nf_origem.estab = p.estab
    WHERE (
            (nf.notaconf = 388  AND nf_origem.notaconf = 387)
         OR (nf.notaconf = 1388 AND nf_origem.notaconf = 1387)
          )
    GROUP BY
        p.estab,
        p.seqnota,
        nf.numerocm
    HAVING COUNT(*) = 1

),

produtor AS (

    SELECT
        p.estab,
        nf.seqnota            AS seq_destino,
        nf_origem.seqnota     AS seq_origem,
        nf.notaconf           AS notaconf_destino,
        nf_origem.notaconf    AS notaconf_origem

    FROM nfcabprodutor p

    INNER JOIN vinculo v
        ON v.estab = p.estab
       AND v.seqnota = p.seqnota

    INNER JOIN nfcab nf
        ON nf.estab = p.estab
       AND nf.seqnota = p.seqnota

    INNER JOIN nfcab nf_origem
        ON nf_origem.chaveacessonfe = p.chaveacessonfp
       AND nf_origem.estab = p.estab

    WHERE (
            (nf.notaconf = 388  AND nf_origem.notaconf = 387)
         OR (nf.notaconf = 1388 AND nf_origem.notaconf = 1387)
          )
      AND NVL(nf.status,'X') <> 'C'
      AND NVL(nf_origem.status,'X') <> 'C'
      AND nf.dtemissao >= DATE '2026-01-01'
      AND nf_origem.dtemissao >= DATE '2026-01-01'

),

ret AS (

    SELECT
        retenporto.*
    FROM retenporto
    INNER JOIN (
        SELECT
            estab,
            seqnota,
            numerocm
        FROM retenporto
        GROUP BY
            estab,
            seqnota,
            numerocm
        HAVING COUNT(*) < 2
    ) aux
        ON aux.estab = retenporto.estab
       AND aux.seqnota = retenporto.seqnota
       AND aux.numerocm = retenporto.numerocm

)

SELECT

    t.estab,
    t.seq_destino AS seqnota,
    1 AS seqnotaitem,
    t.notaconf_destino AS notaconf,

    r_destino.pesodescarregamento,

    GREATEST(
        NVL(r_destino.pesodescarregamento,0),
        NVL(r_origem.pesodescarregamento,0)
    ) AS novo_peso_desc,

    r_destino.pesoretencao,

    GREATEST(
        NVL(r_destino.pesoretencao,0),
        NVL(r_origem.pesoretencao,0)
    ) AS novo_peso_ret

FROM produtor t

INNER JOIN ret r_destino
    ON r_destino.estab = t.estab
   AND r_destino.seqnota = t.seq_destino
   AND r_destino.seqnotaitem = 1

INNER JOIN ret r_origem
    ON r_origem.estab = t.estab
   AND r_origem.seqnota = t.seq_origem
   AND r_origem.seqnotaitem = 1

WHERE
       NVL(r_destino.pesodescarregamento,0)
    <  NVL(r_origem.pesodescarregamento,0)

    OR

    (
        NVL(r_destino.pesodescarregamento,0)=0
        AND
        NVL(r_origem.pesodescarregamento,0)<>0
    )

UNION ALL

SELECT

    t.estab,
    t.seq_origem,
    1,
    t.notaconf_origem,

    r_origem.pesodescarregamento,

    GREATEST(
        NVL(r_destino.pesodescarregamento,0),
        NVL(r_origem.pesodescarregamento,0)
    ) AS novo_peso_desc,

    r_origem.pesoretencao,

    GREATEST(
        NVL(r_destino.pesoretencao,0),
        NVL(r_origem.pesoretencao,0)
    ) AS novo_peso_ret

FROM produtor t

INNER JOIN ret r_destino
    ON r_destino.estab = t.estab
   AND r_destino.seqnota = t.seq_destino
   AND r_destino.seqnotaitem = 1

INNER JOIN ret r_origem
    ON r_origem.estab = t.estab
   AND r_origem.seqnota = t.seq_origem
   AND r_origem.seqnotaitem = 1

WHERE
       NVL(r_origem.pesodescarregamento,0)
    <  NVL(r_destino.pesodescarregamento,0)

    OR

    (
        NVL(r_origem.pesodescarregamento,0)=0
        AND
        NVL(r_destino.pesodescarregamento,0)<>0
    )

)

LOOP

    UPDATE retenporto r
       SET r.pesodescarregamento = valores.novo_peso_desc
     WHERE r.estab = valores.estab
       AND r.seqnota = valores.seqnota
       AND r.seqnotaitem = 1;

    UPDATE retenporto_u u
       SET obs = 'Importação via gatilho - Trading'
     WHERE u.estab = valores.estab
       AND u.seqnota = valores.seqnota
       AND u.seqnotaitem = 1;

    INSERT INTO u_log_sinc_388_387
    (
        estab,
        seqnota,
        seqnotaitem,
        notaconf,
        pesodescarregamento,
        novo_peso_desc,
        pesoretencao,
        novo_peso_ret,
        data
    )
    VALUES
    (
        valores.estab,
        valores.seqnota,
        valores.seqnotaitem,
        valores.notaconf,
        valores.pesodescarregamento,
        valores.novo_peso_desc,
        valores.pesoretencao,
        valores.novo_peso_ret,
        CURRENT_TIMESTAMP
    );

END LOOP;

COMMIT;

END;
