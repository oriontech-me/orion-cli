# Orion CLI

CLI para automatizar tarefas como rodar Langflow, deploy, PR checkout, etc.

## Instalação

```bash
curl -s https://raw.githubusercontent.com/andifilhohub/orion-cli/main/install.sh | bash
```

## Comandos

### `orion langflow`

```bash
orion langflow run <branch>
orion langflow run pr <PR_NUMBER>
orion langflow fix-db [caminho-do-langflow]
```

### `orion install skills` / `orion uninstall skills`

Instala/remove a [biblioteca de skills do Claude Code](https://github.com/andifilhohub/orion-claudecode-skills)
padronizadas pela Orion — skills, `CLAUDE.md` e `settings.json`.

```bash
orion install skills global      # ~/.claude — vale para qualquer projeto
orion install skills project     # ./.claude e ./CLAUDE.md — vale só para o repositório atual

orion uninstall skills global
orion uninstall skills project
```

- `install` nunca sobrescreve o que já existe: `CLAUDE.md` é mesclado num
  bloco delimitado por marcadores, `settings.json` recebe um deep-merge
  aditivo (só adiciona chaves/itens que faltam). Rodar de novo atualiza
  (`git pull` + recopia) o que já estava instalado.
- `uninstall` reverte exatamente isso: remove as skills, o bloco do
  `CLAUDE.md` e os itens de array que vieram do catálogo em `settings.json` —
  sem tocar em nada que o usuário tinha antes.

