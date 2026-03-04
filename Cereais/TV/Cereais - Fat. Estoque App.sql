select
dados.*,
case
	when "Min" between 10 and 15 then 'amarelo'
	when "Min" > 15 then 'vermelho'
	else 'verde'
end cor_status

from(

select
lcd."Id",
emp."NomeFantasia" as "Filial",
si."Descricao" as "Produto",
lv."Placa",
acao."Descricao" as "Status",
lcd."DataCriacao",
lcd."DescrLocalEmbarque" as "Embarque",
sem."Nome"||'-'||se."UF" as "Desembarque",
lcd."Descarga",
ROUND(EXTRACT(EPOCH from (current_timestamp - flow."DataCriacao")) / 60,0) as "Min",
ROUND(EXTRACT(EPOCH from (current_timestamp - lcd."DataCriacao")) / 60,0) as "Min_Total"

from "log_CargaDado" lcd
left join "sys_Pessoa" sp on sp."Id" = lcd."DestinoId"
left join "sys_EstadoMunicipio" sem on sem."Id" = sp."MunicipioId"
left join "sys_Estado" se on se."Id" = sem."EstadoId"
left join "log_CargaTran" lct on lct."CargaDadoId" = lcd."Id"
left join "log_Veiculo" lv on lv."Id" = lct."VeiculoId"
left join "log_CargaItem" lci on lci."CargaDadoId" = lcd."Id"
left join "sys_Item" si on si."Id" = lci."ProdutoId"
left join "sys_Empresa" emp on emp."Id" = lcd."EmpresaId"

inner join (
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
        and sw1."WorkflowAcaoId" in (52,17)
) flow on
    flow."Referencia" = lcd."Guid"
left join "sys_WorkflowAcao" acao on acao."Id" = flow."WorkflowAcaoId"
where
lcd."CargaTipoStatusId" not in (7)
and extract(year from lcd."DataCriacao") > 2024

) dados
