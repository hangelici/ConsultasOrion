create or replace TRIGGER "VIASOFT"."OS_NFITEMTRIGO " 
BEFORE INSERT OR UPDATE
ON VIASOFT.NFITEM FOR EACH ROW
DECLARE
TIPO VARCHAR(2);
TIPONF VARCHAR(2);
BEGIN

    
          IF :NEW.CONTRATO IS NOT NULL THEN
          
             SELECT TIPO INTO TIPONF FROM U_TIPOTRIGO
           WHERE U_TIPOTRIGO.ESTAB=:NEW.ESTABORIGEM
           AND U_TIPOTRIGO.SEQNOTA=:NEW.SEQNOTAORIGEM
           AND U_TIPOTRIGO.SEQNOTAITEM=:NEW.SEQNOTAITEMORIGEM
           ORDER BY U_TIPOTRIGO_ID DESC -- pode ter mais de um registro,em razoa de alteracao, entao tem que pegar o ultimo
           FETCH FIRST 1 ROW ONLY -- pode ter mais de um registro,em razoa de alteracao, entao tem que pegar o ultimo
           ;

              SELECT CASE  WHEN contrato_u.qtrigo = 'Sem_Padrao' Then 99
                          WHEN contrato_u.qtrigo = 'Tipo_1' Then 1 
                          WHEN contrato_u.qtrigo = 'Tipo_2' then 2 
                          WHEN contrato_u.qtrigo = 'Tipo_3' then 3 
                          else 4 end Tipo into TIPO FROM CONTRATO_U 
                          WHERE CONTRATO_U.ESTAB=:NEW.ESTABCONTRATO AND CONTRATO_U.CONTRATO=:NEW.CONTRATO;

            IF :NEW.ITEM = 2 AND (TIPONF <> TIPO) THEN                              
                            RAISE_APPLICATION_ERROR (-20000, 'Qualidade do Trigo Diferente do Contrato! '||
                            'Solução: Entre em contato com o Gerente dos Cereais ');
            END IF; 
            END IF;
            IF :NEW.CONTRATO IS NULL THEN
            
               SELECT TIPO INTO TIPONF FROM U_TIPOTRIGO
           WHERE U_TIPOTRIGO.ESTAB=:NEW.ESTAB
           AND U_TIPOTRIGO.SEQNOTA=:NEW.SEQNOTA
           AND U_TIPOTRIGO.SEQNOTAITEM=:NEW.SEQNOTAITEM
           ORDER BY U_TIPOTRIGO_ID DESC
           FETCH FIRST 1 ROW ONLY
           ;
            
              IF :NEW.ITEM = 2 AND (TIPONF <> :NEW.FINATIPOROMA) THEN                              
                            RAISE_APPLICATION_ERROR (-20000, 'Qualidade do Trigo Diferente da Nota de Origem! '||
                            'Solução: Entre em contato com o Gerente dos Cereais ');
         END IF;
         END IF;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
        NULL;


END;
