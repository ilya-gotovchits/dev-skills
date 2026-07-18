# dev-skills

Единый источник правды для моих Agent Skills — правил/воркфлоу для AI-агентов.
Формат общий для **Claude Code** и **opencode**: каждый скил — папка с `SKILL.md`,
подключается симлинком в `~/.claude/skills/`, откуда его читают оба тула.

## Быстрый старт (развернуть на новой машине)

Пререквизиты: `git`, `bash`, и Claude Code и/или opencode.

```sh
# 1. клонировать куда угодно
git clone git@github.com:ilya-gotovchits/dev-skills.git ~/Projects/dev-skills
cd ~/Projects/dev-skills

# 2. подключить все скилы (симлинки в ~/.claude/skills/)
./install.sh

# 3. проверить
ls -l ~/.claude/skills/        # должны появиться pr-review-comments, self-review, …
```

Всё. Скилы теперь видны в Claude Code и в opencode (оба сканируют `~/.claude/skills/`).

**Обновление:** `git pull` — и готово. Симлинки указывают в репо, так что подтянутся
сразу; новые скилы после pull подключаются повторным `./install.sh` (идемпотентно).

**Кастомная папка скилов:** `CLAUDE_SKILLS_DIR=/path ./install.sh`.

## Как это работает

`~/.claude/skills/` читают оба тула — Claude Code (штатная папка) и opencode
(среди прочих локаций сканирует и `~/.claude/skills/*/SKILL.md`, формат идентичен).
Один симлинк из репо подключает скил сразу к обоим:

```
~/Projects/dev-skills/pr-review-comments  ──симлинк──▶  ~/.claude/skills/pr-review-comments
                                                         ▲            ▲
                                                    Claude Code    opencode
```

`./install.sh` проходит по всем папкам с `SKILL.md` и создаёт/обновляет симлинк на
каждую. Идемпотентен; `--dry-run` — показать без изменений; отказывается перетирать
реальную (не-симлинк) папку с тем же именем.

## Раскладка репо

```
dev-skills/
├── shared/            общее ядро методологии (симлинкуется в references/ скилов)
│   └── review-core.md
├── contracts/         машинные контракты между скилами
│   └── pr-review.contract.md
├── <skill>/           каждый скил: SKILL.md + references/ (часть — симлинки в shared|contracts)
└── install.sh
```

- **`shared/`** — тон-агностичная методология, переиспользуемая несколькими скилами.
  `review-core.md`: Principle #0, find-candidates → verification gate, 4-уровневая
  шкала, анатомия находки, формат отчёта (finding-блок, `Overview`, `Other`).
- **`contracts/`** — контракт формата данных между producer/consumer скилами.
  `pr-review.contract.md`: frontmatter + parse-поля + маппинг finding → GitHub-коммент.
- Общие файлы подключаются в скил **относительным симлинком** из его `references/`
  (корректно резолвится даже через внешний симлинк в `~/.claude/skills`). Правишь в
  одном месте — видят все.

## Скилы

- **`pr-review-comments`** — ревью **чужого** PR: тентативный тон, **никогда не постит**,
  пишет paste-ready `.md` инлайн-комментов (ядро + `pr-review.contract.md`).
- **`self-review`** — ревью **своего** кода (working diff + ветка vs base): тот же
  формат/шкала, прямой тон, **read-only отчёт** (ничего не правит/коммитит), в корень
  проекта. Ядро, без publisher-контракта.
- **`pr-comments-publisher`** — *(план)* читает файл ревью и постит комменты в GitHub
  от имени пользователя (pending review); контракт под него уже готов.

## Добавить новый скил

1. Папка `<имя>/` с `SKILL.md` (frontmatter: `name`, `description` — начинай description с «Use when…», только триггеры).
2. Общее — симлинком: `ln -s ../../shared/review-core.md <имя>/references/review-core.md`.
3. `./install.sh` — подключит. Коммит.

## Переносимость в opencode

Скил работает в opencode без изменений, **если не использует Anthropic-специфичные
вызовы**. Опирайся на переносимые инструменты (`gh`/`git`, MCP-серверы, обычный shell).
Ссылки на слэш-команды Claude (`/code-review` и т.п.) в тексте — подсказки для человека,
не зависимости; допустимы.
