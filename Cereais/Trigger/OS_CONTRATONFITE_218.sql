CREATE OR REPLACE TRIGGER OS_CONTRATONFITE_218
BEFORE INSERT ON CONTRATONFITE
FOR EACH ROW
DECLARE
    TYPE t_log IS RECORD (
        new_estab NUMBER, new_contrato NUMBER, new_seqitem NUMBER,
        new_estabnota NUMBER, new_seqnota NUMBER, new_seqnotaitem NUMBER,
        estab218 NUMBER, seqnota218 NUMBER,
        estab_ctr218 NUMBER, contrato218 NUMBER, contratoo NUMBER,
        ins_estab NUMBER, ins_contrato NUMBER, ins_seqitem NUMBER,
        ins_estabnota NUMBER, ins_seqnota NUMBER, ins_seqnotaitem NUMBER,
        ins_quantidade NUMBER, ins_valor NUMBER, ins_tipobaixa VARCHAR2(1),
        ins_tipoagiocf NUMBER, ins_agiocf NUMBER, ins_desagiocf NUMBER
    );
    l              t_log;

    v_notaconf     NUMBER;
    v_numerocm     NUMBER;
    v_seqitem_o    NUMBER;
    v_seqnotaitem  NUMBER;
    v_qtd          NUMBER;
    v_valor        NUMBER;
    v_existe       NUMBER;

    e_ignora EXCEPTION;   -- sai sem erro (já logado, ou fora da regra)

    /* MODO TESTE: só processa quando o NUMEROCM (pessoa) da nota 217, em
       NFCAB, for o valor abaixo. NULL = sem filtro. VOLTAR PARA NULL APÓS
       O TESTE. */
    v_numerocm_teste NUMBER := 44;

    /* Log na MESMA transação do ERP (some junto se o ERP desfizer a baixa).
       Falha ao gravar o log nunca bloqueia o ERP. */
    PROCEDURE pr_log (p_status VARCHAR2, p_msg VARCHAR2) IS
    BEGIN
        INSERT INTO U_LOG_CONTRATONFITE_218 (
            STATUS,
            NEW_ESTAB, NEW_CONTRATO, NEW_SEQITEM,
            NEW_ESTABNOTA, NEW_SEQNOTA, NEW_SEQNOTAITEM,
            ESTAB218, SEQNOTA218, ESTAB_CTR218, CONTRATO218, CONTRATOO,
            INS_ESTAB, INS_CONTRATO, INS_SEQITEM,
            INS_ESTABNOTA, INS_SEQNOTA, INS_SEQNOTAITEM,
            INS_QUANTIDADE, INS_VALOR, INS_TIPOBAIXA,
            INS_TIPOAGIOCF, INS_AGIOCF, INS_DESAGIOCF,
            MENSAGEM
        ) VALUES (
            p_status,
            l.new_estab, l.new_contrato, l.new_seqitem,
            l.new_estabnota, l.new_seqnota, l.new_seqnotaitem,
            l.estab218, l.seqnota218, l.estab_ctr218, l.contrato218, l.contratoo,
            l.ins_estab, l.ins_contrato, l.ins_seqitem,
            l.ins_estabnota, l.ins_seqnota, l.ins_seqnotaitem,
            l.ins_quantidade, l.ins_valor, l.ins_tipobaixa,
            l.ins_tipoagiocf, l.ins_agiocf, l.ins_desagiocf,
            SUBSTR(p_msg, 1, 4000)
        );
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END pr_log;

BEGIN
    l.new_estab       := :NEW.ESTAB;
    l.new_contrato    := :NEW.CONTRATO;
    l.new_seqitem     := :NEW.SEQITEM;
    l.new_estabnota   := :NEW.ESTABNOTA;
    l.new_seqnota     := :NEW.SEQNOTA;
    l.new_seqnotaitem := :NEW.SEQNOTAITEM;

    /* 1) a nota da baixa é de configuração 217? */
    BEGIN
        SELECT N.NOTACONF, N.NUMEROCM
          INTO v_notaconf, v_numerocm
          FROM NFCAB N
         WHERE N.ESTAB   = l.new_estabnota
           AND N.SEQNOTA = l.new_seqnota;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RAISE e_ignora;
    END;

    IF v_notaconf IS NULL OR v_notaconf <> 217 THEN
        RAISE e_ignora;
    END IF;

    /* MODO TESTE: filtro pela pessoa (NUMEROCM) da nota 217 */
    IF v_numerocm_teste IS NOT NULL
       AND NVL(v_numerocm, -1) <> v_numerocm_teste THEN
        RAISE e_ignora;
    END IF;

    /* a regra de mapeamento usa :NEW.ESTAB como ESTAB da nota */
    IF l.new_estab <> l.new_estabnota THEN
        pr_log('ERRO', 'ESTAB diferente de ESTABNOTA na baixa da nota 217; regra assume iguais.');
        RAISE e_ignora;
    END IF;

    /* par da nota 217 na configuração 218 (pessoa x filial por CNPJ) */
    BEGIN
        SELECT N8.ESTAB, N8.SEQNOTA
          INTO l.estab218, l.seqnota218
          FROM NFCAB N7
          JOIN CONTAMOV C7 ON C7.NUMEROCM = N7.NUMEROCM
          JOIN FILIAL   F7 ON F7.CNPJ     = C7.CNPJF
          JOIN NFCAB    N8 ON N8.ESTAB    = F7.ESTAB
                          AND N8.NOTA     = N7.NOTA
                          AND N8.NOTACONF = 218
          JOIN CONTAMOV C8 ON C8.NUMEROCM = N8.NUMEROCM
          JOIN FILIAL   F8 ON F8.CNPJ     = C8.CNPJF
                          AND F8.ESTAB    = N7.ESTAB
         WHERE N7.ESTAB   = l.new_estabnota
           AND N7.SEQNOTA = l.new_seqnota;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pr_log('IGNORADO', 'Par 218 nao encontrado para a nota 217.');
            RAISE e_ignora;
        WHEN TOO_MANY_ROWS THEN
            pr_log('ERRO', 'Mais de uma nota 218 encontrada para o par.');
            RAISE e_ignora;
    END;

    /* 2) contrato baixado pela nota 218 (uma única linha) */
    BEGIN
        SELECT X.ESTAB, X.CONTRATO, X.SEQITEM
          INTO l.estab_ctr218, l.contrato218, v_seqitem_o
          FROM (SELECT C.ESTAB, C.CONTRATO, C.SEQITEM
                  FROM CONTRATONFITE C
                 WHERE C.ESTABNOTA = l.estab218
                   AND C.SEQNOTA   = l.seqnota218
                 ORDER BY C.SEQITEM, C.SEQNOTAITEM) X
         WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pr_log('IGNORADO', 'Nota 218 sem baixa em CONTRATONFITE.');
            RAISE e_ignora;
    END;

    /* 3) contrato de origem (U_LOGCTR: destino -> origem) */
    BEGIN
        SELECT L2.CONTRATOO
          INTO l.contratoo
          FROM U_LOGCTR L2
         WHERE L2.ESTABD    = l.estab_ctr218
           AND L2.CONTRATOD = l.contrato218;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pr_log('IGNORADO', 'Contrato da nota 218 nao consta em U_LOGCTR (nao e espelho).');
            RAISE e_ignora;
    END;

    /* baixa já está no contrato de origem: nada a fazer (silencioso; também
       é o caminho da linha inserida por esta própria trigger) */
    IF l.new_contrato = l.contratoo THEN
        RAISE e_ignora;
    END IF;

    /* 4) item da própria nota 217 (NFITEM) */
    SELECT NI.SEQNOTAITEM, NI.QUANTIDADE, NI.VALORTOTAL
      INTO v_seqnotaitem, v_qtd, v_valor
      FROM NFITEM NI
     WHERE NI.ESTAB       = l.new_estab
       AND NI.SEQNOTA     = l.new_seqnota
       AND NI.SEQNOTAITEM = l.new_seqnotaitem;

    /* linha a inserir no contrato de origem */
    l.ins_estab       := l.new_estab;
    l.ins_contrato    := l.contratoo;
    l.ins_seqitem     := v_seqitem_o;
    l.ins_estabnota   := l.new_estab;
    l.ins_seqnota     := l.new_seqnota;
    l.ins_seqnotaitem := v_seqnotaitem;
    l.ins_quantidade  := v_qtd;
    l.ins_valor       := v_valor;
    l.ins_tipobaixa   := 'A';
    l.ins_tipoagiocf  := 0;
    l.ins_agiocf      := 0;
    l.ins_desagiocf   := 0;

    INSERT INTO CONTRATONFITE (
        ESTAB, CONTRATO, SEQITEM,
        ESTABNOTA, SEQNOTA, SEQNOTAITEM,
        QUANTIDADE, VALOR,
        TIPOBAIXA, TIPOAGIOCF, AGIOCF, DESAGIOCF
    ) VALUES (
        l.ins_estab, l.ins_contrato, l.ins_seqitem,
        l.ins_estabnota, l.ins_seqnota, l.ins_seqnotaitem,
        l.ins_quantidade, l.ins_valor,
        l.ins_tipobaixa, l.ins_tipoagiocf, l.ins_agiocf, l.ins_desagiocf
    );

    pr_log('OK', 'Baixa inserida no contrato de origem.');

EXCEPTION
    WHEN e_ignora THEN
        NULL;
    WHEN DUP_VAL_ON_INDEX THEN
        pr_log('IGNORADO', 'Baixa ja existe no contrato de origem.');
    WHEN OTHERS THEN
        pr_log('ERRO', SQLERRM || ' | ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END OS_CONTRATONFITE_218;