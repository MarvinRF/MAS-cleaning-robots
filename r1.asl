// R1 - Coletor Inteligente com Navegação Otimizada
// Prioriza garbage, depois gold, entrega tudo ao R2

/* Crenças iniciais */
at(P) :- pos(P,X,Y) & pos(r1,X,Y).
mission_started(false).

/* Objetivo inicial */
!wait_for_map.

/* Planos */

// AGUARDAR MAPA DO SUPERVISOR
+!wait_for_map : mission_started(true)
   <- .print("[R1] Missão já iniciada, ignorando loop").

+!wait_for_map : not mission_started(true)
   <- .wait(500);
      !wait_for_map.

// RECEBER MAPA E INICIAR COLETA
+resource_map(GarbList, GoldList)[source(supervisor)] : not mission_started(true)
   <- .print("[R1] Mapa recebido do supervisor!");
      -+mission_started(true);
      -+garbage_locations(GarbList);
      -+gold_locations(GoldList);
      .length(GarbList, GCount);
      .length(GoldList, AuCount);
      .print("[R1] Detectado: ", GCount, " lixo(s) e ", AuCount, " ouro(s)");
      !start_collection.

// INICIAR PROCESSO DE COLETA
+!start_collection
   <- .print("[R1] Iniciando coleta inteligente...");
      !collect_all_garbage;
      !collect_all_gold;
      !mission_complete.

// ========== FASE 1: COLETA DE LIXO ==========

+!collect_all_garbage
   <- .print("[R1] === FASE 1: COLETA DE LIXO ===");
      ?garbage_locations(GList);
      if (.empty(GList)) {
         .print("[R1] Nenhum lixo encontrado no mapa")
      } else {
         !process_garbage_list(GList)
      }.

+!process_garbage_list([])
   <- .print("[R1] Todo lixo foi coletado!").

+!process_garbage_list([garbage(X,Y)|Rest])
   <- .print("[R1] Próximo alvo: lixo em (", X, ",", Y, ")");
      !collect_garbage_at(X, Y);
      !process_garbage_list(Rest).

// COLETAR LIXO EM POSIÇÃO ESPECÍFICA
+!collect_garbage_at(X, Y)
   <- .print("[R1] Indo para (", X, ",", Y, ")...");
      !move_to(X, Y);
      
      .print("[R1] Chegou ao lixo, tentando coletar...");
      !ensure_pick(garb);
      
      .print("[R1] Lixo coletado! Levando para R2...");
      !deliver_garbage_to_r2;
      
      .print("[R1] Lixo entregue ao incinerador!");
      .send(supervisor, tell, collection_done);
      .wait(100);  // ⭐ AGUARDA PROCESSAMENTO
      .print("[R1] Próximo alvo...").

// ENTREGAR LIXO AO INCINERADOR R2
+!deliver_garbage_to_r2
   <- ?pos(r2, BX, BY);
      .print("[R1] Movendo para incinerador em (", BX, ",", BY, ")");
      !move_to(BX, BY);
      
      .print("[R1] Descartando lixo...");
      drop(garb);
      .wait(500). // Aguarda R2 queimar

// ========== FASE 2: COLETA DE OURO ==========

+!collect_all_gold
   <- .print("[R1] === FASE 2: COLETA DE OURO ===");
      ?gold_locations(AuList);
      if (.empty(AuList)) {
         .print("[R1] Nenhum ouro encontrado no mapa")
      } else {
         !process_gold_list(AuList)
      }.

+!process_gold_list([])
   <- .print("[R1] Todo ouro foi coletado!").

+!process_gold_list([gold(X,Y)|Rest])
   <- .print("[R1] Próximo alvo: ouro em (", X, ",", Y, ")");
      !collect_gold_at(X, Y);
      !process_gold_list(Rest).

// COLETAR OURO EM POSIÇÃO ESPECÍFICA
+!collect_gold_at(X, Y)
   <- .print("[R1] Indo para (", X, ",", Y, ")...");
      !move_to(X, Y);
      
      .print("[R1] Chegou ao ouro, coletando...");
      !ensure_pick(gold);
      
      .print("[R1] Ouro coletado! Levando para R2 armazenar...");
      !deliver_gold_to_r2.

// ⭐ ENTREGAR OURO PARA R2 ARMAZENAR
+!deliver_gold_to_r2
   <- ?pos(r2, R2X, R2Y);
      .print("[R1] Movendo para R2 em (", R2X, ",", R2Y, ")");
      !move_to(R2X, R2Y);
      
      .print("[R1] Entregando ouro para armazenamento seguro...");
      drop(gold);
      .wait(500); // Aguarda R2 processar
      .print("[R1] Ouro entregue ao R2!").

// ========== MISSÃO COMPLETA ==========

+!mission_complete
   <- .print("[R1] ==============================");
      .print("[R1] === MISSÃO CONCLUÍDA ===");
      .print("[R1] Grid completamente limpo!");
      .print("[R1] Sistema entrando em modo de repouso...");
      .print("[R1] ==============================");
      .send(supervisor, tell, all_clear);
      -+mission_started(complete);
      !standby.

+!standby : mission_started(complete)
   <- .wait(60000);
      !standby.

// ========== UTILITÁRIOS ==========

// COLETA COM RETRY (lida com probabilidade de falha)
+!ensure_pick(garb) : garbage(r1)
   <- pick(garb);
      !ensure_pick(garb).

+!ensure_pick(garb) : not garbage(r1)
   <- .print("[R1] Lixo coletado com sucesso!").

+!ensure_pick(gold) : gold(r1)
   <- pick(gold);
      !ensure_pick(gold).

+!ensure_pick(gold) : not gold(r1)
   <- .print("[R1] Ouro coletado com sucesso!").

// NAVEGAÇÃO INTELIGENTE
+!move_to(X, Y) : pos(r1, X, Y)
   <- .print("[R1] Já está no destino (", X, ",", Y, ")").

+!move_to(X, Y) : not pos(r1, X, Y)
   <- move_towards(X, Y);
      .wait(300);
      ?pos(r1, CX, CY);
      if (CX == X & CY == Y) {
         .print("[R1] Chegou em (", X, ",", Y, ")")
      } else {
         !move_to(X, Y)
      }.