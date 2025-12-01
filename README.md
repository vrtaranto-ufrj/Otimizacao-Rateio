# Allocation Optimizer

Otimizador de alocação de fundos usando programação linear inteira mista (MILP).

## 📋 Índice

- [Instalação e Uso](#-instalação-e-uso)
- [O que o Código Faz](#-o-que-o-código-faz)
- [O que é um Solver](#-o-que-é-um-solver)
- [Sobre o SCIP](#-sobre-o-scip)
- [Modelagem Matemática](#-modelagem-matemática)
- [Lógica de min_increment e min_piece](#-lógica-de-min_increment-e-min_piece)
- [API de Matrizes do SCIP](#-api-de-matrizes-do-scip)
- [Técnica Big-M](#-técnica-big-m)

---

## 🚀 Instalação e Uso

### Pré-requisitos

Este projeto usa [uv](https://github.com/astral-sh/uv), um gerenciador de pacotes Python extremamente rápido.

### Instalando uv

```bash
pip install uv
```

### Configurando o Projeto

Crie um ambiente virtual e instale as dependências:
```bash
uv sync
```

O `uv` automaticamente:
- Cria um ambiente virtual em `.venv`
- Instala todas as dependências do `pyproject.toml`
- Resolve e bloqueia as versões em `uv.lock`

### Rodando o Código

```bash
uv run python integer-ratio-optimizer.py
```

Ou ative o ambiente virtual manualmente:
```bash
# Windows
.venv\Scripts\activate

# Linux/macOS
source .venv/bin/activate

# Depois rode
python integer-ratio-optimizer.py
```

---

## 📊 O que o Código Faz

O `integer-ratio-optimizer.py` resolve o seguinte problema:

**Dado:**
- Uma posição atual em vários fundos (ex: `[-3600, -2400, -800, ...]`)
- Um amount de um ativo financeiro (equity, future, option, bond, CDS) para investir (comprar) ou retirar (vender)
- Ratios ideais para cada fundo (ex: `[0.248, 0.165, 0.056, ...]`)
- Restrições de tamanho mínimo de posição e incremento

**Objetivo:**
Encontrar como distribuir o amount entre os fundos para que os ratios finais fiquem o mais próximo possível dos ratios ideais, respeitando todas as restrições.

### Exemplo Prático

```python
# Posição atual (pode ser negativa = vendido)
position = np.array([-3600, -2400, -800, -560, -1400, -250, -460])

# Quero adicionar $4000
positive_amount = 4000

# Ratios ideais (devem somar 1.0)
ideal_ratios = np.array([0.248, 0.165, 0.056, 0.388, 0.095, 0.018, 0.030])

# Restrições
min_piece = 10      # Posição mínima: 0 ou >= 10
min_increment = 10  # Só posso negociar múltiplos de 10

# Otimizar
trades_positive, trades_negative = optimize(...)
```

**Resultado:**
O otimizador retorna quanto comprar/vender de cada fundo para minimizar o erro entre os ratios finais e os ideais.

---

## 🤖 O que é um Solver

Um **solver** (resolvedor) é um software especializado em encontrar soluções ótimas para problemas de otimização matemática.

### Tipos de Problemas

1. **Programação Linear (LP)**: Variáveis contínuas, restrições lineares
2. **Programação Inteira (IP)**: Variáveis inteiras, restrições lineares
3. **Programação Linear Inteira Mista (MILP)**: Mistura de variáveis contínuas e inteiras
4. **Programação Não-Linear (NLP)**: Inclui funções não-lineares

### Como Funciona

Um solver:
1. Recebe a descrição matemática do problema (variáveis, restrições, função objetivo)
2. Aplica algoritmos sofisticados (Branch-and-Bound, Simplex, etc.)
3. Explora o espaço de soluções de forma inteligente
4. Garante encontrar a **solução ótima global** (para MILP)

### Por que Usar um Solver?

- **Garantia de otimalidade**: Não é uma heurística, é a melhor solução possível
- **Eficiência**: Algoritmos otimizados por décadas de pesquisa
- **Complexidade**: Resolve problemas que seriam impossíveis manualmente

---

## 🔧 Sobre o SCIP

**SCIP** (Solving Constraint Integer Programs) é um dos melhores solvers open-source para MILP.

### Características

- **Gratuito e open-source**: Licença Apache 2.0
- **State-of-the-art**: Consistentemente entre os melhores em competições
- **Completo**: Suporta LP, MILP, MINLP
- **Rápido**: Implementação em C altamente otimizada
- **Extensível**: Permite plugins e customizações

### PySCIPOpt

Usamos **PySCIPOpt**, a interface Python para o SCIP:

```python
from pyscipopt import Model

model = Model()  # Cria um novo modelo de otimização
x = model.addVar("x")  # Adiciona variável
model.addCons(x >= 0)  # Adiciona restrição
model.setObjective(x, "minimize")  # Define objetivo
model.optimize()  # Resolve!
```

### Alternativas

- **Gurobi**: Comercial, mais rápido, caro (~$2000/ano)
- **CPLEX**: Comercial, IBM, similar ao Gurobi
- **CBC**: Open-source, mais simples
- **HiGHS**: Open-source, focado em LP

SCIP oferece o melhor custo-benefício: gratuito e muito competente.

---

## 📐 Modelagem Matemática

### Variáveis de Decisão

```python
# Variáveis inteiras (quanto comprar/vender de cada fundo)
trades_positive[i]  # ℤ, dimensão: (num_funds,) - Quantidade a comprar do fundo i
trades_negative[i]  # ℤ, dimensão: (num_funds,) - Quantidade a vender do fundo i
final_position[i]   # ℤ, dimensão: (num_funds,) - Posição final do fundo i

# Variáveis binárias (0 ou 1)
min_piece_valid[i]  # {0,1}, dimensão: (num_funds,) - 1 se posição final != 0, 0 se = 0
is_positive_dir[i]  # {0,1}, dimensão: (num_funds,) - 1 se posição positiva, 0 se negativa

# Variáveis contínuas
new_ratios[i]       # ℝ, dimensão: (num_funds,) - Ratio final do fundo i
z                   # ℝ, escalar - Variável auxiliar para minimizar
```

### Restrições Principais

1. **Conservação de capital**:
```python
trades_positive.sum() == positive_amount  # Gastar tudo que tem pra comprar
trades_negative.sum() == negative_amount  # Vender o valor desejado
```

2. **Posição final**:
```python
final_position = position + trades_positive + trades_negative
```

3. **Min Piece** (usando Big-M):
```python
# Se min_piece_valid[i] = 0: final_position[i] = 0
# Se min_piece_valid[i] = 1: |final_position[i]| >= min_piece
```

4. **Ratios**:
```python
new_ratios = final_position / total
```

### Função Objetivo

Minimizar o **erro absoluto relativo** (norma L1):

```python
minimize: Σ |error_relativo[i]|

onde: error_relativo[i] = (new_ratios[i] - ideal_ratios[i]) / ideal_ratios[i]
```

**Implementação com escalonamento numérico:**
```python
# Reformular para evitar divisão por variáveis (melhor estabilidade numérica)
ratios_errors[i] >= (new_ratios[i] - ideal_ratios[i]) / ideal_ratios[i]
ratios_errors[i] >= -(new_ratios[i] - ideal_ratios[i]) / ideal_ratios[i]

# Escalar objetivo para melhorar condicionamento numérico
minimize: scale_factor * Σ ratios_errors[i]  (scale_factor = 10000)
```

**Por que escalar o objetivo?**
- O objetivo naturalmente é muito pequeno (~1e-6)
- As variáveis são grandes (posições na casa de milhares)
- Essa diferença de escala causa problemas numéricos no solver
- Multiplicar por 10000 traz tudo para escala similar = solver mais estável

**Por que usar erro relativo?**

O erro relativo é essencial porque **um mesmo erro percentual tem impacto muito diferente dependendo do tamanho do fundo**:

- **Fundo pequeno (ratio = 0.02)**: Um erro de 0.01 representa **50% de desvio** - desastroso!
- **Fundo grande (ratio = 0.40)**: O mesmo erro de 0.01 representa apenas **2.5% de desvio** - tolerável

Ao usar erro relativo `(erro / ideal_ratio)`, normalizamos os desvios e tratamos todos os fundos de forma justa, independentemente do seu tamanho. Isso evita que fundos pequenos sejam negligenciados na otimização.

**Por que norma L1 (absoluto) ao invés de L2 (quadrático)?**
- **Performance**: L1 resulta em **MILP** (Mixed Integer Linear Programming), enquanto L2 resulta em **MIQP** (Mixed Integer Quadratic Programming), que é **muito mais lento** de resolver
- **L1**: Distribui o erro mais uniformemente entre todos os fundos
- **L2**: Concentra o erro em poucos fundos (penaliza outliers mais fortemente)
- **L1 é mais justo**: Prefere ter vários erros pequenos do que um erro grande
- **Ambos são convexos**: Garantem otimalidade global

**MILP vs MIQP:**
- MILP: Apenas restrições lineares → algoritmos muito eficientes (Simplex, Branch-and-Bound)
- MIQP: Objetivo ou restrições quadráticas → significativamente mais complexo e lento
- Para problemas com muitos fundos, L1 pode ser **10x-100x mais rápido** que L2

**Nota**: O código também suporta L2 (basta descomentar a linha alternativa no código), mas espere tempos de resolução maiores

---

## 🎯 Lógica de min_increment e min_piece

### min_increment (Incremento Mínimo)

**Problema**: Nem sempre podemos negociar frações arbitrárias. Exemplo:
- Ações: só múltiplos de 1 ação
- Contratos: só múltiplos de 100
- Lotes: só múltiplos de 10

**Solução**: Escalar o problema!

```python
scaled_position = position // min_increment
scaled_trades = trades // min_increment
```

**Exemplo**:
- `min_increment = 10`
- `position = [150, 100]` → `scaled = [15, 10]`
- `trades = [30, -20]` → `scaled = [3, -2]`

Depois, multiplica de volta: `trades * min_increment`

**Vantagem**:
- Reduz o espaço de busca
- Solver trabalha com números menores
- Garante que a solução sempre será múltiplo válido

### min_piece (Tamanho Mínimo)

**Contexto**: Em mercados financeiros, especialmente para **bonds (títulos de renda fixa)**, existem restrições operacionais onde fundos só podem negociar amounts mínimos. Isso ocorre porque:

- **Custos de transação**: Posições muito pequenas não compensam as taxas
- **Liquidez**: Mercado pode não aceitar ordens pequenas
- **Operacional**: Dificulta gestão e controle de risco
- **Regulatório**: Alguns ativos têm lotes mínimos obrigatórios

**Regra**: Uma posição deve ser **0 (zeramos)** OU **|posição| ≥ min_piece**

**Exemplo** (`min_piece = 100`):
- ✅ Válido: `[0, 150, -200, 0, 100]`
- ❌ Inválido: `[50, 150, -30, 0, 100]` (50 e -30 são pequenos demais)

**Implementação**:
Usamos variável binária `min_piece_valid[i]`:
- `min_piece_valid[i] = 0` → forçar `final_position[i] = 0`
- `min_piece_valid[i] = 1` → forçar `|final_position[i]| >= min_piece`

---

## 🔢 API de Matrizes do SCIP

### Problema com Loops

Forma tradicional (RUIM):
```python
for i in range(n):
    x[i] = model.addVar(f"x_{i}")
    model.addCons(x[i] >= 0)
```

**Desvantagens**:
- Código verboso
- Lento para muitas variáveis
- Difícil de ler

### Solução: Matrix API

Forma moderna (BOA):
```python
x = model.addMatrixVar(n, name="x", lb=0)
model.addMatrixCons(x >= 0)
```

**Vantagens**:
- ✅ **Conciso**: 1 linha vs N linhas
- ✅ **Rápido**: Operações vetorizadas
- ✅ **Legível**: Expressões matemáticas diretas
- ✅ **Numpy-like**: Sintaxe familiar

### Operações Suportadas

```python
# Criar variáveis (vetor)
x = model.addMatrixVar(n, name="x", vtype="I")

# Operações aritméticas
model.addMatrixCons(x + y == z)
model.addMatrixCons(2*x - 3*y <= 10)

# Broadcasting (escalar opera em vetor)
model.addMatrixCons(x >= 5)
model.addMatrixCons(x * min_piece_valid == y)

# Agregação
model.addCons(x.sum() == 100)
```

### Exemplo Completo

```python
# 3 variáveis inteiras entre 0 e 10
x = model.addMatrixVar(3, name="x", lb=0, ub=10, vtype="I")

# 3 variáveis binárias
b = model.addMatrixVar(3, name="b", vtype="B")

# Restrições em uma linha
model.addMatrixCons(x <= 10 * b)  # Se b=0, x=0
model.addMatrixCons(x >= 5 * b)   # Se b=1, x>=5
model.addCons(x.sum() == 15)      # Soma = 15
```

Equivalente a 9+ linhas de código tradicional!

---

## 🎭 Técnica Big-M

### O Desafio

Como modelar lógica **"OU"** em otimização linear?

Queremos: `x >= 10 OU x = 0`

Mas só podemos usar: `≤`, `≥`, `=`

### A Solução: Big-M

**Ideia**: Usar um número muito grande (M) para "desligar" restrições.

#### Passo 1: Variável Binária

```python
b = 0 ou 1  # Escolhe qual restrição ativar
```

#### Passo 2: Adicionar M

```python
# Queremos: se b=1, então x >= 10
x >= 10 - M*(1-b)
```

**Análise**:
- Se `b=1`: `x >= 10 - 0 = 10` ✅ (ATIVA)
- Se `b=0`: `x >= 10 - M` ≈ `x >= -∞` (INATIVA)

#### Passo 3: Outra Direção

```python
# Queremos: se b=0, então x = 0
x <= M*b
```

**Análise**:
- Se `b=1`: `x <= M` ≈ `x <= ∞` (INATIVA)
- Se `b=0`: `x <= 0` ✅ (ATIVA)

### No Nosso Código

```python
# Big-M otimizado: calcula valor específico por fundo + margem de segurança
big_m = np.maximum(
    abs(scaled_position + scaled_positive_amount),  # Cenário: comprar tudo nesse fundo
    abs(scaled_position + scaled_negative_amount),  # Cenário: vender tudo nesse fundo
) + scaled_min_piece  # Adicionar min_piece para garantir que restrições funcionem

# Se min_piece_valid=0: final_position=0
model.addMatrixCons(final_position <= big_m * min_piece_valid)
model.addMatrixCons(final_position >= -big_m * min_piece_valid)

# Se min_piece_valid=1 e is_positive_dir=1: final_position >= min_piece
model.addMatrixCons(
    final_position >= scaled_min_piece * min_piece_valid - big_m * (1 - is_positive_dir)
)

# Se min_piece_valid=1 e is_positive_dir=0: final_position <= -min_piece
model.addMatrixCons(
    final_position <= -scaled_min_piece * min_piece_valid + big_m * is_positive_dir + big_m * (1 - min_piece_valid)
)
```

### Escolhendo M

**Importante**: M deve ser:
- ✅ **Grande o suficiente**: Maior que qualquer valor válido da variável
- ✅ **Específico por variável**: Big-M diferente para cada fundo quando possível
- ✅ **Incluir min_piece**: Garante que restrições de limite funcionem corretamente
- ❌ **Não muito grande**: Evitar problemas numéricos e tornar solver mais lento

**Neste código**:
```python
# Big-M otimizado: vetor com valor específico para cada fundo
big_m = np.maximum(
    abs(scaled_position + scaled_positive_amount),
    abs(scaled_position + scaled_negative_amount),
) + scaled_min_piece
```

**Por que essa fórmula?**
1. **`scaled_position + scaled_positive_amount`**: Valor máximo se comprarmos tudo nesse fundo
2. **`scaled_position + scaled_negative_amount`**: Valor mínimo se vendermos tudo nesse fundo
3. **`np.maximum(...)`**: Pega o maior valor absoluto possível por fundo
4. **`+ scaled_min_piece`**: Margem de segurança para as restrições de limite inferior/superior funcionarem

**Vantagens do Big-M otimizado:**
- 🚀 **Mais eficiente**: Cada fundo tem Big-M específico (menor = solver mais rápido)
- ✅ **Mais preciso**: Restrições mais "apertadas" = menos folga desnecessária
- 🐛 **Evita bugs**: Adicionar `scaled_min_piece` corrige casos onde `min_piece` > range de `final_position`

### Tabela Verdade Completa

| min_piece_valid | is_positive_dir | Resultado |
|----------------|-----------------|-----------|
| 0 | 0 | `final_position = 0` |
| 0 | 1 | `final_position = 0` |
| 1 | 0 | `final_position <= -min_piece` |
| 1 | 1 | `final_position >= min_piece` |

Isso implementa: **posição = 0 OU |posição| ≥ min_piece** ✅

---

## 📚 Referências

- [SCIP Optimization Suite](https://scipopt.org/)
- [PySCIPOpt Documentation](https://pyscipopt.readthedocs.io/en/latest/)
- [UV Package Manager](https://github.com/astral-sh/uv)
- [Integer Programming (Wikipedia)](https://en.wikipedia.org/wiki/Integer_programming)
- [Big-M Method](https://en.wikipedia.org/wiki/Big_M_method)
