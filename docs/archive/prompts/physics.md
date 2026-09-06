Plano:

Rodada 1

Desejo agora começar a criar um projeto para exibição de projetos relacionados a conceitos físicos. Eu já tenho um repositório que tem programas implementados em C++, com Raylib para a parte visual e ImGui para os parâmetros. Quero agora deixar isso disponível na web, para que um usuário ao acessar o link consiga executar a simulação e visualizar o movivento da simulações. Para começar não precisa implementar os 3. Quero que comece pelo project2_pendulum. tenho algumas dúvidas:

- Como fazer para essa simulação rodar e funcionar via web?
- Qual processamento é feito do lado do cliente e qual é feito do lado do server?
- O meu VPS dá conta de servir essa aplicação? Considere que já tem a aplicação lists.bwinkeler.com sendo servida.
- Seria possível futuramente fazer upload de uma aplicação que usasse uma outra stack em C++ ao inves de Raylib e ImGui, talvez SDL3, ou Qt?

Planeje cuidadosamente e detalhadamente como fazer isso, considerando tudo que foi comentado, bem como os documentos disponíveis no workspace. 

Rodada 2

É minha primeira vez fazendo isso. Não conheço alguns conceitos e gostaria de um maior esclarecimento. Se possível crie diagramas que me ajudem a entender. Desejo que a teoria física, já presente dentro das pastas do project também sejam exibidas de alguma forma.
Pensei na possibilidade de um side menu colapsável para exibir todas as possíveis simulações, considerando que eventualmente eu desejo adicionar muito mais simulações físicas. Além disso desconsidere o uso futuro de Qt. Apenas usarei bibliotecas que tenha um suporte mais direto ao emscripten

Questões:

- O que é EmScripten e WebAssembly? Conheço Assmebly.
- Atualmente eu estou com meu portfolio em bwinkeler.com. Posso criar mais de uma página no Cloudflare?
- Será necessário realizar modificações no projeto cpp-physics-simulation?
- Quais as limitações dessa abordagem (exibição e simulação via web) quanto a simulações que precisem de um pouco mais de processamento? 
- O resultado que eu consigo nativamente buildando em C++ e rodando localmente, o quão melhor é que usar essa maneira?
- Caso eu aumente consideravelmente a quantidade de simulações, eu precisaria repensar a maneira de hostear? Se sim, acho melhor pensar em algo mais escalável. Seria o VPS nesse caso?
- Já criei e fiz o clone do repositório bwinkeler-physics.
tem alguma maneira de alterar o mínimo possível do repositório cpp-physics-simulation? Eu acredito que o propósito do repositório é de fato para focar em simulações em C++ localmente.

Melhorias:

Rodada 1

O resultado em si, para apenas uma rodada de prompt ficou excelente, ainda assim tem algumas melhorias:

- O tamanho das fontes e da simulação estão pequenos, mal é possível enxergar o que está escrito;
- O ponteiro do mouse dentro da simulação está deslocado do ponteiro do PC. Iss faz com que seja muito difícil clicar e alterar os parâmetro via mouse;
- Deve ter a opção de colocar a simulação em Full Screen, para que o usuário consiga focar exclusivamente na simulação, caso ele queira;

Rodada 2

Desejo adicionar agora os outros dois projetos. As mesmas premissas devem ser mantidas.

Rodada 3

- Como mencionado no documento, colocar a linguagem principal como sendo portugues-br com opcional de ingles
