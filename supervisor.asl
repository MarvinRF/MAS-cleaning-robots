// Supervisor Inteligente - Versão Ultra-Simples
// Recebe apenas relatório final do R1

/* Crenças iniciais */
grid_size(8).
scanned(false).

/* Objetivo inicial */
!scan_environment.

/* Planos */

// ==================== VARREDURA INICIAL ====================

+!scan_environment : not scanned(true)
   <- .print("=== INICIANDO VARREDURA DO AMBIENTE ===");
      ?grid_size(Size);
      !scan_all_cells(0, 0, Size);
      -+scanned(true);
      .print("=== VARREDURA COMPLETA ===");
      !send_initial_map;
      !monitor_system.

+!scan_all_cells(X, Y, Size) : X >= Size
   <- .print("Linha ", Y, " escaneada").

+!scan_all_cells(X, Y, Size) : X < Size & Y >= Size
   <- .print("Varredura do grid completa!").

+!scan_all_cells(X, Y, Size) : X < Size & Y < Size & X+1 >= Size
   <- .wait(50);
      !scan_all_cells(X+1, Y, Size);
      !scan_all_cells(0, Y+1, Size).

+!scan_all_cells(X, Y, Size) : X < Size & Y < Size & X+1 < Size
   <- .wait(50);
      !scan_all_cells(X+1, Y, Size).

// ==================== ENVIO DO MAPA ====================

+!send_initial_map
   <- .print("Enviando mapa de recursos para R1...");
      .wait(500);
      .findall(garbage(X,Y), garbage_at(X,Y), GarbList);
      .findall(gold(X,Y), gold_at(X,Y), GoldList);
      .length(GarbList, GCount);
      .length(GoldList, AuCount);
      .print("Recursos detectados: ", GCount, " lixo(s), ", AuCount, " ouro(s)");
      .send(r1, tell, resource_map(GarbList, GoldList));
      .print("Mapa enviado para R1 - iniciando coleta inteligente!").
      
// ==================== MONITORAMENTO ====================

+!monitor_system
   <- .wait(15000);
      .print("=== SUPERVISOR AGUARDANDO CONCLUSÃO ===");
      !monitor_system.

// ==================== RELATÓRIO FINAL ====================

+mission_report(GarbageCollected, GoldCollected)[source(r1)]
   <- .print("==============================");
      .print("=== MISSÃO CONCLUÍDA ===");
      .print("==============================");
      .print("");
      .print("=== RELATÓRIO FINAL ===");
      .print("Total de lixo coletado e queimado: ", GarbageCollected);
      .print("Total de ouro coletado e armazenado: ", GoldCollected);
      .print("========================");
      .print("✓ Sistema íntegro: Missão completa!");
      .print("Sistema em repouso.").