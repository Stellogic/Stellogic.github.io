---
title: "CS61A 学习随笔（二）"
date: 2025-05-09 08:13:30
tags:
  - CS61A
  - Python
  - 递归
  - 迭代
  - 数据结构
  - 编程概念
categories: 学习笔记
toc: true
---

欢迎来到本周的 CS61A 学习笔记！

上周突然感觉学的东西太多容易忘记，于是开始随手把学到的重要东西记下来（或者截屏下来），在周末生成一篇笔记。
<!-- more-->
主要目的是方便我以后回顾，也期待和各位交流。
发现错误可以联系我

本次包括了从递归到容器（container）章节的，当然也有我写作业时发现的一些小问题。 
至于前面几章（也就是随笔一）是否会补上，随缘吧。



## Python 基础拾遗

在深入具体主题之前，先回顾几个 Python 中常见但易混淆的基础点。

### `print()` 输出与交互式解释器返回值

*   **`print()` 输出**：`print()` 函数的作用是显示对象转换成字符串后的内容。对于字符串对象，它通常不带引号，更侧重于“人类可读”的表示。
*   **交互式解释器显示的返回值**：当你在 Python 交互式解释器（REPL）中输入一个表达式并执行后，解释器会显示该表达式的官方字符串表示形式，即调用对象的 `repr()` 方法得到的结果。对于字符串，这通常会带有引号，以明确表示其类型和精确值。

### 赋值与求值顺序

*   **赋值顺序**：Python 中的赋值操作遵循“先右后左”的原则。即先计算赋值符号（`=`）右边的表达式的值，然后将这个值绑定到左边的变量名上。
*   **短路求值 (Short-circuiting)**：对于逻辑运算符 `and` 和 `or`，Python 会进行短路求值。
    *   `A and B`: 如果 `A` 为假，则整个表达式必为假，不会再评估 `B`。
    *   `A or B`: 如果 `A` 为真，则整个表达式必为真，不会再评估 `B`。
    显示的是最后被评估的那个操作数的值。

### 帧 (Frame) 与环境

在新帧 (frame) 中绑定的参数值来源于创建这个帧的那个环境。这一点对于理解闭包 (closures) 等高级概念至关重要。

## 递归 (Recursion)

递归是一种强大的编程技巧，函数通过调用自身来解决问题。

### 递归函数的构成 (The Anatomy of a Recursive Function)

一个典型的递归函数通常包含以下几个部分：

1.  **函数定义头部 (`def`语句)**：与普通函数类似，定义函数名和参数。
2.  **基本情况 (Base Cases)**：
    *   这是递归的终止条件。
    *   条件语句（如 `if`）用于检查是否达到基本情况。
    *   基本情况的求解**不涉及**进一步的递归调用，直接返回一个结果。
3.  **递归情况 (Recursive Cases)**：
    *   如果未达到基本情况，则进入递归情况。
    *   在递归情况中，问题会被分解成一个或多个规模更小但结构相同的子问题。
    *   函数会**调用自身**来解决这些子问题。
    *   通常会将子问题的解组合起来，形成原问题的解。

### 迭代是递归的一种特殊情况 (Iteration is a special case of recursion)

虽然我们通常感觉递归比迭代复杂，但从理论上讲，任何迭代过程都可以用特定形式的递归（通常是尾递归）来表达。

### 递归的信任飞跃 (The Recursive Leap of Faith)

理解和编写递归函数时，“递归的信任飞跃”是一个非常有用的思维模式。其核心思想是：

**相信你的函数能够正确处理规模更小的子问题。**

以阶乘函数 `fact(n)` 为例：
`n! = n * (n-1)!` (当 n > 0)
`0! = 1`

```python
def fact(n):
    if n == 0:  # 基本情况
        return 1
    else:       # 递归情况
        return n * fact(n-1) # 信任 fact(n-1) 能正确计算 (n-1)!
```

验证 `fact` 是否正确实现：

1.  **验证基本情况**：当 `n == 0` 时，`fact(0)` 返回 `1`。这是正确的。
2.  **将 `fact` 视为一个功能抽象**：暂时不关心 `fact` 内部如何工作，只关心它的功能——计算阶乘。
3.  **假设 `fact(n-1)` 是正确的**：这是信任飞跃的核心。我们假设 `fact(n-1)` 能够完美地计算出 `(n-1)!` 的值。
4.  **验证 `fact(n)` 在假设下的正确性**：基于 `fact(n-1)` 返回 `(n-1)!` 的假设，`fact(n)` 返回 `n * fact(n-1)`，即 `n * (n-1)!`，这正是 `n!` 的定义。因此，`fact(n)` 是正确的。

只要基本情况正确，并且递归步骤能正确地将问题规模缩小并最终达到基本情况，那么递归的信任就能得到回报。

### 递归示例：Luhn 算法的部分求和

Luhn 算法常用于验证信用卡号等识别码。以下是其求和部分的一个递归实现（假设 `split(n)` 函数可以将数字 `n` 分为 `all_but_last` 和 `last` 两部分，`sum_digits(k)` 计算数字 `k` 的各位数字之和）：

```python
def luhn_sum(n):
    if n < 10:  # 基本情况
        return n
    else:       # 递归情况
        all_but_last, last = split(n)
        # 信任 luhn_sum_double 能正确处理 all_but_last
        return luhn_sum_double(all_but_last) + last

def luhn_sum_double(n):
    all_but_last, last = split(n)
    luhn_digit = sum_digits(2 * last) # 对末位加倍并求和
    if n < 10:  # 基本情况
        return luhn_digit
    else:       # 递归情况
        # 信任 luhn_sum 能正确处理 all_but_last
        return luhn_sum(all_but_last) + luhn_digit
```

## 递归与迭代的转换

递归和迭代在很多情况下可以相互转换。

### 将递归转换为迭代 (Converting Recursion to Iteration)

这通常需要思考递归调用栈是如何工作的，并尝试用循环和显式的状态变量（或数据结构如栈）来模拟这个过程。关键是识别出递归过程中哪些信息需要被“记住”和“恢复”。

**示例：`sum_digits` (计算数字各位之和)**

递归版本：

```python
def sum_digits_recursive(n):
    """Return the sum of the digits of positive integer n."""
    if n < 10:  # 基本情况
        return n
    else:       # 递归情况
        all_but_last, last = split(n) # 假设 split(n) 将 n 分为 n//10 和 n%10
        # A partial sum (last) + What's left to sum (sum_digits_recursive(all_but_last))
        return sum_digits_recursive(all_but_last) + last
```

迭代版本：

```python
def sum_digits_iterative(n):
    """Return the sum of the digits of positive integer n."""
    digit_sum = 0
    while n > 0:
        digit_sum = digit_sum + (n % 10) # 累加最后一位
        n = n // 10                    # 去掉最后一位
    return digit_sum
```

转换思路：

*   递归中的参数 `n` 和部分和（通过返回值和加法隐式管理）是状态。
*   迭代中使用 `digit_sum` 显式维护累加和，用 `n` 的变化来控制循环。

### 将迭代转换为递归 (Converting Iteration to Recursion)

这通常更为公式化，因为迭代是递归的一种特殊情况（尾递归）。

**核心思想：迭代过程中的状态可以作为参数传递给递归函数。**

**示例：`sum_digits` (迭代转递归)**

迭代版本 (如上 `sum_digits_iterative(n)`)：

```python
# 迭代版本回顾
# def sum_digits_iterative(n):
#     digit_sum = 0 # 状态变量: 当前数字的总和
#     while n > 0:  # 循环条件
#         # 假设 split(n) 返回 n_prefix, last_digit
#         # 或者更常见的做法是:
#         last = n % 10
#         n = n // 10         # 更新状态变量 n
#         digit_sum = digit_sum + last # 更新状态变量 digit_sum
#     return digit_sum
```

递归版本 (`sum_digits_rec`)：

```python
def sum_digits_rec(n, digit_sum_so_far): # 状态 n 和 digit_sum_so_far 作为参数传入
    if n == 0:  # 基本情况：当 n 没有位数了
        return digit_sum_so_far
    else:
        # 假设 split(n) 返回 n_prefix, last_digit
        # 或者更常见的做法是:
        new_n = n // 10
        last = n % 10
        # 递归调用，更新后的状态作为参数传递
        return sum_digits_rec(new_n, digit_sum_so_far + last)

# 初始调用
# sum_digits_rec(original_n, 0)
```

转换的关键步骤和理解：

1.  **识别状态变量**：在迭代版本中，`n` 和 `digit_sum` 是在循环中不断变化的状态。
2.  **将状态变量作为参数**：在递归版本中，这些状态变量成为递归函数的参数。所以 `sum_digits_rec` 有两个参数 `n` 和 `digit_sum_so_far` (对应迭代中的 `digit_sum`)。
3.  **基本情况 (Base Case)**：迭代的循环终止条件 (如 `while n > 0` 的反面是 `n == 0`) 对应递归的基本情况。当 `n == 0` 时，说明所有位数都处理完了，递归结束，返回当前的 `digit_sum_so_far`。
4.  **递归步骤 (Recursive Step)**：迭代循环体中的操作对应递归步骤。
    *   在迭代中，我们取 `last`，更新 `n`，更新 `digit_sum`。
    *   在递归中，我们取 `last`，然后用更新后的 `n` (即 `new_n`) 和更新后的 `digit_sum_so_far` (即 `digit_sum_so_far + last`) 来进行下一次递归调用。

**老师想表达的意思总结：**

通过这两个方向的转换例子，老师想强调：

1.  **等价性**：对于很多问题，递归和迭代是两种等价的解决思路，可以实现相同的功能。
2.  **状态管理**：
    *   迭代通过循环体内的变量赋值来更新和管理状态。
    *   递归通过将状态作为函数参数传递，并在每次递归调用时传入更新后的状态。
3.  **转换思路**：
    *   **递归转迭代**：思考递归调用栈是如何工作的，尝试用循环和显式的栈（或几个变量）来模拟这个过程，关键是识别出递归过程中哪些信息需要被“记住”和“恢复”。
    *   **迭代转递归**：识别出迭代过程中随循环变化的核心状态变量，将这些变量作为递归函数的参数。循环的条件变为递归的终止条件，循环体内的操作变为递归调用时参数的更新。

“迭代是递归的特殊情况”的深层含义：任何一个循环都可以被看作是一个线性的、顺序的递归调用序列，其中每次递归调用的返回地址都是固定的（即回到循环的下一个迭代步骤）。而更广义的递归（比如树形递归）则没有这种严格的线性结构。尾递归因为其递归调用是最后一步，所以它可以被优化掉调用栈的开销，从而在行为上非常接近迭代。

### 递归示例：`swipe(n)` - 先倒序再正序打印数字

问题：编写一个函数 `swipe(n)`，它能先倒序打印数字 `n` 的各位，然后（如果 `n` 是多位数）再正序打印 `n` 的各位。中间的那个数字（如果是奇数位数）或最内层递归处理的数字（如果是偶数位数的基本情况）只打印一次。

例如 `swipe(2837)` 应打印：
```
7
3
8
2
8
3
7
```
`swipe(283)` 应打印：
```
3
8
2
8
3
```

代码结构：
```python
def swipe(n):
    if n < 10:  # 基本情况
        print(n)
    else:       # 递归情况
        print(n % 10)      # 1. 打印最后一位 (倒序部分)
        swipe(n // 10)     # 2. 对剩下的部分执行完整的 swipe 操作 (信任飞跃!)
        print(n % 10)      # 3. 再次打印最后一位 (正序部分)
```

**理解 `swipe(n)` 的执行（以 `swipe(283)` 为例）：**

1.  **调用 `swipe(283)`**:
    *   `n = 283` (不是 `< 10`)
    *   `print(283 % 10)`  => 打印 `3`
    *   **调用 `swipe(283 // 10)` 即 `swipe(28)` (递归的信任飞跃)**
        *   **进入 `swipe(28)`**:
            *   `n = 28` (不是 `< 10`)
            *   `print(28 % 10)` => 打印 `8`
            *   **调用 `swipe(28 // 10)` 即 `swipe(2)` (递归的信任飞跃)**
                *   **进入 `swipe(2)`**:
                    *   `n = 2` (是 `< 10`)
                    *   `print(2)` => 打印 `2`
                    *   `swipe(2)` 执行完毕，返回到 `swipe(28)` 的调用点。
            *   `swipe(28)` 继续执行，`print(28 % 10)` => 打印 `8`
            *   `swipe(28)` 执行完毕，返回到 `swipe(283)` 的调用点。
    *   `swipe(283)` 继续执行，`print(283 % 10)` => 打印 `3`
    *   `swipe(283)` 执行完毕。

输出序列：`3` (来自 swipe(283)) -> `8` (来自 swipe(28)) -> `2` (来自 swipe(2)) -> `8` (来自 swipe(28)) -> `3` (来自 swipe(283))。

**为什么这个“信任”是合理的？**
因为递归最终会达到一个**基本情况** (`n < 10`)，这个基本情况不需要进一步递归就能直接解决。
*   `swipe(283)` 信任 `swipe(28)`
*   `swipe(28)` 信任 `swipe(2)`
*   `swipe(2)` 是基本情况，直接 `print(2)`。
因为 `swipe(2)` 正确工作，所以 `swipe(28)` 对 `swipe(2)` 的信任得到回报。`swipe(28)` 利用 `swipe(2)` 的正确结果（打印 `2`），在它前后各打印一个 `8`，于是 `swipe(28)` 也正确工作了。
同理，因为 `swipe(28)` 正确工作，`swipe(283)` 对 `swipe(28)` 的信任也得到回报，最终 `swipe(283)` 也正确工作。

### 树形递归 (Tree Recursion)

当一个函数在递归过程中进行多次自身调用时，就形成了树形递归。

**示例：`count_partitions(n, m)`**

计算将正整数 `n` 分解成最大部分不超过 `m` 的不同正整数之和的方法数。
例如，`count_partitions(6, 4)` 表示将 6 分解成最大部分不超过 4 的和的方法数。
如 `2+4`, `1+1+4`, `3+3`, `1+2+3`, `1+1+1+3`, `2+2+2`, `1+1+2+2`, `1+1+1+1+2`, `1+1+1+1+1+1`。

递归分解思路：

1.  **使用至少一个 `m`**：如果使用 `m`，则问题转化为对 `n-m` 进行分解，最大部分仍不超过 `m`。即 `count_partitions(n-m, m)`。
2.  **不使用任何 `m`**：如果不用 `m`，则问题转化为对 `n` 进行分解，但最大部分不超过 `m-1`。即 `count_partitions(n, m-1)`。

总方法数 = (使用 `m` 的方法数) + (不使用 `m` 的方法数)。

```python
def count_partitions(n, m):
    if n == 0:      # 基本情况1: n 已被完全分解
        return 1
    elif n < 0:     # 基本情况2: 无效分解 (n 减为负数)
        return 0
    elif m == 0:    # 基本情况3: 没有可用的部分了 (除非 n 也为0，上面已处理)
        return 0
    else:
        # 递归情况:
        with_m = count_partitions(n - m, m)  # 使用当前最大部分 m
        without_m = count_partitions(n, m - 1) # 不使用当前最大部分 m
        return with_m + without_m
```
树形递归通常涉及探索多种不同的选择路径。

## Python 数据结构

### 序列 (Sequences)

列表 (list) 和字符串 (string) 都是 Python 中的序列类型。它们共享一些通用操作。

#### 数据类型的闭包性质 (The Closure Property of Data Types)

一个组合数据值的方法如果满足闭包性质，意味着：
**组合的结果本身也可以用同样的方法进行组合。**

闭包性质非常强大，因为它允许我们创建层次结构。例如，列表可以包含其他列表作为元素，这些子列表本身又可以包含其他列表，以此类推，形成嵌套结构。
`Lists can contain lists as elements (in addition to anything else)`

#### 序列聚合 (Sequence Aggregation)

Python 提供了一些内置函数来对可迭代对象（包括序列）进行聚合操作：

*   `sum(iterable[, start]) -> value`: 返回可迭代对象中所有数字（非字符串）的和，再加上可选的 `start` 值（默认为 0）。如果可迭代对象为空，返回 `start`。
*   `max(iterable[, key=func]) -> value` 或 `max(a, b, c, ... [, key=func]) -> value`: 返回可迭代对象中最大的项，或多个参数中最大的一个。可选的 `key` 函数用于自定义比较。
*   `all(iterable) -> bool`: 如果可迭代对象中所有元素的布尔值为 `True`（或者可迭代对象为空），则返回 `True`。

### 列表 (Lists)

列表是可变的、有序的元素集合。

#### 列表切片创建新值 (Slicing Creates New Values)

对列表进行切片操作会创建一个新的列表，其中包含原始列表中指定范围的元素的副本。

```python
digits = [1, 8, 2, 8]
start = digits[:1]    # start 会是 [1] (一个新列表)
middle = digits[1:3]  # middle 会是 [8, 2] (一个新列表)
end = digits[2:]      # end 会是 [2, 8] (一个新列表)
```
原始列表 `digits` 保持不变。`start`, `middle`, `end` 都是全新的列表对象。

#### 列表索引与拼接

*   **负索引**：从列表末尾开始计数，最右边元素的索引是 `-1`。
    ```python
    nested_list = [1, [True, [3]]]
    print(nested_list[-1]) # 输出: [True, [3]]
    ```
*   **列表相加（拼接）**：使用 `+` 运算符可以将两个或多个列表拼接起来，生成一个包含所有元素的新列表。
    ```python
    list1 = [1, 2]
    list2 = [3]
    list3 = [4, 5]
    combined_list = list1 + list2 + list3
    print(combined_list) # 输出: [1, 2, 3, 4, 5] (这是一个新列表)
    ```

#### 列表推导式 (List Comprehensions)

列表推导式提供了一种简洁的方式来创建列表。它通过描述列表中的元素来生成新的列表。

基本形式：
`[<expression> for <element> in <sequence>]`

带条件的形式：
`[<expression> for <element> in <sequence> if <condition>]`

示例：

```python
letters = ['a', 'b', 'c', 'd', 'e', 'f', 'm', 'n', 'o', 'p']
# 根据索引列表 [3, 4, 6, 8] 从 letters 构建新列表
selected_letters = [letters[i] for i in [3, 4, 6, 8]]
print(selected_letters) # 输出: ['d', 'e', 'm', 'o']

odds = [1, 3, 5, 7, 9]
plus_one_to_odds = [x + 1 for x in odds]
print(plus_one_to_odds) # 输出: [2, 4, 6, 8, 10]

# 从 odds 中选出能被 25 整除的数 (即 25 % x == 0)
divisible_by_25 = [x for x in odds if 25 % x == 0] # 假设原意是 x 是 25 的因子
print(divisible_by_25) # 输出: [1, 5]
```
列表推导式中的 `if <condition>` 部分允许我们只选择序列中满足特定条件的元素来构建新列表。

#### `range` 对象与 `list`

虽然 `range` 和 `list` 都是序列类型，但它们有所不同：
*   `range(n)` 生成一个表示从 0 到 `n-1` 的数字序列的对象，它不直接存储所有数字，而是按需生成，非常节省内存。`range` 包含 `start` 但不含 `end`。
*   `list` 是一个实际存储所有元素的容器。
可以通过 `list()` 函数将 `range` 对象转换成列表：
```python
my_list = list(range(5)) # my_list 会是 [0, 1, 2, 3, 4]
```

### 字符串 (Strings)

字符串是不可变的字符序列。

#### 字符串作为序列

字符串也支持许多序列操作，如长度获取 (`len()`) 和元素选择（索引）：

```python
city = 'Berkeley'
print(len(city))    # 输出: 8
print(city[3])      # 输出: 'k'
```
**注意**：字符串的一个元素本身也是一个字符串，只是长度为1。例如 `city[3]` 的结果 `'k'` 仍然是字符串类型。

#### `in` 和 `not in` 运算符

对于字符串，`in` 和 `not in` 运算符可以用来检查一个子字符串是否存在于另一个字符串中：
```python
print('here' in "Where's Waldo?")  # 输出: True
```
这与列表不同，在列表中 `in` 通常检查单个元素是否存在，而不是子序列。
```python
print(234 in [1, 2, 3, 4, 5])       # 输出: False (234 不是列表中的一个元素)
print([2, 3, 4] in [1, 2, 3, 4, 5]) # 输出: False (列表 [2,3,4] 不是列表中的一个元素)
```
总结：在列表中，你只能逐个元素查找。但在字符串中，你可以查找连续的子串。

### 字典 (Dictionaries)

字典是键值对 (key-value pairs) 的集合，其中键必须是唯一的且不可变的。

#### 字典的基本操作与特性

```python
my_dict = {1: 'item'}
print(my_dict) # 输出: {1: 'item'}

# 值可以是列表
d = {1: ['first', 'second'], 3: 'third'}
print(d[1])    # 输出: ['first', 'second']
print(len(d))  # 输出: 2 (字典中有两个键值对)
```
**如果想将一个键与多个值关联，应该使用一个序列（如列表）作为该键的值。**
例如，若想让键 `1` 关联到 'first' 和 'second'，应该这样做：`{1: ['first', 'second']}` 而不是尝试 `{1: 'first', 1: 'second'}` (后者会导致键 `1` 的值被 'second' 覆盖)。

#### 字典的限制 (Limitations on Dictionaries)

1.  **键的不可变性**：字典的键不能是列表、字典或其他任何可变类型 (mutable type)。这是因为 Python 内部实现字典时，通常需要对键进行哈希计算。
2.  **键的唯一性**：字典中两个键不能相等。一个给定的键最多只能对应一个值。如果赋给已存在键一个新值，旧值会被覆盖。

第一条限制与 Python 字典的底层实现有关。第二条限制是字典这种数据结构抽象的一部分。

#### 字典推导式 (Dictionary Comprehensions)

与列表推导式类似，字典推导式提供了一种简洁的方式来创建字典。

完整形式：
`{<key_expression>: <value_expression> for <name> in <iterable_expression> if <filter_expression>}`

简化形式 (无条件过滤)：
`{<key_expression>: <value_expression> for <name> in <iterable_expression>}`

字典推导式的求值过程：

1.  创建一个新的、以当前帧为父帧的帧。
2.  创建一个空的结果字典，这个空字典将是整个表达式的值。
3.  对于 `<iterable_expression>` 求值结果中的每一个元素：
    A.  将 `<name>` 绑定到当前元素（在步骤1创建的新帧中）。
    B.  如果存在 `<filter_expression>` 并且其求值为真 (True)：
        将由 `<key_expression>` 求值结果作为键，`<value_expression>` 求值结果作为值的键值对，添加到结果字典中。

## 个人思考（来自草稿）

*   “感觉树形递归总和分类相加有关”
    *   这个观察很敏锐！树形递归问题，如 `count_partitions`，通常将问题分解为几个子问题（树的分支），而原问题的解是这些子问题解的某种组合（常常是相加，如计数问题；或取最优，如优化问题）。每个分支代表一种分类或一种选择。

希望这份整理后的笔记对你有所帮助！
```