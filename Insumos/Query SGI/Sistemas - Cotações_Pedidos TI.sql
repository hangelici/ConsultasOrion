WITH COTACOES AS (
    select distinct
    CASE 
        WHEN cotacaocompra.status = 0 THEN 'Em Andamento'
        WHEN cotacaocompra.status = 1 THEN 'Em Aprovação'
        ELSE 'Pedido em Aberto'
    END STATUS,
    cotacaocompra.estab||'#'||cotacaocompra.idcotacaocompra AS CHAVE
    from solmat
    
    left join solmatdet on solmatdet.estab = solmat.estab
                        and solmatdet.idsolmat = solmat.idsolmat
                        
    left join solmat_u on solmat_u.estab = solmat.estab
                        and solmat_u.idsolmat = solmat.idsolmat                                 
    
    left join solmatdetcotacao on solmatdetcotacao.estab = solmatdet.estab
                            and solmatdetcotacao.idsolmat = solmatdet.idsolmat
                            and solmatdetcotacao.idsolmatdet = solmatdet.idsolmatdet
                            
    left join cotacaocompra on cotacaocompra.idcotacaocompra = solmatdetcotacao.idcotacaocompra
                              and cotacaocompra.estab = solmatdetcotacao.estab
    
    LEFT JOIN PUSUARIO ON PUSUARIO.USERID = solmat.usuariosol       
    
    LEFT JOIN PGRUPOS ON PGRUPOS.CODIGO = PUSUARIO.GRUPO
    
    LEFT JOIN FORNECEDORESCOTACAO ON
        FORNECEDORESCOTACAO.IDCOTACAOCOMPRA = COTACAOCOMPRA.IDCOTACAOCOMPRA
        
    LEFT JOIN ITENSCOTACAO ON
        ITENSCOTACAO.IDFORNECEDORES = FORNECEDORESCOTACAO.IDFORNECEDORES
    
    LEFT JOIN COTACAOPEDITEM ON
        COTACAOPEDITEM.IDITEMCOTACAO = ITENSCOTACAO.IDITEMCOTACAO
        
    LEFT JOIN PEDITEM ON
        PEDITEM.ESTAB = COTACAOPEDITEM.ESTAB
        AND PEDITEM.SERIE = COTACAOPEDITEM.SERIE
        AND PEDITEM.NUMERO = COTACAOPEDITEM.NUMERO
        
     LEFT JOIN PEDCAB ON 
        PEDCAB.ESTAB = PEDITEM.ESTAB AND 
        PEDCAB.SERIE = PEDITEM.SERIE AND
        PEDCAB.NUMERO = PEDITEM.NUMERO
                        
    where
    (
        cotacaocompra.status IN (
            0,
            1
        )
        or pedcab.status not in ('B', 'C')
    )
    
    AND (
        PGRUPOS.CODIGO IN (59,60,61,62)
        OR solmat.usuariosol in ('LUA.MARTINS','ELTON.SILVA','MURILO.LEMES','HENRI.GUARI')
    )
)

SELECT
    STATUS,
    COUNT(CHAVE) AS QUANTIDADE
FROM COTACOES
GROUP BY STATUS