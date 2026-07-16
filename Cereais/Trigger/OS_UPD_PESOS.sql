create or replace TRIGGER OS_UPD_PESOS
FOR INSERT OR UPDATE ON VIASOFT.u_descarga_trading
COMPOUND TRIGGER

    TYPE t_num  IS TABLE OF NUMBER        INDEX BY PLS_INTEGER;
    TYPE t_char IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;

    -- fila apenas para o UPDATE RETENPORTO_U (única causa do mutating table)
    g_estab   t_char;
    g_seqnota t_num;
    g_coditem t_num;
    g_pessoa  t_num;
    g_cnt     PLS_INTEGER := 0;

    BEFORE EACH ROW IS
        V_SEQNOTA    NUMBER;
        V_CNPJ       VARCHAR2(20) := NULL;
        V_FILIAL     VARCHAR2(20) := NULL;
        V_VALIDA_UPD VARCHAR2(1) := 'N';
        V_DESCARGA   NUMBER := 0;
        V_RETENCAO   NUMBER := 0;
        V_QUEBRA     NUMBER := NULL;
        V_PESO       NUMBER := NULL;
        V_LOG        VARCHAR2(1) := 'N';
        V_MOTIVO     VARCHAR2(100);
        V_PESSOA     NUMBER := NULL;
    BEGIN

        /* ###### Ticket 1273481 — ajuste de QUEBRA_SOBRA ###### */
        -- DT_INCLUSAO NÃO PODE SER NULO para esta alteração acontecer
        IF (NVL(:NEW.PLIQUIDO,0) - NVL(:NEW.PORIGEM,0)) <> NVL(:NEW.QUEBRA_SOBRA,0)
           AND :NEW.DT_INCLUSAO IS NOT NULL THEN
            V_QUEBRA := :NEW.QUEBRA_SOBRA;
            :NEW.QUEBRA_SOBRA := (NVL(:NEW.PLIQUIDO,0) - NVL(:NEW.PORIGEM,0));
            V_LOG := 'S';
            V_MOTIVO := 'QUEBRA_SOBRA';
        END IF;

        /* ###### Ticket 1273853 — pesos / RETENPORTO ###### */
        BEGIN
            SELECT SEQNOTA, NUMEROCM
              INTO V_SEQNOTA, V_PESSOA
              FROM NFCAB
             WHERE CHAVEACESSONFE = :NEW.CHAVEACESSO
               AND ESTAB = :NEW.ESTAB;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_SEQNOTA := NULL;
                V_PESSOA := NULL;
        END;

        IF V_SEQNOTA IS NOT NULL THEN
            BEGIN
                SELECT CNPJF INTO V_CNPJ
                FROM CONTAMOV WHERE CONTAMOV.NUMEROCM = :NEW.CODFORNECEDOR;

                SELECT CNPJ INTO V_FILIAL
                FROM FILIAL WHERE FILIAL.ESTAB = :NEW.ESTAB;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_CNPJ := NULL;
                    V_FILIAL := NULL;
            END;
        END IF;

        -- DT_INCLUSAO NÃO PODE SER NULO para esta alteração acontecer também
        IF V_FILIAL = V_CNPJ
           AND :NEW.DT_INCLUSAO IS NOT NULL
           AND :NEW.CODTERMINAL NOT IN (139917, 141456) THEN

            BEGIN
                SELECT 'S', PESODESCARREGAMENTO, PESORETENCAO, PESO
                INTO V_VALIDA_UPD, V_DESCARGA, V_RETENCAO, V_PESO
                FROM RETENPORTO
                WHERE RETENPORTO.ESTAB = :NEW.ESTAB
                  AND RETENPORTO.ITEM = :NEW.CODITEM
                  AND RETENPORTO.SEQNOTA = V_SEQNOTA
                  AND RETENPORTO.SEQNOTAITEM = 1
                  AND (NVL(RETENPORTO.PESO,0) - NVL(RETENPORTO.PESODESCARREGAMENTO,0)) >= 1000;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_VALIDA_UPD := 'N';
                    V_DESCARGA := 0;
                    V_RETENCAO := 0;
            END;

            IF V_VALIDA_UPD = 'S'
               AND ( (NVL(:NEW.PLIQUIDO,0) <> NVL(V_DESCARGA,0))
                  OR (NVL(:NEW.RETENCAO,0) <> NVL(V_RETENCAO,0)) ) THEN

                V_LOG := 'S';

                -- Este UPDATE fica AQUI mesmo, no BEFORE EACH ROW: RETENPORTO
                -- não tem trigger que devolva para U_DESCARGA_TRADING, então
                -- não gera mutating table. Roda imediatamente, como no original.
                UPDATE RETENPORTO
                SET PESODESCARREGAMENTO =
                        CASE WHEN NVL(:NEW.PLIQUIDO,0) <> NVL(V_DESCARGA,0)
                             THEN :NEW.PLIQUIDO ELSE PESODESCARREGAMENTO END,
                    PESORETENCAO =
                        CASE WHEN NVL(:NEW.RETENCAO,0) <> NVL(V_RETENCAO,0)
                             THEN :NEW.RETENCAO ELSE PESORETENCAO END
                WHERE ESTAB = :NEW.ESTAB
                  AND ITEM = :NEW.CODITEM
                  AND SEQNOTA = V_SEQNOTA
                  AND SEQNOTAITEM = 1;

                -- SÓ este UPDATE precisa ser adiado: é ele que dispara
                -- OS_INSERT_DESCARGA_388, que consulta U_DESCARGA_TRADING.
                g_cnt := g_cnt + 1;
                g_estab(g_cnt)   := :NEW.ESTAB;
                g_seqnota(g_cnt) := V_SEQNOTA;
                g_coditem(g_cnt) := :NEW.CODITEM;
                g_pessoa(g_cnt)  := V_PESSOA;

                IF V_MOTIVO IS NULL THEN V_MOTIVO := 'RETENPORTO';
                ELSE V_MOTIVO := V_MOTIVO || ';RETENPORTO';
                END IF;
            END IF;
        END IF;

        IF V_LOG = 'S' THEN
            INSERT INTO U_LOG_TRADING (
                ESTAB, SEQNOTA, CODTERMINAL, CODFORNECEDOR, CHAVEACESSO,
                PESO_ANT, PESORETENCAO_ANT, PESODESCARREGAMENTO_ANT,
                QUEBRA_ANT, QUEBRA_NOVO, PESORETENCAO_NOVO, PESODESCARREGAMENTO_NOVO,
                MOTIVO, DT_INSERT
            ) VALUES (
                :NEW.ESTAB, V_SEQNOTA, :NEW.CODTERMINAL, :NEW.CODFORNECEDOR, :NEW.CHAVEACESSO,
                V_PESO, V_RETENCAO, V_DESCARGA,
                V_QUEBRA, :NEW.QUEBRA_SOBRA, :NEW.RETENCAO, :NEW.PLIQUIDO,
                V_MOTIVO, CURRENT_TIMESTAMP
            );
        END IF;

    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR i IN 1 .. g_cnt LOOP
            UPDATE RETENPORTO_U
            SET CONFERIDO = 'S',
                OBS = 'Importação via gatilho - Trading'
            WHERE ESTAB = g_estab(i)
              AND SEQNOTA = g_seqnota(i)
              AND ITEM = g_coditem(i)
              AND NUMEROCM = g_pessoa(i)
              AND SEQNOTAITEM = 1;
        END LOOP;

        g_estab.DELETE;
        g_seqnota.DELETE;
        g_coditem.DELETE;
        g_pessoa.DELETE;
        g_cnt := 0;
    END AFTER STATEMENT;

END OS_UPD_PESOS;
