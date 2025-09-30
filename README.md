# Depos Action

GitHub Action для обновления версий зависимостей пакетов OneScript в файле _packagedef_ и автоматизации Pull Request’ов.

## 📦 Action: `upgrade`

### Описание

Action выполняет команду [`depos upgrade`](https://github.com/Stivo182/depos?tab=readme-ov-file#upgrade), которая обновляет зависимости в файле _packagedef_ до целевых версий.

### Входные параметры

| Параметр | Описание | Значение по умолчанию |
| --- | --- | --- |
| `packagedef` | Путь к файлу `packagedef` или его каталогу. | Текущая директория |
| `filter`     | Фильтр пакетов по именам (через запятую или пробел), шаблону (`*`, `?`) или регулярному выражению. | |
| `target`     | Тип целевой версии: <br>- `latest` - последняя доступная версия пакета.<br>- `minor` - последняя минорная или патч-версия в пределах основной версии.<br>- `patch` - последняя патч-версия в пределах минорной версии. | `latest` |
| `output`     | Путь для сохранения JSON-отчёта об обновлениях. | |

### Пример использования

```yaml
name: Обновление зависимостей

jobs:
  deps-upgrade:
    runs-on: ubuntu-latest
    steps:
      - name: Актуализация
        uses: actions/checkout@v5.0.0

      - name: Установка OneScript
        uses: otymko/setup-onescript@v1.5.1
        with:
          version: stable

      - name: Обновление зависимостей в packagedef
        uses: Stivo182/depos-action/upgrade@main
        with:
          filter: autumn-* # Обновлять только пакеты autumn
          target: minor    # До минорных версий
          output: report.json

        # 1. Обновлен файл packagedef
        # 2. Создан файл report.json с обновленными пакетами

        # ...
```

## 🤖 Workflow: `upgrade-pr`

### Описание

Workflow запускает обновление зависимостей и автоматически создаёт Pull Request с изменениями.

### Входные параметры

| Параметр | Описание | Значение по умолчанию |
| --- | --- | --- |
| `filter`         | Фильтр пакетов по именам (через запятую или пробел), шаблону (`*`, `?`) или регулярному выражению.   | |
| `target`         | Тип целевой версии: <br>- `latest` - последняя доступная версия пакета.<br>- `minor` - последняя минорная или патч-версия в пределах основной версии.<br>- `patch` - последняя патч-версия в пределах минорной версии. | `latest` |
| `message-prefix` | Префикс для сообщения коммита и заголовка PR. | |

### Пример использования

```yaml
name: Еженедельное обновление зависимостей

on:
  schedule:
    - cron: '0 0 * * 1' # Каждый понедельник

permissions:
  contents: write
  pull-requests: write

jobs:
  depos-upgrade-pr:
    uses: Stivo182/depos-action/.github/workflows/upgrade-pr.yml@main
    with:
      filter: autumn-* # Обновлять только пакеты autumn
      target: minor    # До минорных версий
      message-prefix: build(deps)
```

Пример Pull Request, автоматически созданного через workflow `upgrade-pr`

![Pull Request Example](examples/assets/pr-example.png)