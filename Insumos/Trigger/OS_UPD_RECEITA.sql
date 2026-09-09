create or replace TRIGGER OS_UPD_RECEITA_DIG
BEFORE INSERT OR UPDATE
ON NFCAB
FOR EACH ROW
DECLARE
    V_RECEITA_ASS NUMBER;
    V_ESTAB_ASS   VARCHAR2(3);
    V_RECEITA     NUMBER;
    V_ESTAB       NUMBER;
BEGIN

    /*
        Verifica se existe receita vinculada à nota.

        Se não existir em NFCABRECEITCAB,
        encerra a trigger sem impedir o INSERT/UPDATE da NFCAB.
    */
    BEGIN
        SELECT ESTABRECEITA,
               RECEITUARIOID
        INTO   V_ESTAB,
               V_RECEITA
        FROM NFCABRECEITCAB
        WHERE ESTAB = :NEW.ESTAB
          AND SEQNOTA = :NEW.SEQNOTA;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;

        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Mais de uma receita encontrada em NFCABRECEITCAB para ' ||
                'ESTAB=' || :NEW.ESTAB ||
                ' e SEQNOTA=' || :NEW.SEQNOTA
            );
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
        Busca a assinatura digital do receituário.
    */
    BEGIN
        SELECT ASSINADODIGITALMENTE
        INTO V_RECEITA_ASS
        FROM RECEITCAB
        WHERE ESTAB = V_ESTAB
          AND RECEITUARIOID = V_RECEITA;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;

        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'Mais de um receituário encontrado em RECEITCAB para ' ||
                'ESTAB=' || V_ESTAB ||
                ' e RECEITUARIOID=' || V_RECEITA
            );
    END;


    /*
        Atualiza as informações de assinatura digital
        na tabela complementar da NFCAB.
    */
    UPDATE NFCAB_U
    SET ESTAB_ASS_DIGIT   = V_ESTAB_ASS,
        REC_ASS_DIGIT = V_RECEITA_ASS
    WHERE ESTAB = :NEW.ESTAB
      AND SEQNOTA = :NEW.SEQNOTA;

END;