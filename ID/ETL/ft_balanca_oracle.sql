WITH dados_base AS (

    -- APENAS DESCARGAS pois as regras de bal_entrada, movimentacao, bal_saida, liberacao e fechapeso são diferentes
    
    SELECT 
        balanca.id,
        balanca.estab AS osestab,
        balanca.ticket,
        balanca.romaneioconfig,
        balanca.item AS osproduto,
        balanca.datacriacao,
        balanca.DATAENTRADA,
        balanca.DATAENCENTRADA,
        balanca.DATASAIDA,
        balanca.DATAENCSAIDA,
        balanca.DATACHAMADA,
        DATAFECHAPESO,
        DATAENCFECHAPESO,
        balanca.CHECKIN,

        (CAST(balanca.DATAENCENTRADA AS DATE) - CAST(balanca.DATAENTRADA AS DATE)) * 24 * 60 AS bal_entrada,
        (CAST(balanca.DATASAIDA AS DATE) - CAST(balanca.DATAENCENTRADA AS DATE)) * 24 * 60 AS movimentacao,
        (CAST(balanca.DATAENCSAIDA AS DATE) - CAST(balanca.DATASAIDA AS DATE)) * 24 * 60 AS bal_saida,
        (CAST(balanca.DATAFECHAPESO AS DATE) - CAST(balanca.DATAENCSAIDA AS DATE)) * 24 * 60 AS liberacao,
        (CAST(balanca.DATAENCFECHAPESO AS DATE) - CAST(balanca.DATAFECHAPESO AS DATE)) * 24 * 60 AS fechapeso,

        romacfg.ENTRADASAIDA,

        CASE
            WHEN romacfg.ENTRADASAIDA = 'E' THEN 45
            WHEN romacfg.ENTRADASAIDA = 'S' THEN 80
            ELSE NULL
        END AS TETO

    FROM u_tempobalanca balanca
    
    INNER JOIN romacfg 
        ON romacfg.ROMANEIOCONFIG = balanca.ROMANEIOCONFIG
        
    WHERE romacfg.ENTRADASAIDA = 'E'

    UNION ALL
    
    -- APENAS CARGAS pois as regras de bal_entrada, movimentacao, bal_saida, liberacao e fechapeso são diferentes

    SELECT 
        balanca.id,
        balanca.estab AS osestab,
        balanca.ticket,
        balanca.romaneioconfig,
        balanca.item AS osproduto,
        balanca.DATACRIACAO,
        balanca.DATAENTRADA,
        balanca.DATAENCENTRADA,
        balanca.DATASAIDA,
        balanca.DATAENCSAIDA,
        balanca.DATACHAMADA,
        DATAFECHAPESO,
        DATAENCFECHAPESO,
        balanca.CHECKIN,

        (CAST(balanca.DATAENCENTRADA AS DATE) - CAST(balanca.DATAENTRADA AS DATE)) * 24 * 60 AS bal_entrada,

        CASE
            WHEN balanca.DATACRIACAO < balanca.DATASAIDA THEN 
                (CAST(balanca.DATACRIACAO AS DATE) - CAST(balanca.DATAENCENTRADA AS DATE)) * 24 * 60
            WHEN balanca.DATACRIACAO > balanca.DATASAIDA 
              AND balanca.DATACRIACAO < balanca.DATAENCSAIDA THEN 
                (CAST(balanca.DATASAIDA AS DATE) - CAST(balanca.DATAENCENTRADA AS DATE)) * 24 * 60 
        END AS movimentacao,

        CASE
            WHEN balanca.DATACRIACAO < balanca.DATASAIDA THEN 
                (CAST(balanca.DATASAIDA AS DATE) - CAST(balanca.DATACRIACAO AS DATE)) * 24 * 60
            WHEN balanca.DATACRIACAO > balanca.DATASAIDA 
              AND balanca.DATACRIACAO < balanca.DATAENCSAIDA THEN 
                (CAST(balanca.DATACRIACAO AS DATE) - CAST(balanca.DATASAIDA AS DATE)) * 24 * 60 
        END AS bal_saida,

        (CAST(balanca.DATAFECHAPESO AS DATE) - CAST(balanca.DATAENCSAIDA AS DATE)) * 24 * 60 AS liberacao,

        CASE
            WHEN balanca.DATACRIACAO < balanca.DATASAIDA THEN 
                (CAST(balanca.DATAENCSAIDA AS DATE) - CAST(balanca.DATASAIDA AS DATE)) * 24 * 60 
            WHEN balanca.DATACRIACAO > balanca.DATASAIDA 
              AND balanca.DATACRIACAO < balanca.DATAENCSAIDA THEN 
                (CAST(balanca.DATAENCSAIDA AS DATE) - CAST(balanca.DATACRIACAO AS DATE)) * 24 * 60 
        END AS fechapeso,

        romacfg.ENTRADASAIDA,

        CASE
            WHEN romacfg.ENTRADASAIDA = 'E' THEN 45
            WHEN romacfg.ENTRADASAIDA = 'S' THEN 80
            ELSE NULL
        END AS TETO

    FROM u_tempobalanca balanca
    INNER JOIN romacfg 
        ON romacfg.ROMANEIOCONFIG = balanca.ROMANEIOCONFIG
        
    WHERE romacfg.ENTRADASAIDA = 'S'
),

dados_com_tempo AS (
    SELECT 
        db.*,
        (bal_entrada + movimentacao + bal_saida) AS tempo_total
    FROM dados_base db
),

dados_filtrados AS (
    SELECT 
        dct.*,
        ROW_NUMBER() OVER (
            PARTITION BY id, osestab, ticket, romaneioconfig, osproduto
            ORDER BY (bal_entrada + movimentacao + bal_saida) DESC
        ) AS rn
    FROM dados_com_tempo dct
)

SELECT 
    dados_filtrados.id,
    dados_filtrados.osestab,
    dados_filtrados.ticket,
    dados_filtrados.romaneioconfig,
    dados_filtrados.osproduto,
    dados_filtrados.DATACRIACAO,
    dados_filtrados.DATAENTRADA,
    dados_filtrados.DATAENCENTRADA,
    dados_filtrados.DATASAIDA,
    dados_filtrados.DATAENCSAIDA,
    dados_filtrados.DATACHAMADA,
    dados_filtrados.CHECKIN,
    dados_filtrados.bal_entrada,
    dados_filtrados.movimentacao,
    dados_filtrados.bal_saida,
    dados_filtrados.ENTRADASAIDA,
    dados_filtrados.DATAFECHAPESO,
    dados_filtrados.DATAENCFECHAPESO,
    CASE 
        WHEN dados_filtrados.liberacao < 0 THEN 0 
        ELSE dados_filtrados.liberacao 
    END AS liberacao,
    dados_filtrados.fechapeso,
    dados_filtrados.TETO,
    dados_filtrados.tempo_total,

    CASE
        WHEN dados_filtrados.BAL_ENTRADA > 480 
          OR dados_filtrados.MOVIMENTACAO > 480 
          OR dados_filtrados.BAL_SAIDA > 480 
          OR dados_filtrados.BAL_ENTRADA < 0 
          OR dados_filtrados.MOVIMENTACAO < 0 
          OR dados_filtrados.BAL_SAIDA < 0 
        THEN 'S'

        WHEN dados_filtrados.ENTRADASAIDA = 'S'
          AND (
                 
              dados_filtrados.liberacao IS NULL
              OR dados_filtrados.fechapeso IS NULL
              OR dados_filtrados.fechapeso < 0
             -- OR liberacao < 0
          )
        THEN 'S'
    WHEN
        (CASE WHEN dados_filtrados.BAL_ENTRADA  IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN dados_filtrados.MOVIMENTACAO IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN dados_filtrados.BAL_SAIDA    IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN dados_filtrados.LIBERACAO    IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN dados_filtrados.FECHAPESO    IS NOT NULL THEN 1 ELSE 0 END
        ) = 1
    THEN 'S'

        ELSE 'N'
    END AS erro,

    CASE
        WHEN dados_filtrados.tempo_total > dados_filtrados.TETO THEN 'FORA'
        ELSE 'DENTRO'
    END AS FORA,
    ARREDONDAR((ROMA.PESOTOTAL - ROMA.TARA),2) AS PESOBRUTO

FROM dados_filtrados

left join roma on
    roma.ticket = to_char(dados_filtrados.ticket) AND
    roma.estab =  dados_filtrados.osestab

WHERE rn = 1
