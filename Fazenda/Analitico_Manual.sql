CREATE OR REPLACE VIEW  OS_PLANEJAMENTO_ATIVIDADES as 
WITH base AS (
    SELECT
        fa.OSAPONTA,
        fa.SITUACAO,
        fa.COD_PRODUTOR,
        fa.COD_FAZENDA,
        fa.OSPESSOA,
        fa.COD_ATIVID,
        fa.DT_ABERTO,
        fac.OSTALHAO,
        fac.HA_APLICADOS
    FROM ft_apontamentos fa
    JOIN ft_apt_campos fac
        ON fac.OSAPONTA = fa.OSAPONTA
    WHERE fa.COD_ATIVID IN (18,21,20,8,5,4,86)
      AND fa.SITUACAO = 'Fechado'

    UNION ALL

    SELECT
        '' AS OSAPONTA,
        '' AS SITUACAO,
        dr.NUMEROCM AS COD_PRODUTOR,
        dr.SEQENDERECO AS COD_FAZENDA,
        dr.NUMEROCM || '#' || dr.SEQENDERECO AS OSPESSOA,
        dr.CODIGOATV AS COD_ATIVID,
        dr.DTREPLANEJAMENTO AS DT_ABERTO,
        dr.OSTALHAO,
        0 AS HA_APLICADOS
    FROM dm_replanejamento dr
    WHERE dr.CODIGOATV IN (89,24,88,71,92,96,29)

),

plantio_ref AS (

    SELECT
        b18.OSAPONTA,
        b18.OSTALHAO,
        MIN(b21.DT_ABERTO) AS DT_REPLANTIO
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 21
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY
        b18.OSAPONTA,
        b18.OSTALHAO

),

prox_ativ AS (

    SELECT
        b1.OSAPONTA AS OSAPONTA_BASE,

        MIN(
            CASE
                WHEN b1.COD_ATIVID = 18
                 AND b2.COD_ATIVID = 20
                 AND b2.DT_ABERTO >= b1.DT_ABERTO
                    THEN b2.DT_ABERTO

                WHEN b1.COD_ATIVID = 20
                 AND b2.COD_ATIVID = 8
                 AND b2.DT_ABERTO >= b1.DT_ABERTO
                    THEN b2.DT_ABERTO

                WHEN b1.COD_ATIVID = 24
                 AND b2.COD_ATIVID = 8
                 AND b2.DT_ABERTO >= b1.DT_ABERTO
                    THEN b2.DT_ABERTO
            END
        ) AS DT_ABERTO_PROX_ATIV

    FROM base b1
    LEFT JOIN base b2
        ON b2.OSTALHAO = b1.OSTALHAO
    GROUP BY b1.OSAPONTA

),

plantio_18 AS (

    SELECT
        b18.OSAPONTA AS OSAPONTA_21,
        b18.OSTALHAO,
        MIN(b20.DT_ABERTO) AS DT_1ADUB
    FROM base b20
    LEFT JOIN base b18
        ON b18.OSTALHAO = b20.OSTALHAO
       AND b18.COD_ATIVID = 18
       AND b18.DT_ABERTO <= b20.DT_ABERTO
    WHERE b20.COD_ATIVID = 8
    GROUP BY
        b18.OSAPONTA,
        b18.OSTALHAO

),

plantio_2adub AS (

    SELECT
        b18.OSAPONTA,
        b18.OSTALHAO,
        MIN(b24.DT_ABERTO) AS DT_2ADUB
    FROM base b18
    LEFT JOIN base b24
        ON b24.OSTALHAO = b18.OSTALHAO
       AND b24.COD_ATIVID = 24
       AND b18.DT_ABERTO <= b24.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY
        b18.OSAPONTA,
        b18.OSTALHAO

),

plantio_capina AS (

    SELECT
        b18.OSAPONTA,
        b18.OSTALHAO,
        MIN(b5.DT_ABERTO) AS DT_1CAPINA
    FROM base b18
    LEFT JOIN base b5
        ON b5.OSTALHAO = b18.OSTALHAO
       AND b5.COD_ATIVID = 5
       AND b18.DT_ABERTO <= b5.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY
        b18.OSAPONTA,
        b18.OSTALHAO

),

plantio_2_capina AS (

    SELECT
        b18.OSAPONTA,
        b18.OSTALHAO,
        MIN(b4.DT_ABERTO) AS DT_2CAPINA
    FROM base b18
    LEFT JOIN base b4
        ON b4.OSTALHAO = b18.OSTALHAO
       AND b4.COD_ATIVID = 4
       AND b18.DT_ABERTO <= b4.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY
        b18.OSAPONTA,
        b18.OSTALHAO

),

plantio_capina_cat AS (

    SELECT
        b18.OSAPONTA,
        b18.OSTALHAO,
        MIN(b4.DT_ABERTO) AS DT_CAPCAT
    FROM base b18
    LEFT JOIN base b4
        ON b4.OSTALHAO = b18.OSTALHAO
       AND b4.COD_ATIVID = 86
       AND b18.DT_ABERTO <= b4.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY
        b18.OSAPONTA,
        b18.OSTALHAO

),

plantio_3cap AS (

    SELECT
        b18.OSTALHAO,
        MAX(b18.DT_ABERTO) AS DT_3CAP_PLANTIO
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 89
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY b18.OSTALHAO

),

plantio_2captotal AS (

    SELECT
        b18.OSTALHAO,
        MAX(b18.DT_ABERTO) AS DT_2CAP_PLANTIO
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 88
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY b18.OSTALHAO

),

plantio_2adubplan AS (

    SELECT
        b18.OSTALHAO,
        MAX(b18.DT_ABERTO) AS DT_2ADUB_PLANTIO
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 24
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY b18.OSTALHAO

),

plantio_cap_71 AS (

    SELECT
        b18.OSTALHAO,
        MAX(b18.DT_ABERTO) AS DT_CAP_71_PLANTIO
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 71
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY b18.OSTALHAO

),

plantio_92 AS (
    SELECT
        b18.OSTALHAO,
        MAX(b18.DT_ABERTO) AS DT_2PLANTIO
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 92
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY b18.OSTALHAO

),

plantio_96 AS (

    SELECT
        b18.OSTALHAO,
        MAX(b18.DT_ABERTO) AS DT_ADUB_REF
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 96
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY b18.OSTALHAO

),
plantio_29 AS (
    SELECT
        b18.OSTALHAO,
        MAX(b18.DT_ABERTO) AS DT_ESTRADA
    FROM base b18
    LEFT JOIN base b21
        ON b18.OSTALHAO = b21.OSTALHAO
       AND b21.COD_ATIVID = 29
       AND b18.DT_ABERTO <= b21.DT_ABERTO
    WHERE b18.COD_ATIVID = 18
    GROUP BY b18.OSTALHAO

),
replan AS (

    SELECT
        r.OSTALHAO,

        MIN(CASE WHEN r.CODIGOATV = 8  THEN r.DTREPLANEJAMENTO END) AS replan_1adub,
        MIN(CASE WHEN r.CODIGOATV = 5  THEN r.DTREPLANEJAMENTO END) AS replan_1cap,
        MIN(CASE WHEN r.CODIGOATV = 4  THEN r.DTREPLANEJAMENTO END) AS replan_2cap,
        MIN(CASE WHEN r.CODIGOATV = 24 THEN r.DTREPLANEJAMENTO END) AS replan_2adub,
        MIN(CASE WHEN r.CODIGOATV = 21 THEN r.DTREPLANEJAMENTO END) AS replan_replantio,
        MIN(CASE WHEN r.CODIGOATV = 20 THEN r.DTREPLANEJAMENTO END) AS replan_coveta,
        MIN(CASE WHEN r.CODIGOATV = 18 THEN r.DTREPLANEJAMENTO END) AS replan_plantio,
        MIN(CASE WHEN r.CODIGOATV = 86 THEN r.DTREPLANEJAMENTO END) AS replan_capcat,
        MIN(CASE WHEN r.CODIGOATV = 29 THEN r.DTREPLANEJAMENTO END) AS replan_estradas

    FROM dm_replanejamento r
    GROUP BY r.OSTALHAO

)

SELECT
    b.OSAPONTA,
    b.SITUACAO,
    b.OSPESSOA,
    b.COD_ATIVID,
    b.OSTALHAO,
    b.HA_APLICADOS,
    b.DT_ABERTO,

    p.DT_ABERTO_PROX_ATIV,
    rf.DT_REPLANTIO,
    pl.DT_1ADUB,

    CAST(NULL AS DATE) AS DT_2ADUB,

    pc.DT_1CAPINA,
    p2.DT_2CAPINA,
    pcat.DT_CAPCAT,

    p92.DT_2PLANTIO AS DT_PLT_2PLANTIO,
    p96.DT_ADUB_REF AS DT_PLT_ADUB_REF,
    p29.DT_ESTRADA, -- PLANTIO

    CASE
        WHEN b.COD_ATIVID = 18
         AND rp.replan_plantio IS NOT NULL
            THEN rp.replan_plantio
        WHEN b.COD_ATIVID = 18
            THEN b.DT_ABERTO + 5
    END AS DT_PLANJ_REPLANTIO,

    CASE
        WHEN b.COD_ATIVID = 18
         AND rp.replan_coveta IS NOT NULL
            THEN rp.replan_coveta
        WHEN b.COD_ATIVID = 18
            THEN b.DT_ABERTO + 5
    END AS DT_PLANJ_COVETA,

    CASE
        WHEN b.COD_ATIVID = 18
         AND rp.replan_1adub IS NOT NULL
            THEN rp.replan_1adub
        WHEN b.COD_ATIVID = 18
            THEN b.DT_ABERTO + 90
    END AS DT_PLANJ_1ADUB,

    CASE
        WHEN b.COD_ATIVID = 24
            THEN b.DT_ABERTO
    END AS DT_PLANJ_2ADUB,

    CASE
        WHEN b.COD_ATIVID = 18
         AND rp.replan_1cap IS NOT NULL
            THEN rp.replan_1cap
        WHEN b.COD_ATIVID = 18
            THEN b.DT_ABERTO + 90
    END AS DT_PLANJ_1CAPINA,

    CASE
        WHEN b.COD_ATIVID = 18
         AND rp.replan_2cap IS NOT NULL
            THEN rp.replan_2cap
        WHEN b.COD_ATIVID = 18
            THEN b.DT_ABERTO + 180
    END AS DT_PLANJ_2CAPINA,

    CASE
        WHEN b.COD_ATIVID = 18
         AND rp.replan_capcat IS NOT NULL
            THEN rp.replan_capcat
        WHEN b.COD_ATIVID = 18
            THEN b.DT_ABERTO + 270
    END AS DT_PLANJ_CAPCAT,

    CASE
        WHEN b.COD_ATIVID = 89
            THEN c3.DT_3CAP_PLANTIO
    END AS DT_PLANTIO_3CAP,

    ad.DT_2ADUB_PLANTIO,
    capt_2.DT_2CAP_PLANTIO,
    capt_71.DT_CAP_71_PLANTIO,

    CASE
        WHEN b.COD_ATIVID = 88
            THEN b.DT_ABERTO
    END AS DT_PLANJ_2CAPTOTAL,

    CASE
        WHEN b.COD_ATIVID = 71
            THEN b.DT_ABERTO
    END AS DT_PLANJ_CAP_71

FROM base b

LEFT JOIN prox_ativ p
    ON p.OSAPONTA_BASE = b.OSAPONTA

LEFT JOIN plantio_18 pl
    ON pl.OSAPONTA_21 = b.OSAPONTA
   AND pl.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_ref rf
    ON rf.OSAPONTA = b.OSAPONTA
   AND rf.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_2adub pa
    ON pa.OSAPONTA = b.OSAPONTA
   AND pa.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_capina pc
    ON pc.OSAPONTA = b.OSAPONTA
   AND pc.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_2_capina p2
    ON p2.OSAPONTA = b.OSAPONTA
   AND p2.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_capina_cat pcat
    ON pcat.OSAPONTA = b.OSAPONTA
   AND pcat.OSTALHAO = b.OSTALHAO

LEFT JOIN replan rp
    ON rp.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_3cap c3
    ON c3.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_2adubplan ad
    ON ad.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_2captotal capt_2
    ON capt_2.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_cap_71 capt_71
    ON capt_71.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_92 p92
    ON p92.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_96 p96
    ON p96.OSTALHAO = b.OSTALHAO

LEFT JOIN plantio_29 p29
    ON p29.OSTALHAO = b.OSTALHAO;