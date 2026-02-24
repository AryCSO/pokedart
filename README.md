# Pokédex (Pokedart) 🚀📱

Um aplicativo completo, moderno e responsivo de Pokédex desenvolvido em **Flutter** e **Dart**.
Construído com base numa arquitetura MVVM sólida, o projeto consome a fantástica [PokéAPI](https://pokeapi.co/) para entregar dados detalhados de centenas de monstrinhos de bolso, seus itens nativos e as Regiões de onde vieram!

<div align="center">
  <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png" width="200" alt="Charizard">
  <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/248-mega.png" width="200" alt="Tyranitar Mega">
  <img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/448-mega.png" width="200" alt="Lucario Mega">
</div>

---

## 🌟 Funcionalidades Principais

*   **Pokedex Nacional Completa:** Navegue por Pokémon de todas as gerações.
*   **Design MVVM:** Estado previsível e manutenção fluída através do pacote `provider`.
*   **Hero Cards & Glassmorphism:** Menus laterais dinâmicos e painéis retráteis utilizando a essência de espelhos turvos (Glassmorphism) e UI Modernas para entregar estatísticas de Pokémon.
*   **Formas Alternativas e Evoluções:** Vizulize linhas evolutivas ramificadas, bem como modelos *Mega Evolução*, *Galand*, *Hisui*, e Variantes *Gigantamax*, totalmente pesquisáveis via barra de busca!
*   **Traduções Massiva (Pt-Br) Offline & Neural:** A "Lore" de capa de cada criatura, nomes e utilidade de Itens, são passadas ao vivo via *Motor Neural do GoogleTranslator*. Cidades e localizações inteiras são formatadas de inglês pra português nativamente usando um parser offline em milissegundos sem esgotar sua franquia de dados.
*   **Motor de Filtro Robusto:** O motor permite que procure por IDs ou pelos nomes exatos e complexos como `Lucario Mega` ou `Pikachu Gigamax` limpando magicamente os hifens da base original de dados!
*   **Poké Mart (Aba de Itens):** Descubra valores de compra, efeitos em mapa/batalha e características de todos os itens catalogáveis.
*   **Continentes (Aba de Regiões):** Uma enciclopédia expansível exibindo cards tipográficos associados às famigeradas cores e paletas clássicas dos jogos onde tal Continente apareceu primeiro (Kanto carrega vermelho e azul, Johto Dourado e Prata, etc).
*   **Sistema de Captura Detalhado:** Todos os Pokémon informam em Módulos "Sanfona" (ExpansionTiles) sob quais Fitas exatas/Jogos específicos eles aparecem e quais rotas ou cavernas o Treinador deve seguir.

---

## 🛠️ Tecnologias Utilizadas

- **Flutter:** Framework principal da renderização (Suporte para Mobile & Desktop).
- **Dart:** Linguagem base da arquitetura Orientada a Objetos.
- **Provider:** Padrão sólido e testado na injeção de dependências do View-Model.
- **Http:** Cliente veloz de consumo da RestAPI externa.
- **SidebarX:** Abstração utilizada na responsividade da barra de menu lateral do aplicativo da Desktop para Mobile.
- **Google Translator:** Engine neural para os textos ricos e descritivos (*Lore*).
- **PokeAPI:** Maior e mais rápido banco de dados aberto documentando todos os jogos canônicos da GameFreak.

---

## 📦 Como rodar este projeto?

### Pré-Requisitos:
Antes de começar, você precisa ter instalado em sua máquina o [SDK do Flutter](https://docs.flutter.dev/get-started/install) e a IDE de sua preferência configurada (VS Code, Android Studio, etc).

1. Clone este repositório para a sua máquina física:
   ```bash
   git clone https://github.com/SeuUsername/pokedart.git
   ```

2. Acesse a pasta na raiz do projeto:
   ```bash
   cd pokedart
   ```

3. Baixe os pacotes descritos pelas dependências do aplicativo (`provider`, `http`, `translator`, etc...):
   ```bash
   flutter pub get
   ```

4. Execute a base do App (Configure um emulador rodando ou a versão web local):
   ```bash
   flutter run
   ```

---

## 📖 Arquitetura do Projeto
A adoção do MVVM (Model - View - ViewModel) isolou magnificamente o app:

*   **`lib/models`:** Classes estritas puras para tipagem e formatação da nuvem como: `pokemon_model.dart`, `item_model.dart`, e `region_model.dart`.
*   **`lib/viewmodels`:** Controladores de cache, parsing assíncrono e formatação que conversam entre os endpoints. Destaque par ao `pokedex_viewmodel.dart`.
*   **`lib/views`:** Composição das páginas modulares contendo os componentes visuais com o layout e Hero Elements (`pokedex_page.dart`, `items_page.dart`, `regions_page.dart`).
*   **`lib/utils`:** Ferramentas utilitárias globais puras isoladas, como as "Regras Clandestinas" do `format_helper.dart` que traduz locais pra Pt-Br massivamente em milissegundos sem estourar limites neurais Web.

---

## 💬 Contatos
Desenvolvido com maestria ao redor do fascinante mercado de APIs. Se desejar compartilhar ideias em Dart ou discutir MVVM de Frontend e melhorias para esse mapa, puxe assunto! 

* Desenvolvedor: **Aryel Sobrinho (Ary)**
* A paixão é sempre Geek e tecnológica! ☕👾
