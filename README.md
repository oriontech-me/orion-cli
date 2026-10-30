# Orion CLI

CLI para automatizar tarefas como rodar Langflow, deploy, PR checkout, etc.

## Instalação

```bash
curl -s https://raw.githubusercontent.com/oriontech-me/orion-cli/main/install.sh | bash
```

## Comandos

### `orion langflow`

```bash
orion langflow run <branch>
orion langflow run pr <PR_NUMBER>
orion langflow fix-db [caminho-do-langflow]
```

### `orion list skills`

```bash
orion list skills
```

Sincroniza o catálogo e lista todas as skills disponíveis (nome +
description, lidos do `SKILL.md` de cada uma) — útil pra decidir o que
passar em `--only` antes de instalar.

### `orion install skills` / `orion uninstall skills`

Instala/remove a [biblioteca de skills do Claude Code](https://github.com/oriontech-me/orion-claudecode-skills)
padronizadas pela Orion — skills, `CLAUDE.md` e `settings.json`.

```bash
orion install skills global      # ~/.claude — vale para qualquer projeto
orion install skills project     # ./.claude e ./CLAUDE.md — vale só para o repositório atual

orion install skills project --only bug-report              # instala só uma
orion install skills project --only=bug-report,langflow-auth-token  # ou algumas

orion uninstall skills global
orion uninstall skills project
```

- `install` nunca sobrescreve o que já existe: `CLAUDE.md` é mesclado num
  bloco delimitado por marcadores, `settings.json` recebe um deep-merge
  aditivo (só adiciona chaves/itens que faltam). Rodar de novo atualiza
  (`git pull` + recopia) o que já estava instalado.
- `--only <nomes-separados-por-vírgula>` instala só as skills listadas em vez
  de todas as do catálogo. `CLAUDE.md` e `settings.json` são sempre
  mesclados, independente do `--only`. Nome desconhecido gera um aviso e é
  ignorado (não trava a instalação das demais).
- `uninstall` reverte exatamente isso: remove as skills, o bloco do
  `CLAUDE.md` e os itens de array que vieram do catálogo em `settings.json` —
  sem tocar em nada que o usuário tinha antes.
- O catálogo fica em `~/orion/claudecode-skills`. `install` e `list` fazem
  `checkout main` + `pull` ali e param se houver alteração não commitada.
- `example-skill` não é instalada: é só o modelo para criar skills novas.

### `orion install workspace`

Clona ou atualiza a pasta de trabalho de QA do time,
[`oriontech-me/qa-validation`](https://github.com/oriontech-me/qa-validation),
em `~/orion/qa-validation`. É ali que cada pessoa abre o Claude Code para
validar PRs e onde o [Sieve](https://github.com/remark-so/sieve) grava os
aprendizados compartilhados.

```bash
orion install workspace
```

- Se a pasta tiver alterações não commitadas (por exemplo, aprendizados
  novos do Sieve ainda não revisados), o comando avisa e não atualiza.
- No fim, mostra os passos únicos de cada pessoa: instalar o plugin do
  Sieve e rodar `/sieve --attach`.

### Acesso aos repositórios privados

O catálogo e a pasta de trabalho são privados. Se o clone falhar com
"Repository not found", configure o git para usar o login do `gh` uma vez:

```bash
gh auth login
gh auth setup-git
```

