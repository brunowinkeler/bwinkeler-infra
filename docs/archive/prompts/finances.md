Desejo fazer um reformulação geral do projeto ai-vscode;

- Esse projeto agora será incorporado ao dominio bwinkeler.com;
- Minha intenção é tornar a aplicação acessível publicamente, mas com o login apenas para mim e minha esposa, tal qual o bwinkeler-lists;
- Ele deverá ser chamado agora bwinkeler-finances, cuja pasta e repositório ja foram criados: https://github.com/brunowinkeler/bwinkeler-finances.git
- Nesse caso eu deixei o repositório privado por questões de segurança. Quais os impactos disso? Eu consigo rodar CI/CD?;
- Verifique as opções de hosting da aplicação sabendo que eu tenho uma VPS disponível (usada no lists) e a plataforma do Cloudflare já configurada para páginas estáticas, R2 etc. Novamente, tal qual o lists, não tenho a intenção de expandir para múltiplos usuários, apenas eu e minha esposa;
- Revise desde as stacks que estão sendo utilizadas por cada parte;
- Revise as partes de UI e UX, e sugira novas versões para a aplicação para que eu consiga visualizar e escolher a que eu gostar mais;
- Sugira possíveis funcionalidades e melhorias que podem ser acrescentadas;
- Desejo acrecentar a parte de investimentos;
- Desejo adicionar simulações de investimento com juros compostos, diferentes alternativas de investimento etc.
- Por exemplo, atualmente eu gostaria de saber informações do tipo: "Quanto eu preciso investir por mês para conseguir um determinado objetivo financeiro?" Ou "Quanto eu posso gastar com desepsas variáveis, com lanche, com uber eats, etc.", ou "quais etfs eu deveria investir". 
- Para isso acredito que ao inves de integração com AI na plataforma, é melhor a criação de vários dashboards e relatórios a partir dos dados de entrada que possam ser exportados e posteriormente analisados por alguma AI;
- Enfim eu desejo uma verdadeira financial plataform ao inves de simplesmente uma plataforma de adição de gastos e entradas.

---

- Gostaria de pelo menos mais umas 5 propostas de UI;
- Gostei do modelo Dark da opção A, mas acho que a opção C representa melhor as transações;
- No geral eu gostei mais da opção C;
- A opção B eu não gostei de nada;
- Quero que as opções sejam mais próximas do modelo C;
- Quero que a versão final tenha a opção de mudar de modo Light para modo Dark;
- Pode explorar temas também usados aqui no Vscode como Shades of Purple e Dracula;
- Gostei da navbar ficar no fundo para a versão mobile da opção C;
- Gostei de não sobrar tanto espaço nas laterais na versão PC para a opção A, se comparada com a opção C;

---

- Essas opções de UI não precisam ficar no repositório, após minha escolha, devem ser apagadas;
- A exportação dos relatórios deve poder trazer todas as páginas. O usuário deve poder escolher quais páginas quer exportar de uma vez;

---

1. Gostei mais do layout Bento;
2. Quero todos os temas;

Não precisa apagar os prototypes, apenas colocar em algum canto ignorado para que eu possa ver novamente caso no futuro eu queira mudar algo de alguma forma.

---

Eu quero que a importação tal qual era no projeto ai-vscode (personal-finances) qeu seja possível fazer em lotes de arquivos, ou seja, vários arquivos de uma vez.

Além disso, quero que os outros formatos (MT940, xls, txt) também sejam aceitos;

Além disso, o CAMT.053 ele vem como zip do ABN, quero poder subir o zip e a platforma já ver o que tem dentro e importar. 

A confirmação ainda deve ser necessária, não mudar isso.
