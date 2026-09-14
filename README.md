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

### `orion skills`

Instala/atualiza a [biblioteca de skills do Claude Code](https://github.com/andifilhohub/orion-claudecode-skills)
padronizadas pela Orion.

```bash
orion skills install global    # ~/.claude/skills — vale para qualquer projeto
orion skills install project   # ./.claude/skills — vale só para o repositório atual
```

Rodar de novo atualiza (`git pull` + recopia) as skills já instaladas.

