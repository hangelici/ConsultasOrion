select
*
from (
select
d.filial,
d.chave,
d.num as nota,
d.serie,
d.dtemi,
d.hremi,
d.trnplaca as placa,
d2.cfop,
d2.xprod,
d.emitnome,
d.transpnome,
case when d3.infadfisco = '' then d3.infcpl else d3.infadfisco end info,
d2.qcom,
d2.vuncom,
d2.vprod
from "document" d
inner join docitem d2 on d2.chave = d.chave
inner join filial f2 on f2.cnpj = d.destinid
left join filial f on f.cnpj = d.emitid
left join docheadtext d3 on d3.chave = d.chave
where
d.model = '55'
and d2.cfop in ('5102', '6102', '5101', '6101', '5117', '5116', '5907', '5906', '5949', '5923', '5922', '5105')
and cast(d.dtemi as date) >= :DTINI
and f.cnpj is null
and d.filial in (
'07191228002603',
'07191228001208',
'07191228002522',
'07191228003170',
'07191228003090',
'07191228003413',
'07191228005203',
'07191228005467',
'07191228006943',
'07191228007915',
'07191228007591',
'07191228009373',
'07191228009535',
'07191228006781',
'07191228006862',
'07191228007087',
'07191228007168',
'07191228008997',
'07191228009454'
)
and not exists (
	select
		1
	from
		"event" e
	where
		e.chave = d.chave
		and e.tpevento in ('210240', '210220')
)

)dados
where
      'TODOS' in (:PLACA)
      or dados.placa in (:PLACA)
   or exists (
        select 1
        from unnest(string_to_array(:PLACA, ',')) as p(placa)
        where dados.info ilike '%' || p.placa || '%'
   )

order by cast(dtemi as date) asc