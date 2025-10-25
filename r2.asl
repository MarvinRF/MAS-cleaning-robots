// R2 - Processador
// Queima lixo, guarda ouro

/* Crenças iniciais */
at(P) :- pos(P,X,Y) & pos(r2,X,Y).

/* Planos */

// ========== QUEIMAR LIXO ==========

+garbage(r2) : not gold(r2)
   <- .print("[R2] Queimando lixo...");
      burn(garb);
      .print("[R2] ✓ Lixo queimado!").

+garbage(r2) : gold(r2)
   <- .print("[R2] ALERTA: Ouro presente! Não queimar!").

// ========== ARMAZENAR OURO ==========

+gold(r2) : not garbage(r2)
   <- .print("[R2] ⭐ Armazenando ouro...");
      .wait(300);
      .print("[R2] ✓ Ouro armazenado!").

+gold(r2) : garbage(r2)
   <- .print("[R2] Aguardando queima do lixo...").

// ========== MONITORAMENTO ==========

-garbage(r2) : not gold(r2)
   <- .print("[R2] Pronto para próxima entrega").

-gold(r2) : not garbage(r2)
   <- .print("[R2] Área limpa").