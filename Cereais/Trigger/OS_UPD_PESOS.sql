create or replace TRIGGER OS_UPD_PESOS
BEFORE INSERT
ON VIASOFT.u_descarga_trading FOR EACH ROW
DECLARE
V_SEQNOTA NUMBER;
V_CNPJ VARCHAR2(20) := NULL;
V_FILIAL VARCHAR2(20) := NULL;
V_VALIDA_UPD VARCHAR2(1) := 'N';
V_DESCARGA   NUMBER := 0;
V_RETENCAO   NUMBER := 0;
V_QUEBRA NUMBER := NULL;
V_PESO NUMBER := NULL;
V_LOG VARCHAR2(1) := 'N';
V_MOTIVO VARCHAR2(100);
V_PESSOA NUMBER := NULL;
BEGIN

    /* ###### Validações Ticket 1273481 ###### */
    IF (NVL(:NEW.PLIQUIDO,0) - NVL(:NEW.PORIGEM,0)) <> NVL(:NEW.QUEBRA_SOBRA,0) AND :NEW.DT_INCLUSAO IS NOT NULL THEN
        V_QUEBRA := :NEW.QUEBRA_SOBRA;
        :NEW.QUEBRA_SOBRA := (NVL(:NEW.PLIQUIDO,0) - NVL(:NEW.PORIGEM,0));
        V_LOG := 'S';
        V_MOTIVO := 'QUEBRA_SOBRA';
    END IF;

    /* ###### Validações Ticket 1273853 ###### */

    -- Busca SEQNOTA para validar na Retenporto
    BEGIN
        SELECT SEQNOTA,NUMEROCM
          INTO V_SEQNOTA, V_PESSOA
          FROM NFCAB
         WHERE CHAVEACESSONFE = :NEW.CHAVEACESSO
         AND ESTAB = :NEW.ESTAB;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            V_SEQNOTA := NULL;
            V_PESSOA := NULL;
    END;

    /*Fornecedor e Filial devem ser a mesma pessoa (Pega CNPJ para validar casos onde Cod.Estab é 
    maior que 1000)
    */
    IF V_SEQNOTA IS NOT NULL THEN
        BEGIN
            SELECT CNPJF 
            INTO V_CNPJ 
            FROM CONTAMOV WHERE CONTAMOV.NUMEROCM = :NEW.CODFORNECEDOR;

            SELECT CNPJ 
            INTO V_FILIAL 
            FROM FILIAL WHERE FILIAL.ESTAB = :NEW.ESTAB;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_CNPJ := NULL;
                V_FILIAL := NULL;
        END;
    END IF;

    IF V_FILIAL = V_CNPJ AND :NEW.DT_INCLUSAO IS NOT NULL AND :NEW.CODTERMINAL NOT IN (139917, 141456) THEN

        BEGIN
        -- Verificar se encaixa na regra do ticket 1273853
        SELECT 'S', PESODESCARREGAMENTO, PESORETENCAO, PESO
        INTO V_VALIDA_UPD, V_DESCARGA, V_RETENCAO, V_PESO FROM RETENPORTO
        WHERE RETENPORTO.ESTAB = :NEW.ESTAB
            AND RETENPORTO.ITEM = :NEW.CODITEM
            AND RETENPORTO.SEQNOTA = V_SEQNOTA
            AND RETENPORTO.SEQNOTAITEM = 1
            AND (NVL(RETENPORTO.PESO,0) - NVL(RETENPORTO.PESODESCARREGAMENTO, 0)) >= 1000;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_VALIDA_UPD := 'N';
                V_DESCARGA := 0;
                V_RETENCAO := 0;
        END;

        -- Valida Update dos pesos
        IF V_VALIDA_UPD = 'S' AND (NVL(:NEW.PLIQUIDO,0) <> V_DESCARGA OR NVL(:NEW.RETENCAO,0) <> V_RETENCAO) THEN
            UPDATE RETENPORTO
            SET PESODESCARREGAMENTO =
                    CASE
                        WHEN NVL(:NEW.PLIQUIDO,0) <> V_DESCARGA
                        THEN :NEW.PLIQUIDO
                        ELSE PESODESCARREGAMENTO
                    END,
                PESORETENCAO =
                    CASE
                        WHEN NVL(:NEW.RETENCAO,0) <> V_RETENCAO
                        THEN :NEW.RETENCAO
                        ELSE PESORETENCAO
                    END
            WHERE ESTAB = :NEW.ESTAB
            AND ITEM = :NEW.CODITEM
            AND SEQNOTA = V_SEQNOTA
            AND SEQNOTAITEM = 1;
            V_LOG := 'S';

            UPDATE RETENPORTO_U
                SET CONFERIDO = 'S',
                OBS = 'Importação via gatilho - Trading'
            WHERE ESTAB = :NEW.ESTAB
            AND SEQNOTA = V_SEQNOTA
            AND ITEM = :NEW.CODITEM
            AND NUMEROCM = V_PESSOA
            AND SEQNOTAITEM = 1;

            IF V_MOTIVO IS NULL THEN V_MOTIVO := 'RETENPORTO';
            ELSE
                V_MOTIVO := V_MOTIVO || ';RETENPORTO';
            END IF; 
        END IF;
    END IF;

    IF V_LOG = 'S' THEN
    /* ###### Validações Ticket 1273853 ###### */
        INSERT INTO U_LOG_TRADING (ESTAB, SEQNOTA, CODTERMINAL, CODFORNECEDOR, CHAVEACESSO, PESO_ANT, PESORETENCAO_ANT, PESODESCARREGAMENTO_ANT, QUEBRA_ANT, QUEBRA_NOVO, PESORETENCAO_NOVO, PESODESCARREGAMENTO_NOVO, MOTIVO)
        VALUES (:NEW.ESTAB, V_SEQNOTA, :NEW.CODTERMINAL, :NEW.CODFORNECEDOR, :NEW.CHAVEACESSO, V_PESO, V_RETENCAO, V_DESCARGA, V_QUEBRA, :NEW.QUEBRA_SOBRA, :NEW.RETENCAO, :NEW.PLIQUIDO, V_MOTIVO);
    END IF;

END;