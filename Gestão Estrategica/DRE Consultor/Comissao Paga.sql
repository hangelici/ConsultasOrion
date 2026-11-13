-- comis paga
select
estab,
numerocm as represent,
trunc(datacred,'MM') as data,
sum(comisvalor) as comiss_paga
from comisacdoc
where comisacdoc.datacred between :DTINI and :DTFIM
group by 
estab,
numerocm,
trunc(datacred,'MM')