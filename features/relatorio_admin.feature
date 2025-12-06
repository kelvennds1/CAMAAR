# language: pt
Funcionalidade: Gerar relatório do administrador (#101)
    Como Administrador
    Quero baixar um arquivo CSV contendo os resultados de um formulário
    A fim de avaliar o desempenho das turmas

    Contexto:
        Dado que estou autenticado como administrador

    Cenário: Baixar o CSV com resultados disponíveis
        Dado que existem resultados de formulários disponíveis
        E eu acesso a página de resultados do formulário
        Quando aciono o download dos resultados
        Então o arquivo CSV é baixado
        E o arquivo baixado se chama "avaliacao-desempenho-2025-1-resultados.csv"
        E o conteúdo do CSV inclui os dados das respostas

    Cenário: Mostrar mensagem quando não há respostas para exportar
        Dado que não existem respostas para o formulário
        E eu acesso a página de resultados do formulário
        Quando aciono o download dos resultados
        Então devo ver a mensagem "Ainda não há respostas disponíveis"
        E nenhum arquivo de resultados é baixado