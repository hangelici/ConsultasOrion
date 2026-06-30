SELECT
    OSESTAB,
    OSPLANO, 
    COD_CC,
    REDUZIDA,
    ANO, 
    MES,
   -- sum(MOVANT) as MOVANT,
    SUM(SALDO_INICIAL) as SALDO_INICIAL,
    SUM(CREDITOS) AS CREDITOS, 
    SUM(DEBITOS) AS DEBITOS, 
    SUM(RCREDITOS) AS RCREDITOS,
    SUM(RDEBITOS) AS RDEBITOS

FROM(
SELECT
    1 OSESTAB,
    '2#1' OSPLANO,
    cencusce.centrocus AS COD_CC,
    placonan.reduzida AS REDUZIDA,
    MESES.ano,
    MESES.mes,
    COALESCE((
                                    SELECT FIRST 1
                                       ((s.saLdoini +s.debitos+s.rdebitos) - (s.creditos+s.rcreditos))
                                    FROM (
                                        SELECT 
                                            s.meS,
                                            s.anO,
                                            s.anALItIca,
                                            s.CentrOcUs,
                                            s.SALDOINI,
                                               s.debitos,
                                                s.creditos,
                                                s.rcreditos,
                                                s.rdebitos
                                        FROM SALCONCE s 
                                         where s.estab=1
                                        ORDER BY s.ANO DESC, s.MES DESC, s.anaLitiCA, S.centrocUS
                                    ) s 
                                    wheRe caSt('01.' || lpad(s.mes, 2,'0') || '.' || s.Ano as date) < caSt('01.' || lpad(MESES.mes, 2,'0') || '.' || MESES.Ano as date)
                                        AND s.ANALITICA = PLACONAN.REDUZIDA
                                        AND s.CENTROCUS = CENCUSCE.CEntrOCus
                                        AND PLACONAN.PLANO = 1 
                                        


                                ), 0) as saldoini,
                                SALCONCE.saldoini as saldoini2,
    COALESCE(SALCONCE.saldoini, COALESCE((
                                    SELECT FIRST 1
                                       ((s.saLdoini +s.debitos+s.rdebitos) - (s.creditos+s.rcreditos))
                                    FROM (
                                        SELECT 
                                            s.meS,
                                            s.anO,
                                            s.anALItIca,
                                            s.CentrOcUs,
                                            s.SALDOINI,
                                               s.debitos,
                                                s.creditos,
                                                s.rcreditos,
                                                s.rdebitos
                                        FROM SALCONCE s 
                                         where s.estab=1
                                        ORDER BY s.ANO DESC, s.MES DESC, s.anaLitiCA, S.centrocUS
                                    ) s 
                                    wheRe caSt('01.' || lpad(s.mes, 2,'0') || '.' || s.Ano as date) < caSt('01.' || lpad(MESES.mes, 2,'0') || '.' || MESES.Ano as date)
                                        AND s.ANALITICA = PLACONAN.REDUZIDA
                                        AND s.CENTROCUS = CENCUSCE.CEntrOCus
                                        AND PLACONAN.PLANO = 1 
                                        


                                ), 0)
    ) AS SALDO_INICIAL,
    /*(SELECT
            sum(s.debitos - s.creditos) as movant
        FROM SALCONCE s 
        where s.estab=1
        AND S.ANO = SALCONCE.ano
        AND S.MES = SALCONCE.mes
        and s.analitica = SALCONCE.analitica
        and s.centrocus = SALCONCE.centrocus
        and (SELECT DISTINCT 1 FROM SALCONCE S2
                WHERE S2.ANO = case WHEN S.MES = 1 THEN S.ANO-1 ELSE S.ano end
                AND S2.mes = CASE WHEN S.mes = 1 THEN 12 ELSE S.MES-1 END
                AND S2.analitica = S.ANALITICA
                AND S2.centrocus = S.centrocus
            ) IS NULL) AS MOVANT,    */
    COALESCE(SALCONCE.debitos, 0) AS debitos,
    COALESCE(SALCONCE.creditos, 0) AS creditos,
    COALESCE(SALCONCE.rdebitos, 0)rdebitos,
    COALESCE(SALCONCE.rcreditos, 0)rcreditos

FROM (SELECT DISTINCT
        EXTRACT(MONTH FROM ALLDAYS.DDATA) AS MES,
        EXTRACT(YEAR FROM ALLDAYS.DDATA) AS ANO
        FROM ALLDAYS(CAST('01/12/2019' AS DATE),CURRENT_DATE)
    ) MESES 
INNER JOIN PLACONAN 
    ON PLACONAN.PLANO = 1 
INNER JOIN CENCUSCE 
    ON strlen(CENCUSCE.centrocus) = 9
    AND CENCUSCE.CENCUSCOD = 2
LEFT JOIN SALCONCE 
    ON SALCONCE.MES = MESES.MES 
    AND SALCONCE.ANO = MESES.ANO 
    AND SALCONCE.ANALITICA = PLACONAN.REDUZIDA
    AND SALCONCE.CENTROCUS = CENCUSCE.CENTROCUS
    AND SALCONCE.ESTAB = 1

WHERE SALCONCE.ESTAB = 1
--and PLACONAN.REDUZIDA = 35327
--AND CENCUSCE.CENTROCUS = 010000
 order by  CENCUSCE.CENTROCUS,ano,mes
) DADOS 


--where ano = 2022
--and mes in (7,8)

WHERE 

 caSt('01.' || lpad(dados.mes, 2,'0') || '.' || dados.Ano as date) between (select data from U_PINTEGRACAO) and current_date

GROUP BY  
    OSESTAB,
    OSPLANO, 
    COD_CC,
    REDUZIDA,
    ANO, 
    MES