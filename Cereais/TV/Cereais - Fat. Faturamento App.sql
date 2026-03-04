-- ### Responsavel Faturamento
select
dados.*,
case
	when ("Min" between 5 and 7) and "IdFlow" = 5 then 'amarelo'
	when ("Min" > 7) and "IdFlow" = 5 then 'vermelho'
	when "IdFlow" in (22,36,41,42,49,51) then 'vermelho'
	when ("Min" between 7 and 10) and "IdFlow" = 15 then 'amarelo'
	when ("Min" > 10) and "IdFlow" = 15 then 'vermelho'
	when ("Min" between 5 and 7) and "IdFlow" = 23 then 'amarelo'
	when ("Min" > 7) and "IdFlow" = 23 then 'vermelho'
	else 'verde'
end cor_status
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
ROUND(EXTRACT(EPOCH from (current_timestamp - flow."DataCriacao")) / 60,0) as "Min",
ROUND(EXTRACT(EPOCH from (current_timestamp - flowinicio."DataCriacao")) / 60,0) as "Min_Total"
from "log_CargaDado" lcd
left join "sys_Pessoa" sp on sp."Id" = lcd."DestinoId"
left join "log_CargaTran" lct on lct."CargaDadoId" = lcd."Id"
left join "log_Veiculo" lv on lv."Id" = lct."VeiculoId"
left join "log_CargaItem" lci on lci."CargaDadoId" = lcd."Id"
left join "sys_Item" si on si."Id" = lci."ProdutoId"
left join "sys_Empresa" emp on emp."Id" = lcd."EmpresaId"
left join "sys_EstadoMunicipio" sem on sem."Id" = emp."MunicipioId"
left join "sys_Estado" se on se."Id" = sem."EstadoId"
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
        and sw1."WorkflowAcaoId" in (4,15,22,23,42,49,51)
) flow on
    flow."Referencia" = lcd."Guid"
left join (
	select
	sw."Referencia",
	sw."DataCriacao",
	sw."Id"
	from "sys_Workflow" sw
	inner join (
		select
		min(sw2."Id") as "MinId",
		sw2."Referencia"
		from
		"sys_Workflow" sw2
		where
		sw2."WorkflowAcaoId" in (16,18)
		group by sw2."Referencia"
	)maximo on
	maximo."MinId" = sw."Id"
	and  maximo."Referencia" = sw."Referencia"
)flowinicio on flowinicio."Referencia" = lcd."Guid"
left join "sys_WorkflowAcao" acao on acao."Id" = flow."WorkflowAcaoId"
where
lcd."CargaTipoStatusId" not in (7)
and extract(year from lcd."DataCriacao") > 2024
) dados
