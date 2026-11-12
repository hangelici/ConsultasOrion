with dre as (
    select distinct
    od.reduzida
    from u_dre od
    where 
    upper(od.DESC2) in ('DESPESAS ADMINISTRATIVAS', 'RATEIOS INTERNOS', 'RATEIOS DESPESAS - MANUTENÇÃO E REPAROS', 'DESPESAS COM PESSOAL')
),
pcc as (
select
u_pcc.osplano,
u_pcc.reduzida
from u_pcc
inner join dre on
    dre.reduzida = u_pcc.depara
    and u_pcc.osplano in ('2#1','1#1')
),
colab as (
    select count(*) as qtd, t.estabc as localtrabalho from viasoft.contamovfuncionario f
    inner join viasoft.u_tempresa t on t.estab = f.localtrabalho
    where f.ativo = 'S'
    group by t.estabc
),
saldo as (
    select
    estabc,
    data,
    arredondar(sum(debitos - creditos),2) as mov
    from(
    select
    pcc.osplano,
    estabc,
    s.centrocus,
    TO_DATE('01/'||''||s.mes||'/'||s.ano,'DD/MM/YYYY') as data,
    s.debitos,
    s.creditos
    from salconce s
    inner join pcc on
        pcc.reduzida = s.analitica
        and pcc.osplano = '1#1'
    inner join cencusce ce on
        ce.centrocus = s.centrocus
        and ce.cencuscod = 2
    inner join viasoft.u_tempresa u on u.estab = to_number(ce.centropai)
    inner join colab on colab.localtrabalho = to_number(ce.centropai)
    where s.estab = 1
    and TO_DATE('01/'||''||s.mes||'/'||s.ano,'DD/MM/YYYY') between :DTINI and :DTFIM

    union all

    select
    pcc.osplano,
    estabc,
    l.cod_cc as centrocus,
    TO_DATE('01/'||''||l.mes||'/'||l.ano,'DD/MM/YYYY') as data,
    l.debitos,
    l.creditos
    from viasoft.u_lancf l
    inner join pcc on
        pcc.reduzida = l.reduzida
        and pcc.osplano = '2#1'
    inner join cencusce ce on
        ce.centrocus = l.cod_cc
        and ce.cencuscod = 2
    inner join viasoft.u_tempresa u on u.estab = to_number(ce.centropai)
    inner join colab on colab.localtrabalho = to_number(ce.centropai)
    where l.osestab = 1
    and TO_DATE('01/'||''||l.mes||'/'||l.ano,'DD/MM/YYYY') between :DTINI and :DTFIM

)dados
    group by
    data,
    estabc
)
select
saldo.*,
colab.qtd,
arredondar(
    divide(
        saldo.mov,
        colab.qtd
    ),2
) as vlr
from saldo
inner join colab on colab.localtrabalho = saldo.estabc