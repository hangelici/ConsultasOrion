create or replace TRIGGER OS_INSERT_DESCARGA_388
FOR INSERT OR UPDATE ON RETENPORTO_U
COMPOUND TRIGGER

    TYPE t_estab IS TABLE OF RETENPORTO_U.ESTAB%TYPE   INDEX BY PLS_INTEGER;
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

            FOR VALORES IN (
                WITH PRODUTOR AS (
                    SELECT
                        P.ESTAB,
                        P.SEQNOTA,
                        NF.CHAVEACESSONFE AS CHAVE388,
                        NF.NOTA AS NOTA388,
                        NF.SEQNOTA AS SEQ388,
                        P.CHAVEACESSONFP AS CHAVE387,
                        NF.NUMEROCM
                    FROM NFCABPRODUTOR P
                    INNER JOIN NFCAB NF
                            ON NF.ESTAB = P.ESTAB
                           AND NF.SEQNOTA = P.SEQNOTA
                           AND NF.NOTACONF = 388
                    INNER JOIN NFCAB NF387
                            ON NF387.CHAVEACESSONFE = P.CHAVEACESSONFP
                           AND NF387.ESTAB = P.ESTAB
                           AND NF387.NOTACONF = 387
                    WHERE P.ESTAB = g_estab(i)
                      AND P.SEQNOTA = g_seq(i)
                      AND (NF.STATUS <> 'c' OR NF.STATUS IS NULL)
                      AND (NF387.STATUS <> 'c' OR NF387.STATUS IS NULL)
                      AND NF.DTEMISSAO >= DATE '2026-01-01'
                      AND NF387.DTEMISSAO >= DATE '2026-01-01'
                    GROUP BY
                        P.ESTAB, P.SEQNOTA, NF.CHAVEACESSONFE, NF.NOTA,
                        NF.SEQNOTA, P.CHAVEACESSONFP, NF.NUMEROCM
                    HAVING COUNT(*) = 1
                ),
                BASE AS (
                    SELECT
                        P.CHAVE387,
                        P.CHAVE388,
                        P.NOTA388,
                        U.ESTAB,
                        U.DATA,
                        U.CODTERMINAL,
                        U.SEQ_END_TERMINA,
                        U.CODITEM,
                        U.PLACA,
                        U.PORIGEM,
                        U.PLIQUIDO,
                        U.RETENCAO,
                        TRUNC(CURRENT_DATE) AS DTINCLUSAO,
                        U.ESTAB AS CODFORNECEDOR
                    FROM U_DESCARGA_TRADING U
                    INNER JOIN PRODUTOR P
                            ON P.CHAVE387 = U.CHAVEACESSO
                           AND P.ESTAB = U.ESTAB
                    WHERE U.DT_INCLUSAO IS NOT NULL
                      AND NOT EXISTS (
                            SELECT 1
                            FROM U_DESCARGA_TRADING X
                            WHERE X.ESTAB = P.ESTAB
                              AND X.CHAVEACESSO = P.CHAVE388
                      )
                )
                SELECT *
                FROM BASE
                WHERE CHAVE388 IS NOT NULL
                  AND CHAVE387 IS NOT NULL
            ) LOOP

                INSERT INTO U_DESCARGA_TRADING (
                    U_DESCARGA_TRADING_ID, REF, NF, CHAVEACESSO, ESTAB, DATA,
                    CODTERMINAL, SEQ_END_TERMINA, CODITEM, PLACA, PORIGEM,
                    PLIQUIDO, RETENCAO, DT_INCLUSAO, CODFORNECEDOR, STATUS
                ) VALUES (
                    (SELECT NVL(MAX(U_DESCARGA_TRADING_ID), 0) + 1 FROM U_DESCARGA_TRADING),
                    (SELECT NVL(MAX(REF), 0) + 1 FROM U_DESCARGA_TRADING),
                    VALORES.NOTA388, VALORES.CHAVE388, VALORES.ESTAB, VALORES.DATA,
                    VALORES.CODTERMINAL, VALORES.SEQ_END_TERMINA, VALORES.CODITEM,
                    VALORES.PLACA, VALORES.PORIGEM, VALORES.PLIQUIDO, VALORES.RETENCAO,
                    VALORES.DTINCLUSAO, VALORES.CODFORNECEDOR, 25
                );

                INSERT INTO U_INSERT_DESCARGA_388 (
                    CHAVE387, CHAVE388, NOTA388, ESTAB, DATA, CODTERMINAL,
                    SEQ_END_TERMINA, CODITEM, PLACA, PORIGEM, PLIQUIDO,
                    RETENCAO, DTINCLUSAO, CODFORNECEDOR
                ) VALUES (
                    VALORES.CHAVE387, VALORES.CHAVE388, VALORES.NOTA388, VALORES.ESTAB,
                    VALORES.DATA, VALORES.CODTERMINAL, VALORES.SEQ_END_TERMINA,
                    VALORES.CODITEM, VALORES.PLACA, VALORES.PORIGEM, VALORES.PLIQUIDO,
                    VALORES.RETENCAO, VALORES.DTINCLUSAO, VALORES.CODFORNECEDOR
                );

            END LOOP;
        END LOOP;

        g_estab.DELETE;
        g_seq.DELETE;
        g_cnt := 0;
    END AFTER STATEMENT;

END OS_INSERT_DESCARGA_388;
