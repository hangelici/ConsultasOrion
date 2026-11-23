CREATE OR REPLACE TRIGGER NFITEM_BD_SALDONEG

FOR DELETE ON NFITEM

COMPOUND TRIGGER



  TYPE TChaves IS TABLE OF BOOLEAN INDEX BY VARCHAR2(60);



  -- Chaves do kardex (SEQNOTA:SEQNOTAITEM) excluidas neste comando

  aExcluidas TChaves;



  nTolerancia CONSTANT NUMBER := 0.000001;



  /* Saldo de um local no inicio do mes: fechamento do ultimo mes anterior

     (ITEMSALDO); sem fechamento, saldo de implantacao (ITEMSALDOINI);

     sem nenhum dos dois, zero. */

  FUNCTION SaldoInicioMes(pEstab NUMBER, pItem NUMBER, pLocal NUMBER,

                          pCodSaldo NUMBER, pData DATE) RETURN NUMBER IS

    nSaldo NUMBER;

  BEGIN

    BEGIN

      SELECT SALDOQUANTIDADE

        INTO nSaldo

        FROM (SELECT ITEMSALDO.SALDOQUANTIDADE

                FROM ITEMSALDO

               WHERE ITEMSALDO.ESTAB       = pEstab

                 AND ITEMSALDO.ITEM        = pItem

                 AND ITEMSALDO.LOCAL       = pLocal

                 AND ITEMSALDO.CODIGOSALDO = pCodSaldo

                 AND (    ITEMSALDO.ANO < EXTRACT(YEAR FROM pData)

                      OR (    ITEMSALDO.ANO = EXTRACT(YEAR FROM pData)

                          AND ITEMSALDO.MES < EXTRACT(MONTH FROM pData)))

               ORDER BY ITEMSALDO.ANO DESC, ITEMSALDO.MES DESC)

       WHERE ROWNUM = 1;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        BEGIN

          SELECT ITEMSALDOINI.SALDOINICIAL

            INTO nSaldo

            FROM ITEMSALDOINI

           WHERE ITEMSALDOINI.ESTAB       = pEstab

             AND ITEMSALDOINI.ITEM        = pItem

             AND ITEMSALDOINI.LOCAL       = pLocal

             AND ITEMSALDOINI.CODIGOSALDO = pCodSaldo;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            nSaldo := 0;

        END;

    END;

    RETURN NVL(nSaldo, 0);

  END SaldoInicioMes;



  PROCEDURE Validar(pEstab NUMBER, pSeqNota NUMBER, pItem NUMBER,

                    pLocal NUMBER, pDtEmissao DATE, pHora NFITEM.HORA%TYPE) IS

    cAceitaNeg VARCHAR2(1);

    nSituacao  NUMBER;

    nPorEstab  NUMBER;

    dMesIni    DATE;

    nSaldoSem  NUMBER;  -- saldo sem as linhas excluidas

    nSaldoCom  NUMBER;  -- saldo como esta hoje (com a nota)

    nQtd       NUMBER;

  BEGIN

    /* Item que aceita saldo negativo: ACESALNEG = 'S' no item, ou 'G'

       (segue o grupo) com 'S' no grupo. */

    BEGIN

      SELECT CASE

               WHEN ITEMAGRO.ACESALNEG = 'G' THEN NVL(ITEMGRUPO.ACESALNEG, 'N')

               ELSE NVL(ITEMAGRO.ACESALNEG, 'N')

             END

        INTO cAceitaNeg

        FROM ITEMAGRO

        LEFT JOIN ITEMGRUPO ON (ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO)

       WHERE ITEMAGRO.ITEM = pItem;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        cAceitaNeg := 'N';

    END;



    IF (cAceitaNeg = 'S') THEN

      RETURN;

    END IF;



    /* Nota que nao movimenta estoque: so entram no kardex as notas com

       ME_SITUACAO nula ou 50/53/55/80 (mesma regra da GERARMOVESTOQUE_NOTA). */

    BEGIN

      SELECT NFCAB.ME_SITUACAO

        INTO nSituacao

        FROM NFCAB

       WHERE NFCAB.ESTAB   = pEstab

         AND NFCAB.SEQNOTA = pSeqNota;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN;

    END;



    IF ((nSituacao IS NOT NULL) AND (nSituacao NOT IN (50, 53, 55, 80))) THEN

      RETURN;

    END IF;



    dMesIni := TRUNC(pDtEmissao, 'MM');



    /* Codigos de saldo que a nota SOMA no item ('S' soma, 'M' soma x

       diminui origem) E que sao protegidos contra saldo negativo em

       alguma configuracao de nota. */

    FOR rCod IN (SELECT DISTINCT NATITEMSALDO.CODIGOSALDO

                   FROM NFCAB

                  INNER JOIN NFCFG

                     ON NFCFG.NOTACONF = NFCAB.NOTACONF

                  INNER JOIN NATITEMSALDO

                     ON NATITEMSALDO.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO

                    AND NATITEMSALDO.ENTRADASAIDA       = NFCFG.ENTRADASAIDA

                  WHERE NFCAB.ESTAB   = pEstab

                    AND NFCAB.SEQNOTA = pSeqNota

                    AND NATITEMSALDO.SOMADIMINUINADA_ITEM IN ('S', 'M')

                    AND NATITEMSALDO.CODIGOSALDO IN (SELECT CFG.SLDNEG

                                                       FROM NFCFG CFG

                                                      WHERE CFG.SLDNEG > 0))

    LOOP

      -- Validacao por estabelecimento (todos os locais) ou por local

      SELECT COUNT(*)

        INTO nPorEstab

        FROM NFCFG CFG

       WHERE CFG.SLDNEG = rCod.CODIGOSALDO

         AND (NVL(CFG.VALSALDONEGPOR, 0) = 1 OR NVL(CFG.PRIORLOCESTNF, 0) = 0);



      -- Saldo no inicio do mes da nota

      nSaldoSem := 0;

      IF (nPorEstab > 0) THEN

        FOR rLoc IN (SELECT LOCALEST."LOCAL" AS NLOCAL

                       FROM LOCALEST

                      WHERE LOCALEST.ESTAB = pEstab)

        LOOP

          nSaldoSem := nSaldoSem + SaldoInicioMes(pEstab, pItem, rLoc.NLOCAL, rCod.CODIGOSALDO, pDtEmissao);

        END LOOP;

      ELSE

        nSaldoSem := SaldoInicioMes(pEstab, pItem, pLocal, rCod.CODIGOSALDO, pDtEmissao);

      END IF;

      nSaldoCom := nSaldoSem;



      /* Refaz o saldo movimento a movimento, do inicio do mes ate hoje,

         com e sem as linhas excluidas neste comando. */

      FOR rMov IN (SELECT MOVITEMAGRO.DATAMOVIM,

                          MOVITEMAGRO.HORAMOVIM,

                          MOVITEMAGRO.SOMADIMINUI,

                          MOVITEMAGRO.QUANTIDADE,

                          MOVITEMAGRO.DOC,

                          MOVITEMAGRO.NATUREZA,

                          MOVITEMAGRO.ORIGEM,

                          MOVITEMAGRO.CHAVE

                     FROM MOVITEMAGRO

                    WHERE MOVITEMAGRO.ESTAB       = pEstab

                      AND MOVITEMAGRO.ITEM        = pItem

                      AND MOVITEMAGRO.CODIGOSALDO = rCod.CODIGOSALDO

                      AND MOVITEMAGRO.DATAMOVIM  >= dMesIni

                      AND (nPorEstab > 0 OR MOVITEMAGRO.LOCAL = pLocal)

                    ORDER BY MOVITEMAGRO.DATAMOVIM,

                             MOVITEMAGRO.ORDEM_CRONOLOGICA,

                             MOVITEMAGRO.SOMADIMINUI DESC)

      LOOP

        -- 'S' soma no estoque; qualquer outro valor ('D') diminui

        IF (rMov.SOMADIMINUI = 'S') THEN

          nQtd := NVL(rMov.QUANTIDADE, 0);

        ELSE

          nQtd := -NVL(rMov.QUANTIDADE, 0);

        END IF;



        nSaldoCom := nSaldoCom + nQtd;



        IF NOT (    TRIM(rMov.ORIGEM)   = 'NFI'

                AND TRIM(rMov.NATUREZA) = 'NF'

                AND aExcluidas.EXISTS(TRIM(rMov.CHAVE))) THEN

          nSaldoSem := nSaldoSem + nQtd;

        END IF;



        /* Bloqueia so se, num movimento posterior a nota, o saldo fica

           negativo SEM a nota e nao estava negativo COM ela. */

        IF (    nSaldoSem < -nTolerancia

            AND nSaldoCom >= -nTolerancia

            AND (   TRUNC(rMov.DATAMOVIM) > TRUNC(pDtEmissao)

                 OR (    TRUNC(rMov.DATAMOVIM) = TRUNC(pDtEmissao)

                     AND (pHora IS NULL OR rMov.HORAMOVIM >= pHora)))) THEN

          RAISE_APPLICATION_ERROR(-20901,

            'Nao e permitido excluir a nota (seq. ' || pSeqNota ||

            ', estab ' || pEstab || '): o item ' || pItem ||

            ' ficaria com saldo ' ||

            TRIM(TO_CHAR(nSaldoSem, 'FM999999999990.0000')) ||

            ' no codigo de saldo ' || rCod.CODIGOSALDO ||

            CASE WHEN nPorEstab > 0 THEN ' (estabelecimento)'

                 ELSE ', local ' || pLocal END ||

            ' em ' || TO_CHAR(rMov.DATAMOVIM, 'DD/MM/YYYY') ||

            ', por causa do movimento posterior ' || TRIM(rMov.NATUREZA) ||

            ' ' || TRIM(NVL(rMov.DOC, '')) || '.');

        END IF;

      END LOOP;

    END LOOP;

  END Validar;



  BEFORE EACH ROW IS

  BEGIN

    -- Registra a linha antes de validar: entra no recalculo desta e das proximas

    aExcluidas(:OLD.SEQNOTA || ':' || :OLD.SEQNOTAITEM) := TRUE;



    IF (NVL(SYS_CONTEXT('USERENV', 'CLIENT_INFO'), '-') <> 'LIBERA_EXC_NF_SALDONEG') THEN

      Validar(:OLD.ESTAB, :OLD.SEQNOTA, :OLD.ITEM, :OLD.LOCAL, :OLD.DTEMISSAO, :OLD.HORA);

    END IF;

  END BEFORE EACH ROW;



END NFITEM_BD_SALDONEG;