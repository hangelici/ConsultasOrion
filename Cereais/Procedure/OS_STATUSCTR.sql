create or replace PROCEDURE OS_STATUSCTRFAT
AS
BEGIN

     EXECUTE IMMEDIATE 'update contrato_u cdu set cdu.statusfat=''2 - Verificar'' 

                            where cdu.contrato=(

                            SELECT

                            CONTRATO.CONTRATO

                            FROM CONTRATO
                            
                            INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
                                                   AND CONTRATOCFG.CONTCONF in (20,21)
                                                   
                            INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB=CONTRATO.ESTAB
                                                 AND U_TEMPRESA.GRAOS=''S''

                            INNER JOIN CONTRATOITE ON
                            (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
                            AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

                            INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                            CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                            CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                            NULL, NULL)) PSALDO
                            ON (0=0)
                            
                             INNER join contrato_u on contrato_u.estab=contrato.estab
                                                and contrato_u.contrato=contrato.contrato
                                                 AND CONTRATO_U.STATUSFAT not in (''2 - Verificar'',''3 - Finalizado'')

                            where arredondar(PSALDO.NQTDSALDO,2) = 0                          
                            and cdu.estab=contrato.estab
                            and cdu.contrato=contrato.contrato)';
                            COMMIT;


    EXECUTE IMMEDIATE 'update contrato_u cdu set cdu.statusfat=''2 - Verificar'' 

                            where cdu.contrato=(

                            SELECT

                            CONTRATO.CONTRATO

                            FROM CONTRATO
                            
                            INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
                                                  AND CONTRATOCFG.CONTCONF in (20,21)
                          
                            INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB=CONTRATO.ESTAB
                                                 AND U_TEMPRESA.GRAOS=''S''

                            INNER JOIN CONTRATOITE ON
                            (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
                            AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

                            INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                            CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                            CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                            NULL, NULL)) PSALDO
                            ON (0=0)
                            
                            INNER join contrato_u on contrato_u.estab=contrato.estab
                                                 and contrato_u.contrato=contrato.contrato
                                                 AND CONTRATO_U.STATUSFAT <> ''2 - Verificar''

                            where arredondar(PSALDO.NQTDSALDO,2) > 0 and
                            ARREDONDAR(((CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2))/contratoite.quantidade)*100),2) between 0 and 9.99
                            and cdu.estab=contrato.estab
                            and cdu.contrato=contrato.contrato)';
                            COMMIT;

    EXECUTE IMMEDIATE 'update contrato_u cdu set cdu.statusfat=''1 - Em Aberto''

                       where cdu.contrato=(

                       SELECT

                       CONTRATO.CONTRATO

                       FROM CONTRATO
                       
                       INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
                                            AND CONTRATOCFG.CONTCONF in (20,21)
                       
                       INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB=CONTRATO.ESTAB
                                                 AND U_TEMPRESA.GRAOS=''S''
                            
                       INNER JOIN CONTRATOITE ON
                       (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
                       AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

                       INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                       CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                       CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                       NULL, NULL)) PSALDO
                       ON (0=0)
                       
                       INNER join contrato_u on contrato_u.estab=contrato.estab
                                            and contrato_u.contrato=contrato.contrato
                                            AND CONTRATO_U.STATUSFAT <> ''3 - Finalizado''

                      where PSALDO.NQTDSALDO > 0 and
                      ARREDONDAR(((CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2))/contratoite.quantidade)*100),2) between 10 and 99.99
                      and cdu.estab=contrato.estab
                      and cdu.contrato=contrato.contrato)';
                      COMMIT;

END;