create or replace TRIGGER "VIASOFT"."OS_UPD_PESOS" 
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
        V_SEQNOTA         NUMBER;
        V_CNPJ            VARCHAR2(20) := NULL;
        V_FILIAL          VARCHAR2(20) := NULL;
        V_VALIDA_UPD      VARCHAR2(1) := 'N';
        V_DESCARGA        NUMBER := 0;
        V_RETENCAO        NUMBER := 0;
        V_QUEBRA          NUMBER := NULL;
        V_PESO            NUMBER := NULL;
        V_LOG             VARCHAR2(1) := 'N';
        V_MOTIVO          VARCHAR2(100);
        V_PESSOA          NUMBER := NULL;
        V_QTD_RETENPORTO  NUMBER := 0;
        V_ITEM_OFICIAL    NUMBER := NULL; -- Ticket 1352719: item oficial vindo da NFITEM
        V_CODITEM_ANT     NUMBER := NULL; -- Ticket 1352719: valor anterior do CODITEM, para log
    BEGIN

        /* ###### Ticket 1273481 — ajuste de QUEBRA_SOBRA ###### */
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

        /* ###### Ticket 1352719 — Validação de CODITEM contra NFITEM (fonte oficial) ######
           Regra: NFITEM sempre prevalece. Se houver mais de um item na nota
           (SEQNOTAITEM), usa o de MENOR SEQNOTAITEM como oficial. Se CODITEM
           divergir, corrige antes de gravar. Roda em complemento à correção
           pontual de histórico (UPDATE avulso já aplicado). */
        IF V_SEQNOTA IS NOT NULL THEN
            BEGIN
                SELECT NI.ITEM
                  INTO V_ITEM_OFICIAL
                  FROM NFITEM NI
                 WHERE NI.ESTAB = :NEW.ESTAB
                   AND NI.SEQNOTA = V_SEQNOTA
                   AND NI.SEQNOTAITEM = (
                            SELECT MIN(NI2.SEQNOTAITEM)
                              FROM NFITEM NI2
                             WHERE NI2.ESTAB = :NEW.ESTAB
                               AND NI2.SEQNOTA = V_SEQNOTA
                       );
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    V_ITEM_OFICIAL := NULL;
            END;

            IF V_ITEM_OFICIAL IS NOT NULL
               AND NVL(:NEW.CODITEM,-1) <> V_ITEM_OFICIAL THEN
                V_CODITEM_ANT := :NEW.CODITEM;
                :NEW.CODITEM := V_ITEM_OFICIAL;
                V_LOG := 'S';
                IF V_MOTIVO IS NULL THEN V_MOTIVO := 'CODITEM';
                ELSE V_MOTIVO := V_MOTIVO || ';CODITEM';
                END IF;
            END IF;
        END IF;

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

        IF V_FILIAL = V_CNPJ
           AND :NEW.DT_INCLUSAO IS NOT NULL
           AND :NEW.CODTERMINAL NOT IN (139917, 141456) THEN

            /* ###### Validação de duplicidade ######
                TICKET 1341444
               Verifica se QUALQUER SEQNOTAITEM está duplicado dentro dessa
               SEQNOTA (ESTAB + SEQNOTA). Se algum item repetir, pula a nota
               inteira, independente de qual SEQNOTAITEM está duplicado. */
            SELECT COUNT(*)
              INTO V_QTD_RETENPORTO
              FROM (
                  SELECT SEQNOTAITEM
                    FROM RETENPORTO
                   WHERE ESTAB = :NEW.ESTAB
                     AND SEQNOTA = V_SEQNOTA
                   GROUP BY SEQNOTAITEM
                  HAVING COUNT(*) > 1
              );

            IF V_QTD_RETENPORTO = 0 THEN

                BEGIN
                    SELECT 'S', PESODESCARREGAMENTO, PESORETENCAO, PESO
                    INTO V_VALIDA_UPD, V_DESCARGA, V_RETENCAO, V_PESO
                    FROM RETENPORTO
                    WHERE RETENPORTO.ESTAB = :NEW.ESTAB
                      AND RETENPORTO.ITEM = :NEW.CODITEM
                      AND RETENPORTO.SEQNOTA = V_SEQNOTA
                      AND RETENPORTO.SEQNOTAITEM = 1;
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

                    g_cnt := g_cnt + 1;
                    g_estab(g_cnt)   := :NEW.ESTAB;
                    g_seqnota(g_cnt) := V_SEQNOTA;
                    g_coditem(g_cnt) := :NEW.CODITEM;
                    g_pessoa(g_cnt)  := V_PESSOA;

                    IF V_MOTIVO IS NULL THEN V_MOTIVO := 'RETENPORTO';
                    ELSE V_MOTIVO := V_MOTIVO || ';RETENPORTO';
                    END IF;
                END IF;

            END IF; -- V_QTD_RETENPORTO = 0 (nenhum item duplicado na SEQNOTA)
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