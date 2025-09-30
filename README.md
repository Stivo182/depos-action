# Depos Action

GitHub Action для обновления зависимостей пакетов OneScript в файле _packagedef_ и автоматического создания Pull Request.

## Использование

```yaml
      - name: Обновление зависимостей
        uses: Stivo182/depos-action@main
```

### Входные параметры

| Параметр | Описание | Значение по умолчанию |
| --- | --- | --- |
| `filter`         | Фильтр пакетов по именам (через запятую или пробел), шаблону (`*`, `?`) или регулярному выражению.   | |
| `target`         | Тип целевой версии: <br>- `latest` - последняя доступная версия пакета.<br>- `minor` - последняя минорная или патч-версия в пределах основной версии.<br>- `patch` - последняя патч-версия в пределах минорной версии. | `latest` |
| `message-prefix` | Префикс для сообщения коммита и заголовка Pull Request. | |

### Пример использования

```yaml
name: Еженедельное обновление зависимостей

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
        uses: Stivo182/depos-action@main
        with:
          filter: autumn-* # Обновлять только пакеты autumn
          target: minor    # До минорных версий
          message-prefix: build(deps) 
```

Пример автоматически созданного Pull Request:

![Pull Request Example](examples/assets/pr-example.png)