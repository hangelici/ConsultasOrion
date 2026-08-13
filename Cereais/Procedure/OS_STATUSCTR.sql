CREATE OR REPLACE PROCEDURE OS_STATUSCTRFAT
AS
BEGIN
    /*
        ###### Alterações Ticket 1379898 ######
    */
    ----------------------------------------------------------------------
    -- 1. CONTRATO FINALIZADO
    --    Saldo = 0
    --    Não altera contratos já Finalizados ou Concluídos
    ----------------------------------------------------------------------

    EXECUTE IMMEDIATE '
        UPDATE CONTRATO_U CDU
           SET CDU.STATUSFAT = ''3 - Finalizado''
         WHERE NVL(CDU.STATUSFAT,''X'') NOT IN (''3 - Finalizado'', ''4 - Concluido'')
           AND EXISTS (
                SELECT 1
                  FROM CONTRATO

                 INNER JOIN CONTRATOCFG
                    ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
                   AND CONTRATOCFG.CONTCONF IN (20,21)

                 INNER JOIN U_TEMPRESA
                    ON U_TEMPRESA.ESTAB = CONTRATO.ESTAB
                   AND U_TEMPRESA.GRAOS = ''S''

                 INNER JOIN CONTRATOITE
                    ON CONTRATOITE.ESTAB = CONTRATO.ESTAB
                   AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO

                 INNER JOIN TABLE (
                    PCONTRATOSALDO(
                        CONTRATO.ESTAB,
                        CURRENT_DATE,
                        CONTRATO.CONTRATO,
                        CONTRATO.CONTRATO,
                        CONTRATOITE.SEQITEM,
                        CONTRATOITE.SEQITEM,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    )
                 ) PSALDO
                    ON 0 = 0

                 WHERE CONTRATO.ESTAB = CDU.ESTAB
                   AND CONTRATO.CONTRATO = CDU.CONTRATO
                   AND ARREDONDAR(PSALDO.NQTDSALDO, 2) = 0
           )';

    COMMIT;


    ----------------------------------------------------------------------
    -- 2. CONTRATO PARA VERIFICAR
    --    Saldo > 0 e <= 5% da quantidade
    --    Não altera contratos já Finalizados ou Concluídos
    ----------------------------------------------------------------------

    EXECUTE IMMEDIATE '
        UPDATE CONTRATO_U CDU
           SET CDU.STATUSFAT = ''2 - Verificar''
         WHERE NVL(CDU.STATUSFAT,''X'') NOT IN (''3 - Finalizado'', ''4 - Concluido'')
           AND EXISTS (
                SELECT 1
                  FROM CONTRATO

                 INNER JOIN CONTRATOCFG
                    ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
                   AND CONTRATOCFG.CONTCONF IN (20,21)

                 INNER JOIN U_TEMPRESA
                    ON U_TEMPRESA.ESTAB = CONTRATO.ESTAB
                   AND U_TEMPRESA.GRAOS = ''S''

                 INNER JOIN CONTRATOITE
                    ON CONTRATOITE.ESTAB = CONTRATO.ESTAB
                   AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO

                 INNER JOIN TABLE (
                    PCONTRATOSALDO(
                        CONTRATO.ESTAB,
                        CURRENT_DATE,
                        CONTRATO.CONTRATO,
                        CONTRATO.CONTRATO,
                        CONTRATOITE.SEQITEM,
                        CONTRATOITE.SEQITEM,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    )
                 ) PSALDO
                    ON 0 = 0

                 WHERE CONTRATO.ESTAB = CDU.ESTAB
                   AND CONTRATO.CONTRATO = CDU.CONTRATO
                   AND ARREDONDAR(PSALDO.NQTDSALDO, 2) > 0

                   AND ARREDONDAR(
                        (
                            CAST(
                                COALESCE(PSALDO.NQTDSALDO, 0)
                                AS DECIMAL(18,2)
                            )
                            / CONTRATOITE.QUANTIDADE
                        ) * 100,
                        2
                   ) <= 5
           )';

    COMMIT;


    ----------------------------------------------------------------------
    -- 3. CONTRATO EM ABERTO
    --    Saldo > 5% da quantidade
    --    Não altera contratos já Finalizados ou Concluídos
    ----------------------------------------------------------------------

    EXECUTE IMMEDIATE '
        UPDATE CONTRATO_U CDU
           SET CDU.STATUSFAT = ''1 - Em Aberto''
         WHERE NVL(CDU.STATUSFAT,''X'') NOT IN (''3 - Finalizado'', ''4 - Concluido'')
           AND EXISTS (
                SELECT 1
                  FROM CONTRATO

                 INNER JOIN CONTRATOCFG
                    ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
                   AND CONTRATOCFG.CONTCONF IN (20,21)

                 INNER JOIN U_TEMPRESA
                    ON U_TEMPRESA.ESTAB = CONTRATO.ESTAB
                   AND U_TEMPRESA.GRAOS = ''S''

                 INNER JOIN CONTRATOITE
                    ON CONTRATOITE.ESTAB = CONTRATO.ESTAB
                   AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO

                 INNER JOIN TABLE (
                    PCONTRATOSALDO(
                        CONTRATO.ESTAB,
                        CURRENT_DATE,
                        CONTRATO.CONTRATO,
                        CONTRATO.CONTRATO,
                        CONTRATOITE.SEQITEM,
                        CONTRATOITE.SEQITEM,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL
                    )
                 ) PSALDO
                    ON 0 = 0

                 WHERE CONTRATO.ESTAB = CDU.ESTAB
                   AND CONTRATO.CONTRATO = CDU.CONTRATO
                   AND ARREDONDAR(PSALDO.NQTDSALDO, 2) > 0

                   AND ARREDONDAR(
                        (
                            CAST(
                                COALESCE(PSALDO.NQTDSALDO, 0)
                                AS DECIMAL(18,2)
                            )
                            / CONTRATOITE.QUANTIDADE
                        ) * 100,
                        2
                   ) > 5
           )';

    COMMIT;

END;