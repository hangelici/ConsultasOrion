select
roma.estab as cod_unidade,
romaclass.classificacao as id_classificacao,
roma.romaneio as id_romaneio,
roma.ticket as id_ticket_pesagem,
roma.dtemissao ||' '|| roma.hora as data_hora_classificacao,
roma.item as cod_produto,
sum(case when romadesc.romadesc in (2,32) then romadesc.percentual else null end) umidade_pct,
sum(case when romadesc.romadesc in (1,31) then romadesc.percentual else null end) impureza_pct,
sum(case when romadesc.romadesc in (6,36) then romadesc.percentual else null end) avariados_pct,
roma.ph as ph_valor,
sum(romadesc.pesocalculado) as desconto_qtd_kg,
roma.userid as id_usuario,
case when roma.estornado = 'N' then 'OK' else 'ESTORNADO' end status_romaneio
from roma
left join romaclass on
    romaclass.estab         = roma.estab and
    romaclass.romaneio      = roma.romaneio and
    romaclass.entradasaida  = roma.entradasaida and
    romaclass.numerocm      = roma.numerocm and
    romaclass.percentual    > 0
inner join romadesc on
    romadesc.estab = roma.estab
    and romadesc.romaneio = roma.romaneio
    and romadesc.numerocm = roma.numerocm
    and romadesc.entradasaida = roma.entradasaida
    and romadesc.item = roma.item
inner join romacfg on romacfg.romaneioconfig = roma.romaneioconfig
where roma.estornado = 'N'
and roma.dtemissao between :DTINI and :DTFIM
and romadesc.romadesc in (2,32,1,31,6,36)
and (
    romadesc.percentual <> 0
    or
    romadesc.pesocalculado <> 0
)
/*
2 - umidade / 32 saida
1 - impureza / 31 saida
6 -  avariados / 36 saida
*/
group by
roma.estab,
romaclass.classificacao,
roma.romaneio,
roma.ticket,
roma.dtemissao,
roma.hora,
roma.item,
roma.ph,
roma.userid ,
roma.estornado