select
d.OSPESSOA,
d.desc_nome as NOME_CONTRATO,
d.CNPJF as CNPJF_CONTRATO,
d.INSCESTAD as IE_CONTRATO,
d.EMAILNFE as EMAIL_CONTRATO,
-- d.ENDERECO||', '||d.bairro||' - '||c.DESC_CIDADE||'/'||c.uf as ENDERECO_CONTRATO
d.ENDERECO
    || ', ' || d.NUMEROEND
    || ' - ' || d.BAIRRO
    || ', ' || c.DESC_CIDADE
    || ', ' || d.UF
    || ' - CEP: ' || d.CEP AS ENDERECO_CONTRATO
from DM_PESSOAS d
left join dm_cidades c on c.oscidade = d.oscidade