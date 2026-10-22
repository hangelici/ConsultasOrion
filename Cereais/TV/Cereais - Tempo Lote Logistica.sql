SELECT
    dados.*,
    RANK() OVER (ORDER BY "Vencimento" ASC NULLS LAST) AS "Rank",
    CASE 
        -- Regras FOB
        WHEN "TipoFrete" = 'FOB' AND "Vencimento" > 0 THEN 'VERMELHO'
        WHEN "TipoFrete" = 'FOB' AND "Vencimento" = 0 THEN 'AMARELO'
        -- Regras CIF
        WHEN "TipoFrete" = 'CIF' AND "Tempo" > 25 THEN 'VERMELHO'
        WHEN "TipoFrete" = 'CIF' AND "Tempo" > 15 THEN 'AMARELO'
        ELSE NULL -- não exibe
    END AS "CorStatus"
FROM (
    SELECT 
        lcdl."StatusId",
        TO_CHAR(lcdl."DataCriacao", 'DD/MM/YYYY') AS "DataCriacao",
        TO_CHAR(lcdl."Validade", 'DD/MM/YYYY') AS "Validade",
        FLOOR(EXTRACT(EPOCH FROM (NOW() - lcdl."DataCriacao")) / 86400) AS "Tempo",
        ROUND(FLOOR(EXTRACT(EPOCH FROM (NOW() - lcdl."InicioEmbarque")) / 86400),0)  AS "Vencimento",
        lcdl."Id",
        se2."UF",
        vu.username AS "AgenteLogistico",
        lcdl."Excluido",
        CASE 
            WHEN lcdl."Valor" = 0 THEN 'FOB'
            ELSE 'CIF'
        END AS "TipoFrete"
    FROM "log_CargaDemandaLote" lcdl
    LEFT JOIN vw_users vu ON vu.userid = lcdl."Usuario"         -- agente logístico
    LEFT JOIN "sys_Empresa" se ON se."Id" = lcdl."EmpresaId"    -- filial
    LEFT JOIN "sys_EstadoMunicipio" sem ON sem."Id" = se."MunicipioId" -- cidade
    LEFT JOIN "sys_Estado" se2 ON se2."Id" = sem."EstadoId"     -- uf
    WHERE lcdl."StatusId" NOT IN (3,7,8,4,6)  AND lcdl."StatusId" = 1 
  	and lcdl."DataCriacao" >=  DATE '2025-01-01' 
  	and lcdl."DataCriacao" <= current_date
) dados
WHERE 
    -- FOB: só mostra vencimento >= 0
    ("TipoFrete" = 'FOB' AND "Vencimento" >= 0)
    -- CIF: só mostra se tempo > 15
    OR ("TipoFrete" = 'CIF' AND "Tempo" > 15)
ORDER BY "TipoFrete", "Tempo" DESC