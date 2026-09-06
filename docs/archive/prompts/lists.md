melhorias bwinkeler-lists

admin@example.test / dev-password-change-me (admin)
member@example.test / dev-password-change-me


Rodada 1

- Mudar o título da pagina para um nome que corresponda a uma aplicação que esteja de acordo com as funcionalidades. Fique a vontade para sugerir nomes. Atualmente é "BWinkeler Lists".
- O visual não está moderno e agradável para o usuário. A grande maioria dos elementos visuais estão defasados de aplicações mais modernas;
- A priorização dos itens na lista não estão funcionando. Além disso, não quero botões para fazer essa priorização. desejo no esquema de drag and drop, segurando um item da lista e arrastando para o local onde eu desejo que ele fique;
- Ao criar uma nova lista, a aplicação deve ir para a página da lista que foi criada.
- O botão de delete de um item de uma lista não está funcionando;
- Vários elementos visuais não estão seguindo referencias de posicionamento, o que faz com que elementos fiquem muito colados ou que parecem ter tamanhos diferentes.

Rodada 2

- No Docker Desktop, não vejo os containers do front end e do backend. Faz diferença do ponto de vista de uso de recursos, pensando no futuro deploy na VPS usar essa abordagem de run local ou run via container e orquestração com docker compose? Se não fizer tanta diferença, eu prefiro via docker compose, por questão de organização, não necessidade de instalação de ferramentas locais e reprodutibilidade em outras máquinas/VPS. Além disso, a mesma estrutura do docker compose poderia ser reutilizada em outros projetos hospedados na mesma máquina, o que facilitaria a implementação de futuras aplicações.
- Quero a possibilidade de alterar o tema. Botão no canto superior direito (ícone de lua/sol);
- Quero pode criar categorias dentro da lista. Isso é especialmente útil para lista de compras de supermercado;
- Quero ser possível criar uma cópia de uma lista já existente. Ao criar a cópia, deve ter uma opção de que os itens da cópia virão não completados.
- Possibilidade de criar uma cópia somente do itens não completados de uma lista. Útil para quando quiser fazer uma lista de compras do dia, tendo uma lista gigante de itens previamente salva.

Rodada 3

- Quero que as categorias também possam ser reordenadas da mesma maneira que itens;
- Ao entrar na página da lista, a possibilidade de renomeio deve acontecer ao clicar no título da lista. Não é necessário uma seção de List Settings só para isso. Ao clicar no título, o título se converte num textbox editável e o botão de rename aparece ao lado.
- ícone de sininho das notificação não está alinhado com os demais itens da navbar.
- Atualmente como é possível adicionar um novo membro?
- O tema default deve ser light;

Rodada 4

- Não estou conseguindo mais mover itens entre categorias, nem reordena-los dentro de uma mesma categoria;
- Quando eu clico no sino de notificação, caso eu clique em outro lugar da tela, a lista de notificações deve desaparecer. Atualmente isso não acontece.
- O botão de invite na seção de sharing está desalinhado em altura dos demais elementos da mesma linha (textbox do email);
- Deve ser possível alterar as cores das categorias. Para que visualmente fique mais fácil de diferenciar;
- O texto das categorias deve ser um pouco maior para ter mais destaque que os itens;
- Se a adição de membros é via CLI, qual o sentido de usar email e não um user name qualquer? Além disso, qual a diferença do usuário admin do member?
- O número de itens em uma categoria está desalinhado em altura do nome da categoria.

Rodada 5

- A parte de reordenação está funcional, mas a UX não está boa. Quando um card começa a ser arrastado o card próximo já muda para assumir a nova posição, quando na verdade o que eu esperava é que permanecessem no mesmo local e só fossem pra nova posição quando o card arrastado passasse da metade do que ele está passando por cima.
- Quando eu estou movendo as categorias, o comportamento está mais dentro do que eu também espero para os itens, sendo que quando eu faço o drop na nova posição, as categorias envolvidas, de maneira extremamente rápida, trocam de lugar para a posição original e depois se estabelecem na nova posição. Muito rápido mas ainda perceptível
- Quero que os itens não categorizados, bem como o container 'Uncategorized' fique sempre no bottom. Quando novas categorias forem sendo criadas elas vão ficar sempre a frente dos 'Uncategorized'.
- Quero que seja possível pinar uma lista para que na página inicial que mostra todas as listas criadas, elas sempre fiquem no topo, e separada das demais;
- Alguns botões não estão com o texto centralizado. Por exemplo o botão de Add um item, Duplicate, Create, etc. Ajuste.

Rodada 6

- A parte de reordenação de itens ainda não está boa. O comportamento permanece. Por exemplo, quando eu movo levemente o item o próximo item já assume o lugar. Sendo que agora foi colocado uma cópia de baixa opacidade junto mas não resolveu.
- Quanto a ordenação de listas, anteriormente estava melhor, o mesmo efeito de opacidade dos itens foi acrescentado mas piorou a UX, e não resolveu o flickering que estava acontecendo na ação de drop, pós-drag.
- Foi acrescentado ainda um efeito indesejado de que agora que o Uncategorized esta no bottom, as outras categorias estão conseguindo mover a Uncategorized quando fazem o drag and drop. A categoria não é de fato movida e volta para o bottom, mas o efeito visual é realizado.

Rodada 7

- A parte de reordenação tanto de categorias quanto de itens está completamente bugada. Quando eu arrasto categorias, muitas vezes elas não ficam onde deveriam. Algumas vezes é impossível reordenar uma categoria mais abaixo para colocar no topo. Além disso para várias operações de reordenação não tem nenhuma animação associada, o que faz com que o salto de mudança de posição seja muito brusco e imprevisível. Coloque animações para realizar essas transições de posição. 
- Além disso, use como referencia para passar de uma posição para outra o mouse passar mais de 50% da posição da categoria/item que está sendo afetada.
- A categoria/item que está sendo movida deve sempre ficar visualmente a frente das demais. Algumas vezes quando arrasto para baixo, ela fica visualmente atrás de categorias que serão movidas.

Rodada 8

- O color picker das categorias está sendo contido visualmente pela categoria que está acionando. Em outras palavras, quando eu clico, se a categoria for pequena as cores mais de baixo não são mostradas, pois o color picker fica visualmente como se estivesse dentro do container da categoria.
- As animações da categoria estão ok, mas as entre itens não. Quando eu seguro e arrasto um item, quando ele passa por cima de outro, em um sentido aparece animação e em outro não. Tipo de baixo pra cima aparece mas de cima pra baixo não.
- O flickering quando duas ou mais categorias são ajustadas ainda acontece. Ou seja, quando eu movo uma categoria no lugar de outra e solto o botão do mouse, as categorias rapidamente voltam à posição original e depois se ajustam na nova posição. Investigue isso cuidadosamente e com bastante atenção, pois vem se repetindo a várias rodadas de melhorias.

Rodada 9 (Sol) - Excelente resultado

- O flickering ainda está acontecendo;
- A animação e suavidade das mudanças entre itens está melhor;
- Para as categorias, enquanto eu arrasto uma categoria, ela perde a cor associada, o que causa uma experiencia confusa para o usuário parecendo que é outra categoria que está sendo movida. A parte de mover está boa, só precisa manter a cor enquanto está movendo.

Rodada 10

- As animações da categoria estão ótimas, só que quando a categoria tem muitos elementos, dificulta a ordenação pois o mouse tem rolar muito mais até chegar na metade da próxima categoria. Se tiver alguma alternativa a isso, gostaria que você sugerisse, caso contrário, podemos deixar assim mesmo.
- Quando eu seguro e arrasto um item passando por cima de outro, geralmente o item que foi passado faz uma animação suave de recolocação em um sentido e não faz quando é passado em outro sentido. Tipo de baixo pra cima aparece mas de cima pra baixo não.
- Desejo adicionar a funcionalidade de adicionar um item diretamente em uma categoria, ao invés de sempre seguir o fluxo de adiciona primeiro em sem categoria e depois arrasta pra uma categoria. Me sugira possibilidade para implementação dessa funcionalidade. Quero que seja algo fácil e rápido de fazer.

Rodada 11

- Atualmente quando eu clico fora do input do item dentro da categoria, não é cancelada a edição automaticamente. Eu desejo que assim seja.

Rodada 12

- Tem acontecido um comportamento estranho em produção, que eu não consegui perceber tão evidente em dev. Quando eu movo categorias, principalmente quando é uma categoria mais proxima do fundo ou afastada com pelo menos uma categoria entre ela e o topo, e movo pra cima e tento colocar no topo, na maioria das vezes não funciona. Ou ela volta para a posição anterior, ou em algumas vezes vai para última posição. Isso também acontece com itens dentro de uma categoria. Isso é evidente em produção mas em desenvolvimento raramente ou nunca acontece.

Rodada 13

- Quando eu clico no sininho estando no celular, a janela de notificações fica com metade para fora da tela, como se não estivesse otimizada para o celular. Quero que você verifique isso.
- Além disso quero otimizar a aplicação para celular. Atualmente quando eu dou zoom dentro da aplicação de uma maneira geral, é possivel tanto fazer zoom in, quanto out. Quero que não seja possível. Consequentemente quero que desative a possibilidade de rolagem horizontal, apenas vertical. Todo o conteúdo deve ficar dentro do tamanho da tela. Estou usando um iPhone 13 normal, com safari. Se não for possívek otimizar de uma meneira geral, foque nesse dispositivo.
- Quero que você crie uma maneira mais fácil de adicionar um novo membro, talvez por meio de um script. Não precisa ser via aplicação. 
- Deve ser criado um script de deploy simples para que eu consiga realizar sempre que eu quiser.

Rodada 14

- A opção default de criação de lista deve ser Simple list
- Para a visualização em PC, ainda deve ser exibida num formato mais estreito como estava anteriormente. talvez aumentando um pouco as bordas, mas ainda assim não como está hoje em dia no qual os elementos estão quase sem bordas nas laterais na exibição em um monitor de PC.

Rodada 15

- Colocar o input de adição de categoria dentro de uma lista no topo, próximo ao de adicionar um novo item;
- Remover o input de adicionar um item que está no topo. A maneira padrão de adição de um item vai ser dentro das categorias, includeive para os items sem categoria.
- O botão de adicionar um item dentro de uma categoria não está funcionando pelo celular, mas funciona na versão web. A adição com o botão de retorno está funcionando em ambos os casos;
- Adicionar a funcionalidade de colapsar categorias. Dessa maneira apenas o header da categoria ficaria visível;
    - Deve haver um botão em cada header para colapsar individualmente cada categoria;
    - Deve haver um botão no topo para colapsar todas as categorias;
    - O botão de colapse all, deve de maneira alternada colapsar e descolapsar todos as categorias;
- Deve ser removida o botão de apagar um item individualmente. Os items a medida que forem completados, passarão para o fundo da categoria, e deve haver um botão de remover os itens completados. 
    - Esse botão deve estar disponível por categorias, bem como no topo para todos os itens completados. 
    - Deve exigir confirmação em ambos os casos;
- O tamanho do card de item deve ser 25% menor em termos de altura;

Rodada 16

- No modo de exibição de celular, O campo de adição de um item em uma categoria está compartilhando espaço com o botão de remover items completados e por isso está muito pequeno. Nesse sentido, coloque o botão de remover completados abaixo do input de adicionar item, ainda dentro da categoria.

Rodada 17 (a fazer)

- Quando clicar e visualizar a notificação ela deve ser marcada como lida. Não precisa ter um botão para marcar como lida;
- Campo de nome de nova lista no celular está muito pequeno. Alterar a disposição dos elementos;

Rodada 18

- Colocar o campo de nome de nova lista numa linha separada para o mobile. Atualmente no modo mobile o textbox do nome da nova lista fica na mesma linha do botão de create e do combobox do tipo da lista, sendo que fica muito pequeno e não dá pra ver. Coloque uma linha acima para facilitar a visualização, apenas no modo mobile;
- Faz wrap word por linha. Atualmente na visualização quando o texto de um item de uma lista tem muitas palavras, o texto total fica truncado até o tamanho da aplicação. Quero que seja feito um word wrap para que seja possível visualizar sempre todo o texto. Tanto para PC quanto mobile;
- As novas listas sempre devem ficar no topo da lista "ALL LISTS". Atualmente quando uma nova lista é adicionada ela vai para o final da "ALL LISTS";
- Colocar a funcionalidade de instalar o app para que fique em modo quiosque quando abrir. Quero que quando eu instale a aplicação no Iphone por exemplo, que a aplicação não mostre a barra de navegação nem os controle no bottom da tela;