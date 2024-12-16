select
filial,
contacontabil,
--estab,
nomebem,
--codbem,
taxadep,
vidautil,
dataaquisacao,
vlraquis,
VLRRESIDUAL,
A_DEPRECIAR, 
vlrdepreciado,
saldo_adepreciar,
porct_deprecioar
from(

SELECT
dados3.*,
case when vlraquis = 0 and vlrdepreciado = 0 then 1 else 0 end teste
FROM(
select
estab||'-'||reduzido as filial,
contacontabil,
--estab,
nomebem,
--codbem,
taxadep,
divide(100,taxadep) as vidautil,
dataaquisacao,
(adicao + VLRCORRIGIDO) as vlraquis,
VLRRESIDUAL,
(adicao + VLRCORRIGIDO) - VLRRESIDUAL as A_DEPRECIAR, 
(VLRCORRIGIDO_DEP)*-1 as vlrdepreciado,
saldo_adepreciar  as saldo_adepreciar,
arredondar(
    divide(
        saldo_adepreciar,(adicao + (adicao + VLRCORRIGIDO) - VLRRESIDUAL)),2)*1 as porct_deprecioar
from(

select
dados1.*,
case when nmes = extract(month from cast(dataaq as date) ) and nano = extract(year from cast(dataaq as date) ) then
	coalesce(baixa_p,0)
    else vlraq - baixa_p end vlrult_corr_aquis,
--vlraq - baixa_p as vlrult_corr_aquis,

--vlraq - coalesce(baixa_p,0) - coalesce(vlraquisicao,0) as saldo_ini,
case when nmes = extract(month from cast(dataaq as date) ) and nano = extract(year from cast(dataaq as date) ) then
	coalesce(baixa_p,0)
    else vlraq - coalesce(baixa_p,0) - coalesce(vlraquisicao,0) end saldo_ini,

((depcusto*-1) +  vlrbxdep - (vlrdep))*-1 as VlrCorrigido_dep,
(vlraq - baixa_p) - vlrbx as VlrCorrigido,
--vlraq + vlrdep as saldo_adepreciar
dados1.vlraq - dados1.VLRRESIDUAL - (((depcusto*-1) +  vlrbxdep - (vlrdep)))  as saldo_adepreciar,

case
    when dados1.codgrup = 1 then 14201
    when dados1.codgrup = 3 then 14203
    when dados1.codgrup = 4 then 14204
    when dados1.codgrup = 5 then 14205
    when dados1.codgrup = 6 then 14206
    when dados1.codgrup = 7 then 14207
    when dados1.codgrup = 8 then 14208
    when dados1.codgrup in (9,10) then 14205
    when dados1.codgrup = 11 then 14201
    when dados1.codgrup in (12,13) then 14209
    when dados1.codgrup = 102 then 17101
    when dados1.codgrup = 1001 then 14205
end contacontabil,

BEMCPDEB AS conta_operacao,
DEPRECPCRED AS conta_depre_cred
from(


SELECT 
RAZAOPATRIMONIO.estab,
filial.reduzido,
RAZAOPATRIMONIO.nmes,
RAZAOPATRIMONIO.nano,
RAZAOPATRIMONIO.item,
RAZAOPATRIMONIO.subitem,
RAZAOPATRIMONIO.nomebem,
RAZAOPATRIMONIO.codbem,
RAZAOPATRIMONIO.codgrup,
RAZAOPATRIMONIO.dataaq as dataaquisacao,
to_char(coalesce(borigem.DATAAQUIS,RAZAOPATRIMONIO.dataaq),'DD/MM/YYYY') AS dataaq,
RAZAOPATRIMONIO.tangivel,
RAZAOPATRIMONIO.vlraqcor,
RAZAOPATRIMONIO.vlraq,
 COALESCE((((RAZAOPATRIMONIO.VLRDEPAQANT) -  (RAZAOPATRIMONIO.VLRAQDEPANT))* -1),0) VLRDEPAQANT,
BENSCP_U.PLACA,
BENSCP_U.LINK,
coalesce(RAZAOPATRIMONIO.vlraqcor - coalesce(RAZAOPATRIMONIO.VLRANTRESIDUAL,0) - coalesce(RAZAOPATRIMONIO.VLRDEPAQANT,0),0) AS SALDO_INICIAL,
 case when EXTRACT(MONTH FROM RAZAOPATRIMONIO.dataaq) = dados.nmes
            and  EXTRACT(YEAR FROM RAZAOPATRIMONIO.dataaq) = dados.nano
        then (case when RAZAOPATRIMONIO.vlraqcor = 0  then RAZAOPATRIMONIO.vlraqpercor else RAZAOPATRIMONIO.vlraqcor end ) else 0 END vlraquisicao,
coalesce(RAZAOPATRIMONIO.vlrbx,0)vlrbx,
coalesce(RAZAOPATRIMONIO.vlrbxdep,0) *-1 as vlrbxdep ,
coalesce(RAZAOPATRIMONIO.vlrdepaqant *-1,0) as vlrdep,
coalesce(RAZAOPATRIMONIO.VLRDEPPER*-1,0) as DepCusto,
coalesce(RAZAOPATRIMONIO.VLRAQPERCOR,0) as VLRAQPERCOR,
--RAZAOPATRIMONIO.VLRREAV as ADICAO,
  (SELECT COALESCE(SUM(VLRACRESC),0) as VLRACRESC FROM BEMACRESC WHERE BEMACRESC.ESTAB = RAZAOPATRIMONIO.ESTAB AND BEMACRESC.CODBEM = RAZAOPATRIMONIO.CODBEM and DATAACRESC <=:DTFIM) AS ADICAO,
(RAZAOPATRIMONIO.vlraqcor - coalesce(RAZAOPATRIMONIO.VLRANTRESIDUAL,0) - coalesce(RAZAOPATRIMONIO.VLRDEPAQANT,0)) - RAZAOPATRIMONIO.VLRDEPPER as saldo
,
coalesce(
    (
       select
       sum(vlrbaixa)
       from bensbaixa
       
       where
       bensbaixa.estab = RAZAOPATRIMONIO.estab
       and bensbaixa.codbem = RAZAOPATRIMONIO.codbem
       and bensbaixa.databaixa < DADOS.PRIMEIRO_DIA--TO_DATE(:MES || '/' || :ANO, 'MM/YYYY')
       
        ),0)baixa_p
  ,BENSCP.VLRRESIDUAL
  --,coalesce(BENSCP.taxadep,gruposcp.taxadep)taxadep
  , case when BENSCP.taxadep = 0 or BENSCP.taxadep is null then gruposcp.taxadep
        else BENSCP.taxadep end taxadep
  ,gruposcp.bemcpcred as credito
  ,gruposcp.bemcpdeb as debito
  ,case when benscp.codgrup = 11 then 14308 else gruposcp.DEPRECPCRED end as conta_dep
  FROM
  (
   SELECT
    filial.estab,
    NMES,
    NANO,
    TO_DATE(dt.nmes || '/' || dt.nano, 'MM/YYYY') AS PRIMEIRO_DIA,
    LAST_DAY(TO_DATE(dt.nmes  || '/' || dt.nano, 'MM/YYYY')) AS ULTIMO_DIA
FROM
    DUAL
    inner join viasoft.filial filial on 0=0
    
  INNER JOIN
  (
  SELECT DISTINCT
    NMES,
    NANO
    FROM alldays(:DTINI,:DTFIM)
  
  )dt on 0=0
    
    where
   filial.INATIVA = 'N'
      AND filial.EMPRESA IN 
    (
            SELECT 
            f.estab
            FROM viasoft.filial f
            
            WHERE 
            f.empresa = 1
          /*  (:EMPRESA = 1 AND (f.estab <= 100)) 
            
            OR
            
            
            (:EMPRESA = 2 AND f.estab BETWEEN  802 AND 1000) 
      
      OR 
       (:EMPRESA = 3 AND f.estab in (1001,801)) */
)
    
    
) DADOS
  LEFT JOIN TABLE (RAZAOPATRIMONIO(dados.ESTAB, DADOS.PRIMEIRO_DIA, DADOS.ULTIMO_DIA,NANO,NMES)) RAZAOPATRIMONIO ON 0 = 0
  
  INNER JOIN FILIAL ON FILIAL.ESTAB = RAZAOPATRIMONIO.ESTAB

  INNER JOIN BENSCP ON BENSCP.CODBEM = RAZAOPATRIMONIO.CODBEM
                    AND BENSCP.ESTAB = RAZAOPATRIMONIO.ESTAB
                    
  LEFT JOIN VIASOFTCTB.BENSCP_U BENSCP_U ON BENSCP_U.CODBEM = BENSCP.CODBEM AND
                                            BENSCP_U.ESTAB  = BENSCP.ESTAB                  
                    
    left join gruposcp on
        gruposcp.estab = benscp.estab
        and gruposcp.codgrup = benscp.codgrup
        
    left join bemtransf on
        bemtransf.estabdest = benscp.estab
        and bemtransf.bemdest = benscp.codbem
        
    left join BENSCP borigem on
        borigem.estab = bemtransf.estab
        and borigem.CODBEM = bemtransf.CODBEM
        

        
  
 WHERE (((','||:CODGRUP ||',' LIKE '%,' || RAZAOPATRIMONIO.CODGRUP || ',%')) OR
        (:CODGRUP  = '') OR (:CODGRUP IS NULL))
  --<#if ESTAB?has_content>
      --  AND (filial.ESTAB IN (:ESTAB) OR 0 IN (:ESTAB))
--</#if>
    --  AND BENSCP.CODBEM in (1337,1930,1343)
     --   and BENSCP.codbem = 598
 /*GROUP BY RAZAOPATRIMONIO.ESTAB, RAZAOPATRIMONIO.CODGRUP,RAZAOPATRIMONIO.CODBEM,BENSCP.NOMEBEM, RAZAOPATRIMONIO.NANO,
          RAZAOPATRIMONIO.NMES, RAZAOPATRIMONIO.DESCRICAO,FILIAL.ESTAB,FILIAL.REDUZIDO*/
 ORDER BY RAZAOPATRIMONIO.ESTAB, RAZAOPATRIMONIO.CODGRUP,RAZAOPATRIMONIO.CODBEM,BENSCP.NOMEBEM, RAZAOPATRIMONIO.NANO,
          RAZAOPATRIMONIO.NMES, RAZAOPATRIMONIO.DESCRICAO


)dados1
LEFT JOIN GRUPOSCP ON GRUPOSCP.ESTAB = DADOS1.ESTAB AND GRUPOSCP.CODGRUP = DADOS1.CODGRUP


)dados2


UNION ALL

SELECT
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN '1-OS MATRIZ - SP' END  FILIAL,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN  14203 END contacontabil,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN  'Empilhadeira Hangcha CPQD25 Chassi M5BA21152' END nomebem,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN  0 END taxadep,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN  0 END vidautil,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN  cast('01/03/2024' as date) END dataaquisacao,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN 0.01 end vlraquis,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN 0 end VLRRESIDUAL,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN 0 end A_DEPRECIAR,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN 0 end vlrdepreciado,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN 0 end saldo_adepreciar,
CASE WHEN :DTINI >= '01/01/2024' AND :DTFIM <= '31/03/2024' THEN 0 end porct_deprecioar



FROM DUAL


)dados3

where
(case when vlraquis = 0 and vlrdepreciado = 0 then 1 else 0 end) = 0




)dados4

