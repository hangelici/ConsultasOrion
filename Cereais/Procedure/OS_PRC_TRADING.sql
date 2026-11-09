create or replace PROCEDURE OS_PRC_TRADING IS

BEGIN
 
 
    UPDATE VIASOFT.U_DESCARGA_TRADING UDT

       SET (UDT.SEQNOTA, UDT.NOTACONF, UDT.STATUSNF) = (

                SELECT NF.SEQNOTA,

                       NF.NOTACONF,

                       CASE WHEN NF.STATUS = 'C' THEN 'C' ELSE 'N' END

                  FROM NFCAB NF

                 WHERE NF.ESTAB          = UDT.ESTAB

                   AND NF.CHAVEACESSONFE = UDT.CHAVEACESSO

           )

     WHERE EXISTS (

                SELECT 1

                  FROM NFCAB NF

                 WHERE NF.ESTAB          = UDT.ESTAB

                   AND NF.CHAVEACESSONFE = UDT.CHAVEACESSO

           );

    ------------------------------------------------------------------

    -- TIPOFRETE consolidado num unico UPDATE, agora usando UDT.SEQNOTA/

    -- UDT.NOTACONF ja sincronizados. NAO precisa mais tocar em NFCAB aqui.

    ------------------------------------------------------------------

    UPDATE VIASOFT.U_DESCARGA_TRADING UDT

       SET UDT.TIPOFRETE = (

                CASE

                    -- Formacao de lote / Nota produtor

                    WHEN UDT.NOTACONF IN (394,387,1387,393) THEN

                        COALESCE(

                            (SELECT CU.TIPOFRETES

                               FROM CONTRATONFITE CNF

                               INNER JOIN CONTRATO_U CU

                                       ON CU.ESTAB    = CNF.ESTAB

                                      AND CU.CONTRATO = CNF.CONTRATO

                              WHERE CNF.ESTABNOTA = UDT.ESTAB

                                AND CNF.SEQNOTA   = UDT.SEQNOTA

                                AND CNF.SEQNOTAITEM = (

                                        SELECT MIN(CNF2.SEQNOTAITEM)

                                          FROM CONTRATONFITE CNF2

                                         WHERE CNF2.ESTABNOTA = UDT.ESTAB

                                           AND CNF2.SEQNOTA   = UDT.SEQNOTA

                                    )

                                AND CU.TIPOFRETES IS NOT NULL

                            ),

                            'Pendente'

                        )

                    -- Sempre sem contrato

                    WHEN UDT.NOTACONF = 382 THEN

                        'Sem Contrato'

                    -- Nunca possuem contrato vinculado (nota pode nao existir na NFCAB)

                    WHEN UDT.NOTACONF IN (388,1388) THEN

                        CASE WHEN UDT.SEQNOTA IS NOT NULL THEN 'Sem contrato'

                             ELSE 'Pendente'

                        END

                    ELSE UDT.TIPOFRETE

                END

           )

     WHERE UDT.NOTACONF IN (394,387,1387,393,382,388,1388);

    COMMIT;

EXCEPTION

    WHEN OTHERS THEN

        ROLLBACK;

        RAISE;

END;
