select --dados.saldodisp,
       --dados.saldo,
       dados.tipo,
       dados.estab,
       dados.ES,
       dados.contconf,
       dados.descricao,
       dados.NUMEROCM, 
       dados.NOME,
       dados.CONTRATO,
       dados.pedido,
       TO_CHAR(dados.dtemissao,'DD/MM/YYYY')DTEMISSAO,
       dados.safra,
       TO_CHAR(dados.pedido_emissao,'DD/MM/YYYY')pedido_emissao,
       TO_CHAR(dados.dtmovsaldo,'DD/MM/YYYY')DTMOVSALDO,
       dados.ITEM,    
       dados.valorunit,
       dados.valortotal,
       --CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2)) AS QTDSALDO,
       --COALESCE(PSALDO.NQTDDEV,0) AS QTDDEV,
         dados.QTDCANC,
         dados.qtd,
         CASE WHEN DADOS.TIPO = 2 THEN 0 ELSE DADOS.qtd END AS QTDINICIAL,
         
     SUM(dados.qtd) OVER(PARTITION BY NULL
                             ORDER BY DADOS.TIPO,DADOS.ESTAB, DADOS.dtemissao,DADOS.contrato
                             ROWS BETWEEN
                             UNBOUNDED PRECEDING AND 0 PRECEDING) AS SALDO
         

from(




SELECT

  
       2 as TIPO,         
       CONTRATO.ESTAB,
       contratocfg.entradasaida ES,
       contrato.contconf,contratocfg.descricao,
       CONTRATO.NUMEROCM, CONTAMOV.NOME,
       CONTRATO.CONTRATO,
       contrato.dtemissao,
       contrato.safra,
       pedcab.numero as pedido,  
       pedcab.dtemissao as pedido_emissao,
       contrato.dtmovsaldo,
      CONTRATOITE.ITEM||'-'||ITEMAGRO.DESCRICAO AS ITEM,   
        CASE WHEN contratocfg.entradasaida= 'E' THEN  contratoite.valorunit
   ELSE contratoite.valorunit *-1 END as valorunit,
    
       
     CASE WHEN contratocfg.entradasaida= 'E' THEN  contratoite.valortotal
   ELSE contratoite.valortotal *-1 END as valortotal,
     
         ARREDONDAR(COALESCE(PSALDO.NQTDCANC,0),2) AS QTDCANC,
          CASE WHEN contratocfg.entradasaida = 'E' THEN
          contratoite.quantidade ELSE contratoite.quantidade *-1 END as qtd
     

FROM CONTRATO
      INNER JOIN FILIAL ON
      (FILIAL.ESTAB = CONTRATO.ESTAB)

      INNER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      INNER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

     left join contrato_u on contrato_u.estab=contrato.estab
                        and contrato_u.contrato=contrato.contrato
                        
     left join u_logpedctr on u_logpedctr.contrato = contrato.contrato
                           and  u_logpedctr.estab = contrato.estab
                           
     left join pedcab on pedcab.numero = u_logpedctr.pedido
                      and pedcab.estab = u_logpedctr.estab
  		        AND PEDCAB.PESSOA = u_logpedctr.NUMEROCM

      INNER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
     AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)
  
   INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)

where contrato.contconf in (1,2,20,21)
 
AND ((0 IN (:ESTAB)) OR (CONTRATO.ESTAB IN (:ESTAB)))
and  COALESCE(pedcab.dtemissao,CONTRATO.dtemissao)   between :DTINI and :DTFIM
   
  <#if ITEM?has_content>
 and contratoite.item IN(:ITEM)
 </#if>

AND ((0 IN (:SAFRA)) OR (contrato.safra IN (:SAFRA)))

  union all 
  
  SELECT

  
       2 as TIPO,         
       CONTRATO.ESTAB,
       contratocfg.entradasaida ES,
       contrato.contconf,contratocfg.descricao,
       CONTRATO.NUMEROCM, CONTAMOV.NOME,
       CONTRATO.CONTRATO,
       contrato.dtemissao,
       contrato.safra,
       pedcab.numero as pedido,  
       contrato.dtemissao as pedido_emissao,
       contrato.dtmovsaldo,
      CONTRATOITE.ITEM||'-'||ITEMAGRO.DESCRICAO AS ITEM,   
        CASE WHEN contratocfg.entradasaida= 'E' THEN  contratoite.valorunit
   ELSE contratoite.valorunit *-1 END as valorunit,
    
       
     CASE WHEN contratocfg.entradasaida= 'E' THEN  contratoite.valortotal
   ELSE contratoite.valortotal *-1 END as valortotal,
     
         ARREDONDAR(COALESCE(PSALDO.NQTDCANC,0),2) AS QTDCANC,
          CASE WHEN contratocfg.entradasaida = 'E' THEN
          contratoite.quantidade ELSE contratoite.quantidade *-1 END as qtd
     

FROM CONTRATO
      INNER JOIN FILIAL ON
      (FILIAL.ESTAB = CONTRATO.ESTAB)

      INNER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      INNER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

     left join contrato_u on contrato_u.estab=contrato.estab
                        and contrato_u.contrato=contrato.contrato
                        
     left join u_logpedctr on u_logpedctr.contrato = contrato.contrato
                           and  u_logpedctr.estab = contrato.estab
                           
     left join pedcab on pedcab.numero = u_logpedctr.pedido
                      and pedcab.estab = u_logpedctr.estab
  		        AND PEDCAB.PRESTADOR = u_logpedctr.NUMEROCM

      INNER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
     AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)
  
   INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)

where contrato.contconf in (50,51,6,24)
 
AND ((0 IN (:ESTAB)) OR (CONTRATO.ESTAB IN (:ESTAB)))
and  CONTRATO.dtemissao between :DTINI and :DTFIM
   
  <#if ITEM?has_content>
 and contratoite.item IN(:ITEM)
 </#if>

AND ((0 IN (:SAFRA)) OR (contrato.safra IN (:SAFRA)))

    
order by 9 

)dados