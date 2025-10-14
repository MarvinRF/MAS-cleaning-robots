// R2 - Incinerador Reativo + Armazenador de Ouro
// Queima lixo imediatamente quando detectado
// Armazena ouro com segurança sem destruição

/* Crenças iniciais */
at(P) :- pos(P,X,Y) & pos(r2,X,Y).
gold_storage_count(0).

/* Planos */

// ========== QUEIMA IMEDIATA DE LIXO ==========

+garbage(r2) : not gold(r2)
   <- .print("[R2] Lixo detectado - QUEIMANDO!");
      burn(garb);
      .send(supervisor, tell, burn_done);
      .print("[R2] Lixo queimado com sucesso!").

// PROTEÇÃO DE OURO - Nunca queimar se houver ouro junto
+garbage(r2) : gold(r2)
   <- .print("[R2] !!!ALERTA CRÍTICO!!!");
      .print("[R2] Ouro detectado junto com lixo!");
      .print("[R2] RECUSANDO QUEIMA para proteger ouro!");
      .wait(2000).

// ========== ARMAZENAMENTO DE OURO ==========

+gold(r2) : not garbage(r2)
   <- .print("[R2] 🌟 OURO DETECTADO! 🌟");
      .print("[R2] Iniciando procedimento de armazenamento seguro...");
      .wait(200);
      !secure_gold.

// Se ouro vier junto com lixo, aguarda lixo ser queimado primeiro
+gold(r2) : garbage(r2)
   <- .print("[R2] Ouro detectado, mas há lixo presente");
      .print("[R2] Aguardando queima do lixo primeiro...").

+!secure_gold : gold(r2)
   <- .print("[R2] Verificando integridade do ouro...");
      .wait(200);
      !secure_gold.

+!secure_gold : not gold(r2)
   <- ?gold_storage_count(Count);
      -+gold_storage_count(Count+1);
      .print("[R2] ✓✓✓ OURO ARMAZENADO COM SUCESSO! ✓✓✓");
      .print("[R2] Total de ouro em cofre: ", Count+1);
      .send(supervisor, tell, gold_stored);
      .print("[R2] Supervisor notificado. Aguardando próxima entrega...").

// ========== MONITORAMENTO ==========

// Detecta quando não há mais recursos para processar
-garbage(r2) : not gold(r2)
   <- .print("[R2] Área limpa, aguardando próxima entrega...").

-gold(r2) : not garbage(r2)
   <- .print("[R2] Ouro processado, pronto para nova operação...").