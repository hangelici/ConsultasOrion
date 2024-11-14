select
contamov.numerocm,
contamov.numerocm||'-'||contamov.nome as fornecedor,
nfcab.nota,
pduppaga.quitada,
nfcab.dtentsai,
to_char(nfcab.dtentsai,'MM')mes,
to_char(nfcab.dtentsai,'MM/YYYY')mesano,
to_char(nfcab.dtentsai,'YYYY')ano,
itemagro.descricao as item,
nfcfg.notaconf||' - '||nfcfg.descricao as desc_conf,
nfitem.valortotal as valor
from nfcab

inner join nfitem on nfitem.estab = nfcab.estab
                and nfitem.seqnota = nfcab.seqnota

inner join itemagro on itemagro.item = nfitem.item

inner join contamov on contamov.numerocm = nfcab.numerocm

inner join contamov_u cuu on cuu.numerocm=contamov.numerocm

inner join nfcfg on nfcfg.notaconf = nfcab.notaconf

left join nfcabagrfin on nfcabagrfin.estab = nfcab.estab
                    and nfcabagrfin.seqnota = nfcab.seqnota
                    
left join agrfinduppag on agrfinduppag.estab = nfcabagrfin.estab
                    and agrfinduppag.seqpagamento = nfcabagrfin.seqpagamento
                    
left join pduppaga on pduppaga.empresa = agrfinduppag.estab
                and pduppaga.duppag = agrfinduppag.duppag
                and pduppaga.fornecedor = agrfinduppag.fornecedor


where cuu.fortecnologia='S'
--contamov.numerocm in (34849,32176,21371,32353,16423,20947,
  --                    26897,20691,19901,19901,32176,41306,45954,35812,19904,30631,24952,34416,27507,53136,23972,21278)

and nfcab.notaconf <> 799

/*group by
contamov.nome,
contamov.numerocm,
itemagro.descricao,
nfcab.dtentsai,
nfcfg.notaconf,
nfcfg.descricao*/