WITH DPL AS (
    SELECT EMPRESA,DUPREC,SEQRECBTO,(VALOR) AS VALOR FROM PRDUPRED
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,(VLRCHEQREC) AS VALOR FROM PRDURECH
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR FROM PRDUREDUP 
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR FROM PRDURECAR
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR FROM PRDUREOUT 
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR FROM PRDURECM WHERE TROCO = 'N'
),
BAIXAS_DPL AS (
    SELECT EMPRESA,DUPREC,SEQRECBTO, SUM(VALOR) AS VALOR FROM DPL
    GROUP BY EMPRESA,DUPREC,SEQRECBTO
),    
BAIXAS AS
    (SELECT 
        PRDUPREC.EMPRESA,
        PRDUPREC.DUPREC,
        SUM(BAIXAS_DPL.VALOR) AS VLR,
        SUM(PRDUPREC.VALOR * CASE WHEN PRDUPREC.TIPOREC IN ('R','J') THEN 1 ELSE -1 END) AS PAGO,
        SUM(CASE WHEN PRDUPREC.TIPOREC IN ('J') THEN BAIXAS_DPL.VALOR ELSE 0 END) JUROS,
        SUM(CASE WHEN PRDUPREC.TIPOREC IN ('R') THEN BAIXAS_DPL.VALOR ELSE 0 END) REC
    FROM PRDUPREC
    INNER JOIN BAIXAS_DPL
        ON  BAIXAS_DPL.EMPRESA  = PRDUPREC.EMPRESA
        AND BAIXAS_DPL.DUPREC   = PRDUPREC.DUPREC
        AND BAIXAS_DPL.SEQRECBTO= PRDUPREC.SEQRECBTO
    WHERE
            TIPOREC IN ('R','J')
        AND DTRECBTO <= :DTBASE
    GROUP BY
        PRDUPREC.EMPRESA,
        PRDUPREC.DUPREC
),    
REAJ_ANT AS
    (SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM PDUPRECREAJ
    WHERE DTREAJUSTE <= (:DTBASE)
    ),
REAJ_MAX AS
    (SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM PDUPRECREAJ
    WHERE
        DTREAJUSTE >= (:DTBASE)
    ),
DUP_REAJ AS
    (SELECT 
        RM.ESTAB,
        RM.DUPREC,
        (CASE 
         -- Se a data de posição for menor que a data do reajuste, e não houver registro em REAJ_ANT,
         -- usa o VALORATU (valor antes do reajuste) de RM; caso haja RA, você pode optar por usar
         -- o VALORREAJ de RA se isso for o desejado. Aqui, por exemplo, usamos NVL para usar RA.VALORREAJ se existir;
         -- se não, usamos RM.VALORATU.
            WHEN (:DTBASE) < RM.DTREAJUSTE
                THEN NVL(RA.VALORREAJ, RM.VALORATU)
            ELSE RM.VALORREAJ
        END
        ) AS VALORREAJ
        FROM    (SELECT *
                FROM REAJ_MAX
                WHERE RN = 1
                ) RM
            LEFT JOIN   (SELECT *
                        FROM REAJ_ANT
                        WHERE RN = 1
                        ) RA
                ON  RM.ESTAB = RA.ESTAB
                AND RM.DUPREC = RA.DUPREC
    ),
BAIXAS_CM AS (
    SELECT ESTABACERTADO,SEQACERTADA,NUMEROCM,SUM(VALOR) AS VLR FROM CONTAMOVLANAC
    WHERE TIPO = 'B' AND CONTAMOVLANAC.DTACERTO <= (:DTBASE)
    GROUP BY ESTABACERTADO,SEQACERTADA,NUMEROCM
    ),
CTRNOTA AS (
    SELECT
    CONTRATONFITE.ESTAB,
    CONTRATONFITE.CONTRATO,
    CONTRATONFITE.SEQITEM,
    CASE WHEN NAT.TIPODCTO IN ('N','X','A','T') AND NATAPARTIRDE.TIPOBAIXA IN ('A','V') AND NFCAB.NOTACONF NOT IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 'BAIXA' ELSE 'N' END TIPO,
    CASE 
        WHEN NAT.TIPODCTO IN ('N','X','A','T') AND NATAPARTIRDE.TIPOBAIXA IN ('A','V') AND NFCAB.NOTACONF NOT IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.VALOR
        ELSE 0
    END BAIXADO,
    CASE 
        WHEN (NAT.TIPODCTO = 'D' OR NFCFG.NOTACONF IN (1041)) AND NATAPARTIRDE.TIPOBAIXA IN ('A','V') AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.VALOR
        ELSE 0
    END DEVOLIDO,
    CASE 
        WHEN NAT.TIPODCTO IN ('N','X','A') AND NATAPARTIRDE.TIPOBAIXA IN ('A','V') AND NFCFG.NOTACONF IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.VALOR
        ELSE 0
    END CANCELADO,
    CASE 
        WHEN NAT.TIPODCTO IN ('N','X','A') AND NATAPARTIRDE.TIPOBAIXA IN ('A','V') AND NFCFG.NOTACONF IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.VALOR
        ELSE 0
    END CANCELADO_CALC
    FROM CONTRATONFITE
    INNER JOIN CONTRATO ON CONTRATO.ESTAB = CONTRATONFITE.ESTAB AND CONTRATO.CONTRATO = CONTRATONFITE.CONTRATO
    INNER JOIN CONTRATOITE ON 
        CONTRATOITE.ESTAB = CONTRATONFITE.ESTAB
        AND CONTRATOITE.CONTRATO = CONTRATONFITE.CONTRATO
        AND CONTRATONFITE.SEQITEM = CONTRATONFITE.SEQITEM
    INNER JOIN NFCAB ON NFCAB.ESTAB = CONTRATONFITE.ESTABNOTA AND NFCAB.SEQNOTA = CONTRATONFITE.SEQNOTA
    INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
    INNER JOIN NATOPERACAO NAT ON NAT.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO AND NAT.ENTRADASAIDA = NFCFG.ENTRADASAIDA 
    INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF    
    INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON U_TIPOCTR.U_TIPOCTR_ID = CONTRATOCFG_U.U_TIPOCTR_ID  
    LEFT JOIN NFCFG_U U ON U.NOTACONF = NFCFG.NOTACONF
    LEFT JOIN U_TIPOOP P ON U.U_TIPOOP_ID = P.U_TIPOOP_ID
    INNER JOIN NATAPARTIRDE ON
        NATAPARTIRDE.NATUREZADAOPERACAO = NAT.NATUREZADAOPERACAO
        AND NATAPARTIRDE.ENTRADASAIDA = NAT.ENTRADASAIDA
        AND NATAPARTIRDE.NATOPERORIGEM = CONTRATOCFG.NATUREZA--IN ('CO','CU')
        AND NATAPARTIRDE.ENTRADASAIDAORIGEM IN ('S','E')
    WHERE CONTRATO.ATIVO = 'A'
     <#if NUMEROCM?has_content>  
        AND CONTRATO.NUMEROCM IN (:NUMEROCM)
    </#if>
),
BAIXAS_CTR AS (
    SELECT ESTAB,CONTRATO,SEQITEM,SUM(BAIXADO) AS BAIXADO,SUM(DEVOLIDO) AS DEVOLIDO,SUM(CANCELADO) AS CANCELADO FROM CTRNOTA
    GROUP BY ESTAB, CONTRATO, SEQITEM
),
CANC AS (
    SELECT CONTRATOCANC.ESTAB,CONTRATOCANC.CONTRATO,CONTRATOCANC.SEQITEM,SUM(CONTRATOCANC.VALOR) AS CANC
    FROM CONTRATOCANC
    INNER JOIN CONTRATO ON CONTRATO.ESTAB = CONTRATOCANC.ESTAB AND CONTRATO.CONTRATO = CONTRATOCANC.CONTRATO
    INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF    
    INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON U_TIPOCTR.U_TIPOCTR_ID = CONTRATOCFG_U.U_TIPOCTR_ID 
    GROUP BY CONTRATOCANC.ESTAB, CONTRATOCANC.CONTRATO,CONTRATOCANC.SEQITEM
),
SALDO_CTR AS (
    SELECT
    CONTRATO.NUMEROCM,
    SUM(ARREDONDAR(CONTRATOITE.VALORTOTAL - NVL(BAIXAS_CTR.BAIXADO,0) - NVL(BAIXAS_CTR.CANCELADO,0) + NVL(BAIXAS_CTR.DEVOLIDO,0) - NVL(CANC.CANC,0), 0)) VLRSALDO
    FROM CONTRATO
    INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = CONTRATO.ESTAB
    INNER JOIN CONTRATOITE ON
        CONTRATOITE.ESTAB = CONTRATO.ESTAB
        AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO
    LEFT JOIN BAIXAS_CTR ON
        BAIXAS_CTR.ESTAB = CONTRATOITE.ESTAB
        AND BAIXAS_CTR.CONTRATO = CONTRATOITE.CONTRATO
        AND BAIXAS_CTR.SEQITEM = CONTRATOITE.SEQITEM
    LEFT JOIN CANC ON 
        CANC.ESTAB = CONTRATOITE.ESTAB 
        AND CANC.CONTRATO = CONTRATOITE.CONTRATO
        AND CANC.SEQITEM = CONTRATOITE.SEQITEM
    WHERE CONTRATO.ATIVO = 'A' AND U_TEMPRESA.GRAOS ='S'
    GROUP BY CONTRATO.NUMEROCM
),
BAIXAS_DUPPAG AS (
    SELECT
    EMPRESA,
    DUPPAG,
    FORNECEDOR,
    SUM(VALOR) AS VLR,
    SUM(PPDUPPAG.VALOR * CASE WHEN PPDUPPAG.TIPOPAG IN ('P','J') THEN 1 ELSE -1 END) AS PAGO
    FROM PPDUPPAG

    WHERE TIPOPAG = 'P'
    AND DTPAGTO <= :DTBASE
    <#if NUMEROCM?has_content>  
        AND PPDUPPAG.FORNECEDOR IN (:NUMEROCM)
    </#if>
   AND 
        (
            EXISTS (
                SELECT
                1
                FROM PPDUPPAD
                 WHERE
                 (PPDUPPAD.EMPRESA = PPDUPPAG.EMPRESA)
                           AND (PPDUPPAD.ESTABFORNECEDOR = PPDUPPAG.ESTABFORNECEDOR)
                           AND (PPDUPPAD.FORNECEDOR = PPDUPPAG.FORNECEDOR)
                           AND (PPDUPPAD.DUPPAG = PPDUPPAG.DUPPAG)
                           AND (PPDUPPAD.SEQPAGTODU = PPDUPPAG.SEQPAGTODU)
                )
             OR
             EXISTS (
                 SELECT
                 1
                 FROM PPADUCM
                 WHERE
                 (PPADUCM.EMPRESA = PPDUPPAG.EMPRESA)
                               AND (PPADUCM.ESTABFORNECEDOR = PPDUPPAG.ESTABFORNECEDOR)
                               AND (PPADUCM.FORNECEDOR = PPDUPPAG.FORNECEDOR)
                               AND (PPADUCM.DUPPAG = PPDUPPAG.DUPPAG)
                               AND (PPADUCM.SEQPAGTODU = PPDUPPAG.SEQPAGTODU)
         
                )
            OR
            EXISTS (
                SELECT
                1 
                FROM PPDUPPADUP
                WHERE (PPDUPPADUP.EMPRESA         = PPDUPPAG.EMPRESA)
                        AND (PPDUPPADUP.ESTABFORNECEDOR = PPDUPPAG.ESTABFORNECEDOR)
                        AND (PPDUPPADUP.FORNECEDOR         = PPDUPPAG.FORNECEDOR)
                        AND (PPDUPPADUP.DUPPAG             = PPDUPPAG.DUPPAG)
                        AND (PPDUPPADUP.SEQPAGTODU         = PPDUPPAG.SEQPAGTODU)
                )
            OR
            EXISTS (
                SELECT
                1
                FROM PPADUCHE
                WHERE (PPADUCHE.EMPRESA = PPDUPPAG.EMPRESA)
                            AND (PPADUCHE.ESTABFORNECEDOR = PPDUPPAG.ESTABFORNECEDOR)
                            AND (PPADUCHE.FORNECEDOR = PPDUPPAG.FORNECEDOR)
                            AND (PPADUCHE.DUPPAG = PPDUPPAG.DUPPAG)
                            AND (PPADUCHE.SEQPAGTODU = PPDUPPAG.SEQPAGTODU)
            
                )
            OR
            EXISTS (
                SELECT
                1
                FROM PPADUCHR
                WHERE (PPADUCHR.EMPRESA = PPDUPPAG.EMPRESA)
                            AND (PPADUCHR.ESTABFORNECEDOR = PPDUPPAG.ESTABFORNECEDOR)
                            AND (PPADUCHR.FORNECEDOR = PPDUPPAG.FORNECEDOR)
                            AND (PPADUCHR.DUPPAG = PPDUPPAG.DUPPAG)
                            AND (PPADUCHR.SEQPAGTODU = PPDUPPAG.SEQPAGTODU)
                )
        )
    
    GROUP BY EMPRESA,DUPPAG,FORNECEDOR
),
SALDO_PAG AS (
    SELECT
    PDUPPAGA.FORNECEDOR,
    SUM(PDUPPAGA.VALOR - NVL(PDUPPAGA.DESCPEND,0) - NVL(BAIXAS_DUPPAG.VLR,0)) SALDO_PAGAR
    FROM PDUPPAGA
    LEFT JOIN BAIXAS_DUPPAG ON
			BAIXAS_DUPPAG.EMPRESA = PDUPPAGA.EMPRESA
			AND BAIXAS_DUPPAG.DUPPAG = PDUPPAGA.DUPPAG
			AND BAIXAS_DUPPAG.FORNECEDOR = PDUPPAGA.FORNECEDOR
    WHERE
    0=0
     <#if NUMEROCM?has_content>  
        AND PDUPPAGA.FORNECEDOR IN (:NUMEROCM)
    </#if>
    GROUP BY PDUPPAGA.FORNECEDOR
)
SELECT 
    DADOS1.ESTAB,
    DADOS1.TIPO_FILIAL,
    DADOS1.FILIAL,
    DADOS1.NUMEROCM,
    --DADOS1.PF_PJ,
    DADOS1.TIPO_CLIENTE,
    DADOS1.CNPJF,
    DADOS1.CLIENTE,
    DADOS1.TIPO_DOC,
    DADOS1.desc_tipo,
    DADOS1.DOCUMENTO,
    dados1.status,
    DADOS1.PARCELA,
    DADOS1.DTEMISSAO,
    DADOS1.ANO,
    DADOS1.MES,
    DADOS1.dtvencto,
    DADOS1.ATRASO,
    DADOS1.aging,
    (case
        when TIPO_DOC IN ('ACB','AC','DDVE','AC','ACB','ACC','ACV','DUPP','IMEC','TFDP')
            THEN (DADOS1.VALOR * -1)
        ELSE DADOS1.VALOR
    END
    ) AS VALOR,
(case when TIPO_DOC in ('ACB','AC','DDVE','AC','ACB','ACC','ACV','DUPP','IMEC','TFDP') THEN DADOS1.SALDO *-1 ELSE DADOS1.SALDO END) SALDO,
(SALDO_CTR.VLRSALDO*-1)saldo_ctr,
DADOS1.obs,
DADOS1.situacao,
TO_CHAR(DADOS1.DTPROVAVELPAGAMENTO,'DD/MM/YYYY') AS DTPROVAVELPAGAMENTO,
DADOS1.conceito_credito,
DADOS1.CULTURA,
DADOS1.filial_rtv,
DADOS1.consultor,
PRODUTOR.saldoprod_sc,
PRODUTOR.saldoprod_vlr
,SALDO_PAG.SALDO_PAGAR
,DADOS1.CTACTB
,dados1.fat_agrupa
,coalesce(to_char(to_date(DADOS1.dtreajuste, 'DD/MM/YY')), to_char(to_date(dados1.dtvencto, 'DD/MM/YY'))) DTREAJUSTE
,JUROS
from(
select
--DADOS.TIPO,
DADOS.ESTAB,
CASE WHEN U_TEMPRESA.GRAOS = 'S' THEN 'Cereais'
	when U_TEMPRESA.INSUMOS = 'S' THEN 'Insumos'
    else 'Outros' END TIPO_FILIAL,
DADOS.FILIAL,
DADOS.NUMEROCM,
DADOS.PF_PJ,
DADOS.TIPO_CLIENTE,
DADOS.CNPJF,
DADOS.CLIENTE,
DADOS.TIPO_DOC,
dados.desc_tipo,
DADOS.DOCUMENTO,
dados.status,
DADOS.PARCELA,
DADOS.DTEMISSAO,
DADOS.ANO,
DADOS.MES,
dados.dtvencto,
DADOS.ATRASO,
CASE WHEN atraso <= -31 then '0 - Vencer'
    when atraso >= -30 and atraso <= 0 then '1 - A Vencer até 30'
    when atraso > 0 and atraso < 31 then '2 - 1 a 30 '
    when atraso > 30 and atraso < 61 then '3 - 31 a 60 '
    when atraso > 60 and atraso < 91 then '4 - 61 a 90 '
    when atraso > 90 and atraso < 121 then '5 - 91 a 120 '
    when atraso > 120 and atraso < 181 then '6 - 121 a 180 '
    when atraso > 180 and atraso < 241 then '7 - 181 a 240 '
    when atraso > 240 and atraso < 366 then '8 - 241 a 365 '
    when atraso > 365 then '9 - Acima 365 '
     end aging,
DADOS.VALOR,
case when atraso <=0 then 0 else dados.juros end juros,
DADOS.SALDO,
saldo + (case when atraso <=0 then 0 else dados.juros end) as saldo_atual,
OCORRENCIAFINAN.obs as obs,
ocorrenciatipo.descricao as situacao,
OCORRENCIAFINAN.DTPROVAVELPAGAMENTO,
DADOS.conceito_credito,
DADOS.filial_rtv,
DADOS.consultor,
DADOS.CULTURA
,dados.fat_agrupa
,dados.dtreajuste
,DADOS.CTACTB
from(

select
'A RECEBER' AS TIPO,
filial.estab,
filial.reduzido as filial,
contamov.numerocm,
case when NVL(endereco.cnpjf,contamov.cnpjf) >11 then 'PJ' ELSE 'PF' end PF_PJ,
case when contamov.revenda = 'S' THEN 'Revenda'
    when contamov.produtor = 'S' THEN 'Produtor'
    when conceito.conceito = 96 then 'Fornecedor'
    WHEN NVL(endereco.nome,contamov.nome) like '%USINA%' THEN 'USINA'
    when NVL(endereco.cnpjf,contamov.cnpjf) > 11 then 'PJ' ELSE 'PF'
    end tipo_cliente,
NVL(endereco.cnpjf,contamov.cnpjf)cnpjf,
contamov.nome as cliente,
'DPL' AS TIPO_DOC,
'DUPLICATA' as desc_tipo,
pduprec.duprec as documento,
 psituaca.descricao as status,
pduprec.nroparcela as parcela,
to_char(pduprec.dtemissao,'DD/MM/YYYY') AS dtemissao,
extract(year from pduprec.dtemissao) as ano,
extract(month from pduprec.dtemissao) as mes,
to_char(pduprec.dtvencto,'DD/MM/YYYY')dtvencto,
arredondar(CAST(:DTBASE AS DATE) - pduprec.dtvencto ,0) AS ATRASO,
limcred.descricao as cultura,
pduprec.valorfatura as valor,
pduprec.juros,
CASE WHEN NVL(pduprec.situacao,0) <> 39 THEN NVL(VALORREAJ,PDUPREC.VALOR) - NVL(BAIXAS.REC,0) ELSE NVL(VALORREAJ,PDUPREC.VALOR) - NVL(PDUPREC.DESCONTO,0) END AS SALDO,
conceito.descricao as conceito_credito,
filialrtv.reduzido as filial_rtv,
rtv.nome as consultor,
ocorrenciaduprec.idocorrencia,
PBLOQDIV.fatura as fat_agrupa,
dtreajuste AS  dtreajuste,
NVL(PANALITI.CTACTB,AUX.CTACTB) AS CTACTB
from pduprec

inner join filial on filial.estab = pduprec.empresa
inner join contamov on contamov.numerocm = pduprec.cliente
left join endereco on 
    endereco.numerocm = pduprec.cliente
    and endereco.seqendereco = pduprec.seqendereco
left join conceitopessoa on conceitopessoa.numerocm=contamov.numerocm

left join conceito on conceito.conceito=conceitopessoa.conceito

left join limcred on limcred.id =  pduprec.limcred_id
    
LEFT join contamov rtv on rtv.numerocm = pduprec.represent
left join contamovfuncionario on contamovfuncionario.numerocm = rtv.numerocm

left join filial filialrtv on filialrtv.estab = contamovfuncionario.localtrabalho

  LEFT JOIN BAIXAS ON
    BAIXAS.EMPRESA = PDUPREC.EMPRESA
    AND BAIXAS.DUPREC = PDUPREC.DUPREC

LEFT JOIN DUP_REAJ ON
    DUP_REAJ.ESTAB = PDUPREC.EMPRESA
    AND DUP_REAJ.DUPREC = PDUPREC.DUPREC
  
        
LEFT JOIN ( SELECT  OCORRENCIADUPREC.ESTAB,
                           OCORRENCIADUPREC.DUPREC,
                           MAX(OCORRENCIADUPREC.IDOCORRENCIA)IDOCORRENCIA
                           
     

         FROM OCORRENCIADUPREC

        INNER JOIN OCORRENCIAFINAN ON ocorrenciafinan.idocorrencia = ocorrenciaduprec.idocorrencia

        GROUP BY OCORRENCIADUPREC.ESTAB,OCORRENCIADUPREC.DUPREC

        ) OCORRENCIADUPREC

         ON OCORRENCIADUPREC.ESTAB = PDUPREC.EMPRESA
         AND OCORRENCIADUPREC.duprec = PDUPREC.DUPREC

left join psituaca on psituaca.situacao = pduprec.situacao                             
     inner JOIN PCONFPAD ON
        PCONFPAD.EMPRESA = filial.estab            
        
        left join u_tempresa on u_tempresa.estab = filial.estab
        
left join PBLOQDIV on
  	PBLOQDIV.empresa = pduprec.empresa
  and PBLOQDIV.duprec = pduprec.duprec
  
left join
    (select
    estab,
    duprec,
    max(DTBASEJUROS)dtreajuste,
    min(DTVENCREAJ)dtreaj_ori
    from pduprecreaj
    
    group by
    estab,
    duprec
    )reaj on
    reaj.estab = pduprec.empresa
    and reaj.duprec = pduprec.duprec
    
  LEFT JOIN PANALITI ON
    PANALITI.EMPRESA = FILIAL.EMPRESA
    AND PANALITI.ANALITICA = PDUPREC.ANALITICA
    
    LEFT JOIN PANALITI AUX ON
    AUX.EMPRESA = 1
    AND AUX.ANALITICA = PDUPREC.ANALITICA
  
where
 ARREDONDAR(NVL(VALORREAJ,PDUPREC.VALOR) - NVL(BAIXAS.REC,0) -  NVL(DESCPEND,0) ,0) > 0
 AND  ((NVL(VALORREAJ,PDUPREC.VALOR)  - NVL(BAIXAS.REC,0)) - NVL(PDUPREC.DESCONTO,0)) <> 0
AND PDUPREC.DUPREC <> ('84388-1') 
--and coalesce(pduprec.situacao,0) <> 39
AND (0 in (:ESTAB) OR FILIAL.ESTAB IN (:ESTAB))
AND PDUPREC.DTEMISSAO BETWEEN :DTINI AND :DTFIM
AND PDUPREC.DTVENCTO BETWEEN :DTINIVENC AND :DTFIMVENC

<#if REPRESENT?has_content>  
AND PDUPREC.REPRESENT IN (:REPRESENT)
 </#if>
  
 <#if NUMEROCM?has_content>  
	AND PDUPREC.CLIENTE IN (:NUMEROCM)
</#if>
  
and 
filial.empresa in 
(
select distinct
empresa
from filial

where
(0 in (:ESTAB) OR filial.estab in (:ESTAB))
and
filial.empresa in
(
select DISTINCT
empresa
from filial

where
(:EMPRESA = 1 and EMPRESA >=1)
OR
(:EMPRESA = 2 and EMPRESA <100)
)
)

union all
  SELECT
'A RECEBER' AS TIPO,
FILIAL.ESTAB,
FILIAL.REDUZIDO AS FILIAL,
CONTAMOV.NUMEROCM,
CASE WHEN CONTAMOV.CNPJF >11 THEN 'PJ' ELSE 'PF' END PF_PJ,
CASE WHEN CONTAMOV.REVENDA = 'S' THEN 'Revenda'
    WHEN CONTAMOV.PRODUTOR = 'S' THEN 'Produtor'
    WHEN CONCEITO.CONCEITO = 96 THEN 'Fornecedor'
    WHEN CONTAMOV.NOME LIKE '%USINA%' THEN 'USINA'
    WHEN CONTAMOV.CNPJF > 11 THEN 'PJ' ELSE 'PF'
    END TIPO_CLIENTE,
CONTAMOV.CNPJF,
CONTAMOV.NOME as CLIENTE,
'CHEQ' AS TIPO_DOC,
'CHEQUE' as DESC_TIPO,
CAST(NROCHEQUE AS VARCHAR(100) )AS DOCUMENTO,
PSITUACA.DESCRICAO as STATUS,
1 PARCELA,
TO_CHAR(PCHEQREC.DTEMISSAO,'DD/MM/YYYY') AS DTEMISSAO,
EXTRACT(YEAR FROM PCHEQREC.DTEMISSAO) AS ANO,
EXTRACT(MONTH FROM PCHEQREC.DTEMISSAO) AS MES,
TO_CHAR(PCHEQREC.DTBOMPARA,'DD/MM/YYYY') AS DTVENCTO,
arredondar(CAST(:DTBASE AS DATE) - PCHEQREC.DTBOMPARA ,0) AS ATRASO,
limcred.descricao as cultura,
PCHEQREC.valor,
0 as juros,
CASE
          WHEN PCHEQREC.DTLANCA IS NULL
          THEN PCHEQREC.VALOR
          ELSE
            CASE 
              WHEN PCHEQREC.DTLANCA <= :DTBASE
              THEN 0
              ELSE PCHEQREC.VALOR
          END
      END AS SALDO,
CONCEITO.DESCRICAO AS CONCEITO_CREDITO,
FILIALRTV.REDUZIDO AS FILIAL_RTV,
RTV.NOME AS CONSULTOR,
NULL AS IDOCORRENCIA,
NULL AS FAT_AGRUPA,
NULL DTREAJUSTE,
NVL(PANALITI.CTACTB,AUX.CTACTB) AS CTACTB
FROM PCHEQREC

LEFT JOIN PREPRESE
    ON PREPRESE.EMPRESA = PCHEQREC.ESTABREPRESENTANTE
    AND PREPRESE.REPRESENT = PCHEQREC.REPRESENTANTE

INNER JOIN CONTAMOV ON CONTAMOV.NUMEROCM = PCHEQREC.CLIENTE
LEFT JOIN CONCEITOPESSOA ON CONCEITOPESSOA.NUMEROCM=CONTAMOV.NUMEROCM
LEFT JOIN CONCEITO ON CONCEITO.CONCEITO=CONCEITOPESSOA.CONCEITO

INNER JOIN FILIAL ON FILIAL.ESTAB = PCHEQREC.EMPRESA
INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = FILIAL.ESTAB

LEFT JOIN PSITUACA ON PSITUACA.SITUACAO = PCHEQREC.SITUACAO     
LEFT JOIN LIMCRED ON LIMCRED.ID =  PCHEQREC.LIMCRED_ID
    
LEFT JOIN CONTAMOV RTV ON RTV.NUMEROCM = PCHEQREC.REPRESENTANTE
LEFT JOIN CONTAMOVFUNCIONARIO ON CONTAMOVFUNCIONARIO.NUMEROCM = RTV.NUMEROCM
LEFT JOIN FILIAL FILIALRTV ON FILIALRTV.ESTAB = CONTAMOVFUNCIONARIO.LOCALTRABALHO

LEFT JOIN PANALITI ON
    PANALITI.EMPRESA = FILIAL.EMPRESA
    AND PANALITI.ANALITICA = PCHEQREC.ANALITICA
    
    LEFT JOIN PANALITI AUX ON
    AUX.EMPRESA = 1
    AND AUX.ANALITICA = PCHEQREC.ANALITICA
  
  
WHERE
PCHEQREC.SEQLANCATRAN IS NULL
AND PCHEQREC.DTEMISSAO BETWEEN :DTINI AND :DTFIM
AND PCHEQREC.DTBOMPARA BETWEEN :DTINIVENC AND :DTFIMVENC
AND PCHEQREC.DTLANCA IS NULL 
AND PCHEQREC.EMPRESA <> 800
AND PCHEQREC.SITUACAO  in (12,10)

<#if REPRESENT?has_content>  
AND PCHEQREC.REPRESENTANTE IN (:REPRESENT)
</#if>
  
 <#if NUMEROCM?has_content>  
	AND CONTAMOV.NUMEROCM IN (:NUMEROCM)
</#if>

and 
filial.empresa in 
(
select distinct
empresa
from filial

where
(0 in (:ESTAB) OR filial.estab in (:ESTAB))
and
filial.empresa in
(
select DISTINCT
empresa
from filial

where
(:EMPRESA = 1 and EMPRESA >=1)
OR
(:EMPRESA = 2 and EMPRESA <100)
)
)
  
  
)dados

LEFT JOIN OCORRENCIAFINAN ON ocorrenciafinan.idocorrencia = DADOS.idocorrencia
left join ocorrenciatipo on ocorrenciatipo.id = OCORRENCIAFINAN.idtipo
LEFT JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = DADOS.ESTAB

UNION ALL

SELECT
DADOS.ESTAB,
CASE WHEN U_TEMPRESA.GRAOS = 'S' THEN 'Cereais'
	when U_TEMPRESA.INSUMOS = 'S' THEN 'Insumos'
    else 'Outros' END TIPO_FILIAL,
DADOS.FILIAL,
DADOS.NUMEROCM,
DADOS.PF_PJ,
DADOS.TIPO_CLIENTE,
DADOS.CNPJF,
DADOS.CLIENTE,
DADOS.TIPO_DOC,
dados.desc_tipo,
DADOS.DOCUMENTO,
  dados.status,
DADOS.PARCELA,
DADOS.DTEMISSAO,
DADOS.ANO,
DADOS.MES,
dados.dtvencto,
DADOS.ATRASO,
CASE WHEN atraso <= -31 then '0 - Vencer'
    when atraso >= -30 and atraso <= 0 then '1 - A Vencer até 30'
    when atraso > 0 and atraso < 31 then '2 - 1 a 30 '
    when atraso > 30 and atraso < 61 then '3 - 31 a 60 '
    when atraso > 60 and atraso < 91 then '4 - 61 a 90 '
    when atraso > 90 and atraso < 121 then '5 - 91 a 120 '
    when atraso > 120 and atraso < 181 then '6 - 121 a 180 '
    when atraso > 180 and atraso < 241 then '7 - 181 a 240 '
    when atraso > 240 and atraso < 366 then '8 - 241 a 365 '
    when atraso > 365 then '9 - Acima 365 '
     end aging,
DADOS.VALOR,
case when atraso <=0 then 0 else dados.juros end juros,
DADOS.SALDO,
saldo + (case when atraso <=0 then 0 else dados.juros end) as saldo_atual,
OCORRENCIAFINAN.obs as obs,
ocorrenciatipo.descricao as situacao,
  OCORRENCIAFINAN.DTPROVAVELPAGAMENTO,
DADOS.conceito_credito,
--DADOS.limite_credito,
--DADOS.vlrlimite,
--DADOS.vencimento_limite,
DADOS.filial_rtv,
DADOS.consultor,
DADOS.CULTURA
, null fat_agrupa
,null dtreajuste
,CTACTB
FROM(

select
filial.estab,
filial.reduzido as filial,
CONTAMOVLAN.numerocm,
case when contamov.cnpjf >11 then 'PJ' ELSE 'PF' end PF_PJ,
case when contamov.revenda = 'S' THEN 'Revenda'
    when contamov.produtor = 'S' THEN 'Produtor'
    when conceito.conceito = 96 then 'Fornecedor'
    WHEN contamov.nome like '%USINA%' THEN 'USINA'
    when contamov.cnpjf > 11 then 'PJ' ELSE 'PF'
    end tipo_cliente,
contamov.cnpjf,
contamov.nome as cliente,
contamovtp.tipo as tipo_doc,
contamovtp.descricao as desc_tipo,
contamovlan.nrodocto as documento,
  
    CASE WHEN contamovlan.SITUACAO = 'B' THEN 'Baixado'
  	when contamovlan.situacao = 'P' then 'Pendente'
  when contamovlan.situacao = 'A' then 'Acertado Parcialmente'
  END status,
1 as parcela,
TO_CHAR(CONTAMOVLAN.DTMOVTO,'DD/MM/YYYY')DTEMISSAO,
extract(year from CONTAMOVLAN.DTMOVTO) as ano,
extract(month from CONTAMOVLAN.DTMOVTO) as mes,
TO_CHAR(CONTAMOVLAN.VENCIMENTO,'DD/MM/YYYY') DTVENCTO,
arredondar(CAST(:DTBASE AS DATE) - CONTAMOVLAN.VENCIMENTO,0) AS ATRASO,
contamovlan.valor,
contamovlan.juros,
CONTAMOVLAN.VALOR - COALESCE(BAIXAS_CM.VLR,0) AS SALDO,
conceito.descricao as conceito_credito,
COALESCE(filialrtv.reduzido,'S/RTV') as filial_rtv,
COALESCE(rtv.nome,'S/RTV') as consultor,
ocorrenciacontamov.IDOCORRENCIA,
  '' as cultura,
  contamovtp.CTAPAD AS CTACTB
from CONTAMOVLAN

inner join filial on filial.estab = contamovlan.estab

INNER JOIN CONTAMOV ON
        CONTAMOV.NUMEROCM   = CONTAMOVLAN.NUMEROCM 
        
        left join u_tempresa on u_tempresa.estab = filial.estab
        
left join conceitopessoa on conceitopessoa.numerocm=contamov.numerocm

left join conceito on conceito.conceito=conceitopessoa.conceito

left join contamovtp on
    contamovtp.tipo = CONTAMOVLAN.tipo
    and contamovtp.DEBCRED = CONTAMOVLAN.DEBCRED

    
LEFT JOIN AGRFINCTAMOV ON AGRFINCTAMOV.ESTAB = CONTAMOVLAN.ESTAB
                            AND AGRFINCTAMOV.NUMEROCM = CONTAMOVLAN.NUMEROCM
                            AND AGRFINCTAMOV.SEQCM = CONTAMOVLAN.SEQCM
                            
LEFT JOIN NFCABAGRFIN ON NFCABAGRFIN.ESTAB = AGRFINCTAMOV.ESTAB
                        AND NFCABAGRFIN.SEQPAGAMENTO = AGRFINCTAMOV.SEQPAGAMENTO
                        
LEFT JOIN NFCAB ON NFCAB.SEQNOTA = NFCABAGRFIN.SEQNOTA
                        AND NFCAB.ESTAB = NFCABAGRFIN.ESTAB
 
LEFT JOIN BAIXAS_CM ON
    BAIXAS_CM.ESTABACERTADO = CONTAMOVLAN.ESTAB
    AND BAIXAS_CM.SEQACERTADA = CONTAMOVLAN.SEQCM
    AND BAIXAS_CM.NUMEROCM = CONTAMOVLAN.NUMEROCM
  
  
 LEFT join contamov rtv on rtv.numerocm = NFCAB.represent
left join contamovfuncionario on contamovfuncionario.numerocm = rtv.numerocm

left join filial filialrtv on filialrtv.estab = contamovfuncionario.localtrabalho  
    
 LEFT JOIN ( SELECT  ocorrenciacontamov.ESTAB,
                           ocorrenciacontamov.SEQCM,
                           ocorrenciacontamov.NUMEROCM,
                           MAX(ocorrenciacontamov.IDOCORRENCIA)IDOCORRENCIA
                           
     

         FROM ocorrenciacontamov

        INNER JOIN OCORRENCIAFINAN ON ocorrenciafinan.idocorrencia = ocorrenciacontamov.idocorrencia

        GROUP BY ocorrenciacontamov.ESTAB,ocorrenciacontamov.SEQCM,ocorrenciacontamov.NUMEROCM

        ) ocorrenciacontamov

         ON ocorrenciacontamov.ESTAB = CONTAMOVLAN.ESTAB
         AND ocorrenciacontamov.SEQCM = CONTAMOVLAN.SEQCM
         AND ocorrenciacontamov.NUMEROCM = CONTAMOVLAN.NUMEROCM
    
     inner JOIN PCONFPAD ON
        PCONFPAD.EMPRESA = filial.estab
    
    
    
    
WHERE 
 ARREDONDAR(CONTAMOVLAN.VALOR - COALESCE(BAIXAS_CM.VLR,0),0) > 0

  AND (CONTAMOVLAN.DEBCRED = 'D' OR (CONTAMOVLAN.DEBCRED = 'C' AND CONTAMOVLAN.TIPO IN ('ACB','AC','DDVE','AC','ACB','ACC','ACV','DUPP','IMEC','TFDP')))
and CONTAMOVLAN.TIPO not in ('ACT','AV','DDCO','JCSB')
  AND CONTAMOVLAN.TIPO NOT IN ('ACT','TACT','ACCR')
AND (0 IN (:ESTAB) OR FILIAL.ESTAB IN (:ESTAB))

  
AND CONTAMOVLAN.DTMOVTO BETWEEN :DTINI AND :DTFIM
AND CONTAMOVLAN.VENCIMENTO BETWEEN :DTINIVENC AND :DTFIMVENC

  <#if REPRESENT?has_content>  
    AND NFCAB.REPRESENT IN (:REPRESENT)
  </#if>
  
<#if NUMEROCM?has_content>  
	AND CONTAMOV.NUMEROCM IN (:NUMEROCM)
</#if>

  
    and 
filial.empresa in 
(
select distinct
empresa
from filial

where
(0 in (:ESTAB) OR filial.estab in (:ESTAB))
and
filial.empresa in
(
select DISTINCT
empresa
from filial

where
(:EMPRESA = 1 and EMPRESA >= 1)
OR
(:EMPRESA = 2 and EMPRESA <100)
)
)
  
)DADOS

LEFT JOIN OCORRENCIAFINAN ON ocorrenciafinan.idocorrencia = DADOS.idocorrencia
left join ocorrenciatipo on ocorrenciatipo.id = OCORRENCIAFINAN.idtipo
LEFT JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = DADOS.ESTAB
  

)dados1
LEFT JOIN SALDO_PAG ON SALDO_PAG.FORNECEDOR = DADOS1.NUMEROCM
LEFT JOIN SALDO_CTR ON SALDO_CTR.NUMEROCM = DADOS1.NUMEROCM 
left join
    (
WITH ITEM_COTACAO AS 
(
SELECT
    ITEMCOTITE.ESTAB,
    ITEMCOTITE.COTACAO,
    MAX(ITEMCOTITE.DTCOTACAOFIN) AS ULTDATA,
    MAX(ITEMCOTITE.FIXACAO) KEEP (DENSE_RANK LAST ORDER BY ITEMCOTITE.DTCOTACAOFIN) AS FIXACAO
FROM ITEMCOTITE
INNER JOIN U_TEMPRESA 
    ON U_TEMPRESA.ESTAB = ITEMCOTITE.ESTAB
WHERE
    U_TEMPRESA.GRAOS = 'S'
    AND ITEMCOTITE.COTACAO IN (1, 2, 3, 6)
GROUP BY
    ITEMCOTITE.ESTAB,
    ITEMCOTITE.COTACAO
    )      
SELECT DISTINCT
    DADOS.NUMEROCM, 
    SUM(DADOS.SALDO)/60 AS SALDOPROD_SC,
    SUM(DADOS.SALDO * ITEM_COTACAO.FIXACAO)/60 AS SALDOPROD_VLR
FROM (
  SELECT 
    ESTAB,
    NUMEROCM,
    SEQNOTA,
    SALDOLIQ AS SALDO,
    ITEM
  FROM OS_ROMPEND
  WHERE OS_ROMPEND.DTEMISSAO BETWEEN :DTINI AND :DTFIM
    AND (0 in (:ESTAB) OR OS_ROMPEND.ESTAB IN (:ESTAB)) 
 <#if NUMEROCM?has_content>     
    AND OS_ROMPEND.NUMEROCM IN (:NUMEROCM)
</#if>
  
    
  UNION ALL
  
  SELECT 
    ESTAB,
    NUMEROCM,
    SEQNOTA,
    SALDOLIQ AS SALDO,
    ITEM
  FROM OS_NOTASF
  WHERE OS_NOTASF.DTEMISSAO BETWEEN :DTINI AND :DTFIM
    AND (0 in (:ESTAB) OR OS_NOTASF.ESTAB IN (:ESTAB)) 
 <#if NUMEROCM?has_content>       
    AND OS_NOTASF.NUMEROCM IN (:NUMEROCM)
</#if>

  UNION ALL
  
  SELECT 
    ESTAB,
    NUMEROCM,
    SEQNOTA,
    SALDOLIQ AS SALDO,
    ITEM
  FROM OS_NOTASCD
  WHERE OS_NOTASCD.DTEMISSAO BETWEEN :DTINI AND :DTFIM
    AND (0 in (:ESTAB) OR OS_NOTASCD.ESTAB IN (:ESTAB))
 <#if NUMEROCM?has_content>      
    AND OS_NOTASCD.NUMEROCM IN (:NUMEROCM)
</#if>
) DADOS 
LEFT JOIN ITEM_COTACAO ON ITEM_COTACAO.COTACAO = DADOS.ITEM AND
      				                            ITEM_COTACAO.ESTAB = DADOS.ESTAB 
GROUP BY 
DADOS.NUMEROCM
  
    )PRODUTOR ON
   
    PRODUTOR.NUMEROCM = DADOS1.NUMEROCM
