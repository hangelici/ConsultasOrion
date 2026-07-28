create or replace PROCEDURE OS_UPD_DESCARGA_387 AS
BEGIN

FOR valores IN (

WITH vinculo AS (

    -- ticket 1283092
    -- ticket 1356717
    SELECT
        p.estab,
        p.seqnota,
        nf.numerocm,
        COUNT(p.nfprodutor) qtd
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

    HAVING COUNT(p.nfprodutor) = 1

),

produtor AS (

    SELECT
        p.estab,
        p.seqnota,
        nf.chaveacessonfe      AS chave_destino,
        p.chaveacessonfp       AS chave_origem,
        v.numerocm,
        nf.notaconf            AS notaconf_destino,
        nf_origem.notaconf     AS notaconf_origem

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

      AND nf_origem.dtemissao >= DATE '2026-01-01'
      AND nf.dtemissao >= DATE '2026-01-01'

)

SELECT
    produtor.chave_origem AS chave387,
    u.estab,
    u.data,
    u.pliquido,
    u.retencao,
    u.dt_inclusao,

    produtor.chave_destino AS chave388,

    u388.data AS data388,
    NVL(u388.pliquido,0) AS pliquido388,
    NVL(u388.retencao,0) AS retencao388,

    CASE
        WHEN u.data IS NULL THEN u388.data
        ELSE u.data
    END AS data_nova,

    CASE
        WHEN (u.pliquido IS NULL OR u.pliquido = 0)
            THEN NVL(u388.pliquido,0)
        ELSE NVL(u.pliquido,0)
    END AS pliq_novo,

    CASE
        WHEN (u.retencao IS NULL OR u.retencao = 0)
            THEN NVL(u388.retencao,0)
        ELSE NVL(u.retencao,0)
    END AS ret_novo,

    CASE
        WHEN u.data IS NULL
          OR (u.pliquido IS NULL OR u.pliquido = 0)
          OR (u.retencao IS NULL OR u.retencao = 0)
        THEN TRUNC(CURRENT_DATE)
        ELSE u.dt_inclusao
    END AS dtinclusao_nova

FROM u_descarga_trading u

INNER JOIN produtor
    ON produtor.chave_origem = u.chaveacesso
   AND produtor.estab = u.estab

INNER JOIN u_descarga_trading u388
    ON u388.chaveacesso = produtor.chave_destino
   AND u388.estab = produtor.estab

WHERE
(
    u.data IS NULL
 OR u.pliquido IS NULL
 OR u.pliquido = 0
 OR u.retencao IS NULL
 OR u.retencao = 0
)

AND u.dt_inclusao IS NOT NULL
AND NVL(u.status,'0') <> '23'

AND NOT EXISTS (
    SELECT 1
    FROM u_descarga_trading x
    WHERE x.estab = produtor.estab
      AND x.chaveacesso = produtor.chave_destino
    GROUP BY
        x.estab,
        x.chaveacesso
    HAVING COUNT(*) > 1
)

)

LOOP

    UPDATE u_descarga_trading d
       SET d.pliquido    = valores.pliq_novo,
           d.data         = valores.data_nova,
           d.retencao     = valores.ret_novo,
           d.dt_inclusao  = valores.dtinclusao_nova
     WHERE d.chaveacesso = valores.chave387
       AND d.estab = valores.estab;

    INSERT INTO u_log_upd_387 (
        chave387,
        estab,
        data,
        pliquido,
        retencao,
        chave388,
        data388,
        pliquido388,
        retencao388,
        data_nova,
        pliq_novo,
        ret_novo,
        dt_inclusao,
        dt_inclusao_nova
    )
    VALUES (
        valores.chave387,
        valores.estab,
        valores.data,
        valores.pliquido,
        valores.retencao,
        valores.chave388,
        valores.data388,
        valores.pliquido388,
        valores.retencao388,
        valores.data_nova,
        valores.pliq_novo,
        valores.ret_novo,
        valores.dt_inclusao,
        valores.dtinclusao_nova
    );

END LOOP;

COMMIT;

END;
