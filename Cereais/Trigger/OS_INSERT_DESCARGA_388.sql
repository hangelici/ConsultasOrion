create or replace TRIGGER OS_INSERT_DESCARGA_388
FOR INSERT OR UPDATE ON RETENPORTO_U
COMPOUND TRIGGER

    TYPE t_estab IS TABLE OF RETENPORTO_U.ESTAB%TYPE INDEX BY PLS_INTEGER;
    TYPE t_seq   IS TABLE OF RETENPORTO_U.SEQNOTA%TYPE INDEX BY PLS_INTEGER;

    g_estab t_estab;
    g_seq   t_seq;
    g_cnt   PLS_INTEGER := 0;

    BEFORE EACH ROW IS
    BEGIN
        IF NVL(:NEW.IMPORTACAO_BD, 'S') = 'S' THEN
            g_cnt := g_cnt + 1;
            g_estab(g_cnt) := :NEW.ESTAB;
            g_seq(g_cnt)   := :NEW.SEQNOTA;
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR i IN 1 .. g_cnt LOOP

            FOR valores IN (

                WITH produtor AS (

                    SELECT
                        p.estab,
                        p.seqnota,
                        nf.chaveacessonfe      AS chave_destino,
                        nf.nota               AS nota_destino,
                        nf.seqnota            AS seq_destino,
                        p.chaveacessonfp      AS chave_origem,
                        nf.numerocm,
                        nf.notaconf           AS notaconf_destino,
                        nf_origem.notaconf    AS notaconf_origem

                    FROM nfcabprodutor p

                    INNER JOIN nfcab nf
                        ON nf.estab = p.estab
                       AND nf.seqnota = p.seqnota

                    INNER JOIN nfcab nf_origem
                        ON nf_origem.chaveacessonfe = p.chaveacessonfp
                       AND nf_origem.estab = p.estab

                    WHERE p.estab = g_estab(i)
                      AND p.seqnota = g_seq(i)

                      AND (
                              (nf.notaconf = 388  AND nf_origem.notaconf = 387)
                           OR (nf.notaconf = 1388 AND nf_origem.notaconf = 1387)
                          )

                      AND (nf.status <> 'C' OR nf.status IS NULL)
                      AND (nf_origem.status <> 'C' OR nf_origem.status IS NULL)

                      AND nf.dtemissao >= DATE '2026-01-01'
                      AND nf_origem.dtemissao >= DATE '2026-01-01'

                    GROUP BY
                        p.estab,
                        p.seqnota,
                        nf.chaveacessonfe,
                        nf.nota,
                        nf.seqnota,
                        p.chaveacessonfp,
                        nf.numerocm,
                        nf.notaconf,
                        nf_origem.notaconf

                    HAVING COUNT(*) = 1

                ),

                base AS (

                    SELECT
                        p.chave_origem,
                        p.chave_destino,
                        p.nota_destino,
                        u.estab,
                        u.data,
                        u.codterminal,
                        u.seq_end_termina,
                        u.coditem,
                        u.placa,
                        u.porigem,
                        u.pliquido,
                        u.retencao,
                        TRUNC(CURRENT_DATE) AS dtinclusao,
                        u.estab AS codfornecedor

                    FROM u_descarga_trading u

                    INNER JOIN produtor p
                        ON p.chave_origem = u.chaveacesso
                       AND p.estab = u.estab

                    WHERE u.dt_inclusao IS NOT NULL

                      AND NOT EXISTS (
                            SELECT 1
                              FROM u_descarga_trading x
                             WHERE x.estab = p.estab
                               AND x.chaveacesso = p.chave_destino
                      )

                )

                SELECT *
                FROM base
                WHERE chave_destino IS NOT NULL
                  AND chave_origem IS NOT NULL

            ) LOOP

                INSERT INTO u_descarga_trading (
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
                )
                VALUES (
                    (SELECT NVL(MAX(u_descarga_trading_id),0)+1 FROM u_descarga_trading),
                    (SELECT NVL(MAX(ref),0)+1 FROM u_descarga_trading),
                    valores.nota_destino,
                    valores.chave_destino,
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

                INSERT INTO u_insert_descarga_388 (
                    chave387,
                    chave388,
                    nota388,
                    estab,
                    data,
                    codterminal,
                    seq_end_termina,
                    coditem,
                    placa,
                    porigem,
                    pliquido,
                    retencao,
                    dtinclusao,
                    codfornecedor
                )
                VALUES (
                    valores.chave_origem,
                    valores.chave_destino,
                    valores.nota_destino,
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

            END LOOP;

        END LOOP;

        g_estab.DELETE;
        g_seq.DELETE;
        g_cnt := 0;

    END AFTER STATEMENT;

END OS_INSERT_DESCARGA_388;
