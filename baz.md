# Write yourself a Brainfuck in an hour 

Introdu��o
----------

Este � um tutorial b�sico sobre como criar um interpretador Brainfuck inteiramente caracterizado em Haskell.
Brainfuck � uma (Turing completo!) Linguagem de programa��o que visa ter muito pouco de sintaxe, e devido � seu aparelho simples de instru��o, � muito f�cil de implementar.

Este tutorial � *muito* b�sico: ter lido Lear Yourself A Haskell � bom o suficiente. Na verdade, n�s veremos r que n�o precisa nem de nenhum Functor / Applicatives / m�nadas
tudo vai ser pattern-matching, tipos de dados personalizados, e claro, da aplica��o de fun��o. Para ser mais espec�fico, vamos usar LYAH os cap�tulos cap�tulos 1-6, 8, muito pouco de 9, e
o in�cio de 14.

O tutorial � dividido em tr�s partes. Primeiro, vamos criar um tipo de dados para representam o c�digo-fonte Brainfuck, e como converter c�digo fonte Brainfuck em
este formato. Na segunda parte, iremos modelar a fita e converter o Brainfuck c�digo-fonte em uma representa��o mais adequada. A se��o final ser�
avalia��o, em que n�s andamos em torno da fita fazendo as opera��es a fonte dita.

### Especifica��o completa da linguagem

O c�digo Brainfuck consiste em uma sequ�ncia de caracteres de controle, infinitamente fita longa preenchido com zeros, e o assim chamado ponteiro de dados que aponta para o
posi��o inicial sobre a fita. O s�mbolo atual no c�digo � lido e executado, ent�o o pr�ximo s�mbolo � olhado. Este processo � repetido at� que a �ltima instru��o tem sido tratado.

- `>` Move o ponteiro de dados de um campo � direita.
- `<` Move o ponteiro de um campo de dados para a esquerda.
- `+` Adiciona 1 para o campo atual.
- `-` Subtrai 1 para o campo atual.
- `.` Imprime o caracter que corresponde ao valor da corrente de campo (ASCII).
- `,` L� um �nico caractere do teclado e armazena seu valor no c�lula atual.
- `[` Se o valor atual � zero, e depois saltar para a frente para o comando ap�s a comando correspondente ].
- `] 'Se o valor atual for diferente de zero, e depois saltar de volta para o comando ap�s o comando corresponde [ .
- Qualquer outro caractere � tratado como um coment�rio.

� isso a�. Note-se como o �nico erro de sintaxe poss�vel � descasamento entre par�nteses.

### Alguns exemplos de c�digo Brainfuck

Para lhe dar um vislumbre de a abomina��o que estamos prestes a criar:

- `[-]` Limpa uma c�lula contendo um valor positivo: Quando a `[` � atingido, o
�� c�lula � zero j� (caso em que o programa salta ap�s o
�� Coincidindo `] ', ou seja, o programa termina), ou diferente de zero. No caso diferente de zero,
�� o `[` � simplesmente ignorado, `-` � avaliado e diminui a c�lula atual
�� por um, e `]` � atingido. Se a c�lula � zero agora, ent�o ignorar o `] 'e
�� rescindir, caso contr�rio, pule de volta para depois do `[`. A partir desta voc� pode ver como
�� `[]` Atua como um loop.
�� 
�� - `> [-] <[-> + <]` Move os dados a partir de uma c�lula de uma c�lula para a direita (substituindo
�� seu valor). Em primeiro lugar, o ponteiro de dados move um para a direita com `>`, ent�o
�� h� o comando "c�lulas claras" `[-]` voc� sabe de cima, eo ponteiro
�� se move para tr�s. O que temos agora � uma c�lula com algum conte�do, que tem um vazio
�� pr�ximo � sua direita. Agora, a segunda la�o come�ar: diminuir a corrente
�� celular, mova um para a direita, incrementar c�lula vizinha, mover para a esquerda novamente. este
�� O corpo de circuito toma o conte�do da c�lula para a esquerda e coloca-a no direito
�� c�lula, um por um, at� que a c�lula � esquerda est� vazia. No final, o ponteiro
�� estar na c�lula � esquerda vazio, enquanto a c�lula vizinha � preenchido com os dados.
�� 
�� - Para imprimir a letra "a", que tem um valor ASCII 97, use `++++++++++ [> ++++++++++ <-]> ---`.. Isso inicializa pilha 0 com 10, e em seguida, incrementa celular 1 dez vezes por outros 10, nos dando 100 na c�lula 1. 
�� Finalmente, subtraia 3 e imprimir o resultado. O [standard "Hello World"program][helloworld] � constru�do com base neste princ�pio.
�� [helloworld]: http://en.wikipedia.org/wiki/Brainfuck#Hello_World.21

�� Como voc� pode ver, os programas n�o s�o muito leg�vel. Como temos sorte que n�o somos n�s que vamos tentar escrever, mas sim implementa-lo, que � muito mais f�cil.
�� 
�� Parte 1: Brainfuck type, e como analisar isso.
�� 
�� Para o tipo de dados, vamos simplesmente criar um que tem um construtor para cada elemento sint�tica:
�� 
�� ```haskell
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

Vamos tamb�m criar um sin�nimo tipo de representar todo um programa Brainfuck,
                      
```haskell
type BrainfuckSource = [BrainfuckCommand]
```

Nosso objetivo agora est� tomando uma string como `[-]` e convert�-lo para o Haskell valor `[LoopL, Decrement, LoopR]`. Uma vez que estamos atravessando a cadeia de entrada
caractere por caractere (porque cada instru��o � apenas um caractere), podemos apenas usar `map` converter-se entre String e `BrainfuckSource`:

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

Isso � muito bonito isso para esta parte. Note como qualquer coisa que n�o corresponde a um comando v�lido � interpretada como um coment�rio na �ltima linha.

### Exerc�cios

Aqui est�o algumas melhorias que voc� pode fazer em seu c�digo. (N�o se preocupe se voc� n�o faz�-las, o resto do tutorial n�o vai lev�-los em conta.)

1. (f�cil) Coment�rios n�o s�o necess�rios para a avalia��o, portanto, pode apenas deix�-los
��� a partir da fonte quando n�s analis�-lo. Olhe para cima o que `mapMaybe` faz (por exemplo,
��� usando [Hoogle] [Hoogle]) e us�-lo para substituir o `map` em` parseBrainfuck`
��� de modo que os coment�rios s�o ignorados.

[hoogle]: http://www.haskell.org/hoogle/

2. (f�cil) Voc� n�o pode escrever uma inst�ncia `show` para um sin�nimo tipo como
��� `BrainfuckSource` (porqu�?). Reescrev�-lo usando uma `declara��o data` a um tipo
��� que cont�m um `[BrainfuckCommand]`, e definir uma inst�ncia `show` para esse novo
��� Tipo que imprime a fonte contido. Por exemplo, `Show $ BFSource [LoopL, Decrement, LoopR]` deve gerar "[-]" em GHCi.

3. Checking syntax

1. (m�dio) O �nico erro de sintaxe poss�vel em c�digo Brainfuck � descasamento
������ par�nteses. Por exemplo `[-` tem uma abertura, mas nenhum fechamento de correspond�ncia
������ par�ntese, e `-]` tem um par�ntese de fechamento, mas n�o correspondente
������ uma abertura. Escrever uma fun��o `checkSyntax` do tipo
������ `BrainfuckSource -> Maybe BrainfuckSource` que retorna `Nothing` se o
������ c�digo for inv�lido, e de outra forma `Apenas <c�digo v�lido>`. Use esta fun��o para
������ modificar `parseBrainfuck` para rejeitar c�digo inv�lido, o que, em seguida, tem o novo
������ digite `String -> Maybe BrainfuckSource`.

2. (Dificil) Modifique o `Maybe tipo BrainfuckSource` para
������ `Either String BrainfuckSource`. c�digo correto deve gerar
������ `<Valid Code> Right`, enquanto uma incorreta deve resultar em um valor `Left`
������ informando os usu�rios sobre o problema, por exemplo, "a abertura sem correspond�ncia par�ntese".

3. (Dificil) Fa�a as mensagens de erro a partir de cima melhor: fazer as mensagens de erro informar ao usu�rio sobre a posi��o dos par�nteses ofensivas,
	     por exemplo, "o car�ter fonte n-th � um par�ntese de fechamento sem um uma abertura".


Parte 2: A fita
---------------

A fita � uma longa linhagem de c�lulas, cada um segurando um n�mero. O tipo mais f�cil
Haskell para representar um n�mero � uma lista, mas lembre-se o que queremos fazer com
a fita: atravess�-lo em ambas as dire��es, e elementos de atualiza��o (potencialmente profunda
para baixo) com frequ�ncia, ambas as listas coisas s�o particularmente ruim em: travessia, tanto
dire��es simplesmente n�o � poss�vel (listas v�o somente ida), e atualizar um
elemento requer atravessando a lista inteira at� aquele elemento, deixando de lado o
espinha atravessada (todo o `:` n�s que encontrou no caminho at� l�), fazer a mudan�a,
e, em seguida, recriar toda a `:` acabamos de nos livrar. Isso � O(n) para um acesso aleat�rio que tamb�m � muito terr�vel.

Mas talvez possamos usar listas de alguma forma, n�o apenas simples como `[a]`. N�s
queremos que a nossa fita de ter um "meio", ou seja, ele tem um elemento estamos atualmente
olhando para, em seguida, n�s tamb�m temos de colocar os elementos n�o estamos olhando
algum lugar. N�o vai ser uma "esquerda do meio" e "direito da m�dia"
parte para isso, e tomados em conjunto que � nosso novo tipo:

```haskell
data Tape a = Tape [a] -- Left of the pivot element
                    a  -- Pivot element
                   [a] -- Right of the pivot element
```

Agora temos a nossa fita, mas n�o h� nada que podemos fazer com ele al�m de fazer
um. Mas espere, vamos precisar fazer isso de qualquer maneira - o programa come�a com um vazio
fita, que tem um eixo de rota��o de zero, e os zeros infinito em ambas as direc��es:

```haskell
emptyTape :: Tape Int
emptyTape = Tape zeros 0 zeros
      where zeros = repeat 0
```

Como um benef�cio agrad�vel para a pregui�a de Haskell, voc� tem fita infinita tanto para a esquerda e para a direita para livre,
e o compilador ir� preocupar sobre como lidar com os detalhes.

Tudo bem, o que mais precisamos? Queremos ir para a esquerda e para a direita na fita
(Lembre-se que `<>` fazer). A fun��o `moveRight` faz exatamente isso: � preciso um
elemento da lista da direita e coloca-lo em foco, e coloca o piv� anterior
na lista � esquerda. `moveLeft` � o mesmo, mas o contr�rio:

```haskell
moveRight :: Tape a -> Tape a
moveRight (Tape ls p (r:rs)) = Tape (p:ls) r rs

moveLeft :: Tape a -> Tape a
moveLeft (Tape (l:ls) p rs) = Tape ls l (p:rs)
```

Ent�o essa � a fita de todos codificados em Haskell. Voc� provavelmente j� adivinhou que
`moveRight` est� relacionado o`> `faz, mas isso � parte da pr�xima se��o.

No interpretador acabado, n�s vamos ter que objetos `Tape`: um para os dados
fita (aquele com os n�meros nele), e uma para o c�digo-fonte (porque
quando nos deparamos com um `]` temos que andar para tr�s no c�digo-fonte). Enquanto
a fita de dados � infinita, a fita de origem � finito e come�a com uma
vazio lado "esquerdo".


### Exerc�cios

1. (f�cil) Eu mencionei que voc� n�o precisa `Functor` para este tutorial, mas no caso
��� voc� quer ter um ir para l�: escrever uma inst�ncia `Functor` para `Tape` (n�o
��� se esque�a de verificar as leis).
��� 
2. (m�dio) As fun��es `moveLeft` e `moveRight` tem um problema: para alguns (ou seja, bem-digitados) fitas v�lidas eles se comportassem mal. 
	   Em particular, consideram que, como mencionado acima, a fita de instru��o � finito. O que acontece quando chegarmos ao fim e concentrar-se novamente � direita? 
	   Qual seria maneiras de corrigir o problema?

3. Streams
  1. (m�dio) Uma vez que a fita de dados � sempre infinito, a lista n�o � absolutamente
������ o tipo certo para ele - ele permite que uma lista vazia. A melhor representa��o
������ para isso seria um tipo `Stream`, que � id�ntico ao listas exceto que n�o tem nenhum elemento de "vazio", ou seja, todos os valores s�o de comprimento infinito.
������ Implementar esse tipo e uma fun��o `repeat` para ele an�logo ao `Data.List.repeat`.
��2. (Dificil) Modifique o tipo `Tape` por isso leva o tipo de recipiente para
������ usar como um argumento de tipo, permitindo que voc� crie uma fita com `[]` ou
������ `Stream` neles. Para cada um, escreva `` moveLeft` e moveRight`. o
������ tipo com base em lista ir� sofrer com as quest�es levantadas no exerc�cio acima,
������ mas que sobre os rota��es de fita baseados em `Stream`?���� 
�

Parte 3: Avalia��o
------------------

Tudo bem, as ferramentas terminar, tempo para obter a avalia��o real para trabalhar!
Vamos pensar sobre o tipo da fun��o `runBrainfuck` que gostar�amos de escrever.
Leva fonte Brainfuck que temos convenientemente analisado para `BrainfuckSource`
na parte 1, e tudo o que vai fazer � ler caracteres simples (quando se deparam com um
`,` Na fonte) ou imprimi-los (`.`), que s�o opera��es de IO. Portanto, o
Tipo n�s estamos olhando � `BrainfuckSource -> IO ()`.

Mas `BrainfuckSource` � uma lista, que temos declarado impr�prio para
representando nossos dados! O que fazer? Bem, escrever a lista para um `Tape`:

```haskell
runBrainfuck :: BrainfuckSource -> IO ()
runBrainfuck = run emptyTape . bfSource2Tape
    where bfSource2Tape (b:bs) = Tape [] b bs
          -- (`run` is defined below)
```

N�s j� fizemos uma fun��o `run`, que avalia uma instru��o, e
come�a com uma fita vazia. Vamos agora construir esta fun��o pe�a por
pe�a. Em primeiro lugar, o tipo de `run` deve ser de modo que ele toma a dados
`Tape` ea instru��o` Tape` como argumentos para que ele possa trabalhar com eles:


```haskell
-- Interpret the command currently focussed on the instruction tape
run :: Tape Int              -- Data tape
    -> Tape BrainfuckCommand -- Instruction tape
    -> IO ()
```

Agora vamos avaliar a nossa primeira instru��o, `GoRight`! O que ele deve fazer para a fita de dados? Bem, nada al�m de mover o pivot:

```haskell
run dataTape source@(Tape _ GoRight _) =
      advance (moveRight dataTape) source

run dataTape source@(Tape _ GoLeft  _) =
      advance (moveLeft dataTape) source
```

Isso � `>` e `<` j� tratadas: quando encontrados, o foco sobre os dados
fita vai mover uma c�lula para a direita ou para a esquerda, respectivamente. A seguir, precisamos
seguir em frente na fita de origem, porque sen�o estar�amos interpretando o mesmo
instru��o mais e mais. Isso � o que `advance` � para.

```haskell
advance :: Tape Int              -- Data tape
        -> Tape BrainfuckCommand -- Instruction tape
        -> IO ()

advance dataTape (Tape _ _ []) = return ()
advance dataTape source = run dataTape (moveRight source)
```

Observe o primeiro caso, que � invocado quando n�s funcionamos fora do c�digo-fonte, ou seja,
chegar ao final do programa, no caso em que apenas, em vez de terminar recursivamente a diante.

Agora que isso est� coberta, vamos passar para as pr�ximas duas instru��es, al�m
e subtra��o:

```haskell
run (Tape l p r) source@(Tape _ Increment  _) =
    advance (Tape l (p+1) r) source

run (Tape l p r) source@(Tape _ Decrement  _) =
    advance (Tape l (p-1) r) source
```

Aqueles eram os dois mais simples mortos, agora para as duas opera��es de IO. `.` Deve
ler o valor do piv� e imprimir o seu car�cter correspondente; o �ltimo
� feito com `Data.Char.chr`, que voc� ter� que importar manualmente. Para
raz�es t�cnicas voc� deve tamb�m `import System.IO (hFlush, stdout)`, que vamos usar para obter quest�es em torno do tamponamento
(se voc� n�o entender por que isso � necess�rio: � uma coisa IO para imprimir caracteres assim que dizem que deveria,
simplesmente ignorar as linhas associadas e voc� vai ficar bem).

```haskell
run dataTape@(Tape _ p _) source@(Tape _ Print  _) = do
    putChar (chr p)
    hFlush stdout
    advance dataTape source
```

E da mesma forma que vamos implementar `,`, usando o `chr` que � inversa �` ord` e
d�-nos um Int associada a um `Char`:

```haskell
run dataTape@(Tape l _ r) source@(Tape _ Read  _) = do
    p <- getChar
    advance (Tape l (ord p) r) source
```

Agora para a �ltima parte: as constru��es de looping. Esses s�o um pouco mais complicado
porque temos de manter o controle de quantas sub-lacetes que encontrou portanto,
encontrar as chaves correspondentes direita. Com `seekLoopX` ainda indefinido, podemos pelo
menos anote como reagir a `[` ou `]` j�:


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

O que resta agora � como codificar as fun��es `seekLoopX`. Conceitualmente, eles
deve mover-se ao longo da fita de origem at� que uma cinta correspondente for encontrado, e em seguida
apenas continuar a avalia��o normal. O primeiro par�metro codifica as chaves de nidifica��o
n�vel estamos em encontrar chaves combinando - se encontrar um outro dois abertura `[`
ap�s o primeiro que encontrar, vamos ter de passar mais dois `]` para compensar.


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

E, finalmente, n�o devemos esquecer os coment�rios de avalia��o, � claro, mas isso � trivial, pois um coment�rio simplesmente n�o fazer nada:

```haskell
run dataTape source@(Tape _ (Comment _) _) = advance dataTape source
```

E a� est�, um int�rprete de Brainfuck inteiramente caracterizado! Para us�-lo,
simplesmente fornecer a fonte para `runBrainfuck . parseBrainfuck`,  v.g. de
especificando um arquivo de origem como `readFile "filename.bf" >>= runBrainfuck . parseBrainfuck`.Tente [Hello World][helloworld] da Wikipedia!

### Exerc�cios

1. (f�cil) A fun��o `bfSource2Tape` n�o vai funcionar quando voc� d� um program v�lido
��� programa representado por uma cadeia vazia. O que seria uma maneira f�cil de fixa��o
��� esta? Dica: `Comment` n�o fazem nada e pode salv�-lo de adicionar um tipo`Maybe`.

2. (f�cil) A chamada para `ord` produz um erro quando aplicado a um elemento negativo,
   e voc� provavelmente n�o vai querer imprimir o n�mero de caracteres 9001 em
���Brainfuck vez de qualquer maneira. Como voc� pode modificar o comando para restringir a
���sa�da para ASCII?
���
3. (m�dio) refatorar o c�digo! Para n�o afogar o texto em detalhes bacana, asfun��es implementadas na parte 3 s�o muito detalhadas.
    Voc� pode eliminar uma grande quantidade de casos comuns entre essas fun��es. Por exemplo, considere como um `[` se o
��� 0 piv� � o mesmo que � um coment�rio, ou como semelhantes, mas todo o primeiro caso para `seekLoopX` s�o.

4. H� muitas maneiras em que este interprete poderiam ser melhoradas.

1. (m�dio) Se voc� j� fez os exerc�cios de partes 1 e 2, voc� pode incorporar os seus resultados para o c�digo final.

2. (M�dio) Em vez de ter `LoopL` e `LoopR` como primitivos, voc� poderia
������ substitu�-los por um tipo `loop BrainfuckSource`, representando a totalidade
������ loop e do corpo. Avaliando tal `Loop` poderia saltar para o in�cio
������ do c�digo contido muito mais f�cil: n�o h� necessidade de caminhar ao redor da
������ fonte para encontrar mais a chave correspondente. Isto elimina a necessidade das fun��es
������ `seekLoopX` e permite que o c�digo de fonte a ser armazenado numa
������ lista normal em vez de usar o `Tape`. Note que isto tamb�m torna a execu��o
������ mais r�pido: agora saltando para tr�s `N` instru��es � O (1) em vez de O(n)!
������
3. V�rias otimiza��es (abertas): Voc� pode combinar m�ltiplos usos da `Increment` modo que em vez de adicionar 1 cinco vezes, voc� pode simplesmente adicionar um �nico 5; 
   usos sucessivos de `+` e `-` anular, como fazem`> `e` <`. 
   E depois h� otimiza��es de n�vel superior, bem claro, como reescrever `[-]` para "zerada ou erro se o conte�do da c�lula � negativo".