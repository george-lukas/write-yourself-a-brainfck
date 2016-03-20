# Write yourself a Brainfuck in an hour 

Introdução
----------

Este é um tutorial básico sobre como criar um interpretador Brainfuck inteiramente caracterizado em Haskell.
Brainfuck é uma (Turing completo!) Linguagem de programação que visa ter muito pouco de sintaxe, e devido à seu aparelho simples de instrução, é muito fácil de implementar.

Este tutorial é *muito* básico: ter lido Lear Yourself A Haskell é bom o suficiente. Na verdade, nós veremos r que não precisa nem de nenhum Functor / Applicatives / mônadas
tudo vai ser pattern-matching, tipos de dados personalizados, e claro, da aplicação de função. Para ser mais específico, vamos usar LYAH os capítulos capítulos 1-6, 8, muito pouco de 9, e
o início de 14.

O tutorial é dividido em três partes. Primeiro, vamos criar um tipo de dados para representam o código-fonte Brainfuck, e como converter código fonte Brainfuck em
este formato. Na segunda parte, iremos modelar a fita e converter o Brainfuck código-fonte em uma representação mais adequada. A seção final será
avaliação, em que nós andamos em torno da fita fazendo as operações a fonte dita.

### Especificação completa da linguagem

O código Brainfuck consiste em uma sequência de caracteres de controle, infinitamente fita longa preenchido com zeros, e o assim chamado ponteiro de dados que aponta para o
posição inicial sobre a fita. O símbolo atual no código é lido e executado, então o próximo símbolo é olhado. Este processo é repetido até que a última instrução tem sido tratado.

- `>` Move o ponteiro de dados de um campo à direita.
- `<` Move o ponteiro de um campo de dados para a esquerda.
- `+` Adiciona 1 para o campo atual.
- `-` Subtrai 1 para o campo atual.
- `.` Imprime o caracter que corresponde ao valor da corrente de campo (ASCII).
- `,` Lê um único caractere do teclado e armazena seu valor no célula atual.
- `[` Se o valor atual é zero, e depois saltar para a frente para o comando após a comando correspondente ].
- `]` 'Se o valor atual for diferente de zero, e depois saltar de volta para o comando após o comando corresponde [ .
- Qualquer outro caractere é tratado como um comentário.

É isso aí. Note-se como o único erro de sintaxe possível é descasamento entre parênteses.

### Alguns exemplos de código Brainfuck

Para lhe dar um vislumbre de a abominação que estamos prestes a criar:

- `[-]` Limpa uma célula contendo um valor positivo: Quando a `[` é atingido, o
   célula é zero já (caso em que o programa salta após o
   Coincidindo `]`, ou seja, o programa termina), ou diferente de zero. No caso diferente de zero,
   o `[` é simplesmente ignorado, `-` é avaliado e diminui a célula atual
   por um, e `]` é atingido. Se a célula é zero agora, então ignorar o `]` 'e
   rescindir, caso contrário, pule de volta para depois do `[`. A partir desta você pode ver como
   `[]` Atua como um loop.
   
   - `> [-] <[-> + <]` Move os dados a partir de uma célula de uma célula para a direita (substituindo
   seu valor). Em primeiro lugar, o ponteiro de dados move um para a direita com `>`, então
   há o comando "células claras" `[-]` você sabe de cima, eo ponteiro
   se move para trás. O que temos agora é uma célula com algum conteúdo, que tem um vazio
   próximo à sua direita. Agora, a segunda laço começar: diminuir a corrente
   celular, mova um para a direita, incrementar célula vizinha, mover para a esquerda novamente. este
   O corpo de circuito toma o conteúdo da célula para a esquerda e coloca-a no direito
   célula, um por um, até que a célula à esquerda está vazia. No final, o ponteiro
   estar na célula à esquerda vazio, enquanto a célula vizinha é preenchido com os dados.
   
   - Para imprimir a letra "a", que tem um valor ASCII 97, use `++++++++++ [> ++++++++++ <-]> ---`. Isso inicializa pilha 0 com 10, e em seguida, incrementa celular 1 dez vezes por outros 10, nos dando 100 na célula 1. 
Finalmente, subtraia 3 e imprimir o resultado. O [standard "Hello World"program][helloworld] é construído com base neste princípio.
[helloworld]: http://en.wikipedia.org/wiki/Brainfuck#Hello_World.21

   Como você pode ver, os programas não são muito legível. Como temos sorte que não somos nós que vamos tentar escrever, mas sim implementa-lo, que é muito mais fácil.

Parte 1: Brainfuck type, e como analisar isso.

Para o tipo de dados, vamos simplesmente criar um que tem um construtor para cada elemento sintática:

```haskell
data BrainfuckCommand = GoRight      -- >
                      | GoLeft       -- <
                      | Increment    -- +
                      | Decrement    -- -
                      | Print        -- .
                      | Read         -- ,
                      | LoopL        -- [
                      | LoopR        -- ]
                      | Comment Char -- anything else
```

Vamos também criar um sinônimo tipo de representar todo um programa Brainfuck,
                      
```haskell
type BrainfuckSource = [BrainfuckCommand]
```

Nosso objetivo agora está tomando uma string como `[-]` e convertê-lo para o Haskell valor `[LoopL, Decrement, LoopR]`. Uma vez que estamos atravessando a cadeia de entrada
caractere por caractere (porque cada instrução é apenas um caractere), podemos apenas usar `map` converter-se entre String e `BrainfuckSource`:

```haskell
parseBrainfuck :: String -> BrainfuckSource
parseBrainfuck = map charToBF
  where
    charToBF x = case x of
        '>' -> GoRight
        '<' -> GoLeft
        '+' -> Increment
        '-' -> Decrement
        '.' -> Print
        ',' -> Read
        '[' -> LoopL
        ']' -> LoopR
         c  -> Comment c
```

Isso é muito bonito isso para esta parte. Note como qualquer coisa que não corresponde a um comando válido é interpretada como um comentário na última linha.

### Exercícios

Aqui estão algumas melhorias que você pode fazer em seu código. (Não se preocupe se você não fazê-las, o resto do tutorial não vai levá-los em conta.)

1. (fácil) Comentários não são necessários para a avaliação, portanto, pode apenas deixá-los
    a partir da fonte quando nós analisá-lo. Olhe para cima o que `mapMaybe` faz (por exemplo,
    usando [Hoogle] [Hoogle]) e usá-lo para substituir o `map` em `parseBrainfuck`
    de modo que os comentários são ignorados.

[hoogle]: http://www.haskell.org/hoogle/

2. (fácil) Você não pode escrever uma instância `show` para um sinônimo tipo como
    `BrainfuckSource` (porquê?). Reescrevê-lo usando uma `declaração data` a um tipo
    que contém um `[BrainfuckCommand]`, e definir uma instância `show` para esse novo
    Tipo que imprime a fonte contido. Por exemplo, `Show $ BFSource [LoopL, Decrement, LoopR]` deve gerar "[-]" em GHCi.

3. Checking syntax

1. (médio) O único erro de sintaxe possível em código Brainfuck é descasamento
       parênteses. Por exemplo `[-` tem uma abertura, mas nenhum fechamento de correspondência
       parêntese, e `-]` tem um parêntese de fechamento, mas não correspondente
       uma abertura. Escrever uma função `checkSyntax` do tipo
       `BrainfuckSource -> Maybe BrainfuckSource` que retorna `Nothing` se o
       código for inválido, e de outra forma válida  `<código válido>`. Use esta função para
       modificar `parseBrainfuck` para rejeitar código inválido, o que, em seguida, tem o novo
       digite `String -> Maybe BrainfuckSource`.

2. (Dificil) Modifique o `Maybe tipo BrainfuckSource` para
       `Either String BrainfuckSource`. código correto deve gerar
       `<Valid Code> Right`, enquanto uma incorreta deve resultar em um valor `Left`
       informando os usuários sobre o problema, por exemplo, "a abertura sem correspondência parêntese".

3. (Dificil) Faça as mensagens de erro a partir de cima melhor: fazer as mensagens de erro informar ao usuário sobre a posição dos parênteses ofensivas,
	     por exemplo, "o caráter fonte n-th é um parêntese de fechamento sem um uma abertura".


Parte 2: A fita
---------------

A fita é uma longa linhagem de células, cada um segurando um número. O tipo mais fácil
Haskell para representar um número é uma lista, mas lembre-se o que queremos fazer com
a fita: atravessá-lo em ambas as direções, e elementos de atualização (potencialmente profunda
para baixo) com frequência, ambas as listas coisas são particularmente ruim em: travessia, tanto
direções simplesmente não é possível (listas vão somente ida), e atualizar um
elemento requer atravessando a lista inteira até aquele elemento, deixando de lado o
espinha atravessada (todo o `:` nós que encontrou no caminho até lá), fazer a mudança,
e, em seguida, recriar toda a `:` acabamos de nos livrar. Isso é O(n) para um acesso aleatório que também é muito terrível.

Mas talvez possamos usar listas de alguma forma, não apenas simples como `[a]`. Nós
queremos que a nossa fita de ter um "meio", ou seja, ele tem um elemento estamos atualmente
olhando para, em seguida, nós também temos de colocar os elementos não estamos olhando
algum lugar. Não vai ser uma "esquerda do meio" e "direito da média"
parte para isso, e tomados em conjunto que é nosso novo tipo:

```haskell
data Tape a = Tape [a] -- Left of the pivot element
                    a  -- Pivot element
                   [a] -- Right of the pivot element
```

Agora temos a nossa fita, mas não há nada que podemos fazer com ele além de fazer
um. Mas espere, vamos precisar fazer isso de qualquer maneira - o programa começa com um vazio
fita, que tem um eixo de rotação de zero, e os zeros infinito em ambas as direcções:

```haskell
emptyTape :: Tape Int
emptyTape = Tape zeros 0 zeros
      where zeros = repeat 0
```

Como um benefício agradável para a preguiça de Haskell, você tem fita infinita tanto para a esquerda e para a direita para livre,
e o compilador irá preocupar sobre como lidar com os detalhes.

Tudo bem, o que mais precisamos? Queremos ir para a esquerda e para a direita na fita
(Lembre-se que `<>` fazer). A função `moveRight` faz exatamente isso: é preciso um
elemento da lista da direita e coloca-lo em foco, e coloca o pivô anterior
na lista à esquerda. `moveLeft` é o mesmo, mas o contrário:

```haskell
moveRight :: Tape a -> Tape a
moveRight (Tape ls p (r:rs)) = Tape (p:ls) r rs

moveLeft :: Tape a -> Tape a
moveLeft (Tape (l:ls) p rs) = Tape ls l (p:rs)
```

Então essa é a fita de todos codificados em Haskell. Você provavelmente já adivinhou que
`moveRight` está relacionado o`> `faz, mas isso é parte da próxima seção.

No interpretador acabado, nós vamos ter que objetos `Tape`: um para os dados
fita (aquele com os números nele), e uma para o código-fonte (porque
quando nos deparamos com um `]` temos que andar para trás no código-fonte). Enquanto
a fita de dados é infinita, a fita de origem é finito e começa com uma
vazio lado "esquerdo".


### Exercícios

1. (fácil) Eu mencionei que você não precisa `Functor` para este tutorial, mas no caso
    você quer ter um ir para lá: escrever uma instância `Functor` para `Tape` (não
    se esqueça de verificar as leis).
    
2. (médio) As funções `moveLeft` e `moveRight` tem um problema: para alguns (ou seja, bem-digitados) fitas válidas eles se comportassem mal. 
	   Em particular, consideram que, como mencionado acima, a fita de instrução é finito. O que acontece quando chegarmos ao fim e concentrar-se novamente à direita? 
	   Qual seria maneiras de corrigir o problema?

3. Streams
  1. (médio) Uma vez que a fita de dados é sempre infinito, a lista não é absolutamente
       o tipo certo para ele - ele permite que uma lista vazia. A melhor representação
       para isso seria um tipo `Stream`, que é idêntico ao listas exceto que não tem nenhum elemento de "vazio", ou seja, todos os valores são de comprimento infinito.
       Implementar esse tipo e uma função `repeat` para ele análogo ao `Data.List.repeat`.
  2. (Dificil) Modifique o tipo `Tape` por isso leva o tipo de recipiente para
       usar como um argumento de tipo, permitindo que você crie uma fita com `[]` ou
       `Stream` neles. Para cada um, escreva `` moveLeft` e moveRight`. o
       tipo com base em lista irá sofrer com as questões levantadas no exercício acima,
       mas que sobre os rotações de fita baseados em `Stream`?     
 

Parte 3: Avaliação
------------------

Tudo bem, as ferramentas terminar, tempo para obter a avaliação real para trabalhar!
Vamos pensar sobre o tipo da função `runBrainfuck` que gostaríamos de escrever.
Leva fonte Brainfuck que temos convenientemente analisado para `BrainfuckSource`
na parte 1, e tudo o que vai fazer é ler caracteres simples (quando se deparam com um
`,` Na fonte) ou imprimi-los (`.`), que são operações de IO. Portanto, o
Tipo nós estamos olhando é `BrainfuckSource -> IO ()`.

Mas `BrainfuckSource` é uma lista, que temos declarado impróprio para
representando nossos dados! O que fazer? Bem, escrever a lista para um `Tape`:

```haskell
runBrainfuck :: BrainfuckSource -> IO ()
runBrainfuck = run emptyTape . bfSource2Tape
    where bfSource2Tape (b:bs) = Tape [] b bs
          -- (`run` is defined below)
```

Nós já fizemos uma função `run`, que avalia uma instrução, e
começa com uma fita vazia. Vamos agora construir esta função peça por
peça. Em primeiro lugar, o tipo de `run` deve ser de modo que ele toma a dados
`Tape` ea instrução` Tape` como argumentos para que ele possa trabalhar com eles:


```haskell
-- Interpret the command currently focussed on the instruction tape
run :: Tape Int              -- Data tape
    -> Tape BrainfuckCommand -- Instruction tape
    -> IO ()
```

Agora vamos avaliar a nossa primeira instrução, `GoRight`! O que ele deve fazer para a fita de dados? Bem, nada além de mover o pivot:

```haskell
run dataTape source@(Tape _ GoRight _) =
      advance (moveRight dataTape) source

run dataTape source@(Tape _ GoLeft  _) =
      advance (moveLeft dataTape) source
```

Isso é `>` e `<` já tratadas: quando encontrados, o foco sobre os dados
fita vai mover uma célula para a direita ou para a esquerda, respectivamente. A seguir, precisamos
seguir em frente na fita de origem, porque senão estaríamos interpretando o mesmo
instrução mais e mais. Isso é o que `advance` é para.

```haskell
advance :: Tape Int              -- Data tape
        -> Tape BrainfuckCommand -- Instruction tape
        -> IO ()

advance dataTape (Tape _ _ []) = return ()
advance dataTape source = run dataTape (moveRight source)
```

Observe o primeiro caso, que é invocado quando nós funcionamos fora do código-fonte, ou seja,
chegar ao final do programa, no caso em que apenas, em vez de terminar recursivamente a diante.

Agora que isso está coberta, vamos passar para as próximas duas instruções, além
e subtração:

```haskell
run (Tape l p r) source@(Tape _ Increment  _) =
    advance (Tape l (p+1) r) source

run (Tape l p r) source@(Tape _ Decrement  _) =
    advance (Tape l (p-1) r) source
```

Aqueles eram os dois mais simples mortos, agora para as duas operações de IO. `.` Deve
ler o valor do pivô e imprimir o seu carácter correspondente; o último
é feito com `Data.Char.chr`, que você terá que importar manualmente. Para
razões técnicas você deve também `import System.IO (hFlush, stdout)`, que vamos usar para obter questões em torno do tamponamento
(se você não entender por que isso é necessário: é uma coisa IO para imprimir caracteres assim que dizem que deveria,
simplesmente ignorar as linhas associadas e você vai ficar bem).

```haskell
run dataTape@(Tape _ p _) source@(Tape _ Print  _) = do
    putChar (chr p)
    hFlush stdout
    advance dataTape source
```

E da mesma forma que vamos implementar `,`, usando o `chr` que é inversa à` ord` e
dá-nos um Int associada a um `Char`:

```haskell
run dataTape@(Tape l _ r) source@(Tape _ Read  _) = do
    p <- getChar
    advance (Tape l (ord p) r) source
```

Agora para a última parte: as construções de looping. Esses são um pouco mais complicado
porque temos de manter o controle de quantas sub-lacetes que encontrou portanto,
encontrar as chaves correspondentes direita. Com `seekLoopX` ainda indefinido, podemos pelo
menos anote como reagir a `[` ou `]` já:


```haskell
run dataTape@(Tape _ p _) source@(Tape _ LoopL  _)
    -- If the pivot is zero, jump to the
    -- corresponding LoopR instruction
    | p == 0 = seekLoopR 0 dataTape source
    -- Otherwise just ignore the `[` and continue
    | otherwise = advance dataTape source

run dataTape@(Tape _ p _) source@(Tape _ LoopR  _)
    | p /= 0 = seekLoopL 0 dataTape source
    | otherwise = advance dataTape source
```

O que resta agora é como codificar as funções `seekLoopX`. Conceitualmente, eles
deve mover-se ao longo da fita de origem até que uma cinta correspondente for encontrado, e em seguida
apenas continuar a avaliação normal. O primeiro parâmetro codifica as chaves de nidificação
nível estamos em encontrar chaves combinando - se encontrar um outro dois abertura `[`
após o primeiro que encontrar, vamos ter de passar mais dois `]` para compensar.


```haskell
-- Move the instruction pointer left until a "[" is found.
-- The first parameter ("b" for balance) retains the current
-- bracket balance to find the matching partner. When b is 1,
-- then the found LoopR would reduce the counter to zero,
-- hence we break even and the search is successful.
seekLoopR :: Int                   -- Parenthesis balance
          -> Tape Int              -- Data tape
          -> Tape BrainfuckCommand -- Instruction tape
          -> IO ()
seekLoopR 1 dataTape source@(Tape _ LoopR _) = advance dataTape source
seekLoopR b dataTape source@(Tape _ LoopR _) =
    seekLoopR (b-1) dataTape (moveRight source)
seekLoopR b dataTape source@(Tape _ LoopL _) =
    seekLoopR (b+1) dataTape (moveRight source)
seekLoopR b dataTape source =
    seekLoopR b dataTape (moveRight source)

seekLoopL :: Int                   -- Parenthesis balance
          -> Tape Int              -- Data tape
          -> Tape BrainfuckCommand -- Instruction tape
          -> IO ()
seekLoopL 1 dataTape source@(Tape _ LoopL _) = advance dataTape source
seekLoopL b dataTape source@(Tape _ LoopL _) =
    seekLoopL (b-1) dataTape (moveLeft source)
seekLoopL b dataTape source@(Tape _ LoopR _) =
    seekLoopL (b+1) dataTape (moveLeft source)
seekLoopL b dataTape source =
    seekLoopL b dataTape (moveLeft source)
```

E, finalmente, não devemos esquecer os comentários de avaliação, é claro, mas isso é trivial, pois um comentário simplesmente não fazer nada:

```haskell
run dataTape source@(Tape _ (Comment _) _) = advance dataTape source
```

E aí está, um intérprete de Brainfuck inteiramente caracterizado! Para usá-lo,
simplesmente fornecer a fonte para `runBrainfuck . parseBrainfuck`,  v.g. de
especificando um arquivo de origem como `readFile "filename.bf" >>= runBrainfuck . parseBrainfuck`.Tente [Hello World][helloworld] da Wikipedia!

### Exercícios

1. (fácil) A função `bfSource2Tape` não vai funcionar quando você dá um program válido
    programa representado por uma cadeia vazia. O que seria uma maneira fácil de fixação
    esta? Dica: `Comment` não fazem nada e pode salvá-lo de adicionar um tipo`Maybe`.

2. (fácil) A chamada para `ord` produz um erro quando aplicado a um elemento negativo,
   e você provavelmente não vai querer imprimir o número de caracteres 9001 em
   Brainfuck vez de qualquer maneira. Como você pode modificar o comando para restringir a
   saída para ASCII?
   
3. (médio) refatorar o código! Para não afogar o texto em detalhes bacana, asfunções implementadas na parte 3 são muito detalhadas.
    Você pode eliminar uma grande quantidade de casos comuns entre essas funções. Por exemplo, considere como um `[` se o
    0 pivô é o mesmo que é um comentário, ou como semelhantes, mas todo o primeiro caso para `seekLoopX` são.

4. Há muitas maneiras em que este interprete poderiam ser melhoradas.

1. (médio) Se você já fez os exercícios de partes 1 e 2, você pode incorporar os seus resultados para o código final.

2. (Médio) Em vez de ter `LoopL` e `LoopR` como primitivos, você poderia
       substituí-los por um tipo `loop BrainfuckSource`, representando a totalidade
       loop e do corpo. Avaliando tal `Loop` poderia saltar para o início
       do código contido muito mais fácil: não há necessidade de caminhar ao redor da
       fonte para encontrar mais a chave correspondente. Isto elimina a necessidade das funções
       `seekLoopX` e permite que o código de fonte a ser armazenado numa
       lista normal em vez de usar o `Tape`. Note que isto também torna a execução
       mais rápido: agora saltando para trás `N` instruções é O (1) em vez de O(n)!
      
3. Várias otimizações (abertas): Você pode combinar múltiplos usos da `Increment` modo que em vez de adicionar 1 cinco vezes, você pode simplesmente adicionar um único 5; 
   usos sucessivos de `+` e `-` anular, como fazem`> `e` <`. 
   E depois há otimizações de nível superior, bem claro, como reescrever `[-]` para "zerada ou erro se o conteúdo da célula é negativo".
