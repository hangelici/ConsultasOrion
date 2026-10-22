SELECT
  dados.*,
  CASE
    WHEN "IdFlow" IN (7) THEN 'vermelho'
    WHEN "Min" > 10 AND "IdFlow" = 46 THEN 'vermelho'
    WHEN ("Min" BETWEEN 7 AND 10) AND "IdFlow" = 46 THEN 'amarelo'
    WHEN "Min" > 7 AND "IdFlow" IN (16,47) THEN 'vermelho'
    WHEN ("Min" BETWEEN 5 AND 7) AND "IdFlow" IN (16,47) THEN 'amarelo'
    ELSE 'verde'
  END cor_status
FROM (
  SELECT
    lcd."Id",
    emp."NomeFantasia" AS "Filial",
    se."UF",
    si."Descricao" AS "Produto",
    lv."Placa",
    lcd."DataCriacao",
    acao."Descricao" AS "Status",
    flow."WorkflowAcaoId" AS "IdFlow", 
    lcd."DescrLocalEmbarque" AS "Embarque",
    sem."Nome" || '-' || se."UF" AS "Desembarque",
    lcd."Descarga",
    -- CORRIGIDO: diferença em minutos entre datas no Oracle
    ROUND((CAST(current_timestamp AS DATE) - CAST(flow."DataCriacao" AS DATE)) * 24 * 60, 0) AS "Min",
    ROUND((CAST(current_timestamp AS DATE) - CAST(lcd."DataCriacao" AS DATE)) * 24 * 60, 0) AS "Min_Total"
  FROM "log_CargaDado" lcd
  LEFT JOIN "sys_Pessoa" sp ON sp."Id" = lcd."DestinoId"
  LEFT JOIN "log_CargaTran" lct ON lct."CargaDadoId" = lcd."Id"
  LEFT JOIN "log_Veiculo" lv ON lv."Id" = lct."VeiculoId"
  LEFT JOIN "log_CargaItem" lci ON lci."CargaDadoId" = lcd."Id"
  LEFT JOIN "sys_Item" si ON si."Id" = lci."ProdutoId"
  LEFT JOIN "sys_Empresa" emp ON emp."Id" = lcd."EmpresaId"
  LEFT JOIN "sys_EstadoMunicipio" sem ON sem."Id" = emp."MunicipioId"
  LEFT JOIN "sys_Estado" se ON se."Id" = sem."EstadoId"
  INNER JOIN (
      SELECT
          sw1."DataCriacao",
          sw1."WorkflowAcaoId",
          sw1."Referencia"
      FROM (
          SELECT
              sw."Referencia",
              MAX(sw."Id") AS "maxid"
          FROM "sys_Workflow" sw
          GROUP BY "Referencia"
      ) dados
      INNER JOIN "sys_Workflow" sw1 ON
          sw1."Referencia" = dados."Referencia"
          AND sw1."Id" = dados."maxid"
          AND sw1."WorkflowAcaoId" IN (25,24)
  ) flow ON
      flow."Referencia" = lcd."Guid"
  LEFT JOIN "sys_WorkflowAcao" acao ON acao."Id" = flow."WorkflowAcaoId"
  WHERE
    lcd."CargaTipoStatusId" NOT IN (7)
    AND EXTRACT(YEAR FROM lcd."DataCriacao") > 2024
) dados