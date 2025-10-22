# Computational Mathematics — Lua-First Interactive Toolkit

**Computational_Mathematics** — это инструментальная библиотека и набор скриптов для численных методов, реализованных на **Lua**.  
Проект ориентирован на демонстрацию и исследование алгоритмов вычислительной математики — интерполяции, интегрирования, решения нелинейных уравнений, систем и ОДУ.  
Lua-реализация сопровождается Java-модулем для консольных расчётов и построения графиков.

---

## Возможности

### Lua (основной фокус)
- Приближение функций (несколько реализаций);
- Численное интегрирование (трапеций, Симпсона);
- Решение нелинейных уравнений и систем;
- Решение обыкновенных дифференциальных уравнений (ОДУ);
- Визуализация вычислительных процессов через Roblox Runtime (Lua API);
- Возможность переноса в чистый Lua 5.3+.

### Java (дополнительный модуль)
- Методы интерполяции: Лагранж, Ньютон (прямые/обратные разности), Гаусс (вперёд/назад), Стерлинг, Бессель;
- Таблицы конечных разностей, вычисление значения функции в точке;
- Источники данных: консоль, файл, аналитическая функция;
- Встроенное построение графиков и сравнение методов.

---

## Структура проекта

```
Computational_Mathematics/
├── README.md
├── lua_vers/ (roblox_vers)       # Основная реализация на Lua
│   ├── function_approximation.lua
│   ├── function_approximation_2.lua
│   ├── integration_methods.lua
│   ├── linear_system_solver.lua
│   ├── nonlinear_equation.lua
│   ├── nonlinear_system.lua
│   ├── ode_solver.lua
│   └── assets/
│       └── game.rbxl             # Сцена для визуального запуска
└── java_vers/                    # Дополнительная реализация на Java
    └── src/
        ├── Main.java
        ├── io/
        │   ├── ConsoleDataProvider.java
        │   ├── DataProvider.java
        │   ├── DataSet.java
        │   ├── FileDataProvider.java
        │   └── FunctionDataProvider.java
        ├── methods/
        │   ├── LagrangeMethod.java
        │   ├── NewtonForwardMethod.java
        │   ├── NewtonBackwardMethod.java
        │   ├── GaussForwardMethod.java
        │   ├── GaussBackwardMethod.java
        │   ├── StirlingMethod.java
        │   └── BesselMethod.java
        └── plot/
            └── GraphPlotter.java
```

- **Lua** — ядро и визуальные реализации методов (Roblox Runtime API).  
- **Java** — консольный модуль для точных расчётов и визуализации.

---

## Запуск Lua-версии

### В Roblox Runtime
1. Установите Roblox Studio (используется как Lua runtime);
2. Откройте сцену: `lua_vers/assets/game.rbxl`;
3. Запустите Play и активируйте нужный скрипт из набора (`function_approximation.lua`, `integration_methods.lua` и др.).

> Вся вычислительная логика реализована на Lua, Roblox используется только как визуальный движок. Перенос в чистый Lua возможен (для терминальной или графической визуализации).

### Онлайн-доступ
Доступна онлайн на Roblox:
[Перейти к Computational Mathematics на Roblox](https://www.roblox.com/games/16835734822/Computational-Math)

---

## Запуск Java-версии

### Требования
- **JDK 17+** (подходит и 11+);
- Любая ОС с `javac`/`java` в PATH.

### Сборка
```bash
cd java_vers/src
javac $(find . -name "*.java")
```

### Запуск
```bash
cd java_vers/src
java Main
```

Приложение интерактивное: можно выбрать метод, источник данных и точку интерполяции.  
Результаты отображаются в консоли и на графиках.

---

## Используемые технологии

![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![Roblox Studio](https://img.shields.io/badge/Runtime-Roblox_Engine-informational?style=for-the-badge&logo=roblox&logoColor=white)
![Java](https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![JDK](https://img.shields.io/badge/JDK-17%2B-informational?style=for-the-badge)

---

## План развития

- Единый интерфейс запуска Lua-сцен (UI для переключения методов внутри одной сцены);
- Экспорт численных результатов в CSV/PNG;
- Расширение Java-модуля методами сплайновой интерполяции;

---

## Автор

**Садовой Григорий**  
Software Engineer  
[Telegram](https://t.me/e345ee) • [VK](https://vk.com/kobievportfievleze) • [Email](mailto:gsad1030@gmail.com)
