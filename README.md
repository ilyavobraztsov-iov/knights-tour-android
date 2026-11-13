# Ход Конём! — Android (WebView)

Нативное Android-приложение: вся игра лежит внутри APK как
`app/src/main/assets/index.html` (один файл, 1.1 МБ, все звуки и картинки
встроены в base64).

## Чем отличается от сборки через PWABuilder

| | PWABuilder (TWA) | этот проект |
|---|---|---|
| Где лежит игра | на GitHub Pages | внутри APK |
| Нужен интернет при 1-м запуске | да | **нет** |
| Адресная строка | появляется, пока не пройдёт проверка домена | **не бывает никогда** |
| `assetlinks.json` / Digital Asset Links | обязателен | **не нужен** |
| Разрешение INTERNET | нужно | **не запрашивается** |

Приложение физически не умеет обращаться в сеть: в `AndroidManifest.xml`
нет `android.permission.INTERNET`, а любая навигация за пределы
`file:///android_asset/` отклоняется в `MainActivity`.

## Сборка

Проект собирается на GitHub Actions — Android Studio и SDK на компьютере
не нужны. Полный порядок действий, включая создание ключа подписи и
заполнение карточки магазина, описан в **[RUSTORE.md](RUSTORE.md)**.

Коротко: создайте ключ через `tools/make-keystore.sh`, положите четыре
секрета в репозиторий, залейте проект — вкладка **Actions** соберёт
`app-release.aab` для RuStore и `app-release.apk` для проверки на телефоне.

Сборка без ключа намеренно падает: неподписанный артефакт магазин всё
равно отклонит.

## Как собрать локально

Нужен Android Studio или Android SDK:

```
gradle :app:assembleRelease
```

APK появится в `app/build/outputs/apk/release/`.

## Версия приложения

Задаётся в `app/build.gradle`:

```
versionCode 1
versionName "1.0.0"
```

`versionCode` нужно увеличивать при каждой новой сборке, которую вы
ставите поверх предыдущей.
