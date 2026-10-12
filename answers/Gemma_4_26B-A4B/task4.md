## Задача 4

Привет! Как твой помощник, я разложил этот фрагмент «по полочкам». В научной среде такие описания стандартны, но за ними стоят вполне конкретные логические шаги.

Вот подробный разбор:

### 1. Какие данные анализируются?
Анализируется **время выполнения задания** (непрерывная величина). 
У исследователей есть две группы участников:
*   **Экспериментальная группа** ($n = 24$ человека) — те, на кого воздействовали (например, дали новый инструмент или метод).
*   **Контрольная группа** ($n = 22$ человека) — «базовая» группа для сравнения.

### 2. Какой статистический критерий выбран и почему?
Выбран **U-критерий Манна — Уитни**.

**Почему именно он?**
В статистике есть два типа тестов: *параметрические* (например, t-критерий Стьюдента) и *непараметрические* (как Манн — Уитни). 
*   Параметрические тесты требуют, чтобы данные были распределены «нормально» (в форме колокола, где большинство значений в центре).
*   Авторы проверили это с помощью **критерия Шапиро — Уилка**. Результат $p < 0,05$ означает, что гипотеза о нормальности отклоняется: данные распределены «криво» (например, есть резкие выбросы или скошенность).
*   **Вывод:** Раз данные не «нормальные», использовать обычный t-критерий нельзя (это даст ошибку), поэтому они выбрали Манна — Уитни, который работает не с самими значениями, а с их **рангами** (порядковыми номерами).

### 3. Что означают величина эффекта и поправка на множественные сравнения?

*   **Величина эффекта (Rank-biserial correlation):** 
    Статистическая значимость ($p < 0,05$) говорит нам только о том, что разница между группами, скорее всего, *не случайна*. Но она не говорит, *насколько она велика*. 
    *Пример:* Разница в 0,1 секунды может быть статистически значимой на огромной выборке, но на практике она бесполезна. 
    **Величина эффекта** (в данном случае рангово-бисериальный коэффициент) показывает «мощность» этого различия: насколько сильно принадлежность к группе влияет на результат.

*   **Поправка на множественные сравнения (Holm–Bonferroni):**
    Если вы проверяете только один показатель, риск совершить ошибку «ложноположительного результата» (найти разницу там, где её нет) составляет 5%. Но если вы начнете проверять 10 разных показателей подряд, этот риск суммируется и растет. Это называется «проблемой множественных сравнений».
    **Поправка Холма — Бонферрони** — это математический способ «ужесточить» требования к значимости для каждого последующего теста, чтобы общая вероятность ошибки осталась на уровне 0,05. Это делает выводы исследования более надежными.

### 4. Какие ограничения есть у такого подхода?
1.  **Потеря информации:** Поскольку критерий Манна — Уитни переводит точное время (например, 12.45 сек и 12.46 сек) в ранги (1-е место и 2-е место), мы теряем информацию о точных значениях и их интервалах.
2.  **Меньшая мощность:** Если бы данные *были* распределены нормально, этот тест был бы менее «чувствительным», чем t-критерий (он мог бы не заметить реальную разницу, которую заметил бы t-тест).
3.  **Сложность интерпретации:** Величина эффекта через ранговую корреляцию менее интуитивна для читателя, чем, например, разница в средних значениях (на сколько секунд в среднем быстрее стала работать группа).

---

### 5. Можно ли применить такой же подход для сравнения двух моделей машинного обучения?

**Да, можно, и это будет грамотно.**

Если у тебя есть 30 запусков (runs) для Модели А и 30 для Модели Б, и ты сравниваешь их точность (accuracy):

1.  **Проверка на нормальность:** Сначала примени критерий Шапиро — Уилка к результатам точности обеих моделей. 
    *   Если точность распределена нормально $\rightarrow$ используй **t-критерий Стьюдента**.
    *   Если точность распределена ненормально (например, много результатов очень близких к 1.0, что дает «скошенное» распределение) $\rightarrow$ используй **U-критерий Манна — Уитни**.
2.  **Величина эффекта:** Обязательно посчитай её (например, $d$ Коэна для t-теста или ту же корреляцию для Манна — Уитни). В ML важно знать не только «стала ли модель лучше», но и «насколько существенно этот прирост».
3.  **Множественные сравнения:** Если ты сравниваешь модели не только по *Accuracy*, но еще и по *F1-score*, *Precision* и *Recall* одновременно — **обязательно** используй поправку (Бонферрони или Холма), иначе ты рискуешь заявить о превосходстве модели там, где это просто статистический шум.

**Совет:** Для 30 запусков (это уже неплохая выборка) часто используют **парный** критерий Манна — Уитни (Wilcoxon signed-rank test), если эти 30 запусков проводились на одних и тех же наборах данных (seeds/folds). Это гораздо мощнее, чем сравнивать две независимые группы.

<details><summary>Рассуждение модели</summary>


*   *Context:* A fragment from a "Methods" section of a scientific paper.
*   *Task:* Explain in simple language:
    1.  What data is being analyzed?
    2.  Which statistical test was chosen and why?
    3.  What do "effect size" and "multiple comparisons correction" mean?
    4.  What are the limitations of this approach?
    5.  Can this approach be applied to compare two ML models' accuracy over 30 runs?
*   *Role:* Assistant to a Master's student.
*   *Language:* Russian.

    *   *Data:* Time taken to complete a task (experimental group $n=24$, control group $n=22$).
    *   *Test:* Mann-Whitney U-test.
    *   *Reasoning:* Shapiro-Wilk test showed non-normal distribution ($p < 0.05$).
    *   *Significance level ($\alpha$):* 0.05.
    *   *Effect size:* Rank-biserial correlation coefficient.
    *   *Multiple comparisons correction:* Holm-Bonferroni correction (used for 3 additional indicators).

    *   **Q1: What data is being analyzed?**
        *   *Simple explanation:* The researchers are comparing how long it takes people (or subjects) to do a task. They have two groups: one that got a special treatment (experimental) and one that didn't (control). They are looking at the *time* spent.

    *   **Q2: Which test and why?**
        *   *The test:* Mann-Whitney U-test.
        *   *The "Why":* Most standard tests (like the t-test) assume data follows a "bell curve" (normal distribution). The authors checked this using the Shapiro-Wilk test. Since the test said "no, this isn't a bell curve" ($p < 0.05$), they had to use a "non-parametric" test. Mann-Whitney doesn't care about the shape of the distribution; it works with ranks (order) rather than raw values.

    *   **Q3: Effect size and Multiple comparisons correction?**
        *   *Effect size (Rank-biserial correlation):* Statistical significance ($p < 0.05$) only tells you *if* there is a difference, not how *big* it is. Effect size tells you the strength of the difference. For example, a difference might be "statistically significant" but so tiny it doesn't matter in real life. This coefficient quantifies that "magnitude."
        *   *Multiple comparisons (Holm-Bonferroni):* If you test one thing, the chance of a "false positive" (Type I error) is 5%. If you test 10 things, the chance of finding *at least one* false positive increases significantly. It's like "fishing" for results. The Holm-Bonferroni correction makes the threshold for significance stricter for each additional test to keep the overall error rate at 0.05.

    *   **Q4: Limitations?**
        *   *Loss of information:* Non-parametric tests use ranks, not actual values. You lose the nuance of the exact numbers.
        *   *Power:* If the data *were* actually normal, the Mann-Whitney test is slightly less "powerful" (less likely to find a real difference) than a t-test.
        *   *Complexity of interpretation:* Rank-biserial correlation is less intuitive than, say, a difference in means.

    *   **Q5: Application to ML models (30 runs)?**
        *   *Scenario:* Model A vs. Model B, 30 runs each, comparing accuracy.
        *   *Analysis:*
            *   Can we use Mann-Whitney? Yes, if the accuracy scores aren't normally distributed.
            *   Is it appropriate? Yes, it's a common way to compare models when you don't want to assume normality.
            *   *Nuance:* With $n=30$, the Central Limit Theorem starts to kick in, so a t-test *might* be okay, but Mann-Whitney is "safer" if the distribution is weird (e.g., many models hitting 99% or 10%).
            *   *Important addition:* Mention that for ML, we often care about the *distribution* of errors or use paired tests if the runs are on the same data splits.

    *   Use clear headings.
    *   Avoid overly dense jargon where possible, or explain it immediately.
    *   Maintain a helpful, academic-yet-accessible tone.
</details>
