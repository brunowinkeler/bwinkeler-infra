Desejo criar nesse workspace duas aplicações uma que vai rodar no mobile e uma que vai rodar na minha TV LG (appTV) e outra que vai rodar no meu celular (appMobile).  

O fluxo de execução das aplicações será o seguinte:

- O usuário faz um desenho em uma folha de papel de fundo branco;
- O desenho pode estar pintado ou não;
- Em seguida uma foto é capturada dentro da appMobile;
- Deve também ser possível carregar uma foto já capturada previamente;
- O desenho deve ser exibido em modo preview no appMobile sem o fundo branco;
- O usuário deve confirmar o desenho e solicitar envio para TV;
- O desenho tal qual exibido na prévia do celular deve também ser exibido na TV;
- O desenho deve iniciar movimentação na tela de maneira fluida e simulando um ser aquatico;

Exemplo real: Uma criança desenhou um peixe dentro do espaço delimitado da folha e coloriu, ao tirar a foto e carregar no appMobile, o peixe deve ser mostrado em modo prévia. Em seguida, ao solicitar envio para o appTV, o peixe deve ser exibido na TV, que terá uma animação de aquário e deverá exibir, a partir de então, o peixe tal qual foi desenhado e apresentado no appMobile.

Detalhes do appMobile:

- Deve ser possível capturar uma foto de dentro do aplicativo;
- Deve ser possível carregar uma foto da galeria do celular já previamente capturada;
- O app deve rodar tanto em iOS quanto em Android;
- A aplicação não precisa ser nativa ao sistema, pode usar plataforma híbrida;

Detalhes do appTV:

- A TV para a qual o aplicativo está destinado possui as seguintes especificações:

LG TV
Model: 43UK6300PLB
webOS TV Version: 4.4.3-22 (goldilocks-gorongosa)
Available Internal Storage: 0.14/0.53 GB
- A princípio o aplicativo deve ser pensado exclusivamente para essa TV, a menos que seja possível fazer um aplicativo que rode em multiplas marcas e sistemas de TV, sem acréscimo de tempo de desenvolvimento ou investigação;

Crie um plano de design para esse projeto e acrescente diagramas, imagens, e tudo que puder ajudar a entender melhor a arquitetura e design dos sistemas;
Qualquer dúvida, pode perguntar.

---

Eu já possuo uma conta no Cloudflare associada aos projeto desse workspace, inclusive revise o plano e veja se é possível adaptar à estrutura estabeleciada nesse workspace.

---

1. analise o arquivo de architecture dentro de bwinkeler-aquarium e modifique para se adequar ao plano. Além disso alguns pontos:

outros pontos:

- "1. **Teste imediato:** abrir `https://lists.bwinkeler.com` no navegador da TV. É a mesma zona e o mesmo tipo de certificado." eu tinha entendido que seria criado uma aplicação para a tv e não que eu teria de acessar o browser para testar alguma coisa;
- Pensando em escalabilidade, caso eu queria adicionar suporte a mais marcas e sistemas de TV, bem como permitir que o programa seja rodado em várias TVs ao mesmo tempo, a arquitetura já está pensada nessa possibilidade ou eu teria de refazer muita coisa?
- O fluxo na minha interpretação seria: O usuário clica na aplicação da TV e abre; aperta em algo como "Criar um novo Aquario"; Aparece na tela da TV um código para ser digitado no celular; O usuario digita na aplicação do celular o código que apareceu; a aplicação da tv reconhece que tem usuário logado (deve aparecer ainda em algum canto da tela a possibilidade de mostrar novamente o código para o caso de mais algum usuário querer entrar e colaborar com o aquário); O usuário pode então enviar imagens para o aquario; É assim que está o fluxo hoje em dia?
- Acredito que os aquarios não devem ser persistidos por muito tempo. deve ter um tempo limite de reconexão com o aquario, caso contrário será necessário criar outro;
---
Analise o que eu falei e veja o que já tinha sido pensado dessa forma, se faz sentido o que eu falei e se precisa ser adaptado;

---

**Várias TVs no mesmo aquário**: Se acrescentar muita implementação e validação, não precisa. Apenas vários celulares conectados ao mesmo aquario em uma unica TV é a feature desejada.

Pode começar as implementações.
