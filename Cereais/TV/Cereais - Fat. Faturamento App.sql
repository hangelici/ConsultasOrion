-- ### Responsavel Faturamento
select
dados.*
from(
select
lcd."Id",
emp."NomeFantasia" as "Filial",
se."UF",
si."Descricao" as "Produto",
lv."Placa",
lcd."DataCriacao",
acao."Descricao" as "Status",
flow."WorkflowAcaoId" as "IdFlow", 
lcd."DescrLocalEmbarque" as "Embarque",
sem."Nome"||'-'||se."UF" as "Desembarque",
lcd."Descarga",
(EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60)::int as "Min",
(EXTRACT(EPOCH FROM (current_timestamp - flowinicio."DataCriacao"))/60)::int as "Min_Total",
CASE
    WHEN flow."WorkflowAcaoId" IN (22,36,41,42,49,51) THEN 'vermelho'
    WHEN flow."WorkflowAcaoId" = 5 AND (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) > 7 THEN 'vermelho'
    WHEN flow."WorkflowAcaoId" = 5 AND (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) >= 5 THEN 'amarelo'
    WHEN flow."WorkflowAcaoId" = 15 AND (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) > 10 THEN 'vermelho'
    WHEN flow."WorkflowAcaoId" = 15 AND (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) >= 7 THEN 'amarelo'
    WHEN flow."WorkflowAcaoId" = 23 AND (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) > 7 THEN 'vermelho'
    WHEN flow."WorkflowAcaoId" = 23 AND (EXTRACT(EPOCH FROM (current_timestamp - flow."DataCriacao"))/60) >= 5 THEN 'amarelo'
    ELSE 'verde'
END as cor_status
from "log_CargaDado" lcd
left join "sys_Pessoa" sp on sp."Id" = lcd."DestinoId"
left join "log_CargaTran" lct on lct."CargaDadoId" = lcd."Id"
left join "log_Veiculo" lv on lv."Id" = lct."VeiculoId"
left join "log_CargaItem" lci on lci."CargaDadoId" = lcd."Id"
left join "sys_Item" si on si."Id" = lci."ProdutoId"
left join "sys_Empresa" emp on emp."Id" = lcd."EmpresaId"
left join "sys_EstadoMunicipio" sem on sem."Id" = emp."MunicipioId"
left join "sys_Estado" se on se."Id" = sem."EstadoId"
INNER JOIN LATERAL (
    SELECT
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = lcd."Guid"
    ORDER BY sw."Id" DESC
    LIMIT 1
) flow 
ON flow."WorkflowAcaoId" IN (4,15,22,23,42,49,51)
LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE
        sw."Referencia" = lcd."Guid"
        AND sw."WorkflowAcaoId" IN (16,18)
    ORDER BY sw."Id" DESC
    LIMIT 1
) flowinicio ON true
left join "sys_WorkflowAcao" acao on acao."Id" = flow."WorkflowAcaoId"
where
lcd."CargaTipoStatusId" not in (7)
and lcd."DataCriacao" >= DATE '2025-01-01'
) dados
