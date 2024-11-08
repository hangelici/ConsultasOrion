select
dados1.*,

case when mes_ent = 7 then 1
    when mes_ent = 8 then 2
    when mes_ent = 9 then 3
    when mes_ent = 10 then 4
    when mes_ent = 11 then 5
    when mes_ent = 12 then 6
    when mes_ent = 1 then 7
    when mes_ent = 2 then 8
    when mes_ent = 3 then 9
    when mes_ent = 4 then 10
    when mes_ent = 5 then 11
    when mes_ent = 6 then 12
    end||'-'||
to_char(cast('01/'||mes_ent||'/'||ano_ent as date),'mon') as mes_nome,
DECODE(mes_ent,
        7, 1,
        8, 2,
        9, 3,
        10, 4,
        11, 5,
        12, 6,
        1, 7,
        2, 8,
        3, 9,
        4, 10,
        5, 11,
        6, 12,
        'Mês inválido'
    ) AS mes_ent_nome
from(
select
uf,
numerocm,
consultor,
cargo,
mes,
ano,
CASE
    WHEN CAST ('01/' || dados.mes || '/' || dados.ano AS VARCHAR(100)) BETWEEN '01/07/2021' AND '30/06/2022' THEN '21/22'
    WHEN CAST ('01/' || dados.mes || '/' || dados.ano AS VARCHAR(100)) BETWEEN '01/07/2022' AND '30/06/2023' THEN '22/23'
    WHEN CAST ('01/' || dados.mes || '/' || dados.ano AS VARCHAR(100)) BETWEEN '01/07/2023' AND '30/06/2024' THEN '23/24'
    WHEN CAST ('01/' || dados.mes || '/' || dados.ano AS VARCHAR(100)) BETWEEN '01/07/2024' AND '30/06/2025' THEN '24/25'
    WHEN CAST ('01/' || dados.mes || '/' || dados.ano AS VARCHAR(100)) BETWEEN '01/07/2025' AND '30/06/2026' THEN '25/26'
END SAFRA_EMISSAO,
CASE
    WHEN CAST ('01/' || dados.mes_ent || '/' || dados.ano_ent AS VARCHAR(100)) BETWEEN '01/07/2021' AND '30/06/2022' THEN '21/22'
    WHEN CAST ('01/' || dados.mes_ent || '/' || dados.ano_ent AS VARCHAR(100)) BETWEEN '01/07/2022' AND '30/06/2023' THEN '22/23'
    WHEN CAST ('01/' || dados.mes_ent || '/' || dados.ano_ent AS VARCHAR(100)) BETWEEN '01/07/2023' AND '30/06/2024' THEN '23/24'
    WHEN CAST ('01/' || dados.mes_ent || '/' || dados.ano_ent AS VARCHAR(100)) BETWEEN '01/07/2024' AND '30/06/2025' THEN '24/25'
        WHEN CAST ('01/' || dados.mes || '/' || dados.ano AS VARCHAR(100)) BETWEEN '01/07/2025' AND '30/06/2026' THEN '25/26'
END SAFRA_ENT,
to_number(mes_ent) as mes_ent,
to_number(ano_ent) as ano_ent,
item,
PRODUTO,
sum(qtdsc) as qtd,
sum(qtdcanc) as qtdcanc,
sum(qtdsc) - sum(qtdcanc) as qtdsc,
0 meta,
local

from(
-------------------------------------------------------------------- COMPRA NORMAL
SELECT
cidade.uf,
contamov.numerocm,
contamov.nome AS consultor,
cargo.idcargo || '-' || cargo.descricao AS cargo,
EXTRACT (MONTH FROM contrato.dtemissao) AS mes,
EXTRACT (YEAR FROM contrato.dtemissao) AS ano,
  --concat((EXTRACT (MONTH FROM contrato.dtemissao)),(EXTRACT (YEAR FROM contrato.dtemissao)) AS am-emissao,
EXTRACT (MONTH FROM contrato.dtlimentimp) AS mes_ent,
EXTRACT (YEAR FROM contrato.dtlimentimp) AS ano_ent,

CASE
    WHEN U_AGRPRODGR.U_AGRPRODGR_ID IS NULL THEN 998
    ELSE U_AGRPRODGR.U_AGRPRODGR_ID
END  ITEM,

CASE
    WHEN u_agrprodgr.U_AGRPRODGR_ID NOT IN (1,2,3,24,5,15)
    THEN
        (SELECT descagrupa
        FROM u_agrprodgr
        WHERE U_AGRPRODGR_ID = 998)
    ELSE
    u_agrprodgr.descagrupa END PRODUTO,
    
COALESCE (arredondar (divide ( (contratoite.quantidade), 60), 2),0) qtdsc,
0 as qtdcanc,
localest.DESCRICAO as local
                   
FROM contrato
INNER JOIN filial ON filial.estab = contrato.estab
INNER JOIN cidade ON cidade.cidade = filial.cidade

INNER JOIN contratoite ON 
    contratoite.estab = contrato.estab
    AND contratoite.contrato = contrato.contrato
    
INNER JOIN
    (SELECT DISTINCT
        contratocom.estab,
        contratocom.contrato,
        contratocom.numerocm
        FROM os_contratocom contratocom
        WHERE contratocom.meta > 0
    )contratocom ON     
    contratocom.contrato = contrato.contrato
    AND contratocom.estab = contrato.estab

INNER JOIN contamov ON contamov.numerocm = contratocom.numerocm
LEFT JOIN contamovfuncionario ON contamovfuncionario.numerocm = contamov.numerocm
LEFT JOIN cargo ON cargo.idcargo = contamovfuncionario.cargo
INNER JOIN itemagro ON itemagro.item = contratoite.item
INNER JOIN itemagro_u ON itemagro_u.item = itemagro.item
LEFT JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = itemagro_u.u_agrprodgr_id
LEFT JOIN localest ON 
          localest.local = contratoite.local
          and localest.estab = contratoite.estab

WHERE 
0=0 
and CAST(contrato.dtemissao AS DATE) BETWEEN CAST(:DTMINI AS DATE) AND CAST(:DTMFIM AS DATE)
AND contrato.contconf IN (1, 2,0)
and ('X' IN (:UF) OR CIDADE.UF IN (:UF))
and contrato.dtlimentimp IS NOT NULL

union all

------------------------------------------------------ COMPRA limite
SELECT
cidade.uf,
contamov.numerocm,
contamov.nome AS consultor,
cargo.idcargo || '-' || cargo.descricao AS cargo,
7 AS mes,
extract(year from CAST(:DTMINI AS DATE)) as ano,
--EXTRACT (YEAR FROM contrato.dtemissao) AS ano,
  --concat((EXTRACT (MONTH FROM contrato.dtemissao)),(EXTRACT (YEAR FROM contrato.dtemissao)) AS am-emissao,
7 AS mes_ent,
extract(year from CAST(:DTMINI AS DATE)) AS ano_ent,

CASE
    WHEN U_AGRPRODGR.U_AGRPRODGR_ID IS NULL THEN 998
    ELSE U_AGRPRODGR.U_AGRPRODGR_ID
END  ITEM,

CASE
    WHEN u_agrprodgr.U_AGRPRODGR_ID NOT IN (1,2,3,24,5,15)
    THEN
        (SELECT descagrupa
        FROM u_agrprodgr
        WHERE U_AGRPRODGR_ID = 998)
    ELSE
    u_agrprodgr.descagrupa END PRODUTO,
    
COALESCE (arredondar (divide ( (contratoite.quantidade), 60), 2),0) qtdsc,
0 as qtdcanc,
localest.DESCRICAO as local
                   
FROM contrato
INNER JOIN filial ON filial.estab = contrato.estab
INNER JOIN cidade ON cidade.cidade = filial.cidade

INNER JOIN contratoite ON 
    contratoite.estab = contrato.estab
    AND contratoite.contrato = contrato.contrato
    
INNER JOIN
    (SELECT DISTINCT
        contratocom.estab,
        contratocom.contrato,
        contratocom.numerocm
        FROM os_contratocom contratocom
        WHERE contratocom.meta > 0
    )contratocom ON     
    contratocom.contrato = contrato.contrato
    AND contratocom.estab = contrato.estab

INNER JOIN contamov ON contamov.numerocm = contratocom.numerocm
LEFT JOIN contamovfuncionario ON contamovfuncionario.numerocm = contamov.numerocm
LEFT JOIN cargo ON cargo.idcargo = contamovfuncionario.cargo
INNER JOIN itemagro ON itemagro.item = contratoite.item
INNER JOIN itemagro_u ON itemagro_u.item = itemagro.item
LEFT JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = itemagro_u.u_agrprodgr_id
LEFT JOIN localest ON 
          localest.local = contratoite.local
          and localest.estab = contratoite.estab

WHERE 
0=0 
and CAST(contrato.dtlimentimp AS DATE) BETWEEN CAST(:DTMINI AS DATE) AND CAST(:DTMFIM AS DATE)
and CAST(contrato.dtemissao AS DATE) < CAST(:DTMINI AS DATE)
AND contrato.contconf IN (1, 2,0)

and ('X' IN (:UF) OR CIDADE.UF IN (:UF))

union all

----------------------------------- CANCELADOS
select
dadosx.uf,
  dadosx.numerocm,
  dadosx.consultor,
  dadosx.cargo,
     case
        when emiss between  CAST(:DTMINI AS DATE) AND CAST(:DTMFIM AS DATE) then extract(month from emiss)
        else 7
        end mes,
    case 
        when emiss between  CAST(:DTMINI AS DATE) AND CAST(:DTMFIM AS DATE) then extract(year from emiss)
        else extract(year from CAST(:DTMINI AS DATE))
        end ano, 
--dadosx.mes,
--dadosx.ano,
dadosx.mes_ent,
dadosx.ano_ent,
dadosx.ITEM,
dadosx.PRODUTO,
dadosx.qtdsc,
dadosx.qtdcanc,
dadosx.local
  
  from(
  
    select
cidade.uf,
contamov.numerocm,
contamov.nome AS consultor,
cargo.idcargo || '-' || cargo.descricao AS cargo,
    
EXTRACT (MONTH FROM contrato.dtlimentimp) AS mes,
EXTRACT (YEAR FROM contrato.dtlimentimp) AS ano,

        
EXTRACT (MONTH FROM contrato.dtlimentimp) AS mes_ent,
EXTRACT (YEAR FROM contrato.dtlimentimp) AS ano_ent,

coalesce(contratocanc.dtcancelamento,contratocanc.data) as emiss,

 case when contrato.dtlimentimp > coalesce(contratocanc.dtcancelamento,contratocanc.data) 
            then contrato.dtlimentimp
            else coalesce(contratocanc.dtcancelamento,contratocanc.data)
        end limiteent,    
        
        
CASE
    WHEN U_AGRPRODGR.U_AGRPRODGR_ID IS NULL THEN 998
    ELSE U_AGRPRODGR.U_AGRPRODGR_ID
END  ITEM,

CASE
    WHEN u_agrprodgr.U_AGRPRODGR_ID NOT IN (1,2,3,24,5,15)
    THEN
        (SELECT descagrupa
        FROM u_agrprodgr
        WHERE U_AGRPRODGR_ID = 998)
    ELSE
    u_agrprodgr.descagrupa END PRODUTO,
    
0 qtdsc,
COALESCE (arredondar (divide ( (contratocanc.quantidade), 60), 2),0) as qtdcanc,
localest.DESCRICAO as local
                   
FROM contrato
INNER JOIN filial ON filial.estab = contrato.estab
INNER JOIN cidade ON cidade.cidade = filial.cidade

INNER JOIN contratoite ON 
    contratoite.estab = contrato.estab
    AND contratoite.contrato = contrato.contrato
    
INNER JOIN
    (SELECT DISTINCT
        contratocom.estab,
        contratocom.contrato,
        contratocom.numerocm
        FROM os_contratocom contratocom
        WHERE contratocom.meta > 0
    )contratocom ON     
    contratocom.contrato = contrato.contrato
    AND contratocom.estab = contrato.estab

INNER JOIN contamov ON contamov.numerocm = contratocom.numerocm
LEFT JOIN contamovfuncionario ON contamovfuncionario.numerocm = contamov.numerocm
LEFT JOIN cargo ON cargo.idcargo = contamovfuncionario.cargo
INNER JOIN itemagro ON itemagro.item = contratoite.item
INNER JOIN itemagro_u ON itemagro_u.item = itemagro.item
LEFT JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = itemagro_u.u_agrprodgr_id

inner join 
    
    contratocanc on
    contratocanc.contrato = contratoite.contrato
    and contratocanc.estab = contratoite.estab
    and contratocanc.seqitem = contratoite.seqitem
    
    LEFT JOIN localest ON 
          localest.local = contratoite.local
          and localest.estab = contratoite.estab
WHERE
0=0
-- CAST(coalesce(contratocanc.dtcancelamento,contratocanc.data) AS DATE) BETWEEN CAST(:DTMINI AS DATE) AND CAST(:DTMFIM AS DATE)
AND contrato.contconf IN (1, 2,0)
and ('X' IN (:UF) OR CIDADE.UF IN (:UF))    
--and contrato.contrato = 1388 and contrato.estab = 31
  )dadosx
  where cast(limiteent as date) BETWEEN CAST(:DTMINI AS DATE) AND CAST(:DTMFIM AS DATE)
  
 
 )dados
 
where 
((0 IN (:ITEM)) OR (dados.item in (:ITEM)))
group by
uf,
numerocm,
consultor,
cargo,
mes,
ano,
mes_ent,
ano_ent,
PRODUTO,
item,
local

union all

SELECT  distinct    
u_metacompra.uf,
u_metacompra.numerocm,
contamov.nome AS consultor,
cargo.idcargo || '-' || cargo.descricao AS cargo,
EXTRACT (MONTH FROM data) AS mes,
EXTRACT (YEAR FROM data) AS ano,

CASE
    WHEN  data BETWEEN '01/07/2021' AND '30/06/2022' THEN '21/22'
    WHEN  data BETWEEN '01/07/2022' AND '30/06/2023' THEN '22/23'
    WHEN  data  BETWEEN '01/07/2023' AND '30/06/2024' THEN '23/24'
    WHEN  data BETWEEN '01/07/2024' AND '30/06/2025' THEN '24/25'
    WHEN  data BETWEEN '01/07/2025' AND '30/06/2026' THEN '25/26'
END SAFRA_EMISSAO,

CASE
    WHEN data BETWEEN '01/07/2021' AND '30/06/2022' THEN '21/22'
    WHEN data BETWEEN '01/07/2022' AND '30/06/2023' THEN '22/23'
    WHEN data BETWEEN '01/07/2023' AND '30/06/2024' THEN '23/24'
    WHEN data BETWEEN '01/07/2024' AND '30/06/2025' THEN '24/25'
    WHEN  data BETWEEN '01/07/2025' AND '30/06/2026' THEN '25/26'
END SAFRA_ENT,

TO_NUMBER(EXTRACT (MONTH FROM data)) AS mes_ent,
TO_NUMBER(EXTRACT (YEAR FROM data)) AS ano_ent,
u_agrprodgr.u_agrprodgr_id AS item,
u_agrprodgr.descagrupa AS produto,
0 as qtd,
0 as qtdcanc,
0 AS qtdsc,
meta,
'0' as local
            FROM u_metacompra
                 INNER JOIN cidade on cidade.uf = u_metacompra.uf
                 INNER JOIN contamov
                    ON contamov.numerocm = u_metacompra.numerocm
                 LEFT JOIN contamovfuncionario
                    ON contamovfuncionario.numerocm = contamov.numerocm
                 LEFT JOIN cargo ON cargo.idcargo = contamovfuncionario.cargo
                 LEFT JOIN FILIAL ON FILIAL.CIDADE = CIDADE.CIDADE
                 --inner join u_agrprodgr on u_agrprodgr.u_agrprodgr_id = u_metacompra.u_agrprodgr_id
                 INNER JOIN u_agrprodgr
                    ON CASE
                          WHEN u_agrprodgr.u_agrprodgr_id NOT IN (1,
                                                                  2,
                                                                  3,
                                                                  4,
                                                                  5,
                                                                  15,
                                                                  24)
                          THEN
                             998
                          ELSE
                             u_agrprodgr.u_agrprodgr_id
                       END = u_metacompra.u_agrprodgr_id
           WHERE 
         --  CAST(u_metacompra.data AS DATE) BETWEEN CAST('01/07/2023' AS DATE) AND CAST(:DTFIMEMI AS DATE)
         CAST(u_metacompra.data AS DATE) BETWEEN CAST(:DTMINI AS DATE) AND CAST(:DTMFIM  AS DATE)
         -- DTFIMEMI 
         and ('X' IN (:UF) OR CIDADE.UF IN (:UF))
         AND ((0 IN (:ITEM)) OR (U_AGRPRODGR.U_AGRPRODGR_ID in (:ITEM)))

)dados1
order by
CASE 
        WHEN mes_ent >= 7 THEN mes_ent
        ELSE mes_ent + 12
    END,
    CASE 
        WHEN mes_ent >= 7 THEN ano_ent
        ELSE ano_ent - 1
    END

