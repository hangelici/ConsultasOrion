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
    swa."WorkflowAcaoId",
    swa."DataCriacao"
FROM cargas_filtradas cf
JOIN LATERAL (
    SELECT
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = cf."Guid"
    ORDER BY sw."Id" DESC
    LIMIT 1
)swa ON swa."WorkflowAcaoId" IN (4,15,22,23,42,49,51,52,17)
),
workflow_ag AS (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."WorkflowAcaoId" IN (16,18)
    ORDER BY sw."Referencia", sw."Id" ASC
),
workflow_ag18 AS (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."WorkflowAcaoId" IN (18)
    ORDER BY sw."Referencia", sw."Id" DESC
),
workflow_ag16 AS (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."WorkflowAcaoId" IN (16)
    ORDER BY sw."Referencia", sw."Id" DESC
)
select
c."Id",
c."Guid",
emp."NomeFantasia" as "Filial",
se."UF",
si."Descricao" as "Produto",
wa."DataCriacao",
acao."Descricao" as "Status",
c."DescrLocalEmbarque" as "Embarque",
case 
	when wa."WorkflowAcaoId" in (4,15,22,23,42,49,51) then sem."Nome"||'-'||se."UF"
	else semp."Nome"||'-'||sep."UF"
end "Desembarque",
c."Descarga",
ROUND(EXTRACT(EPOCH from (current_timestamp - ag18."DataCriacao")) / 60,0) as "Min", -- agora para status atual
ROUND(EXTRACT(EPOCH from (current_timestamp - coalesce(ag16."DataCriacao",ag."DataCriacao"))) / 60,0) as "Min_Total"
from cargas_filtradas c
inner join workflow_atual wa ON wa."Guid" = c."Guid"
inner join "sys_Empresa" emp on emp."Id" = c."EmpresaId"
inner join "sys_EstadoMunicipio" sem on sem."Id" = emp."MunicipioId"
inner join "sys_Estado" se on se."Id" = sem."EstadoId"
inner join "log_CargaItem" lci on lci."CargaDadoId" = c."Id"
left join "sys_Item" si on si."Id" = lci."ProdutoId"
inner join "sys_WorkflowAcao" acao on acao."Id" = wa."WorkflowAcaoId"
left join "sys_Pessoa" sp on sp."Id" = c."DestinoId"
left join "sys_EstadoMunicipio" semp on semp."Id" = sp."MunicipioId"
left join "sys_Estado" sep on sep."Id" = semp."EstadoId"
left join workflow_ag ag on ag."Referencia" = c."Guid"
left join workflow_ag18 ag18 on ag18."Referencia" = c."Guid"
left join workflow_ag16 ag16 on ag16."Referencia" = c."Guid"
