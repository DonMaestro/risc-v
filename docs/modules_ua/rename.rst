Rename
======

Етап перейменування являється етапом оптимізації.
Одно поточна програма не дає можливості для виконання декількох
інструкцій одночасно.

Розглянемо фрагмент коду:

.. image:: ../img/rename_example.png
   :width: 800
   :align: center

На рисунку стрілочками позначено залежні регістри між інструкціями.
Програма проводить операції та записує результати в один регістр.
Тому дана програма виконується в один потік та виконання займає шість тактів.
І для прискорення виконання програми потребується збільшення тактової частоти.

В даному прикладі можливе прискорення виконання програми.
Розглянемо той самий приклад, але проведемо деякі маніпуляції.
Для кожного регістра призначення(rd) задамо віртуальний регістр
з таблиці freelist.
Бо цей регістр призначення являється залежністю для наступних інструкцій
то потрібно провести заміну для коректного виконання.

Так, наприклад інструкцій записує значення в регістр a2, тому для другої
інструкції(addi) відбувається заміна залежного регістра a5 на a2.
Регістр призначення для другої інструкції призначається новий віртуальний
адрес a3. Який своєю чергою являється залежним регістром для третьої
інструкції(sw) і т.д. Всі залежності прибрати не можна.
Результат наведений праворуч від оригінала.

Дану програму можна виконувати у два потоки та виконання займає вже три такти:

1. Зчитування даних з пам'яті в регістр a2 та a4;
2. Додавання записуючи результат в регістри a3 та a5 відповідно;
3. Запис результату в пам'ять з регістрів a3 та a5.

Дану оптимізацію можна виконати двома методами:

- програмний;
- фізичний.

Дану оптимізацію можна виконати на етапі компіляції.
Але за допомогою даного методу не можна розширити адресу.
Якщо для регістра в інструкції виділено ширину в 5 біт.
То регістровий файл має розмір в 32 комірки.
Тому одночасно можна тримати 31 перейменований регістр,
оскільки регістр за нульовою адресою завжди зберігає нуль
і перейменування не можливе.
Це накладає обмеження на розмір і кількість черг що своєю чергою
задає максимальну можливу кількість паралельного виконання інструкцій.
Збільшую розмір буфера зменшується кількість простоїв, бо збільшується
ймовірність знаходження в черзі інструкцій готових до виконання.
Тому збільшуючи розмір і кількість черг теоретично збільшує швидкість
виконання програми. Тому потрібно мати потрібну кількість віртуальних адрес.

Звісно не можна розв'язати всі залежності між інструкціями.
Тому залишається сама гіршай ситуація в якій кожна наступна
інструкція залежить від попередньої.

Проводить перейменовування в кристалі являється краще.
Бо дає змогу підбирати розмір максимальної кількості перейменованих
регістрів в залежності від розміру черг і кількості модулів виконання.
Разом з тим суттєво збільшує ресурсні затрати.

.. image:: ../img/rename.png
   :width: 800
   :align: center

Даний модуль відпрацьовує:

1. відповідність між фізичним регістром і віртуальним регістром;
2. Порівняння залежних регістрів з минулими регістрами призначення;
3. Перевірка на нульовий регістр;
4. Зміна віртуальної адреси за адресою фізичного регістра.

В RISC-V архітектурі регістр за нульовою адресує завжди містить нуль.
Необхідність в перейменовуванні його нема.

В модуль потрапляє одночасно чотири інструкції.
Тому потрібно залежні регістри перевірити з регістрами призначення попередніх
інструкцій.
Оскільки кожна наступна інструкція може залежати від попередніх інструкцій.

Також модуль повинен коректно визначати попередню віртуальну адресу
для кожного регістра призначення в пакета. Які відправляться в ROB для стадії
commit.
