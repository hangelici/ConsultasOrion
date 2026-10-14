create or replace NONEDITIONABLE PROCEDURE OS_FINALIZAR_SESSAO_INATIVA
AS
   v_exists NUMBER;
BEGIN
   FOR r IN (
        SELECT s.sid, s.serial#, s.username, s.machine, s.program
        FROM v$session s
        WHERE s.status = 'INACTIVE'
        AND s.username IS NOT NULL
        AND s.username NOT IN ('SYS','SYSTEM','OS.CONTABIL','OS_PENTAHO','OS','OS_ID','OS_ORION','OS_CTB_ORION','OS_API')
        AND s.module not in ('AGRO[OS.CONTABIL]','Oracle SQL Developer for VS Code/26.1.2','AGRO[OS.SISTEMAS]')
        AND s.type <> 'BACKGROUND'
        AND s.last_call_et > 240
        AND s.sid <> SYS_CONTEXT('USERENV','SID')
   )
   LOOP
      BEGIN

         -- confirma se a sessão ainda existe
         SELECT COUNT(*)
         INTO v_exists
         FROM v$session
         WHERE sid = r.sid
         AND serial# = r.serial#;

         IF v_exists > 0 THEN

            DBMS_OUTPUT.PUT_LINE(
               'KILLING SID=' || r.sid ||
               ' SERIAL#=' || r.serial# ||
               ' USER=' || r.username ||
               ' MACHINE=' || r.machine
            );

            EXECUTE IMMEDIATE
               'ALTER SYSTEM KILL SESSION ''' || r.sid || ',' || r.serial# || ''' IMMEDIATE';

         END IF;

      EXCEPTION
         WHEN OTHERS THEN
            -- ignora erros de sessão já encerrada
            IF SQLCODE NOT IN (-31, -26, -27, -30) THEN
               RAISE;
            END IF;
      END;

   END LOOP;
END;