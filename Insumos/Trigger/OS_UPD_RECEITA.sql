CREATE OR REPLACE TRIGGER OS_UPD_RECEITA_DIG
BEFORE INSERT OR UPDATE
ON NFCAB
FOR EACH ROW

DECLARE

    V_RECEITA_ASS NUMBER;
    V_ESTAB_ASS   VARCHAR2(3);
    V_QTD         NUMBER;
    V_MIN_ASS     NUMBER;
    V_MAX_ASS     NUMBER;

BEGIN

    /*
        Busca todas as receitas vinculadas à nota.

        Regra:
          - Todas 0 -> V_RECEITA_ASS = 0
          - Todas 1 -> V_RECEITA_ASS = 1
          - Mistura 0 e 1 -> V_RECEITA_ASS = 3

        Se não existir nenhuma receita, encerra a trigger.
    */
    BEGIN

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
        WHERE NR.ESTAB = :NEW.ESTAB
          AND NR.SEQNOTA = :NEW.SEQNOTA;

        /*
            Nenhuma receita encontrada.
        */
        IF V_QTD = 0 THEN
            RETURN;
        END IF;

        /*
            Consolida o status das receitas:
            
            0 + 0 + 0 = 0
            1 + 1 + 1 = 1
            0 + 1       = 3
        */
        IF V_MIN_ASS = 0 AND V_MAX_ASS = 0 THEN

            V_RECEITA_ASS := 0;

        ELSIF V_MIN_ASS = 1 AND V_MAX_ASS = 1 THEN

            V_RECEITA_ASS := 1;

        ELSE

            V_RECEITA_ASS := 3;

        END IF;

    END;


    /*
        Busca a configuração de assinatura digital da empresa.
    */
    BEGIN

        SELECT ASSINADIGITALMENTE
        INTO V_ESTAB_ASS
        FROM U_TEMPRESA
        WHERE ESTAB = :NEW.ESTAB;

    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RETURN;

        WHEN TOO_MANY_ROWS THEN

            RAISE_APPLICATION_ERROR(
                -20002,
                'Mais de uma configuração encontrada em U_TEMPRESA para ' ||
                'ESTAB=' || :NEW.ESTAB
            );

    END;


    /*
        Atualiza as informações de assinatura digital
        na tabela complementar da NFCAB.
    */
    UPDATE NFCAB_U
       SET ESTAB_ASS_DIGIT = V_ESTAB_ASS,
           REC_ASS_DIGIT   = V_RECEITA_ASS
     WHERE ESTAB = :NEW.ESTAB
       AND SEQNOTA = :NEW.SEQNOTA;

END;
/