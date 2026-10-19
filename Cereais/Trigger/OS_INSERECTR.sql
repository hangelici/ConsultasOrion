create or replace TRIGGER OS_INSERECTR
BEFORE INSERT OR UPDATE ON CONTRATO
FOR EACH ROW

DECLARE

    CONTRATOD NUMBER;
    u_logctr_id NUMBER;
    ESTABD NUMBER;
    CONTCONFO NUMBER;
    GERADO VARCHAR2(10);
    V_VALIDA_ESTAB NUMBER := 0;
    V_ESTAB NUMBER;

    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

    IF INSERTING THEN

        IF (:NEW.CONTCONF = 6) THEN

            BEGIN

                SELECT 1
                INTO V_VALIDA_ESTAB
                FROM U_TEMPRESA
                WHERE U_TEMPRESA.ESTAB = :NEW.ESTAB
                AND U_TEMPRESA.GRAOS = 'S'
                AND U_TEMPRESA.EXVENDA = 'S';

            EXCEPTION

                WHEN NO_DATA_FOUND THEN
                    V_VALIDA_ESTAB := 0;

            END;


            IF V_VALIDA_ESTAB = 1 THEN

                BEGIN -- ticket 1363844

                    SELECT ESTAB_COPIA
                    INTO V_ESTAB
                    FROM U_CONTRATOCOPIA
                    WHERE U_CONTRATOCOPIA.ESTAB = :NEW.ESTAB
                    AND U_CONTRATOCOPIA.CONTRATO = :NEW.CONTRATO;

                EXCEPTION

                    WHEN NO_DATA_FOUND THEN
                        V_ESTAB := :NEW.NUMEROCM;

                END;


                IF V_ESTAB IS NULL THEN
                    /* ESTAB da filial cujo CNPJ é o CNPJF da pessoa (CONTAMOV) do contrato */
                    BEGIN
                        SELECT F.ESTAB
                        INTO V_ESTAB
                        FROM CONTAMOV C
                        INNER JOIN FILIAL F ON F.CNPJ = C.CNPJF
                        WHERE C.NUMEROCM = :NEW.NUMEROCM;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            V_ESTAB := NULL;  -- sem filial para esse CNPJ: o contrato espelho não é criado
                    END;
                END IF;


                SELECT (ID_INT) + 1
                INTO CONTRATOD
                FROM SEQPRIMARYKEY
                WHERE TABELA = 'CONTRATO'
                AND SUBSTR(CHAVEVALOR, 7, 4) = V_ESTAB;


                :NEW.PRIORIDADE := 3;


                INSERT INTO CONTRATO
                (
                    CONTRATO.ESTAB,
                    CONTRATO.CONTRATO,
                    CONTRATO.CONTCONF,
                    CONTRATO.NUMEROCM,
                    CONTRATO.NUMEROCMADIC,
                    CONTRATO.DTEMISSAO,
                    CONTRATO.DTVENCTO,
                    CONTRATO.USERID,
                    CONTRATO.SAFRA,
                    CONTRATO.VALORTOTAL,
                    CONTRATO.MOEDA,
                    CONTRATO.TIPOFRETE,
                    CONTRATO.ASSOCIADO,
                    CONTRATO.SEXO,
                    CONTRATO.CONSFINAL,
                    CONTRATO.PRIORIDADE,
                    CONTRATO.PADRAO,
                    CONTRATO.SALDOVALOR,
                    CONTRATO.NUMCOMPRADOR,
                    CONTRATO.ATIVO,
                    CONTRATO.DATALIMITEENT,
                    CONTRATO.DATALIMITELIQ,
                    CONTRATO.MOEDADIA,
                    CONTRATO.DTMOVSALDO,
                    CONTRATO.DTLIMENTIMP,
                    CONTRATO.DTLIMLIQIMP,
                    CONTRATO.DTCOTACAO,
                    CONTRATO.CENCUSCOD,
                    CONTRATO.TIPORATEIO
                )
                VALUES
                (
                    V_ESTAB,
                    CONTRATOD,
                    24,
                    :NEW.ESTAB,
                    :NEW.ESTAB,
                    :NEW.DTEMISSAO,
                    :NEW.DTVENCTO,
                    :NEW.USERID,
                    :NEW.SAFRA,
                    :NEW.VALORTOTAL,
                    :NEW.MOEDA,
                    :NEW.TIPOFRETE,

                    /* CORRECAO:
                       Não copiar :NEW.ASSOCIADO.
                       O contrato destino deve ser criado com ASSOCIADO NULL.
                    */
                    NULL,

                    :NEW.SEXO,
                    :NEW.CONSFINAL,
                    :NEW.PRIORIDADE,
                    :NEW.PADRAO,
                    :NEW.SALDOVALOR,
                    :NEW.NUMEMPRESA,
                    :NEW.ATIVO,
                    :NEW.DATALIMITEENT,
                    :NEW.DATALIMITELIQ,
                    :NEW.MOEDADIA,
                    :NEW.DTMOVSALDO,
                    :NEW.DTLIMENTIMP,
                    :NEW.DTLIMLIQIMP,
                    :NEW.DTCOTACAO,
                    :NEW.CENCUSCOD,
                    0
                );

                COMMIT;


                /*
                ============================================================
                NOVO PROCESSO
                Inclusão automática da ressalva para o contrato CONTCONF 24
                ============================================================
                */

                INSERT INTO U_RESSALVACONTRATO
                (
                    ESTAB,
                    CONTRATO,
                    STATUS,
                    IDTROCABARTER,
                    TEXTO,
                    DTINCLUSAO,
                    DTCONCLUSAO
                )
                VALUES
                (
                    V_ESTAB,
                    CONTRATOD,
                    'PENDENTE',
                    NULL,
                    'INSERIDO ATRAVÉS DE GATILHO',
                    SYSDATE,
                    NULL
                );

                COMMIT;


                INSERT INTO U_CONTRATO
                (
                    U_CONTRATO_ID,
                    ESTABCOMPRA,
                    CONTRATOCOMPRA,
                    ESTABVENDA,
                    CONTRATOVENDA
                )
                VALUES
                (
                    (
                        SELECT COALESCE(MAX(U_CONTRATO_ID), 0) + 1
                        FROM U_CONTRATO
                    ),
                    :NEW.ESTAB,
                    :NEW.CONTRATO,
                    V_ESTAB,
                    CONTRATOD
                );

                COMMIT;


                INSERT INTO U_LOGCTR
                (
                    U_LOGCTR_ID,
                    U_LOGCTR.ESTABO,
                    U_LOGCTR.CONTCONFO,
                    U_LOGCTR.CONTRATOO,
                    U_LOGCTR.ESTABD,
                    U_LOGCTR.CONTCONFD,
                    U_LOGCTR.CONTRATOD,
                    GERADO
                )
                VALUES
                (
                    OS_GEN_LOGCTR_ID.NEXTVAL,
                    :NEW.ESTAB,
                    :NEW.CONTCONF,
                    :NEW.CONTRATO,
                    V_ESTAB,
                    24,
                    CONTRATOD,
                    'N'
                );

                COMMIT;


                INSERT INTO CONTRATOESTAB
                (
                    ESTAB,
                    CONTRATO,
                    ESTABBX
                )
                VALUES
                (
                    V_ESTAB,
                    CONTRATOD,
                    V_ESTAB
                );

                COMMIT;


                /*
                INSERT INTO CONTRATOROMCFG
                (
                    ESTAB,
                    CONTRATO,
                    SEQUENCIA,
                    ROMANEIOCONFIG,
                    PADRAO
                )
                VALUES
                (
                    :NEW.NUMEROCM,
                    CONTRATOD,
                    1,
                    82,
                    1
                );

                COMMIT;
                */


                INSERT INTO CONTRATODTVENCTO
                (
                    ESTAB,
                    CONTRATO,
                    SEQUENCIA,
                    DTVENCTO,
                    QTDFLUXOCX,
                    NUMDIASPAGTO
                )
                VALUES
                (
                    V_ESTAB,
                    CONTRATOD,
                    1,
                    :NEW.DTVENCTO,
                    0,
                    0
                );

                COMMIT;


                INSERT INTO CONTRATO_U
                (
                    ESTAB,
                    CONTRATO,
                    STATUSASS,
                    STATUSAPROV,
                    OBS,
                    TIPOFRETES,
                    TIPOENTREGA,
                    TIPOPGTO,
                    TIPOPESSOA,
                    DTINICIOENT,
                    QTRIGO,
                    STATUSASSE,
                    STATUSFAT,
                    DTEMISSAOORI,
                    CONTRATO_EDIT
                )
                VALUES
                (
                    V_ESTAB,
                    CONTRATOD,
                    'Pendente',
                    '2 - Aprovado',
                    'Contrato Automático Do Estab: ' ||
                    :NEW.ESTAB ||
                    ' Contrato Origem: ' ||
                    :NEW.CONTRATO,
                    'AJUSTE',
                    'AJUSTE',
                    'AJUSTE',
                    'AJUSTE',
                    :NEW.DTMOVSALDO,
                    'Sem_Padrao',
                    'N',
                    '0 - A Faturar',
                    :NEW.DTEMISSAO,
                    'N'
                );

                COMMIT;

            END IF;

        END IF;


        IF CONTRATOD IS NOT NULL THEN

            UPDATE SEQPRIMARYKEY
            SET SEQPRIMARYKEY.ID_INT = CONTRATOD
            WHERE TABELA = 'CONTRATO'
            AND SUBSTR(CHAVEVALOR, 7, 4) = V_ESTAB;

            COMMIT;

        END IF;

    END IF;


    IF UPDATING THEN

        SELECT
            ESTABD,
            CONTRATOD,
            CONTCONFO,
            GERADO
        INTO
            ESTABD,
            CONTRATOD,
            CONTCONFO,
            GERADO
        FROM U_LOGCTR
        WHERE U_LOGCTR.ESTABO = :NEW.ESTAB
        AND U_LOGCTR.CONTRATOO = :NEW.CONTRATO;


        IF (:NEW.CONTCONF = 6 AND GERADO = 'S') THEN

            BEGIN

                SELECT 1
                INTO V_VALIDA_ESTAB
                FROM U_TEMPRESA
                WHERE U_TEMPRESA.ESTAB = :NEW.ESTAB
                AND U_TEMPRESA.GRAOS = 'S'
                AND U_TEMPRESA.EXVENDA = 'S';

            EXCEPTION

                WHEN NO_DATA_FOUND THEN
                    V_VALIDA_ESTAB := 0;

            END;


            IF V_VALIDA_ESTAB = 1 THEN

                UPDATE CONTRATO
                SET CONTRATO.DTMOVSALDO = :NEW.DTMOVSALDO
                WHERE CONTRATO.ESTAB = ESTABD
                AND CONTRATO.CONTRATO = CONTRATOD;

                COMMIT;

            END IF;

        END IF;

    END IF;


EXCEPTION

    WHEN NO_DATA_FOUND THEN
        NULL;

END;