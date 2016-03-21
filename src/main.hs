import Parser

main :: IO ()
main = readFile "helloworld.bf" >>= runBrainfuck . parseBrainfuck
