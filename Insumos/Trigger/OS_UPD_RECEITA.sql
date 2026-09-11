create or replace TRIGGER OS_UPD_RECEITA_DIG
FOR INSERT OR UPDATE OF ASSINADODIGITALMENTE
ON RECEITCAB
COMPOUND TRIGGER

    TYPE T_RECEITA IS RECORD (
        ESTAB          RECEITCAB.ESTAB%TYPE,
        RECEITUARIOID  RECEITCAB.RECEITUARIOID%TYPE
    );

    TYPE T_RECEITAS IS TABLE OF T_RECEITA
        INDEX BY PLS_INTEGER;

    V_RECEITAS T_RECEITAS;
    V_CONTADOR PLS_INTEGER := 0;


    AFTER EACH ROW IS
    BEGIN

        V_CONTADOR := V_CONTADOR + 1;

        V_RECEITAS(V_CONTADOR).ESTAB :=
            :NEW.ESTAB;

        V_RECEITAS(V_CONTADOR).RECEITUARIOID :=
            :NEW.RECEITUARIOID;

    END AFTER EACH ROW;


    AFTER STATEMENT IS

        V_RECEITA_ASS NUMBER;
        V_ESTAB_ASS   VARCHAR2(3);
        V_QTD         NUMBER;
        V_MIN_ASS     NUMBER;
        V_MAX_ASS     NUMBER;

    BEGIN

        /*
            Para cada receituário alterado/inserido,
            localiza as notas vinculadas.
        */
        FOR I IN 1 .. V_CONTADOR
        LOOP

            FOR R IN (
                SELECT DISTINCT
                       NR.ESTAB,
                       NR.SEQNOTA
                FROM NFCABRECEITCAB NR
                WHERE NR.ESTABRECEITA = V_RECEITAS(I).ESTAB
                  AND NR.RECEITUARIOID = V_RECEITAS(I).RECEITUARIOID
            )
            LOOP

                /*
                    Calcula o status de todas as receitas
                    vinculadas à nota.
                */
                SELECT COUNT(*),
                       MIN(RC.ASSINADODIGITALMENTE),
                       MAX(RC.ASSINADODIGITALMENTE)
                INTO   V_QTD,
                       V_MIN_ASS,
                       V_MAX_ASS
                FROM NFCABRECEITCAB NR
                INNER JOIN RECEITCAB RC
                    ON RC.ESTAB = NR.ESTABRECEITA
                   AND RC.RECEITUARIOID = NR.RECEITUARIOID
                WHERE NR.ESTAB = R.ESTAB
                  AND NR.SEQNOTA = R.SEQNOTA;


                IF V_QTD = 0 THEN
                    CONTINUE;
                END IF;


                /*
                    Regra:

                    Todas 0 -> 0
                    Todas 1 -> 1
                    Mistura 0/1 -> 2
                */
                IF V_MIN_ASS = 0
                   AND V_MAX_ASS = 0 THEN

                    V_RECEITA_ASS := 0;

                ELSIF V_MIN_ASS = 1
                  AND V_MAX_ASS = 1 THEN

                    V_RECEITA_ASS := 1;

                ELSE

                    V_RECEITA_ASS := 2;

                END IF;


                /*
                    Busca configuração da empresa.
                */
                BEGIN

                    SELECT ASSINADIGITALMENTE
                    INTO V_ESTAB_ASS
                    FROM U_TEMPRESA
                    WHERE ESTAB = R.ESTAB;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        CONTINUE;

                    WHEN TOO_MANY_ROWS THEN
                        RAISE_APPLICATION_ERROR(
                            -20002,
                            'Mais de uma configuração encontrada em U_TEMPRESA para ' ||
                            'ESTAB=' || R.ESTAB
                        );
                END;


                /*
                    Atualiza NFCAB_U.
                */
                UPDATE NFCAB_U
                   SET ESTAB_ASS_DIGIT = V_ESTAB_ASS,
                       REC_ASS_DIGIT   = V_RECEITA_ASS
                 WHERE ESTAB = R.ESTAB
                   AND SEQNOTA = R.SEQNOTA;

            END LOOP;

        END LOOP;

    END AFTER STATEMENT;

END;
