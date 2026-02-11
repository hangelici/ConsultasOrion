create or replace TRIGGER OS_INSERECTR
BEFORE INSERT OR UPDATE ON CONTRATO FOR EACH ROW
DECLARE
CONTRATOD NUMBER;
u_logctr_id NUMBER;
ESTABD number;
CONTCONFO number;
GERADO varchar2(10);
PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

  IF INSERTING THEN
   --SELECT MAX(CONTRATO)+1 INTO CONTRATOD FROM CONTRATO WHERE ESTAB=:NEW.NUMEROCM;     
   IF (:NEW.CONTCONF = 6 AND :NEW.ESTAB IN (12,26,31,30) ) THEN
   SELECT (ID_INT)+1 INTO CONTRATOD from seqprimarykey where tabela='CONTRATO'AND SUBSTR(CHAVEVALOR,7,4)=:NEW.NUMEROCM; 
   --SELECT MAX(u_logctr_id)+1 INTO u_logctr_id FROM u_logctr;  
   :NEW.PRIORIDADE := 3;
   INSERT INTO CONTRATO(contrato.estab,contrato.contrato,contrato.contconf,contrato.numerocm,contrato.numerocmadic,contrato.dtemissao,contrato.dtvencto,contrato.userid,
   contrato.safra,contrato.valortotal,contrato.moeda,contrato.tipofrete,contrato.associado,contrato.sexo,contrato.consfinal,contrato.prioridade,
   contrato.padrao,contrato.saldovalor,contrato.numcomprador,contrato.ativo,contrato.datalimiteent,contrato.datalimiteliq,contrato.moedadia,
   contrato.dtmovsaldo,contrato.dtlimentimp,contrato.dtlimliqimp,contrato.dtcotacao,contrato.cencuscod,contrato.tiporateio)
   VALUES(:NEW.NUMEROCM,CONTRATOD,24,:NEW.ESTAB,:NEW.ESTAB,:new.dtemissao,:new.dtvencto,:new.userid,
   :new.safra,:new.valortotal,:new.moeda,:new.tipofrete,:new.associado,:new.sexo,:new.consfinal,:NEW.PRIORIDADE,
   :new.padrao,:new.saldovalor,:new.numempresa,:new.ativo,:new.datalimiteent,:new.datalimiteliq,:new.moedadia,
   :new.dtmovsaldo,:new.dtlimentimp,:new.dtlimliqimp,:new.dtcotacao,:new.cencuscod,0);
   COMMIT;
   INSERT INTO U_CONTRATO(U_CONTRATO_ID, ESTABCOMPRA, CONTRATOCOMPRA, ESTABVENDA, CONTRATOVENDA)                              --PER2572
   VALUES((SELECT COALESCE(MAX(U_CONTRATO_ID), 0) + 1 FROM U_CONTRATO), :NEW.ESTAB, :NEW.CONTRATO, :NEW.NUMEROCM, CONTRATOD); --PER2572                     
   COMMIT;                                                                                                                    --PER2572

   INSERT INTO U_LOGCTR (u_logctr_id,U_LOGCTR.ESTABO,U_LOGCTR.CONTCONFO,U_LOGCTR.CONTRATOO,u_logctr.estabD,u_logctr.CONTCONFD,u_logctr.CONTRATOD,GERADO)
   VALUES (OS_GEN_LOGCTR_ID.NEXTVAL,:NEW.ESTAB,:NEW.CONTCONF,:NEW.CONTRATO,:NEW.NUMEROCM,24,CONTRATOD,'N');
   COMMIT;

   INSERT INTO CONTRATOESTAB (ESTAB,CONTRATO,ESTABBX)
   VALUES (:NEW.NUMEROCM,CONTRATOD,:NEW.NUMEROCM);
   COMMIT;

  /* INSERT INTO CONTRATOROMCFG (ESTAB,CONTRATO,SEQUENCIA,ROMANEIOCONFIG,PADRAO)
   VALUES (:NEW.NUMEROCM,CONTRATOD,1,82,1);
   COMMIT;*/
   INSERT INTO contratodtvencto (estab,contrato,sequencia,dtvencto,qtdfluxocx,numdiaspagto)
   VALUES (:NEW.NUMEROCM,CONTRATOD,1,:new.dtvencto,0,0);
   COMMIT;

   INSERT INTO CONTRATO_U (ESTAB,CONTRATO,STATUSASS,statusaprov,OBS,tipofretes,tipoentrega,tipopgto,tipopessoa,dtinicioent,qtrigo,statusasse,statusfat,dtemissaoori,contrato_edit)   
   VALUES (:NEW.NUMEROCM,CONTRATOD,'Pendente','2 - Aprovado','Contrato Automático Do Estab: '||:NEW.ESTAB|| ' Contrato Origem: '||:NEW.CONTRATO,'AJUSTE','AJUSTE','AJUSTE','AJUSTE',
   :new.dtmovsaldo,'Sem_Padrao','N','0 - A Faturar',:new.dtemissao, 'N');    
   COMMIT;
   END IF;
   IF CONTRATOD IS NOT NULL THEN
   UPDATE seqprimarykey SET seqprimarykey.id_int= CONTRATOD
   where tabela='CONTRATO'AND SUBSTR(CHAVEVALOR,7,4)=:NEW.NUMEROCM; 
   COMMIT;
   END IF;
   END IF;
   IF UPDATING THEN
   SELECT ESTABD,CONTRATOD,CONTCONFO,GERADO INTO ESTABD,CONTRATOD,CONTCONFO,GERADO FROM u_logctr
                                                                            WHERE u_logctr.estabo = :NEW.ESTAB
                                                                            AND u_logctr.contratoo=:NEW.CONTRATO;   
   IF (:NEW.CONTCONF = 6 AND :NEW.ESTAB IN (12,26,31,30) AND GERADO='S') THEN
   UPDATE CONTRATO SET CONTRATO.DTMOVSALDO =:NEW.DTMOVSALDO WHERE CONTRATO.ESTAB=ESTABD AND CONTRATO.CONTRATO=CONTRATOD;
   COMMIT;
   END IF;
   END IF;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
    NULL;
END;