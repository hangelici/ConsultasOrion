
select distinct
        lcd."Id",
        swa."Descricao" as "Status",
        emp."NomeFantasia" as "Filial",
        si."Descricao" as "Produto",
        lv."Placa",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque" as "Embarque",
        sem."Nome"||'-'||se."UF" as "Desembarque",
        ROUND(EXTRACT(EPOCH from (current_timestamp - maximo."DataCriacao")) / 60,0) as "Min",
        ROUND(EXTRACT(EPOCH from (current_timestamp - flow."DataCriacao")) / 60,0) as "Min_Total"
    from "log_CargaDado" lcd
    left join "sys_Pessoa" sp on sp."Id" = lcd."DestinoId"
    left join "sys_EstadoMunicipio" sem on sem."Id" = sp."MunicipioId"
    left join "sys_Estado" se on se."Id" = sem."EstadoId"
    left join "log_CargaTran" lct on lct."CargaDadoId" = lcd."Id"
    left join "log_Veiculo" lv on lv."Id" = lct."VeiculoId"
    left join "log_CargaItem" lci on lci."CargaDadoId" = lcd."Id"
    left join "sys_Item" si on si."Id" = lci."ProdutoId"
    left join "sys_Empresa" emp on emp."Id" = lcd."EmpresaId"
    left join (
        select
            sw1."DataCriacao",
            sw1."WorkflowAcaoId",
            sw1."Referencia"
        from (
            select
                sw."Referencia",
                max(sw."Id") as "maxid"
            from "sys_Workflow" sw
            where sw."WorkflowAcaoId" in (18,16)
            group by "Referencia"
        ) dados
        inner join "sys_Workflow" sw1 on
            sw1."Referencia" = dados."Referencia"
            and sw1."Id" = dados."maxid"
    ) flow on
    flow."Referencia" = lcd."Guid"
    left join (
        select
            sw1."DataCriacao",
            sw1."WorkflowAcaoId",
            sw1."Referencia"
        from (
            select
                sw."Referencia",
                max(sw."Id") as "maxid"
            from "sys_Workflow" sw
            group by "Referencia"
        ) dados
        inner join "sys_Workflow" sw1 on
            sw1."Referencia" = dados."Referencia"
            and sw1."Id" = dados."maxid"
    ) maximo on
    maximo."Referencia" = lcd."Guid"
    left join "sys_WorkflowAcao" swa on swa."Id" = maximo."WorkflowAcaoId"
    where
        lcd."Guid" IN (
            SELECT sw1."Referencia"
            FROM "sys_Workflow" sw1
            WHERE sw1."WorkflowAcaoId" in (18,16)
        )
        AND lcd."Guid" NOT IN (
            SELECT sw2."Referencia"
            FROM "sys_Workflow" sw2
            WHERE sw2."WorkflowAcaoId" in (5,12,13,14,9,14)
        )
        and lcd."Guid" not in (
            select
                sww."Referencia"
            from "sys_Workflow" sww
            inner join (
                select
                    max("Id") as "maxid",
                    "Referencia"
                from "sys_Workflow" sw
                group by "Referencia"
            ) maximo on
                maximo."maxid" = sww."Id"
                and maximo."Referencia" = sww."Referencia"
            where sww."WorkflowAcaoId" = 48
        )
        and lcd."CargaTipoStatusId" not in (7)
        and swa."Id" not in (54)
        and si."ItemGrupoId" = 2
