// R1 - Coletor
// Coleta tudo e envia relatório final

/* Crenças iniciais */
at(P) :- pos(P,X,Y) & pos(r1,X,Y).
mission_started(false).
garbage_collected(0).
gold_collected(0).

/* Objetivo inicial */
!wait_for_map.

/* Planos */

// AGUARDAR MAPA
+!wait_for_map : mission_started(true)
   <- .print("[R1] Missão já iniciada").

+!wait_for_map : not mission_started(true)
   <- .wait(500);
      !wait_for_map.

// RECEBER MAPA
+resource_map(GarbList, GoldList)[source(supervisor)] : not mission_started(true)
   <- .print("[R1] Mapa recebido!");
      -+mission_started(true);
      -+garbage_locations(GarbList);
      -+gold_locations(GoldList);
      .length(GarbList, GCount);
      .length(GoldList, AuCount);
      .print("[R1] Detectado: ", GCount, " lixo(s) e ", AuCount, " ouro(s)");
      !start_collection.

// INICIAR COLETA
+!start_collection
   <- .print("[R1] === INICIANDO COLETA ===");
      !collect_all_garbage;
      !collect_all_gold;
      !send_final_report.

// ========== COLETAR LIXO ==========

+!collect_all_garbage
   <- .print("[R1] FASE 1: Coletando lixo...");
      ?garbage_locations(GList);
      !process_garbage_list(GList).

+!process_garbage_list([])
   <- .print("[R1] Todo lixo processado!").

+!process_garbage_list([garbage(X,Y)|Rest])
   <- .print("[R1] Indo para lixo em (", X, ",", Y, ")");
      !move_to(X, Y);
      !ensure_pick(garb);
      !deliver_to_r2;
      ?garbage_collected(C);
      -+garbage_collected(C+1);
      .print("[R1] Lixo #", C+1, " entregue!");
      !process_garbage_list(Rest).

// ========== COLETAR OURO ==========

+!collect_all_gold
   <- .print("[R1] FASE 2: Coletando ouro...");
      ?gold_locations(AuList);
      !process_gold_list(AuList).

+!process_gold_list([])
   <- .print("[R1] Todo ouro processado!").

+!process_gold_list([gold(X,Y)|Rest])
   <- .print("[R1] Indo para ouro em (", X, ",", Y, ")");
      !move_to(X, Y);
      !ensure_pick(gold);
      !deliver_to_r2;
      ?gold_collected(G);
      -+gold_collected(G+1);
      .print("[R1] Ouro #", G+1, " entregue!");
      !process_gold_list(Rest).

// ========== ENTREGAR PARA R2 ==========

+!deliver_to_r2
   <- ?pos(r2, BX, BY);
      !move_to(BX, BY);
      drop(garb);
      drop(gold);
      .wait(500).

// ========== RELATÓRIO FINAL ==========

+!send_final_report
   <- ?garbage_collected(GC);
      ?gold_collected(AC);
      .print("[R1] ==============================");
      .print("[R1] === MISSÃO CONCLUÍDA ===");
      .print("[R1] Lixo coletado: ", GC);
      .print("[R1] Ouro coletado: ", AC);
      .print("[R1] ==============================");
      .send(supervisor, tell, mission_report(GC, AC));
      !standby.

+!standby
   <- .wait(60000);
      !standby.

// ========== UTILITÁRIOS ==========

+!ensure_pick(garb) : garbage(r1)
   <- pick(garb);
      !ensure_pick(garb).

+!ensure_pick(garb) : not garbage(r1)
   <- true.

+!ensure_pick(gold) : gold(r1)
   <- pick(gold);
      !ensure_pick(gold).

+!ensure_pick(gold) : not gold(r1)
   <- true.

+!move_to(X, Y) : pos(r1, X, Y)
   <- true.

+!move_to(X, Y) : not pos(r1, X, Y)
   <- move_towards(X, Y);
      .wait(300);
      !move_to(X, Y).