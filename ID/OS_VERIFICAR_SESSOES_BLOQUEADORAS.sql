create or replace NONEDITIONABLE PROCEDURE OS_VERIFICAR_SESSOES_BLOQUEADORAS AS
BEGIN
    FOR r IN (
        SELECT DISTINCT 
               'ALTER SYSTEM KILL SESSION ''' || h.session_id || ',' || ub.serial# || ''' IMMEDIATE;' AS comando_kill,
               h.session_id AS sessao_id, 
               ub.serial# AS serial, 
               ub.username AS usuario_travador
        FROM dba_locks w, dba_locks h, v$session ub, v$session uw
        WHERE h.blocking_others = 'Blocking'
          AND h.mode_held NOT IN ('None', 'Null')
          AND h.session_id = ub.sid
          AND w.mode_requested != 'None'
          AND w.lock_type = h.lock_type
          AND w.lock_id1 = h.lock_id1
          AND w.lock_id2 = h.lock_id2
          AND w.session_id = uw.sid
          AND h.session_id NOT IN (
              SELECT w.session_id
              FROM dba_locks w, dba_locks h, v$session ub, v$session uw
              WHERE h.blocking_others = 'Blocking'
                AND h.mode_held NOT IN ('None', 'Null')
                AND h.session_id = ub.sid
                AND w.mode_requested != 'None'
                AND w.lock_type = h.lock_type
                AND w.lock_id1 = h.lock_id1
                AND w.lock_id2 = h.lock_id2
                AND w.session_id = uw.sid
          )
    ) LOOP
        BEGIN
            -- Registra que a sessão será finalizada
            INSERT INTO SESSION_KILL_LOG (SESSION_ID, SERIAL, USERNAME, STATUS)
            VALUES (r.sessao_id, r.serial, r.usuario_travador, 'Finalizando sessão');
            COMMIT;

            -- Executa o comando para matar a sessão
            EXECUTE IMMEDIATE r.comando_kill;

            -- Registra que a sessão foi finalizada
            INSERT INTO SESSION_KILL_LOG (SESSION_ID, SERIAL, USERNAME, STATUS)
            VALUES (r.sessao_id, r.serial, r.usuario_travador, 'Sessão Finalizada');
            COMMIT;

        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    v_sql_id        VARCHAR2(13);
                    v_sql_text      CLOB;
                    v_comando_kill  VARCHAR2(1000);
                    v_erro          VARCHAR2(4000);
                BEGIN
                    v_comando_kill := r.comando_kill;
                    v_erro := SQLCODE || ' - ' || SQLERRM;

                    -- Tenta capturar SQL_ID e SQL_TEXT
                    SELECT s.sql_id INTO v_sql_id
                    FROM v$session s
                    WHERE s.sid = r.sessao_id AND s.serial# = r.serial;

                    SELECT sql_text INTO v_sql_text
                    FROM v$sql
                    WHERE sql_id = v_sql_id AND ROWNUM = 1;

                    -- Registra erro com SQL capturado
                    INSERT INTO SESSION_KILL_LOG (
                        SESSION_ID, SERIAL, USERNAME, STATUS, ERRO, COMANDO_SQL, SQL_ID, SQL_TEXT
                    ) VALUES (
                        r.sessao_id,
                        r.serial,
                        r.usuario_travador,
                        'Erro',
                        v_erro,
                        v_comando_kill,
                        v_sql_id,
                        v_sql_text
                    );
                    COMMIT;

                EXCEPTION
                    WHEN OTHERS THEN
                        -- Se falhar até ao capturar SQL, loga erro simples
                        v_erro := SQLCODE || ' - ' || SQLERRM;
                        INSERT INTO SESSION_KILL_LOG (
                            SESSION_ID, SERIAL, USERNAME, STATUS, ERRO, COMANDO_SQL
                        ) VALUES (
                            r.sessao_id,
                            r.serial,
                            r.usuario_travador,
                            'Erro (sem SQL)',
                            v_erro,
                            v_comando_kill
                        );
                        COMMIT;
                END;
        END;
    END LOOP;
END OS_VERIFICAR_SESSOES_BLOQUEADORAS;