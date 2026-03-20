create or replace TRIGGER OS_BLOQ_NF_DEVOL 
BEFORE INSERT OR UPDATE
ON NFITEMAPARTIRDE FOR EACH ROW
DECLARE
CONF_DEST NUMBER;
V_NFDEVOL NUMBER;
V_NFORI NUMBER;
V_ESTABORI NUMBER;
V_VALIDA NUMBER;
BEGIN

    --- VERIFICAR SE A CONFIG DE DEVOL É 383 OU 399
   BEGIN
        SELECT NOTACONF
        INTO CONF_DEST
        FROM NFCAB
        WHERE ESTAB = :NEW.ESTAB
          AND SEQNOTA = :NEW.SEQNOTA;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN; -- não faz nada
    END;

    -- SE FOR 383 OU 399 BUSCAR NOTA DE ORIGEM
    IF CONF_DEST IN (383,399) THEN

        BEGIN
            SELECT NOTA, ESTAB
            INTO V_NFORI, V_ESTABORI
            FROM NFCAB
            WHERE ESTAB = :NEW.ESTABORIGEM
              AND SEQNOTA = :NEW.SEQNOTAORIGEM;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN; -- não tem origem, deixa passar
        END;

        IF NVL(V_NFORI,0) <> 0 THEN

           /*BEGIN
                SELECT NF_DEVOLUCAO
                INTO V_NFDEVOL
                FROM U_DESCARGA_TRADING
                WHERE ESTAB = V_ESTABORI
                  AND NF = V_NFORI;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_NFDEVOL := NULL;
            END;*/
            
            BEGIN
                SELECT 1
                INTO V_VALIDA
                FROM DUAL
                WHERE EXISTS(
                    SELECT 1 
                    FROM U_DESCARGA_TRADING
                    WHERE U_DESCARGA_TRADING.ESTAB = V_ESTABORI
                      AND U_DESCARGA_TRADING.NF = V_NFORI
                      AND NVL(U_DESCARGA_TRADING.NF_DEVOLUCAO,0) <> 0
                      AND U_DESCARGA_TRADING.CHAVEACESSO IS NOT NULL
                ); 
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_VALIDA := 0;
            END;

            IF NVL(V_VALIDA, 0) <> 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20000,
                    'Essa Nota já tem NF de Devolução vinculada na Descarga Trading'
                );
            END IF;

        END IF;

    END IF;

END;