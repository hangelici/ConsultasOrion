CREATE OR REPLACE PROCEDURE OS_UPD_VENCFIN AS
BEGIN

    FOR VALORES IN (
        SELECT
            P.NUMEROCM,
            P.LIMCRED_ID,
            U.VENCFININICI,
            U.VENCFINFINAL,
            U.VIGINI,
            U.VIGFIM,
            U.ENTRINI,
            U.ENTRFIM
        FROM PESSOALIMCRED P

        INNER JOIN CONTAMOV C
            ON C.NUMEROCM = P.NUMEROCM

        INNER JOIN U_ALTCONLIMITE U
            ON U.ID = P.LIMCRED_ID
           AND U.ESTAB =
               CASE
                   /* Se existe a combinação
                      ESTABFINRESPONSAVEL + LIMCRED_ID,
                      usa o estabelecimento responsável */
                   WHEN EXISTS (
                       SELECT 1
                       FROM U_ALTCONLIMITE UX
                       WHERE UX.ESTAB = C.ESTABFINRESPONSAVEL
                         AND UX.ID    = P.LIMCRED_ID
                   )
                   THEN C.ESTABFINRESPONSAVEL

                   /* Caso contrário, usa a configuração padrão */
                   ELSE 1
               END

        WHERE
            (
                NVL(P.DTVIGENCIAFININI, DATE '1900-01-01') <>
                NVL(U.VENCFININICI, DATE '1900-01-01')

                OR

                NVL(P.DTVIGENCIAFINFIM, DATE '1900-01-01') <>
                NVL(U.VENCFINFINAL, DATE '1900-01-01')

                OR (
                    U.VIGINI IS NOT NULL
                    AND NVL(P.DTVIGENCIAINI, DATE '1900-01-01') <>
                        NVL(U.VIGINI, DATE '1900-01-01')
                )

                OR (
                    U.VIGFIM IS NOT NULL
                    AND NVL(P.DTVIGENCIAFIM, DATE '1900-01-01') <>
                        NVL(U.VIGFIM, DATE '1900-01-01')
                )

                OR (
                    U.ENTRINI IS NOT NULL
                    AND EXISTS (
                        SELECT 1
                        FROM PESSOALIMCRED_U PU
                        WHERE PU.LIMCRED_ID = P.LIMCRED_ID
                          AND PU.NUMEROCM   = P.NUMEROCM
                          AND NVL(PU.DT_ENTREGA_INI, DATE '1900-01-01') <>
                              NVL(U.ENTRINI, DATE '1900-01-01')
                    )
                )

                OR (
                    U.ENTRFIM IS NOT NULL
                    AND EXISTS (
                        SELECT 1
                        FROM PESSOALIMCRED_U PU
                        WHERE PU.LIMCRED_ID = P.LIMCRED_ID
                          AND PU.NUMEROCM   = P.NUMEROCM
                          AND NVL(PU.DT_ENTREGA_FIM, DATE '1900-01-01') <>
                              NVL(U.ENTRFIM, DATE '1900-01-01')
                    )
                )
            )
    )
    LOOP

        UPDATE PESSOALIMCRED
        SET
            DTVIGENCIAFININI = VALORES.VENCFININICI,
            DTVIGENCIAFINFIM = VALORES.VENCFINFINAL,

            DTVIGENCIAINI =
                CASE
                    WHEN VALORES.VIGINI IS NOT NULL
                    THEN VALORES.VIGINI
                    ELSE DTVIGENCIAINI
                END,

            DTVIGENCIAFIM =
                CASE
                    WHEN VALORES.VIGFIM IS NOT NULL
                    THEN VALORES.VIGFIM
                    ELSE DTVIGENCIAFIM
                END

        WHERE NUMEROCM   = VALORES.NUMEROCM
          AND LIMCRED_ID = VALORES.LIMCRED_ID;


        IF VALORES.ENTRINI IS NOT NULL
           OR VALORES.ENTRFIM IS NOT NULL
        THEN

            UPDATE PESSOALIMCRED_U
            SET
                DT_ENTREGA_INI =
                    CASE
                        WHEN VALORES.ENTRINI IS NOT NULL
                        THEN VALORES.ENTRINI
                        ELSE DT_ENTREGA_INI
                    END,

                DT_ENTREGA_FIM =
                    CASE
                        WHEN VALORES.ENTRFIM IS NOT NULL
                        THEN VALORES.ENTRFIM
                        ELSE DT_ENTREGA_FIM
                    END

            WHERE LIMCRED_ID = VALORES.LIMCRED_ID
              AND NUMEROCM   = VALORES.NUMEROCM;

        END IF;

    END LOOP;

    COMMIT;

END;
/