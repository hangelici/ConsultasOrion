WITH cargas_filtradas AS (
SELECT
    lcd."Id",
    lcd."Guid",
    lcd."EmpresaId",
    lcd."DestinoId",
    lcd."DataCriacao",
    lcd."DescrLocalEmbarque",
    lcd."Descarga"
FROM "log_CargaDado" lcd
WHERE
    lcd."CargaTipoStatusId" <> 7
    AND lcd."DataCriacao" >= DATE '2025-01-01'
),
workflow_atual AS (
SELECT
    cf."Guid",
    sw."WorkflowAcaoId",
    sw."DataCriacao"
FROM cargas_filtradas cf
JOIN LATERAL (
    SELECT
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = cf."Guid"
    ORDER BY sw."Id" DESC
    LIMIT 1
) sw ON sw."WorkflowAcaoId" IN (52,17)
)
SELECT
cf."Id",
emp."NomeFantasia" as "Filial",
si."Descricao" as "Produto",
lv."Placa",
acao."Descricao" as "Status",
cf."DataCriacao",
cf."DescrLocalEmbarque" as "Embarque",
sem."Nome"||'-'||se."UF" as "Desembarque",
cf."Descarga",
(EXTRACT(EPOCH FROM (current_timestamp - wa."DataCriacao"))/60)::int as "Min",
(EXTRACT(EPOCH FROM (current_timestamp - cf."DataCriacao"))/60)::int as "Min_Total",
CASE
    WHEN (EXTRACT(EPOCH FROM (current_timestamp - wa."DataCriacao"))/60) > 15 THEN 'vermelho'
    WHEN (EXTRACT(EPOCH FROM (current_timestamp - wa."DataCriacao"))/60) >= 10 THEN 'amarelo'
    ELSE 'verde'
END cor_status
FROM cargas_filtradas cf
JOIN workflow_atual wa ON wa."Guid" = cf."Guid"
LEFT JOIN "sys_WorkflowAcao" acao ON acao."Id" = wa."WorkflowAcaoId"
LEFT JOIN "sys_Pessoa" sp ON sp."Id" = cf."DestinoId"
LEFT JOIN "sys_EstadoMunicipio" sem ON sem."Id" = sp."MunicipioId"
LEFT JOIN "sys_Estado" se ON se."Id" = sem."EstadoId"
LEFT JOIN "log_CargaTran" lct ON lct."CargaDadoId" = cf."Id"
LEFT JOIN "log_Veiculo" lv ON lv."Id" = lct."VeiculoId"
LEFT JOIN "log_CargaItem" lci ON lci."CargaDadoId" = cf."Id"
LEFT JOIN "sys_Item" si ON si."Id" = lci."ProdutoId"
LEFT JOIN "sys_Empresa" emp ON emp."Id" = cf."EmpresaId";