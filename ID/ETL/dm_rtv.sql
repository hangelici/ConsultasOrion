SELECT 
    dados.*,
    CASE 
        WHEN FUNC LIKE '%INTERNO%' THEN 'S'
        ELSE 'N'
    END AS INTERNO

FROM (

    SELECT DISTINCT
        preprese.represent || '#' || preprese.empresa AS OSRTV,
        preprese.empresa,
        preprese.represent AS COD_RTV,
        preprese.descricao AS DESC_RTV,
        preprese.tppagcomis,
        preprese.bxcomissaotot,

        CASE
            WHEN U_AGDVINCULO.REPRESENT IS NULL THEN 'N'
            ELSE 'S'
        END AS AGD,

        COALESCE(preprese.comisconf, 0) AS comisconf,

        CASE
            WHEN contamovfuncionario.ativo = 'S' THEN 'N'
            WHEN contamovfuncionario.ativo = 'N' THEN 'S'
        END AS inativo,

        CASE
            WHEN contamovfuncionario.localtrabalho IS NOT NULL
                THEN contamovfuncionario.localtrabalho
            WHEN estabfinresponsavel > 0
                THEN 1
            WHEN contador.qtd IS NULL
                THEN 0
        END AS ESTABRTV,

        COALESCE(cargo.DESCRICAO, 'OUTROS') AS FUNC,
        contamov.CNPJF,
        contamovtribpes.DATAADMISSAO AS dtadmissao,
		contamov_u.OBS_CAD

    FROM preprese

    LEFT JOIN contamov
        ON contamov.numerocm = preprese.represent
        
   LEFT JOIN contamov_u ON
   		contamov_u.numerocm = contamov.numerocm

    LEFT JOIN contamovfuncionario
        ON contamovfuncionario.numerocm = contamov.numerocm

    LEFT JOIN cargo
        ON cargo.idcargo = contamovfuncionario.cargo

    LEFT JOIN contamovtribpes
        ON contamovtribpes.numerocm = contamov.numerocm

    LEFT JOIN (
        SELECT DISTINCT
            represent,
            COUNT(tabprc) AS qtd
        FROM prepretabpre
        GROUP BY represent
    ) contador
        ON contador.represent = preprese.represent

    LEFT JOIN contamovfuncionario
        ON contamovfuncionario.numerocm = contamov.numerocm

    LEFT JOIN U_AGDVINCULO
        ON preprese.REPRESENT = U_AGDVINCULO.REPRESENT

    LEFT JOIN (

        SELECT
            CPF,
            DESCFUNCAO,
            MAX(DT)

        FROM (

            SELECT
                rhpessoa.cpf,
                rhpessoa.nome,
                FUNC.DESCFUNCAO,
                S1.DATA AS DT

            FROM viasoftrh.rhpessoa rhpessoa

            INNER JOIN viasoftrh.rhempregado rhempregado
                ON rhempregado.idpess = rhpessoa.idpess

            INNER JOIN TABLE(
                viasoftrh.RHSITUACAONADATA(
                    RHEMPREGADO.ESTAB,
                    RHEMPREGADO.IDEMPREGADO,
                    CURRENT_DATE
                )
            ) S1
                ON (0 = 0)

            INNER JOIN TABLE(
                viasoftrh.RHFUNCAONADATA(
                    RHEMPREGADO.ESTAB,
                    RHEMPREGADO.IDEMPREGADO,
                    CURRENT_DATE
                )
            ) FUNC
                ON (0 = 0)

            INNER JOIN (

                SELECT
                    rhpessoa.cpf,
                    MAX(S1.DATA) AS DT

                FROM viasoftrh.rhpessoa rhpessoa

                INNER JOIN viasoftrh.rhempregado rhempregado
                    ON rhempregado.idpess = rhpessoa.idpess

                INNER JOIN TABLE(
                    viasoftrh.RHSITUACAONADATA(
                        RHEMPREGADO.ESTAB,
                        RHEMPREGADO.IDEMPREGADO,
                        CURRENT_DATE
                    )
                ) S1
                    ON (0 = 0)

                INNER JOIN TABLE(
                    viasoftrh.RHFUNCAONADATA(
                        RHEMPREGADO.ESTAB,
                        RHEMPREGADO.IDEMPREGADO,
                        CURRENT_DATE
                    )
                ) FUNC
                    ON (0 = 0)

                GROUP BY
                    rhpessoa.cpf

            ) ULT
                ON ULT.CPF = rhpessoa.CPF
               AND ULT.DT = S1.DATA

        ) DADOS

        WHERE DESCFUNCAO IS NOT NULL

        GROUP BY
            CPF,
            DESCFUNCAO

    ) cargo
        ON cargo.cpf = contamov.cnpjf

    WHERE
        preprese.empresa = 1

    UNION ALL

    SELECT
        'SR' AS OSRTV,
        1 AS EMPRESA,
        0 AS COD_RTV,
        'S/ RTV' AS DESC_RTV,
        NULL AS TPPAGCOMIS,
        NULL AS BXCOMISSAOTOT,
        NULL AS AGD,
        NULL AS COMISCONF,
        'N' AS INATIVO,
        NULL AS ESTABRTV,
        NULL AS FUNC,
        NULL AS CNPJF,
        NULL AS dtadmissao,
		null as OBS_CAD

    FROM DUAL

) dados

WHERE
    0 = 0
    -- dados.estabrtv NOT IN (12,25,26,30,31)
    OR dados.cod_rtv IN (32824, 58631, 58626)