# Depos Action

GitHub Action для автоматического обновления зависимостей пакетов OneScript в файле `packagedef` с помощью [depos](https://github.com/Stivo182/depos). Если найдены обновления, Action создаёт или обновляет Pull Request.

## Использование

```yaml
name: Обновление зависимостей

on:
  schedule:
    - cron: '0 0 * * 1' # Каждый понедельник
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  update-dependencies:
    runs-on: ubuntu-latest
    steps:
      - name: Обновление зависимостей
        uses: Stivo182/depos-action@v1
        with:
          target: minor
```

### Входные параметры

| Параметр | Описание | Значение по умолчанию |
| --- | --- | --- |
| `packagedef` | Относительный путь к файлу `packagedef` или содержащему его каталогу. | `packagedef` |
| `filter` | Фильтр пакетов по именам через запятую или пробел, шаблону (`*`, `?`) или регулярному выражению. | |
| `target` | Тип целевой версии: `latest`, `minor` или `patch`. | `latest` |
| `depos-version` | Версия `depos`, устанавливаемая через `opm`. | Версия из [`.depos-version`](.depos-version) |
| `base` | Базовая ветка Pull Request. | Ветка по умолчанию репозитория |
| `message-prefix` | Префикс сообщения коммита и заголовка Pull Request. | `build(deps)` |
| `branch` | Имя ветки Pull Request. | `depos/bump-deps/<target>` для основной ветки; для другой базы добавляется `/<base>` |
| `labels` | Метки Pull Request, разделённые запятой или переводом строки. | `dependencies` |
| `token` | Токен для создания и обновления Pull Request. | `GITHUB_TOKEN` |

## Настройка токена

По умолчанию Action использует встроенный `GITHUB_TOKEN`. Для него необходимо:

1. Включить **Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests**.
2. Предоставить права в workflow:

   ```yaml
   permissions:
     contents: write
     pull-requests: write
   ```

События, созданные с помощью `GITHUB_TOKEN`, [не всегда запускают другие workflows](https://docs.github.com/en/actions/concepts/security/github_token). Если workflows создаваемого Pull Request должны выполняться автоматически, передайте Personal Access Token (PAT) или токен GitHub App.

Для fine-grained PAT достаточно выбрать целевой репозиторий и предоставить разрешения **Contents: Read and write** и **Pull requests: Read and write**. Для classic PAT требуется scope `repo`. Храните токен в GitHub Actions secret и передавайте его через параметр `token`:

```yaml
permissions:
  contents: read

jobs:
  update-dependencies:
    runs-on: ubuntu-latest
    steps:
      - name: Обновление зависимостей
        uses: Stivo182/depos-action@v1
        with:
          target: minor
          token: ${{ secrets.PAT }}
```

Не сохраняйте PAT непосредственно в workflow или других файлах репозитория.

## Поведение

Action обновляет указанный `packagedef` и при наличии изменений создаёт либо обновляет Pull Request. Повторные запуски с одинаковыми `base` и `branch` используют тот же Pull Request.

Для ветки по умолчанию рабочая ветка имеет вид `depos/bump-deps/<target>`. Для другой базовой ветки к имени добавляется `/<base>`, например `depos/bump-deps/minor/develop`.

Если в одном репозитории настроено несколько независимых обновлений с одинаковыми `base` и `target`, задайте каждой конфигурации уникальный параметр `branch`.

## Локальный предпросмотр Pull Request

Скрипт предпросмотра сам запускает `depos`, загружает метаданные и выводит в консоль заголовок и Markdown-тело будущего PR:

```powershell
opm install -l
oscript scripts/preview-pr.os --manifest packagedef --target minor
```

Доступны параметры `--manifest`, `--filter`, `--target` и `--message-prefix`. Полный список можно получить командой:

```powershell
oscript scripts/preview-pr.os --help
```

Без `GH_TOKEN` выводится сокращённый вариант без release notes и коммитов. Для полного предпросмотра передайте токен через переменную среды `GH_TOKEN`.

Исходный manifest не изменяется: `depos` работает с его временной копией. Версия `depos`
берётся из `.depos-version` и устанавливается самим скриптом через `opm`.

Параметр `packagedef` разрешается до конкретного файла. Если указан каталог, используется `<каталог>/packagedef`. Файл должен находиться под контролем Git; в Pull Request добавляются изменения только этого файла.

Если обновлений больше нет, Action ищет открытый Pull Request с теми же `base` и `branch`:

- Pull Request закрывается, а его ветка удаляется только при наличии в описании служебного маркера `depos-action`.
- Немаркированный Pull Request и его ветка остаются без изменений.
- Автоматически выбранная ветка без открытого Pull Request удаляется как оставшийся ресурс Action.
- Пользовательская ветка из параметра `branch` без управляемого Pull Request остаётся без изменений.

## E2E-тестирование изменений

Полный E2E-набор находится в отдельном репозитории [`Stivo182/depos-action-e2e`](https://github.com/Stivo182/depos-action-e2e). Администратор может запустить его для Pull Request комментарием:

```text
/test
```

Обработчик команды должен находиться в ветке по умолчанию `depos-action`. Настройка, способы запуска и используемые токены описаны в README тестового репозитория.

## Пример Pull Request

Заголовок сохраняет прежний компактный формат:

```text
build(deps): Bump autumn 4.3.10 → 4.3.11, semver 1.0.0 → 1.1.0 and 1 more package
```

Описание содержит сводную таблицу, а подробности по релизам и коммитам свёрнуты:

| Package | From | To | Update | Links |
|---|---:|---:|:---:|---|
| [oint](https://github.com/oscript-library/oint) | `1.0.0` | `2.0.0` | ⚠️ major | [Hub](https://hub.oscript.io/package/oint) · [Repo](https://github.com/oscript-library/oint) |
| [autumn](https://github.com/oscript-library/autumn) | `4.3.10` | `4.3.11` | patch | [Hub](https://hub.oscript.io/package/autumn) · [Repo](https://github.com/oscript-library/autumn) |

<details>
<summary>Release notes</summary>

Показываются release notes версий, попавших в диапазон обновления.

</details>

<details>
<summary>Commits</summary>

Показываются до десяти последних коммитов и ссылка на полный compare view.

</details>

Для каждого пакета Action сначала проверяет `oscript-library/<пакет>`. Если это форк, также рассматриваются
его `parent` и корневой `source`. Приоритет получает активный репозиторий с нужными тегами и сравнением, затем
более свежий по `pushed_at`; `source` используется только при полном равенстве. Поэтому поддерживаемый форк может
остаться источником метаданных, даже если исходный репозиторий заброшен. Поддерживаются теги `1.2.3`, `v1.2.3`
и `ver1.2.3`.

Получение метаданных через GitHub API выполняется в режиме best effort: ошибка API не мешает обновлению
`packagedef` и созданию Pull Request. Release notes ограничиваются 50 строками, список коммитов — 10 записями,
а всё описание — 60 000 символами. Внешний Markdown обезвреживается перед добавлением в Pull Request,
относительные ссылки разрешаются относительно репозитория пакета.
