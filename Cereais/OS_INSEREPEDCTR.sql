create or replace TRIGGER VIASOFT.OS_INSEREPEDCTR
BEFORE INSERT OR UPDATE ON VIASOFT.PEDCAB FOR EACH ROW
DECLARE
CONTRATOD NUMBER;
ESTABD number;
CONTCONFO number;
GERADON varchar2(10);
MARGENMINIMA NUMBER;
item number;
quantidade NUMBER;
valor NUMBER;
valorunitario NUMBER;
PEDLOCAL NUMBER; 
CONTRATOCONF NUMBER;
prazopagamento DATE;
TIPOFRETES VARCHAR2(40);
TIPOENTREGA VARCHAR2(40);
TIPOPGTO VARCHAR2(40);
TIPOPESSOA VARCHAR2(40);
QTRIGO VARCHAR2(40);
CORRETOR1 NUMBER;
CORRETOR2 NUMBER;
VLRCORRETOR1 NUMBER;
VLRCORRETOR2 NUMBER;
NRTICKET VARCHAR2(40);
P_ATIVO VARCHAR2(1);
PERCENTUAL1 NUMBER;
PERCENTUAL2 NUMBER;
TIPO VARCHAR2(1);
P_INSECAOTAXA CHAR(1);
P_VALOR NUMBER;
P_UNIDADE VARCHAR2(2);
P_NUMDIASPGTO NUMBER;
P_ESTABORIGEM NUMBER;
V_MULTIPLIC NUMBER ;
v_item NUMBER;
v_seqitem number ;
v_moeda number ;
v_moeda_data varchar2(3) ;
v_prazo DATE;
v_regiao varchar2(100);

BEGIN

   IF UPDATING THEN

   IF :NEW.PEDIDOCONF IN (200,201,202,204)  AND :NEW.ETAPA > 3 AND :NEW.PODEFATURAR='S' AND :NEW.STATUS='N' AND :NEW.PROCURADOR IS NULL THEN
   
   --SELECT MAX(CONTRATO)+1 INTO CONTRATOD FROM CONTRATO WHERE ESTAB=:NEW.ESTAB;
   SELECT (ID_INT)+1 INTO CONTRATOD from seqprimarykey where tabela='CONTRATO'AND SUBSTR(CHAVEVALOR,7,4)=:NEW.ESTAB; 
   CONTRATOCONF := CASE WHEN :NEW.PEDIDOCONF = 200 THEN 1 WHEN :NEW.PEDIDOCONF = 204 THEN 7 WHEN :NEW.PEDIDOCONF = 202 THEN 50 ELSE 2 END;
   
    SELECT 
        CASE 
            WHEN (FORMAPGTO IN (24,22,20,21) AND (PRAZOPAGAMENTO > CURRENT_DATE)) THEN PRAZOPAGAMENTO
            ELSE CURRENT_DATE 
        END INTO PRAZOPAGAMENTO 
    FROM PEDCABPGTO WHERE PEDCABPGTO.ESTAB=:NEW.ESTAB AND PEDCABPGTO.SERIE=:NEW.SERIE AND PEDCABPGTO.NUMERO=:NEW.NUMERO;
 
 --  SELECT CASE WHEN (FORMAPGTO IN (24,22,20) and (prazopagamento <= current_date + 2)) THEN current_date ELSE prazopagamento end into prazopagamento FROM pedcabpgto where pedcabpgto.estab=:NEW.ESTAB AND pedcabpgto.SERIE=:NEW.SERIE AND pedcabpgto.NUMERO=:NEW.NUMERO;
  
  BEGIN
   SELECT NUMDIASPAGTO INTO P_NUMDIASPGTO FROM PEDCABDTPAGTO where PEDCABDTPAGTO.estab=:NEW.ESTAB AND PEDCABDTPAGTO.SERIE=:NEW.SERIE AND PEDCABDTPAGTO.NUMERO=:NEW.NUMERO;
   EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
         P_NUMDIASPGTO := NULL; 
   END;
    
   select peditem.item,peditem.quantidade,peditem.valor,peditem.valorunitario,local INTO ITEM,quantidade,valor,valorunitario,pedlocal  
   from peditem where peditem.estab=:NEW.ESTAB and peditem.serie=:NEW.SERIE and peditem.numero=:NEW.NUMERO; 
   
   select peditem.item into v_item from peditem where peditem.estab=:NEW.ESTAB and peditem.serie=:NEW.SERIE and peditem.numero=:NEW.NUMERO; 
   
   v_moeda := NVL(:NEW.MOEDA, 0);
   
   v_moeda_data := CASE WHEN V_MOEDA = 2 THEN 'B' ELSE NULL END ;
   
   select contratocfgite.seqitem into v_seqitem from contratocfgite 
   where contratocfgite.contconf = (CASE WHEN :NEW.PEDIDOCONF = 200 THEN 1 WHEN :NEW.PEDIDOCONF = 204 THEN 7 WHEN :NEW.PEDIDOCONF = 202 THEN 50 ELSE 2 END)
   and contratocfgite.item = v_item
   ;
   
   BEGIN
        SELECT MULTIPLIC 
          INTO V_MULTIPLIC 
          FROM ITEMPREMB 
         WHERE ITEMPREMB.ESTAB = :NEW.ESTAB AND ITEMPREMB.ITEM = v_item;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_MULTIPLIC := 60;
      END;

   select  TIPOFRETES,TIPOENTREGA,TIPOPGTO,TIPOPESSOA,COALESCE(QTRIGO,'Sem_Padrao'),CORRETOR1,CORRETOR2,VLRCORRETOR1,VLRCORRETOR2,NRTICKET,COALESCE(DOCPENDENTE,'N')
   AS DOCPENDENTE,PERCENTUAL1,PERCENTUAL2, INSECAOTAXA,ESTABORIGEM,DTVECTOORIGEM,REGIAO
    INTO TIPOFRETES,TIPOENTREGA,TIPOPGTO,TIPOPESSOA,QTRIGO,CORRETOR1,CORRETOR2,VLRCORRETOR1,VLRCORRETOR2,NRTICKET,P_ATIVO,PERCENTUAL1,PERCENTUAL2, P_INSECAOTAXA,P_ESTABORIGEM,v_prazo,v_regiao from pedcab_u
   where pedcab_u.estab=:NEW.ESTAB and pedcab_u.serie=:NEW.SERIE and pedcab_u.numero=:NEW.NUMERO; 
   
   INSERT INTO CONTRATO(contrato.estab,contrato.contrato,contrato.numintermediario,contrato.endalternativo,contrato.contconf,contrato.numerocm,contrato.numerocmadic,contrato.dtemissao,contrato.dtvencto,contrato.userid,
   contrato.safra,contrato.valorprod,contrato.valortotal,contrato.moeda,contrato.observacoes,contrato.prioridade,contrato.padrao,contrato.saldovalor,contrato.ativo,contrato.datalimiteent,contrato.datalimiteliq,
   contrato.dtmovsaldo,contrato.dtlimentimp,contrato.dtlimliqimp,contrato.dtcotacao,contrato.tiporateio,vlrfrete,moedadia)

   VALUES(:NEW.ESTAB,CONTRATOD,:NEW.NUMERO,:NEW.SEQENDERECO,CONTRATOCONF,:NEW.PESSOA,:NEW.PESSOA,to_date(CURRENT_DATE),COALESCE(v_prazo,prazopagamento),:new.userid,
   :new.safra,:new.VALORMERCADORIA,:new.VALORMERCADORIA,v_moeda,:NEW.OBS,1,'N',:new.valortotal,'A',:new.DTPREVISAO,:new.DTVALIDADE,
   :new.DTPREVISAO,:new.DTVALIDADE,:new.DTVALIDADE,to_date(CURRENT_DATE),0,:new.kmfrete,v_moeda_data);

   INSERT INTO CONTRATOITE (CONTRATOITE.ESTAB,CONTRATOITE.CONTRATO,CONTRATOITE.SEQITEM,CONTRATOITE.ITEM,CONTRATOITE.LOCAL,CONTRATOITE.DTEMISSAO,CONTRATOITE.QUANTIDADE,CONTRATOITE.VALORUNIT,
   CONTRATOITE.VALORTOTAL,CONTRATOITE.TIPOSALDO,CONTRATOITE.PRECOVENDA,CONTRATOITE.QUALCOTACAO,CONTRATOITE.DTMOVSALDO)
   VALUES (:NEW.ESTAB,CONTRATOD,v_seqitem/*ITEM*/,ITEM,PEDLOCAL,to_date(CURRENT_DATE),QUANTIDADE,ARREDONDAR((valorunitario*V_MULTIPLIC),6),ARREDONDAR((VALOR),2),'A','I','N',:new.DTPREVISAO);

   INSERT INTO CONTRATOESTAB (ESTAB,CONTRATO,ESTABBX)
   VALUES (:NEW.ESTAB,CONTRATOD,:NEW.ESTAB);
   
    IF :NEW.REPRESENT > 0 THEN
        -- Obtém a margem mínima ou define 0.05 caso seja NULL
        SELECT NVL(MARGENMINIMA, 0.05) 
        INTO MARGENMINIMA 
        FROM PREPRESE 
        WHERE PREPRESE.REPRESENT = :NEW.REPRESENT 
          AND EMPRESA = 1;
        
        -- Insere os dados com a margem correta
        INSERT INTO contratocom (estab, contrato, sequencia, numerocm, percentual, liberado, tipo, unidade) 
        VALUES (:NEW.ESTAB, CONTRATOD, 1, :NEW.REPRESENT, MARGENMINIMA, 'N', 'V', 'SC');
        
        INSERT INTO os_contratocom (estab, contrato, numerocm, seq, meta) 
        VALUES (:NEW.ESTAB, CONTRATOD, :NEW.REPRESENT, '1', '100');
    END IF;
   
   IF CORRETOR1 > 0 THEN
   TIPO := CASE WHEN VLRCORRETOR1 IS NULL OR VLRCORRETOR1 = 0 THEN 'P' ELSE 'V' END;
   P_UNIDADE := CASE WHEN VLRCORRETOR1 IS NULL OR VLRCORRETOR1 = 0 THEN NULL ELSE 'SC' END;
   P_VALOR := CASE WHEN VLRCORRETOR1 IS NULL OR VLRCORRETOR1 = 0 THEN PERCENTUAL1 ELSE VLRCORRETOR1 END;
   INSERT INTO contratocom (estab,contrato,sequencia,numerocm,percentual,liberado,tipo,unidade) 
   VALUES (:NEW.ESTAB,CONTRATOD,2,CORRETOR1,P_VALOR,'N',TIPO,P_UNIDADE);
   END IF;
   
   IF CORRETOR2 > 0 THEN
   TIPO := CASE WHEN VLRCORRETOR2 IS NULL OR VLRCORRETOR2 = 0 THEN 'P' ELSE 'V' END;
   P_UNIDADE := CASE WHEN VLRCORRETOR1 IS NULL OR VLRCORRETOR1 = 0 THEN NULL ELSE 'SC' END;
   P_VALOR := CASE WHEN VLRCORRETOR2 IS NULL OR VLRCORRETOR2 = 0 THEN PERCENTUAL2 ELSE VLRCORRETOR2 END;
   INSERT INTO contratocom (estab,contrato,sequencia,numerocm,percentual,liberado,tipo,unidade) 
   VALUES (:NEW.ESTAB,CONTRATOD,3,CORRETOR2,P_VALOR,'N',TIPO,P_UNIDADE);
   END IF;

   INSERT INTO contratodtvencto (estab,contrato,sequencia,dtvencto,qtdfluxocx,numdiaspagto)
   VALUES (:NEW.ESTAB,CONTRATOD,1,(CASE WHEN P_NUMDIASPGTO IS NULL THEN coalesce(v_prazo,prazopagamento) ELSE NULL END),ARREDONDAR((VALOR),2),P_NUMDIASPGTO);

   INSERT INTO CONTRATO_U (ESTAB,CONTRATO,STATUSASS,statusaprov,OBS,tipofretes,tipoentrega,tipopgto,tipopessoa,dtinicioent,qtrigo,statusasse,statusfat,dtemissaoori,contrato_edit,NRTICKET,INSECAOTAXA,ESTABORIGEM, ATIVO_OS,REGIAO)   
   VALUES (:NEW.ESTAB,CONTRATOD,'Pendente','0 - Em Análise','Contrato Automático Do Pedido: '||:NEW.NUMERO,
   TIPOFRETES,TIPOENTREGA,TIPOPGTO,TIPOPESSOA,
  -- 'AJUSTE','AJUSTE','AJUSTE','AJUSTE',
   :new.DTPREVISAO,
   QTRIGO,
   --'Sem_Padrao',
   'N','0 - A Faturar',to_date(CURRENT_DATE),'N',NRTICKET, P_INSECAOTAXA,P_ESTABORIGEM,
   (case when P_ATIVO = 'N' then 'A'  when P_ATIVO = null then 'I' when P_ATIVO = 'S' then 'I' else 'I' end),v_regiao);   

   INSERT INTO u_logpedctr ( u_logpedctr_id,estab,serie_ped,pedido,confctr,contrato,GERADO,EXCLUIR,NUMEROCM,QUANTIDADE) VALUES 
   (OS_GEN_LOGPEDCTR_ID.NEXTVAL,:NEW.ESTAB,:NEW.SERIE,:NEW.NUMERO,CONTRATOCONF,CONTRATOD,'S','N',:NEW.PESSOA,QUANTIDADE); 

   :NEW.PROCURADOR:=1;
   
   IF CONTRATOD IS NOT NULL THEN
   UPDATE seqprimarykey SET seqprimarykey.id_int= CONTRATOD
   where tabela='CONTRATO' AND SUBSTR(CHAVEVALOR,7,4)=:NEW.ESTAB;
   END IF;
   
   END IF;
   END IF;

   EXCEPTION
   WHEN NO_DATA_FOUND THEN
   NULL;
   END;
