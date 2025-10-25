# 🚀 Mars Cleanup System - Sistema Multi-Agente Inteligente

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura do Sistema](#-arquitetura-do-sistema)
- [Agentes](#-agentes)
- [Fluxo de Operação](#-fluxo-de-operação)
- [Requisitos](#-requisitos)
- [Instalação](#-instalação)
- [Execução](#-execução)
- [Estrutura de Arquivos](#-estrutura-de-arquivos)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Detalhamento Técnico](#-detalhamento-técnico)
- [Solução de Problemas](#-solução-de-problemas)
- [Melhorias Futuras](#-melhorias-futuras)

---

## 🎯 Visão Geral

O **Mars Cleanup System** é um sistema multi-agente desenvolvido em **Jason (AgentSpeak)** para simular operações de limpeza e coleta de recursos em um ambiente de grid 8x8 simulando Marte. O sistema coordena três agentes autônomos que trabalham de forma colaborativa para coletar lixo, queimar resíduos e armazenar recursos valiosos (ouro).

### Objetivos do Sistema

1. **Varredura completa** do ambiente para mapeamento de recursos
2. **Coleta inteligente** de lixo e ouro usando pathfinding
3. **Processamento seguro** de resíduos no incinerador
4. **Armazenamento protegido** de recursos valiosos
5. **Supervisão centralizada** com relatórios de performance

### Principais Características

- ✅ **Arquitetura Multi-Agente**: 3 agentes especializados trabalhando colaborativamente
- ✅ **Comunicação Assíncrona**: Mensagens entre agentes usando protocolo Jason
- ✅ **Navegação Inteligente**: Pathfinding com retry automático
- ✅ **Detecção de Recursos**: Varredura completa do grid 8x8
- ✅ **Processamento Robusto**: Garantia de coleta com retry em caso de falha
- ✅ **Relatórios Detalhados**: Monitoramento em tempo real e relatório final

---

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                      MARS CLEANUP SYSTEM                     │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   SUPERVISOR      │
                    │   (Coordenador)   │
                    └─────────┬─────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
      ┌───────▼───────┐              ┌───────▼───────┐
      │      R1       │              │      R2       │
      │   (Coletor)   │◄────────────►│  (Processador)│
      └───────────────┘   entrega    └───────────────┘
              │            recursos           │
              │                               │
         coleta no                       processa
           grid                           recursos
```

### Hierarquia de Agentes

```
Supervisor (Nível Estratégico)
    ↓
    ├─→ R1 - Robô Coletor (Nível Tático)
    │       • Recebe mapa de recursos
    │       • Planeja rotas otimizadas
    │       • Executa coletas
    │
    └─→ R2 - Robô Processador (Nível Operacional)
            • Queima lixo
            • Armazena ouro
            • Protege recursos valiosos
```

---

## 🤖 Agentes

### 1. Supervisor (supervisor.asl)

**Papel**: Coordenador e monitor central do sistema

**Responsabilidades**:

- 🔍 Varredura inicial completa do grid 8x8
- 📊 Identificação de todos os recursos (garbage e gold)
- 📡 Envio de mapa consolidado para R1
- 📈 Monitoramento periódico do sistema
- 📋 Geração de relatórios finais

**Crenças Principais**:

```asl
grid_size(8)        // Tamanho do grid
scanned(false)      // Status da varredura
```

**Objetivos**:

```asl
!scan_environment   // Objetivo inicial
!send_initial_map   // Enviar mapa para R1
!monitor_system     // Monitoramento contínuo
```

**Comunicação**:

- **Envia para R1**: `resource_map(GarbageList, GoldList)`
- **Recebe de R1**: `mission_report(GarbageCollected, GoldCollected)`

---

### 2. R1 - Robô Coletor (r1.asl)

**Papel**: Agente móvel responsável pela coleta de recursos

**Responsabilidades**:

- 📥 Receber mapa de recursos do Supervisor
- 🎯 Planejar rotas otimizadas (garbage primeiro, depois gold)
- 🚚 Coletar recursos usando `pick(garb)` e `pick(gold)`
- 🔄 Transportar recursos para R2
- 📊 Contar e reportar total de coletas

**Crenças Principais**:

```asl
mission_started(false)     // Status da missão
garbage_collected(0)       // Contador de lixo
gold_collected(0)          // Contador de ouro
garbage_locations([...])   // Lista de posições de lixo
gold_locations([...])      // Lista de posições de ouro
```

**Fluxo de Operação**:

1. **Aguardar Mapa**:

   ```asl
   +!wait_for_map : not mission_started(true)
      <- .wait(500);
         !wait_for_map.
   ```

2. **Receber e Processar Mapa**:

   ```asl
   +resource_map(GarbList, GoldList)[source(supervisor)]
      <- -+mission_started(true);
         -+garbage_locations(GarbList);
         -+gold_locations(GoldList);
         !start_collection.
   ```

3. **Fase 1 - Coletar Lixo**:

   ```asl
   +!collect_all_garbage
      <- ?garbage_locations(GList);
         !process_garbage_list(GList).
   ```

4. **Fase 2 - Coletar Ouro**:

   ```asl
   +!collect_all_gold
      <- ?gold_locations(AuList);
         !process_gold_list(AuList).
   ```

5. **Enviar Relatório Final**:
   ```asl
   +!send_final_report
      <- ?garbage_collected(GC);
         ?gold_collected(AC);
         .send(supervisor, tell, mission_report(GC, AC)).
   ```

**Navegação Inteligente**:

```asl
+!move_to(X, Y) : pos(r1, X, Y)
   <- true.  // Já está no destino

+!move_to(X, Y) : not pos(r1, X, Y)
   <- move_towards(X, Y);
      .wait(300);
      !move_to(X, Y).  // Retry até chegar
```

**Coleta com Retry**:

```asl
// Tenta coletar até conseguir (lida com probabilidade de falha)
+!ensure_pick(garb) : garbage(r1)
   <- pick(garb);
      !ensure_pick(garb).

+!ensure_pick(garb) : not garbage(r1)
   <- true.  // Sucesso!
```

---

### 3. R2 - Robô Processador (r2.asl)

**Papel**: Agente estacionário responsável pelo processamento de recursos

**Responsabilidades**:

- 🔥 Queimar lixo recebido do R1
- ⭐ Armazenar ouro de forma segura
- 🛡️ Proteger ouro (nunca queimar se ouro estiver presente)
- 📦 Manter inventário de recursos processados

**Crenças Principais**:

```asl
at(P) :- pos(P,X,Y) & pos(r2,X,Y)  // Posição fixa em (3,3)
```

**Planos Reativos**:

1. **Queimar Lixo** (apenas se não houver ouro):

   ```asl
   +garbage(r2) : not gold(r2)
      <- .print("[R2] Queimando lixo...");
         burn(garb);
         .print("[R2] ✓ Lixo queimado!").
   ```

2. **Proteger Ouro**:

   ```asl
   +garbage(r2) : gold(r2)
      <- .print("[R2] ALERTA: Ouro presente! Não queimar!").
   ```

3. **Armazenar Ouro** (apenas se não houver lixo):

   ```asl
   +gold(r2) : not garbage(r2)
      <- .print("[R2] ⭐ Armazenando ouro...");
         .wait(300);
         .print("[R2] ✓ Ouro armazenado!").
   ```

4. **Aguardar Limpeza**:
   ```asl
   +gold(r2) : garbage(r2)
      <- .print("[R2] Aguardando queima do lixo...").
   ```

**Sistema de Segurança**:

- ⚠️ **Nunca queima** se detectar ouro presente
- ⏳ **Aguarda processamento** do lixo antes de armazenar ouro
- 🔒 **Armazenamento seguro** sem risco de destruição

---

## 🔄 Fluxo de Operação

### Diagrama de Sequência Completo

```
┌────────────┐        ┌────────────┐        ┌────────────┐
│ Supervisor │        │     R1     │        │     R2     │
└──────┬─────┘        └──────┬─────┘        └──────┬─────┘
       │                     │                     │
       │ 1. Varredura Grid   │                     │
       │────────────────────►│                     │
       │                     │                     │
       │ 2. Mapa de Recursos │                     │
       │────────────────────►│                     │
       │                     │                     │
       │                     │ 3. Coleta Lixo #1  │
       │                     │────────────────────►│
       │                     │                     │
       │                     │                     │ 4. Queima
       │                     │                     │────────►
       │                     │                     │
       │                     │ 5. Coleta Lixo #2  │
       │                     │────────────────────►│
       │                     │                     │
       │                     │                     │ 6. Queima
       │                     │                     │────────►
       │                     │                     │
       │                     │ 7. Coleta Ouro #1  │
       │                     │────────────────────►│
       │                     │                     │
       │                     │                     │ 8. Armazena
       │                     │                     │────────►
       │                     │                     │
       │ 9. Relatório Final  │                     │
       │◄────────────────────│                     │
       │                     │                     │
```

### Fases Detalhadas

#### Fase 1: Inicialização (0-5s)

1. **Ambiente carrega** (MarsEnv.java)

   - Grid 8x8 criado
   - Recursos distribuídos aleatoriamente
   - R1 posicionado em (0,0)
   - R2 posicionado em (3,3)

2. **Supervisor inicia**

   ```
   [supervisor] === INICIANDO VARREDURA DO AMBIENTE ===
   ```

3. **Varredura célula por célula**
   ```
   [supervisor] Linha 0 escaneada
   [supervisor] Linha 1 escaneada
   ...
   [supervisor] Linha 7 escaneada
   [supervisor] Varredura do grid completa!
   ```

#### Fase 2: Mapeamento (5-6s)

4. **Consolidação de recursos**

   ```asl
   .findall(garbage(X,Y), garbage_at(X,Y), GarbList)
   .findall(gold(X,Y), gold_at(X,Y), GoldList)
   ```

5. **Envio do mapa para R1**

   ```
   [supervisor] Recursos detectados: 4 lixo(s), 2 ouro(s)
   [supervisor] Mapa enviado para R1
   ```

6. **R1 recebe e planeja**
   ```
   [r1] Mapa recebido!
   [r1] Detectado: 4 lixo(s) e 2 ouro(s)
   [r1] === INICIANDO COLETA ===
   ```

#### Fase 3: Coleta de Lixo (6-30s)

Para cada lixo na lista:

7. **R1 navega até o lixo**

   ```
   [r1] Indo para lixo em (1,3)
   [MarsEnv] r1 executando: move_towards(1,3)
   ```

8. **R1 coleta o lixo** (com retry se falhar)

   ```
   [MarsEnv] r1 executando: pick(garb)
   ✓ R1 coletou lixo!
   ```

9. **R1 transporta para R2**

   ```
   [r1] Indo para R2 em (3,3)
   [MarsEnv] r1 executando: move_towards(3,3)
   ```

10. **R1 entrega o lixo**

    ```
    [MarsEnv] r1 executando: drop(garb)
    ✓ R1 largou lixo
    ```

11. **R2 queima imediatamente**
    ```
    [r2] Queimando lixo...
    [MarsEnv] r2 executando: burn(garb)
    ✓ R2 queimou lixo!
    ```

_Repete para cada lixo..._

#### Fase 4: Coleta de Ouro (30-45s)

Para cada ouro na lista:

12. **R1 navega até o ouro**

    ```
    [r1] FASE 2: Coletando ouro...
    [r1] Indo para ouro em (2,5)
    ```

13. **R1 coleta o ouro**

    ```
    [MarsEnv] r1 executando: pick(gold)
    ✓ R1 coletou ouro!
    ```

14. **R1 transporta para R2**

    ```
    [r1] Indo para R2 em (3,3)
    ```

15. **R1 entrega o ouro**

    ```
    [MarsEnv] r1 executando: drop(gold)
    ✓ R1 armazenou ouro
    ```

16. **R2 armazena com segurança**
    ```
    [r2] ⭐ Armazenando ouro...
    [r2] ✓ Ouro armazenado!
    ```

_Repete para cada ouro..._

#### Fase 5: Finalização (45-46s)

17. **R1 envia relatório final**

    ```
    [r1] === MISSÃO CONCLUÍDA ===
    [r1] Lixo coletado: 4
    [r1] Ouro coletado: 2
    ```

18. **Supervisor recebe e exibe relatório**

    ```
    [supervisor] === RELATÓRIO FINAL ===
    [supervisor] Total de lixo coletado e queimado: 4
    [supervisor] Total de ouro coletado e armazenado: 2
    [supervisor] ✓ Sistema íntegro: Missão completa!
    ```

19. **Sistema entra em standby**
    ```
    [supervisor] Sistema em repouso.
    ```

---

## 📦 Requisitos

### Software Necessário

- **Java JDK**: 8 ou superior
- **Jason Framework**: 2.6 ou superior
- **IDE Recomendada**: Eclipse, IntelliJ IDEA, ou VS Code com extensão Jason

### Dependências

```xml
<!-- Jason já inclui todas as dependências necessárias -->
- jason-2.6.jar (ou superior)
- cartago-2.5.jar
- stdlib AgentSpeak
```

### Sistema Operacional

- ✅ Windows 10/11
- ✅ Linux (Ubuntu 20.04+)
- ✅ macOS 10.15+

---

## 🚀 Instalação

### 1. Instalar Jason Framework

#### Opção A: Download Direto

```bash
# Baixar do site oficial
https://sourceforge.net/projects/jason/

# Extrair o arquivo
unzip jason-2.6.zip

# Configurar variável de ambiente
export JASON_HOME=/path/to/jason-2.6
export PATH=$PATH:$JASON_HOME/bin
```

#### Opção B: Via Gradle

```gradle
dependencies {
    implementation 'org.jason-lang:jason:2.6'
}
```

### 2. Clonar o Projeto

```bash
git clone https://github.com/seu-usuario/mars-cleanup-system.git
cd mars-cleanup-system
```

### 3. Verificar Estrutura

```
mars-cleanup-system/
├── supervisor.asl
├── r1.asl
├── r2.asl
├── mars.mas2j
├── MarsEnv.java
└── README.md
```

---

## ▶️ Execução

### Método 1: Via Linha de Comando

```bash
# Navegar até o diretório do projeto
cd mars-cleanup-system

# Executar o sistema
jason mars.mas2j
```

### Método 2: Via IDE (Eclipse)

1. Importar projeto como "Jason Project"
2. Abrir arquivo `mars.mas2j`
3. Clicar com botão direito → "Run As" → "Jason Application"

### Método 3: Via Gradle

```bash
gradle run
```

### Saída Esperada

```
Runtime Services (RTS) is running at 192.168.1.103:xxxxx
Agent mind inspector is running at http://192.168.1.103:3272
========================================
  INICIALIZANDO MARS ENVIRONMENT
  Grid: 8x8
========================================

=== ADICIONANDO RECURSOS AO GRID ===
✓ Lixo adicionado em (1,1)
✓ Lixo adicionado em (1,3)
✓ Lixo adicionado em (6,2)
✓ Lixo adicionado em (4,6)
✓ Ouro adicionado em (7,7)
✓ Ouro adicionado em (2,5)
=== RECURSOS ADICIONADOS ===

[supervisor] === INICIANDO VARREDURA DO AMBIENTE ===
[supervisor] Varredura do grid completa!
[supervisor] Mapa enviado para R1

[r1] Mapa recebido!
[r1] === INICIANDO COLETA ===
[r1] FASE 1: Coletando lixo...
...
[r1] === MISSÃO CONCLUÍDA ===
[r1] Lixo coletado: 4
[r1] Ouro coletado: 2

[supervisor] === RELATÓRIO FINAL ===
[supervisor] Total de lixo coletado e queimado: 4
[supervisor] Total de ouro coletado e armazenado: 2
[supervisor] ✓ Sistema íntegro: Missão completa!
```

---

## 📁 Estrutura de Arquivos

### mars.mas2j (Configuração do Sistema)

```java
MAS mars {
    infrastructure: Centralised

    environment: MarsEnv

    agents:
        supervisor;
        r1;
        r2 #[beliefs="pos(r2,3,3)"];  // R2 fixo em (3,3)

    aslSourcePath: "src/asl";
}
```

**Configurações**:

- `infrastructure: Centralised` - Todos os agentes em uma única JVM
- `environment: MarsEnv` - Classe Java do ambiente
- Posição inicial de R2 definida como crença

### MarsEnv.java (Ambiente)

Classe Java que implementa o grid 8x8 e as ações dos agentes:

```java
public class MarsEnv extends Environment {
    // Grid 8x8
    private static final int GRID_SIZE = 8;

    // Ações disponíveis
    public boolean executeAction(String ag, Structure action) {
        if (action.getFunctor().equals("move_towards")) {
            // Movimento
        } else if (action.getFunctor().equals("pick")) {
            // Coleta
        } else if (action.getFunctor().equals("drop")) {
            // Descarte
        } else if (action.getFunctor().equals("burn")) {
            // Queima
        }
    }
}
```

**Percepções Fornecidas**:

- `pos(Agent, X, Y)` - Posição de cada agente
- `garbage(Agent)` - Agente está carregando lixo
- `gold(Agent)` - Agente está carregando ouro
- `garbage_at(X, Y)` - Lixo em posição (X,Y)
- `gold_at(X, Y)` - Ouro em posição (X,Y)

---

## 🔧 Tecnologias Utilizadas

### Jason (AgentSpeak)

**Versão**: 2.6+

**Características Principais**:

- Linguagem de programação orientada a agentes
- Baseada em BDI (Beliefs, Desires, Intentions)
- Sintaxe Prolog-like
- Comunicação via KQML/FIPA

**Componentes BDI**:

```asl
// BELIEFS (Crenças) - O que o agente sabe
pos(r1, 0, 0).
garbage_collected(0).

// DESIRES (Desejos) - O que o agente quer alcançar
!collect_all_garbage.

// INTENTIONS (Intenções) - Planos para alcançar desejos
+!collect_all_garbage
   <- .print("Coletando...");
      !move_to(1, 1);
      pick(garb).
```

### Java

**Versão**: 8+

**Uso**: Implementação do ambiente (MarsEnv.java)

**Bibliotecas**:

- `jason.environment.Environment` - Classe base para ambientes
- `jason.asSyntax.*` - Manipulação de estruturas AgentSpeak

### Padrões de Design Implementados

1. **Observer Pattern**: Agentes observam mudanças no ambiente
2. **Strategy Pattern**: Diferentes estratégias de coleta (lixo vs ouro)
3. **Command Pattern**: Ações encapsuladas como comandos
4. **State Pattern**: Estados dos agentes (idle, moving, collecting, etc.)

---

## 🔍 Detalhamento Técnico

### Comunicação entre Agentes

#### Protocolo de Mensagens

```asl
// Enviar mensagem
.send(destino, performative, conteudo)

// Exemplos:
.send(r1, tell, resource_map([garbage(1,1)], [gold(2,2)]))
.send(supervisor, tell, mission_report(4, 2))
```

**Performatives Utilizadas**:

- `tell` - Informação factual (assertiva)
- `achieve` - Requisição de objetivo (não usado neste projeto)
- `ask` - Pergunta sobre crença (não usado neste projeto)

#### Recepção de Mensagens

```asl
// Regra de adição (+) ativa quando mensagem chega
+mensagem[source(Remetente)]
   <- // Ação ao receber
      .print("Recebido de ", Remetente).
```

### Sistema de Crenças

#### Operações sobre Crenças

```asl
// ADICIONAR crença
+pos(r1, 5, 3)

// REMOVER crença
-pos(r1, 0, 0)

// ATUALIZAR crença (remove antiga e adiciona nova)
-+garbage_collected(5)

// CONSULTAR crença
?pos(r1, X, Y)  // Unifica X e Y com valores atuais
```

#### Crenças Dinâmicas vs Estáticas

```asl
// ESTÁTICA (definida no início)
grid_size(8).

// DINÂMICA (muda durante execução)
pos(r1, X, Y).  // Atualizada a cada movimento
garbage_collected(N).  // Incrementada a cada coleta
```

### Sistema de Planos

#### Estrutura de um Plano

```asl
+gatilho : contexto
   <- ação1;
      ação2;
      !sub_objetivo.
```

**Componentes**:

- `+gatilho` - Evento que dispara o plano (adição de crença/objetivo)
- `contexto` - Condições que devem ser verdadeiras
- `<-` - Separador entre cabeça e corpo
- `;` - Separador de ações
- `.` - Fim do plano

#### Seleção de Planos

Quando múltiplos planos atendem ao mesmo evento:

```asl
// Plano 1: Se posição já é a correta
+!move_to(X, Y) : pos(r1, X, Y)
   <- .print("Já estou aqui!").

// Plano 2: Se precisa se mover
+!move_to(X, Y) : not pos(r1, X, Y)
   <- move_towards(X, Y);
      !move_to(X, Y).  // Recursão
```

Jason tenta o primeiro plano cujo contexto é verdadeiro.

### Ações Internas (Internal Actions)

```asl
// Print no console
.print("Mensagem")

// Enviar mensagem
.send(agente, performative, conteudo)

// Aguardar (ms)
.wait(500)

// Buscar todas as soluções
.findall(Variável, Condição, Lista)

// Tamanho de lista
.length(Lista, Tamanho)

// Verificar lista vazia
.empty(Lista)
```

### Ações de Ambiente

Definidas em `MarsEnv.java` e chamadas do AgentSpeak:

```asl
// Mover em direção a (X,Y)
move_towards(X, Y)

// Coletar item
pick(garb)   // ou pick(gold)

// Descartar item
drop(garb)   // ou drop(gold)

// Queimar lixo
burn(garb)
```

### Recursão e Iteração

#### Processamento de Listas

```asl
// Lista vazia - caso base
+!process_list([])
   <- .print("Lista processada!").

// Lista com elementos - caso recursivo
+!process_list([Head|Tail])
   <- .print("Processando: ", Head);
      // Processar Head aqui
      !process_list(Tail).  // Recursão com o resto
```

#### Loop com Retry

```asl
// Tenta até conseguir
+!ensure_pick(garb) : garbage(r1)
   <- pick(garb);
      !ensure_pick(garb).  // Tenta novamente

// Sucesso quando não tem mais
+!ensure_pick(garb) : not garbage(r1)
   <- .print("Coletado!").
```

### Otimizações Implementadas

#### 1. Coleta em Duas Fases

```asl
!collect_all_garbage;  // Prioridade 1
!collect_all_gold;     // Prioridade 2
```

**Motivo**: Lixo precisa ser queimado, ouro precisa ser preservado. Separar evita confusão.

#### 2. Mensagem Única no Final

```asl
// ❌ RUIM: Mensagem a cada coleta (race condition)
!collect_item;
.send(supervisor, tell, item_collected).

// ✅ BOM: Mensagem única no final
!collect_all_items;
.send(supervisor, tell, mission_report(Total)).
```

**Motivo**: Evita condições de corrida e perda de mensagens.

#### 3. Navegação com Retry Automático

```asl
+!move_to(X, Y) : not pos(r1, X, Y)
   <- move_towards(X, Y);
      .wait(300);
      !move_to(X, Y).  // Chama recursivamente até chegar
```

**Motivo**: Garante chegada ao destino mesmo com movimentos probabilísticos.

#### 4. Proteção de Recursos Valiosos

```asl
+garbage(r2) : gold(r2)
   <- .print("ALERTA: Não queimar com ouro presente!").
```

**Motivo**: Evita destruição acidental de ouro.

---

## 🐛 Solução de Problemas

### Problema 1: Jason não encontrado

**Sintoma**:

```
bash: jason: command not found
```

**Solução**:

```bash
# Configurar JASON_HOME
export JASON_HOME=/path/to/jason
export PATH=$PATH:$JASON_HOME/bin

# Ou no Windows
set JASON_HOME=C:\jason
set PATH=%PATH%;%JASON_HOME%\bin
```

### Problema 2: Erro de sintaxe "Expected {"

**Sintoma**:

```
[RunLocalMAS] as2j: error parsing "file:supervisor.asl":
Encountered " "if" "if "" at line 139, column 14.
Was expecting: "{" ...
```

**Causa**: Uso incorreto de `if` em Jason. Jason não suporta `if` como statement no corpo do plano.

**Solução**:

```asl
// ❌ ERRADO
+!plano
   <- acao1;
      if (condicao) {
         acao2
      }.

// ✅ CORRETO - Usar planos condicionais
+!plano : condicao
   <- acao1;
      acao2.

+!plano : not condicao
   <- acao1.
```

### Problema 3: Agentes não se comunicam

**Sintoma**:

```
[r1] Aguardando mapa...
[r1] Aguardando mapa...
[supervisor] Mapa enviado!
```

**Causa**: Agente não tem plano para receber mensagem.

**Solução**:

```asl
// Adicionar plano de recepção
+resource_map(G, Au)[source(supervisor)]
   <- .print("Mapa recebido!");
      // Processar mapa
```

### Problema 4: Contador sempre 1

**Sintoma**:

```
[supervisor] Total de lixo coletado: 1
[supervisor] Total de lixo queimado: 1
```

**Causa**: Múltiplas mensagens chegando simultaneamente (race condition).

**Solução**: Usar contador local no R1 e enviar total no final:

```asl
// No R1
?garbage_collected(C);
-+garbage_collected(C+1);

// Ao final
?garbage_collected(Total);
.send(supervisor, tell, mission_report(Total, ...)).
```

### Problema 5: Agente fica preso em loop

**Sintoma**:

```
[r1] Indo para (5,5)...
[r1] Indo para (5,5)...
[r1] Indo para (5,5)...
```

**Causa**: Condição de saída não está correta.

**Solução**:

```asl
// Adicionar verificação de chegada
+!move_to(X, Y) : pos(r1, X, Y)
   <- .print("Chegou!").  // Caso base

+!move_to(X, Y) : not pos(r1, X, Y)
   <- move_towards(X, Y);
      .wait(300);
      !move_to(X, Y).
```

### Problema 6: Recurso não coletado

**Sintoma**:

```
[r1] Tentando coletar...
[r1] Tentando coletar...
[MarsEnv] Falha na coleta (probabilidade)
```

**Causa**: Ação `pick` tem probabilidade de falha.

**Solução**: Usar retry automático:

```asl
+!ensure_pick(garb) : garbage(r1)
   <- pick(garb);
      !ensure_pick(garb).  // Tenta novamente

+!ensure_pick(garb) : not garbage(r1)
   <- .print("Sucesso!").  // Termina quando coletar
```

### Problema 7: R2 queima ouro acidentalmente

**Sintoma**:

```
[r2] Queimando...
✓ Ouro destruído!
```

**Causa**: Plano de queima não verifica presença de ouro.

**Solução**:

```asl
// Adicionar proteção
+garbage(r2) : gold(r2)
   <- .print("ALERTA: Ouro detectado! Não queimar!").

+garbage(r2) : not gold(r2)
   <- burn(garb).
```

---

## 🔬 Testes e Validação

### Casos de Teste

#### Teste 1: Varredura Completa

**Objetivo**: Verificar se o Supervisor detecta todos os recursos.

**Procedimento**:

1. Executar sistema
2. Observar logs de varredura

**Resultado Esperado**:

```
[supervisor] Linha 0 escaneada
[supervisor] Linha 1 escaneada
...
[supervisor] Linha 7 escaneada
[supervisor] Varredura do grid completa!
[supervisor] Recursos detectados: X lixo(s), Y ouro(s)
```

**Critério de Sucesso**: ✅ Total de recursos = soma de `garbage_at` + `gold_at`

#### Teste 2: Comunicação Supervisor → R1

**Objetivo**: Verificar recepção do mapa de recursos.

**Procedimento**:

1. Observar envio do supervisor
2. Confirmar recebimento do R1

**Resultado Esperado**:

```
[supervisor] Mapa enviado para R1
[r1] Mapa recebido do supervisor!
[r1] Detectado: X lixo(s) e Y ouro(s)
```

**Critério de Sucesso**: ✅ Valores recebidos = valores enviados

#### Teste 3: Coleta de Lixo

**Objetivo**: Verificar coleta e entrega de todos os lixos.

**Procedimento**:

1. Contar lixos no início
2. Acompanhar cada coleta
3. Verificar queima

**Resultado Esperado**:

```
[r1] Indo para lixo em (X,Y)
[MarsEnv] r1 executando: pick(garb)
✓ R1 coletou lixo!
[MarsEnv] r1 executando: drop(garb)
✓ R1 largou lixo
[r2] Queimando lixo...
✓ R2 queimou lixo!
```

**Critério de Sucesso**: ✅ Todos os lixos coletados e queimados

#### Teste 4: Coleta de Ouro

**Objetivo**: Verificar coleta e armazenamento seguro de ouro.

**Procedimento**:

1. Contar ouros no início
2. Acompanhar cada coleta
3. Verificar armazenamento (sem queima!)

**Resultado Esperado**:

```
[r1] Indo para ouro em (X,Y)
[MarsEnv] r1 executando: pick(gold)
✓ R1 coletou ouro!
[r2] ⭐ Armazenando ouro...
[r2] ✓ Ouro armazenado!
```

**Critério de Sucesso**: ✅ Todos os ouros armazenados sem destruição

#### Teste 5: Relatório Final

**Objetivo**: Verificar precisão dos contadores.

**Resultado Esperado**:

```
[r1] === MISSÃO CONCLUÍDA ===
[r1] Lixo coletado: 4
[r1] Ouro coletado: 2

[supervisor] === RELATÓRIO FINAL ===
[supervisor] Total de lixo coletado e queimado: 4
[supervisor] Total de ouro coletado e armazenado: 2
[supervisor] ✓ Sistema íntegro: Missão completa!
```

**Critério de Sucesso**: ✅ Valores corretos e consistentes

### Métricas de Performance

| Métrica                  | Valor Esperado | Observação                   |
| ------------------------ | -------------- | ---------------------------- |
| Tempo de varredura       | ~2-3s          | Depende do `.wait()`         |
| Tempo por coleta de lixo | ~5-8s          | Movimento + coleta + entrega |
| Tempo por coleta de ouro | ~5-8s          | Movimento + coleta + entrega |
| Taxa de sucesso coleta   | 100%           | Retry garante sucesso        |
| Mensagens perdidas       | 0              | Mensagem única no final      |
| Tempo total (4L + 2O)    | ~45-50s        | Para 4 lixos e 2 ouros       |

---

## 🚀 Melhorias Futuras

### Curto Prazo

#### 1. Otimização de Rotas

**Problema**: R1 pode fazer rotas sub-ótimas.

**Solução**:

```asl
// Implementar A* ou Dijkstra
+!find_optimal_path(Start, Goal, Path)
   <- // Algoritmo de pathfinding
      !follow_path(Path).
```

**Benefício**: Redução de 20-30% no tempo de coleta.

#### 2. Múltiplos Coletores

**Problema**: R1 sozinho pode ser lento em grids grandes.

**Solução**:

```java
// No mars.mas2j
agents:
    supervisor;
    r1 #[beliefs="pos(r1,0,0)"];
    r1_backup #[beliefs="pos(r1_backup,7,7)"];
    r2 #[beliefs="pos(r2,3,3)"];
```

**Benefício**: Paralelização da coleta.

#### 3. Priorização Dinâmica

**Problema**: Ordem fixa (lixo → ouro) pode não ser ideal.

**Solução**:

```asl
// Calcular distâncias e priorizar mais próximos
+!collect_smartly
   <- !calculate_distances(Resources, Distances);
      !sort_by_distance(Distances, Sorted);
      !collect_in_order(Sorted).
```

**Benefício**: Redução no tempo de movimento.

### Médio Prazo

#### 4. Interface Gráfica

**Tecnologia**: JavaFX ou Swing

**Features**:

- Visualização do grid 8x8 em tempo real
- Posições dos agentes atualizadas
- Recursos coloridos (vermelho=lixo, amarelo=ouro)
- Estatísticas em tempo real

**Mockup**:

```
┌─────────────────────────────┐
│   MARS CLEANUP SYSTEM       │
├─────────────────────────────┤
│  Grid 8x8                   │
│  ┌───┬───┬───┬───┬───┐      │
│  │ R1│   │ 🗑 │   │   │      │
│  ├───┼───┼───┼───┼───┤      │
│  │   │   │   │ R2│   │      │
│  ├───┼───┼───┼───┼───┤      │
│  │   │ 🗑 │   │   │ 🏆│      │
│  └───┴───┴───┴───┴───┘      │
│                              │
│  Estatísticas:               │
│  ├ Lixo coletado: 2/4       │
│  ├ Ouro coletado: 1/2       │
│  └ Tempo decorrido: 25s     │
└─────────────────────────────┘
```

#### 5. Sistema de Log Estruturado

**Problema**: Logs misturados dificultam debug.

**Solução**:

```java
// Logger estruturado com níveis
Logger logger = Logger.getLogger("MarsSystem");
logger.info("[R1] Iniciando coleta");
logger.debug("[R1] Posição atual: (5,3)");
logger.warning("[R2] Ouro detectado com lixo!");
```

**Benefício**: Melhor debugging e análise post-mortem.

#### 6. Persistência de Dados

**Objetivo**: Salvar histórico de missões.

**Solução**:

```asl
// Ao final da missão
+!save_mission_data
   <- .date(Y,M,D);
      .time(H,Min,S);
      !write_to_file("missions.csv", [Y,M,D,H,Min,GarbageCount,GoldCount]).
```

**Benefício**: Análise de tendências e performance ao longo do tempo.

### Longo Prazo

#### 7. Machine Learning

**Objetivo**: Aprender rotas otimizadas.

**Tecnologia**: TensorFlow + Jason

**Abordagem**:

- Reinforcement Learning para otimizar rotas
- Q-Learning para decisões de priorização
- Neural Networks para predição de recursos

#### 8. Ambiente Dinâmico

**Features**:

- Recursos aparecem durante execução
- Obstáculos móveis
- Clima (tempestades de areia reduzem visibilidade)
- Bateria dos robôs (necessidade de recarga)

#### 9. Comunicação Descentralizada

**Problema**: Supervisor como ponto único de falha.

**Solução**:

```asl
// Agentes se comunicam diretamente
.send(r1_backup, tell, help_needed(5,5));
.send(r2, askOne, is_available, Available);
```

**Benefício**: Sistema mais robusto e escalável.

#### 10. Simulação 3D

**Tecnologia**: Unity + Jason Bridge

**Features**:

- Renderização 3D do ambiente marciano
- Física realista (gravidade reduzida)
- Câmera livre para observação
- VR support

---

## 📊 Análise de Complexidade

### Complexidade Temporal

#### Varredura do Grid

```
Complexidade: O(n²)
onde n = grid_size = 8

Operações: 8 × 8 = 64 células escaneadas
Tempo: ~50ms × 64 = ~3.2s
```

#### Coleta de Recursos

```
Por recurso:
- Movimento: O(distância) = O(√(x² + y²))
- Coleta: O(1) com retry
- Entrega: O(distância até R2)

Total: O(n × d)
onde:
  n = número de recursos
  d = distância média

Exemplo (4 lixos + 2 ouros):
  Tempo ≈ 6 × 7s = 42s
```

#### Complexidade Total

```
T(total) = T(varredura) + T(coleta)
         = O(grid²) + O(recursos × distância)
         = O(64) + O(6 × 7)
         = ~3s + ~42s
         = ~45s
```

### Complexidade Espacial

```
Memória por agente:
- Crenças: O(grid²) para percepções
- Planos: O(1) (fixo)
- Mensagens: O(recursos) para mapa

Total: O(n²) onde n = grid_size
```

### Eficiência de Comunicação

```
Mensagens enviadas:
- Supervisor → R1: 1 (mapa inicial)
- R1 → Supervisor: 1 (relatório final)

Total: 2 mensagens

Comparado com abordagem anterior:
- 4 (coletas) + 4 (queimas) + 2 (ouro) = 10 mensagens
- Redução: 80% 🎉
```

---

## 📚 Referências

### Documentação Oficial

1. **Jason Framework**

   - Site: https://jason-lang.github.io/
   - Manual: https://jason-lang.github.io/doc/
   - API: https://jason-lang.github.io/api/

2. **AgentSpeak(L)**

   - Paper original: Rao, A. S. (1996). "AgentSpeak(L): BDI agents speak out in a logical computable language"
   - Tutorial: https://jason-lang.github.io/tutorial/

3. **Multi-Agent Systems**
   - Livro: "Programming Multi-Agent Systems in AgentSpeak using Jason" (Bordini et al., 2007)
   - ISBN: 978-0470029008

### Papers Relacionados

1. Bordini, R. H., & Hübner, J. F. (2005). "BDI agent programming in AgentSpeak using Jason"
2. Wooldridge, M. (2009). "An Introduction to MultiAgent Systems" (2nd ed.)
3. Russell, S., & Norvig, P. (2020). "Artificial Intelligence: A Modern Approach" (4th ed.)

### Tutoriais e Exemplos

1. **Jason Examples**: https://github.com/jason-lang/jason/tree/master/examples
2. **Mars Rover Case Study**: Similar ao nosso projeto
3. **Cleaning Robots**: Exemplo clássico de MAS

---

## 👥 Contribuindo

### Como Contribuir

1. **Fork** o repositório
2. **Clone** seu fork
   ```bash
   git clone https://github.com/seu-usuario/mars-cleanup-system.git
   ```
3. **Crie uma branch** para sua feature
   ```bash
   git checkout -b feature/nova-funcionalidade
   ```
4. **Commit** suas mudanças
   ```bash
   git commit -m "Adiciona nova funcionalidade X"
   ```
5. **Push** para o GitHub
   ```bash
   git push origin feature/nova-funcionalidade
   ```
6. Abra um **Pull Request**

### Guia de Estilo

#### Código AgentSpeak

```asl
// Comentários em português
// Nomes de planos em snake_case
+!meu_plano : contexto
   <- acao1;
      acao2.

// Identação: 3 espaços
// Linhas: máximo 80 caracteres
```

#### Código Java

```java
// Seguir padrão Google Java Style
public class MarsEnv extends Environment {
    private static final int GRID_SIZE = 8;

    @Override
    public boolean executeAction(String ag, Structure action) {
        // Implementação
    }
}
```

#### Commits

```
feat: Adiciona sistema de pathfinding
fix: Corrige bug na coleta de ouro
docs: Atualiza README com exemplos
refactor: Simplifica comunicação entre agentes
test: Adiciona testes unitários para R1
```

### Issues

Ao abrir uma issue, inclua:

- **Descrição clara** do problema ou feature
- **Passos para reproduzir** (se bug)
- **Comportamento esperado** vs **comportamento atual**
- **Logs relevantes**
- **Versão** do Jason e Java

Exemplo:

```markdown
## Bug: R2 queima ouro acidentalmente

**Descrição**: Em algumas situações, R2 queima ouro junto com lixo.

**Passos para reproduzir**:

1. Executar sistema com 2 lixos e 1 ouro
2. R1 entrega lixo e ouro simultaneamente
3. R2 queima ambos

**Esperado**: R2 deve armazenar ouro e queimar apenas lixo

**Atual**: R2 queima tudo

**Logs**:
```

[r2] Queimando...
✓ Ouro destruído!

```

**Versão**: Jason 2.6, Java 11
```

---

## 📜 Licença

Este projeto está licenciado sob a **MIT License**.

```
MIT License

Copyright (c) 2025 Mars Cleanup System

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Agradecimentos

- **Jason Team** - Pelo excelente framework de agentes
- **Rafael Bordini** - Criador do Jason
- **Comunidade AgentSpeak** - Suporte e exemplos
- **Todos os contribuidores** deste projeto

---

## 📞 Contato

- **GitHub**: https://github.com/seu-usuario/mars-cleanup-system
- **Issues**: https://github.com/seu-usuario/mars-cleanup-system/issues
- **Email**: contato@mars-cleanup.dev

---

## 🎓 Contexto Educacional

Este projeto foi desenvolvido como parte de estudos em:

- **Sistemas Multi-Agentes (MAS)**
- **Inteligência Artificial Distribuída**
- **Arquitetura BDI (Beliefs-Desires-Intentions)**
- **Coordenação e Comunicação entre Agentes**

Ideal para:

- 📚 Disciplinas de IA e Sistemas Distribuídos
- 🎯 Trabalhos de conclusão de curso
- 🔬 Pesquisa em MAS
- 💻 Aprendizado de Jason/AgentSpeak

---

## 📈 Status do Projeto

![Status](https://img.shields.io/badge/status-stable-green)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Jason](https://img.shields.io/badge/jason-2.6+-orange)
![Java](https://img.shields.io/badge/java-8+-red)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

**Última atualização**: 24 de Outubro de 2025

---

<div align="center">

### ⭐ Se este projeto foi útil, considere dar uma estrela no GitHub! ⭐

**Desenvolvido com 💙 para a comunidade Jason/AgentSpeak**

</div>
