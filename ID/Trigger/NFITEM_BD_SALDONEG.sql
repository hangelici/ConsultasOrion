create or replace TRIGGER NFITEM_BD_SALDONEG
BEFORE DELETE ON NFITEM
FOR EACH ROW

DECLARE
    cAceitaNeg VARCHAR2(1);
    nSituacao  NUMBER;
    cChave     VARCHAR2(30);
    dMesIni    DATE;
    nSaldo     NUMBER;

BEGIN
    /*
        1) LIBERACAO PONTUAL
        Se o suporte marcar a sessao com
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO('LIBERA_EXC_NF_SALDONEG'),
        a exclusao segue sem validar.
    */
    IF (SYS_CONTEXT('USERENV', 'CLIENT_INFO') = 'LIBERA_EXC_NF_SALDONEG') THEN
        RETURN;
    END IF;

    /*
        2) ITEM QUE ACEITA SALDO NEGATIVO
        Respeita o cadastro: ACESALNEG = 'S' no item, ou 'G' (segue o
        grupo) com ACESALNEG = 'S' no grupo. Nesses casos nao bloqueia.
    */
    BEGIN
        SELECT
            CASE
                WHEN ITEMAGRO.ACESALNEG = 'G'
                    THEN NVL(ITEMGRUPO.ACESALNEG, 'N')
                ELSE NVL(ITEMAGRO.ACESALNEG, 'N')
            END
        INTO cAceitaNeg
        FROM ITEMAGRO
        LEFT JOIN ITEMGRUPO
            ON ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO
        WHERE ITEMAGRO.ITEM = :OLD.ITEM;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            cAceitaNeg := 'N';
    END;

    IF (cAceitaNeg = 'S') THEN
        RETURN;
    END IF;

    /*
        3) NOTA QUE NAO MOVIMENTA ESTOQUE
        So entram no kardex as notas com ME_SITUACAO nula ou 50/53/55/80.
    */
    BEGIN
        SELECT
            NFCAB.ME_SITUACAO
        INTO nSituacao
        FROM NFCAB
        WHERE NFCAB.ESTAB = :OLD.ESTAB
          AND NFCAB.SEQNOTA = :OLD.SEQNOTA;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN;
    END;

    IF (
        nSituacao IS NOT NULL
        AND nSituacao NOT IN (50, 53, 55, 80)
    ) THEN
        RETURN;
    END IF;

    -- Chave usada pela GERARMOVESTOQUE_NOTA para gravar este item no kardex
    cChave := :OLD.SEQNOTA || ':' || :OLD.SEQNOTAITEM;

    -- O recalculo parte do inicio do mes da nota
    dMesIni := TRUNC(:OLD.DTEMISSAO, 'MM');

    /*
        4) CODIGOS DE SALDO QUE A NOTA SOMA NO ITEM
        Pela natureza de operacao da configuracao da nota, pega os codigos
        de saldo em que ela SOMA no item ('S' = soma, 'M' = soma x diminui
        origem).
    */
    FOR rCod IN (
        SELECT DISTINCT
            NATITEMSALDO.CODIGOSALDO
        FROM NFCAB
        INNER JOIN NFCFG
            ON NFCFG.NOTACONF = NFCAB.NOTACONF
        INNER JOIN NATITEMSALDO
            ON NATITEMSALDO.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO
            AND NATITEMSALDO.ENTRADASAIDA = NFCFG.ENTRADASAIDA
        WHERE NFCAB.ESTAB = :OLD.ESTAB
          AND NFCAB.SEQNOTA = :OLD.SEQNOTA
          AND NATITEMSALDO.SOMADIMINUINADA_ITEM IN ('S', 'M')
    )
    LOOP
        /*
            5) SALDO NO INICIO DO MES DA NOTA
            Busca o fechamento do ultimo mes anterior na ITEMSALDO.
            Se nao houver, usa o saldo de implantacao (ITEMSALDOINI);
            se tambem nao houver, parte de zero.
        */
        BEGIN
            SELECT
                SALDOQUANTIDADE
            INTO nSaldo
            FROM (
                SELECT
                    ITEMSALDO.SALDOQUANTIDADE
                FROM ITEMSALDO
                WHERE ITEMSALDO.ESTAB = :OLD.ESTAB
                  AND ITEMSALDO.ITEM = :OLD.ITEM
                  AND ITEMSALDO.LOCAL = :OLD.LOCAL
                  AND ITEMSALDO.CODIGOSALDO = rCod.CODIGOSALDO
                  AND (
                      ITEMSALDO.ANO < EXTRACT(YEAR FROM :OLD.DTEMISSAO)
                      OR (
                          ITEMSALDO.ANO = EXTRACT(YEAR FROM :OLD.DTEMISSAO)
                          AND ITEMSALDO.MES < EXTRACT(MONTH FROM :OLD.DTEMISSAO)
                      )
                  )
                ORDER BY
                    ITEMSALDO.ANO DESC,
                    ITEMSALDO.MES DESC
            )
            WHERE ROWNUM = 1;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN
                    SELECT
                        ITEMSALDOINI.SALDOINICIAL
                    INTO nSaldo
                    FROM ITEMSALDOINI
                    WHERE ITEMSALDOINI.ESTAB = :OLD.ESTAB
                      AND ITEMSALDOINI.ITEM = :OLD.ITEM
                      AND ITEMSALDOINI.LOCAL = :OLD.LOCAL
                      AND ITEMSALDOINI.CODIGOSALDO = rCod.CODIGOSALDO;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        nSaldo := 0;
                END;
        END;

        nSaldo := NVL(nSaldo, 0);

        /*
            6) REFAZ O SALDO MOVIMENTO A MOVIMENTO, SEM ESTE ITEM DA NOTA
            Percorre o kardex (MOVITEMAGRO) do mesmo estab/item/codigo de
            saldo/local, do inicio do mes ate hoje, ignorando o movimento
            deste item da nota (ORIGEM 'NFI' + CHAVE).
        */
        FOR rMov IN (
            SELECT
                MOVITEMAGRO.DATAMOVIM,
                MOVITEMAGRO.HORAMOVIM,
                MOVITEMAGRO.SOMADIMINUI,
                MOVITEMAGRO.QUANTIDADE,
                MOVITEMAGRO.DOC,
                MOVITEMAGRO.NATUREZA
            FROM MOVITEMAGRO
            WHERE MOVITEMAGRO.ESTAB = :OLD.ESTAB
              AND MOVITEMAGRO.ITEM = :OLD.ITEM
              AND MOVITEMAGRO.DATAMOVIM >= dMesIni
              AND MOVITEMAGRO.CODIGOSALDO = rCod.CODIGOSALDO
              AND MOVITEMAGRO.LOCAL = :OLD.LOCAL
              AND NOT (
                  MOVITEMAGRO.ORIGEM = 'NFI'
                  AND MOVITEMAGRO.CHAVE = cChave
                  AND MOVITEMAGRO.NATUREZA = 'NF'
              )
            ORDER BY
                MOVITEMAGRO.DATAMOVIM,
                MOVITEMAGRO.ORDEM_CRONOLOGICA,
                MOVITEMAGRO.SOMADIMINUI DESC
        )
        LOOP
            -- 'S' soma no estoque; qualquer outro valor ('D') diminui
            IF (rMov.SOMADIMINUI = 'S') THEN
                nSaldo := nSaldo + NVL(rMov.QUANTIDADE, 0);
            ELSE
                nSaldo := nSaldo - NVL(rMov.QUANTIDADE, 0);
            END IF;

            /*
                7) BLOQUEIO
                So bloqueia se o saldo ficar negativo num movimento posterior
                a nota. A tolerancia evita bloqueios por arredondamento.
            */
            IF (
                nSaldo < -0.000001
                AND (
                    TRUNC(rMov.DATAMOVIM) > TRUNC(:OLD.DTEMISSAO)
                    OR (
                        TRUNC(rMov.DATAMOVIM) = TRUNC(:OLD.DTEMISSAO)
                        AND (
                            :OLD.HORA IS NULL
                            OR rMov.HORAMOVIM >= :OLD.HORA
                        )
                    )
                )
            ) THEN
                RAISE_APPLICATION_ERROR(
                    -20901,
                    'Nao e permitido excluir a nota (seq. ' ||
                    :OLD.SEQNOTA || ', estab ' || :OLD.ESTAB ||
                    '): o item ' || :OLD.ITEM ||
                    ' ficaria com saldo ' ||
                    TRIM(TO_CHAR(nSaldo, 'FM999999999990.0000')) ||
                    ' no codigo de saldo ' || rCod.CODIGOSALDO ||
                    ', local ' || :OLD.LOCAL ||
                    ' em ' || TO_CHAR(rMov.DATAMOVIM, 'DD/MM/YYYY') ||
                    ', por causa do movimento posterior ' ||
                    TRIM(rMov.NATUREZA) || ' ' ||
                    TRIM(NVL(rMov.DOC, '')) || '.'
                );
            END IF;

        END LOOP;
    END LOOP;

END;
