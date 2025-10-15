create or replace TRIGGER "VIASOFT"."OS_TIPTRIGO " 
BEFORE INSERT 
ON VIASOFT.NFITEM FOR EACH ROW
DECLARE
TIPO INT;
CLIENTE INT;

BEGIN
            IF :NEW.ITEM=2 AND :NEW.ROMANEIO IS NOT NULL then
            
            SELECT NUMEROCM INTO CLIENTE FROM NFCAB
            WHERE NFCAB.SEQNOTA = :NEW.SEQNOTA
            AND   NFCAB.ESTAB = :NEW.ESTAB;
            
            SELECT TIPO INTO TIPO FROM ROMA 
           
            WHERE ROMA.ESTAB=:NEW.ESTAB
                AND ROMA.ROMANEIO=:NEW.ROMANEIO
                AND ROMA.NUMEROCM=CLIENTE;
                           
            IF TIPO IS NOT NULL THEN
            INSERT INTO u_tipotrigo (u_tipotrigo_id,estab,seqnota,seqnotaitem,tipo,romaneio)
            VALUES (OS_GEN_IDTIPTRIGO.nextval,:NEW.ESTAB,:NEW.SEQNOTA,:NEW.SEQNOTAITEM,COALESCE(TIPO,99),:NEW.ROMANEIO);  
            END IF; 
            
            IF TIPO IS NULL THEN 
            INSERT INTO u_tipotrigo (u_tipotrigo_id,estab,seqnota,seqnotaitem,tipo,romaneio)
            VALUES (OS_GEN_IDTIPTRIGO.nextval,:NEW.ESTAB,:NEW.SEQNOTA,:NEW.SEQNOTAITEM,COALESCE(:NEW.FINATIPOROMA,99),:NEW.ROMANEIO);  
            END IF; 
            END IF;

           EXCEPTION
           WHEN NO_DATA_FOUND THEN
        NULL;


END;
