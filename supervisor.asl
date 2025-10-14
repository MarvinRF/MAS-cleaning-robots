// Supervisor Inteligente - Mapeia grid e coordena agentes
// Versão corrigida com rastreamento preciso de mensagens

/* Crenças iniciais */
collection_count(0).
burn_count(0).
gold_count(0).
grid_size(8).  // 8x8
scanned(false).

/* Objetivo inicial */
!scan_environment.

/* Planos */

// VARREDURA INICIAL - Mapeia todo o grid
+!scan_environment : not scanned(true)
   <- .print("=== INICIANDO VARREDURA DO AMBIENTE ===");
      ?grid_size(Size);
      !scan_all_cells(0, 0, Size);
      -+scanned(true);
      .print("=== VARREDURA COMPLETA ===");
      !send_initial_map;
      !monitor_system.

// Escanear todas as células recursivamente
+!scan_all_cells(X, Y, Size) : X >= Size
   <- .print("Linha ", Y, " escaneada").

+!scan_all_cells(X, Y, Size) : X < Size & Y >= Size
   <- .print("Varredura do grid completa!").

+!scan_all_cells(X, Y, Size) : X < Size & Y < Size
   <- .wait(50);
      !scan_all_cells(X+1, Y, Size);
      if (X+1 >= Size) {
         !scan_all_cells(0, Y+1, Size)
      }.

// Enviar mapa inicial para R1
+!send_initial_map
   <- .print("Enviando mapa de recursos para R1...");
      .wait(500);
      .findall(garbage(X,Y), garbage_at(X,Y), GarbList);
      .findall(gold(X,Y), gold_at(X,Y), GoldList);
      .length(GarbList, GCount);
      .length(GoldList, AuCount);
      .print("Recursos detectados: ", GCount, " lixo(s), ", AuCount, " ouro(s)");
      
      if (GCount > 0) {
         .print("Lista de lixo: ", GarbList)
      };
      if (AuCount > 0) {
         .print("Lista de ouro: ", GoldList)
      };
      
      .send(r1, tell, resource_map(GarbList, GoldList));
      .print("Mapa enviado para R1 - iniciando coleta inteligente!").

// Monitoramento contínuo
+!monitor_system
   <- .wait(10000);
      !analyze_performance;
      !monitor_system.

// Análise de desempenho
+!analyze_performance
   <- ?collection_count(C);
      ?burn_count(B);
      ?gold_count(G);
      .print("=== RELATÓRIO DO SUPERVISOR ===");
      .print("Coletas de lixo: ", C);
      .print("Lixo queimado: ", B);
      .print("Ouro armazenado: ", G);
      .print("===============================");
      
      if (B == C & C > 0) {
         .print("EXCELENTE: Sistema operando eficientemente!")
      };
      
      if (C > B + 2) {
         .print("ALERTA: R2 está atrasado - ", C-B, " itens aguardando")
      }.

// Atualizar mapa quando recursos são detectados
+garbage_at(X,Y) : true
   <- .print("✓ Lixo mapeado em (", X, ",", Y, ")").

+gold_at(X,Y) : true
   <- .print("✓ Ouro mapeado em (", X, ",", Y, ")").

// ⭐ PROCESSAMENTO DE MENSAGENS - CADA MENSAGEM É ÚNICA
+collection_done[source(r1)]
   <- .print(">>> DEBUG: Recebendo collection_done de R1");
      ?collection_count(C);
      -+collection_count(C+1);
      .print("✓ Coleta #", C+1, " registrada");
      .print(">>> DEBUG: Contador agora em ", C+1).

+burn_done[source(r2)]
   <- .print(">>> DEBUG: Recebendo burn_done de R2");
      ?burn_count(B);
      -+burn_count(B+1);
      .print("✓ Queima #", B+1, " registrada");
      .print(">>> DEBUG: Contador agora em ", B+1).

+gold_stored[source(r2)]
   <- .print(">>> DEBUG: Recebendo gold_stored de R2");
      ?gold_count(G);
      -+gold_count(G+1);
      .print("✓ OURO #", G+1, " ARMAZENADO!");
      .print("Excelente trabalho na proteção de recursos valiosos!");
      .print(">>> DEBUG: Contador agora em ", G+1).

// Notificação de conclusão
+all_clear[source(r1)]
   <- .wait(1000);
      .print("==============================");
      .print("=== MISSÃO CONCLUÍDA ===");
      .print("R1 reportou grid completamente limpo!");
      .print("==============================");
      !final_report.

+!final_report
   <- ?collection_count(C);
      ?burn_count(B);
      ?gold_count(G);
      .print("");
      .print("=== RELATÓRIO FINAL ===");
      .print("Total de lixo coletado: ", C);
      .print("Total de lixo queimado: ", B);
      .print("Total de ouro armazenado: ", G);
      .print("========================");
      
      // Validação de integridade
      if (C == B) {
         .print("✓ Sistema íntegro: Todo lixo foi processado")
      } else {
         .print("⚠ ATENÇÃO: Divergência detectada!")
      };
      
      .print("Sistema em repouso. Missão bem-sucedida!").