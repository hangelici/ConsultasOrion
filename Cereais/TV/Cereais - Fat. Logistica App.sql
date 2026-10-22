--- ### Responsavel Logistica
WITH workflow_max AS (
    SELECT
        sw."Referencia",
        MAX(sw."Id") as maxid
    FROM "sys_Workflow" sw
    GROUP BY sw."Referencia"
),
workflow_filtrado AS (
    SELECT
        sw."Referencia",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM workflow_max w
    JOIN "sys_Workflow" sw
        ON sw."Id" = w.maxid
       AND sw."Referencia" = w."Referencia"
    WHERE sw."WorkflowAcaoId" IN (18,27,28,50)
)
SELECT
lcd."Id",
emp."NomeFantasia" as "Filial",
se."UF",
item."Descricao" as "Produto",  -- lateral aqui
lv."Placa",
lcd."DataCriacao",
acao."Descricao" as "Status",
flow."WorkflowAcaoId" as "IdFlow",
lcd."DescrLocalEmbarque" as "Embarque",
sem."Nome"||'-'||se."UF" as "Desembarque",
lcd."Descarga",
vu.dispname as "AgLog",
(EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60)::int as "Min",
(EXTRACT(EPOCH FROM (current_timestamp - lcd."DataCriacao"))/60)::int as "Min_Total",
CASE
    WHEN flow."WorkflowAcaoId" IN (27,28) THEN 'vermelho'
    WHEN flow."WorkflowAcaoId" = 18 AND
         (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) > 10
    THEN 'vermelho'
    WHEN flow."WorkflowAcaoId" = 18 AND
         (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) >= 7
    THEN 'amarelo'
    WHEN flow."WorkflowAcaoId" = 50 AND
         (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) > 30
    THEN 'vermelho'
    WHEN flow."WorkflowAcaoId" = 50 AND
         (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) >= 25
    THEN 'amarelo'
    ELSE 'verde'
END cor_status
FROM "log_CargaDado" lcd
JOIN workflow_filtrado flow ON flow."Referencia" = lcd."Guid"
LEFT JOIN "sys_WorkflowAcao" acao ON acao."Id" = flow."WorkflowAcaoId"
LEFT JOIN "sys_Pessoa" sp ON sp."Id" = lcd."DestinoId"
LEFT JOIN "sys_Empresa" emp ON emp."Id" = lcd."EmpresaId"
LEFT JOIN "sys_EstadoMunicipio" sem ON sem."Id" = emp."MunicipioId"
LEFT JOIN "sys_Estado" se ON se."Id" = sem."EstadoId"
LEFT JOIN "log_CargaTran" lct ON lct."CargaDadoId" = lcd."Id"
LEFT JOIN "log_Veiculo" lv ON lv."Id" = lct."VeiculoId"
LEFT JOIN LATERAL (
    SELECT si."Descricao"
    FROM "log_CargaItem" lci
    JOIN "sys_Item" si ON si."Id" = lci."ProdutoId"
    WHERE lci."CargaDadoId" = lcd."Id"
    LIMIT 1
) item ON true
left join "log_CargaDemandaLote" lcdl on lcdl."Id" = lcd."CargaDemandaLoteId"
left join "log_CargaDemandaOportunidade" lcdo on lcdo."Id" = lcdl."CargaDemandaOportunidadeId"
left join vw_users vu on vu.username = coalesce(lcdo."Usuario",lcdl."Usuario")
WHERE
    lcd."CargaTipoStatusId" <> 7
    AND lcd."DataCriacao" >= DATE '2025-01-01'