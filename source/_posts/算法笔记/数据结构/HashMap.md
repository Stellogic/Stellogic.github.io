---
title: HashMap
date: 2025-09-15 09:19:35
categories:
  - 数据结构
tags:
  - 数据结构
  - 学习笔记
---


# 哈希表核心知识点与 Java 实现

## 1. 定义与核心原理

**哈希表 (Hash Table)**，又称散列表，是一种通过**哈希函数 (Hash Function)** 将键 (Key) 映射到数组索引，从而实现高效键值 (Key-Value) 存储与访问的数据结构。

<!-- more -->


*   **核心目标**: 实现平均时间复杂度为 **O(1)** 的插入、删除、查找操作。
*   **基本组件**:
    1.  **键值对 (Pair)**: 数据存储的基本单元。
    2.  **桶数组 (Bucket Array)**: 哈希表底层的数组，用于存放数据。
    3.  **哈希函数 (Hash Function)**: 负责将 Key 转换为桶数组的索引。

## 2. 关键组件一：哈希函数

哈希函数是哈希表的基石，其质量直接影响哈希表的性能。

### 2.1. 必备特性
*   **确定性**: 相同的 Key 输入必须产生相同的索引输出。
*   **高效性**: 函数计算速度必须快。
*   **均匀性**: 必须能将不同的 Key 尽可能均匀地分布到桶数组的各个位置，以最小化**哈希冲突**。

### 2.2. Java 中的 `hashCode()` 与 `equals()`
在 Java 中，`HashMap` 等数据结构依赖对象的 `hashCode()` 方法来计算哈希值。为保证正确性，必须遵守以下契约：
*   **`equals()` 相等的两个对象，其 `hashCode()` 必须相等。**
*   `hashCode()` 相等的两个对象，其 `equals()` 不一定相等（这正是哈希冲突）。
*   如果重写了 `equals()` 方法，就必须重写 `hashCode()` 方法以维护此契约。

## 3. 关键组件二：哈希冲突解决方案

**哈希冲突**: 两个不同的 Key 经过哈希函数计算后得到了相同的数组索引。冲突是必然的，解决冲突的策略是哈希表设计的核心。

### 3.1. 方案 A: 链式地址法 (Separate Chaining)

*   **机制**: 桶数组的每个位置不直接存储元素，而是存储一个数据集合（如链表、动态数组）的引用。所有哈希到同一索引的键值对，都被添加到该位置的集合中。

*   **操作流程**:
    *   **插入 (`put`)**: 计算索引，定位到桶。遍历桶内集合：若 Key 已存在，则更新 Value；若不存在，则将新键值对添加到集合末尾。
    *   **查找 (`get`)**: 计算索引，定位到桶。遍历桶内集合，查找匹配的 Key 并返回其 Value。
    *   **删除 (`remove`)**: 计算索引，定位到桶。遍历桶内集合，找到并移除匹配的键值对。

*   **重要优化：红黑树化 (Treeifying)**
    *   **问题**: 当大量 Key 哈希到同一个桶时，链表会变得很长，查询效率从 O(1) 退化到 O(N)。
    *   **解决方案**: 在 Java 8 及以后的 `HashMap` 中，当一个桶内的链表长度超过阈值（默认为 8）且哈希表总容量大于 64 时，该链表会转换为一棵**红黑树**。
    *   **效果**: 将该桶的最坏查询时间复杂度从 O(N) 优化到 **O(logN)**。

*   **链式地址法总结**:
    *   **优点**: 实现逻辑清晰，删除操作简单直接，负载因子理论上可以大于1。
    *   **缺点**: 存在额外的数据结构开销（如链表节点的指针），对 CPU 缓存不友好。

### 3.2. 方案 B: 开放寻址法 (Open Addressing)

*   **机制**: 所有元素都直接存储在桶数组中。当发生冲突时，通过一个**探测序列**在数组中寻找下一个可用的空槽位。

*   **核心：懒删除 (Lazy Deletion) 与 `TOMBSTONE`**
    *   **问题**: 直接删除元素（置为 `null`）会中断探测链，导致后续本应能找到的元素查找失败。
    *   **解决方案**: 删除时，不将槽位置为 `null`，而是放置一个特殊的**墓碑对象 (`TOMBSTONE`)**。
    *   **`TOMBSTONE` 的作用**:
        *   对于**查找**操作：遇到墓碑，表示探测应继续进行。
        *   对于**插入**操作：墓碑所在的位置被视为可用槽位，可以直接插入新元素。

*   **探测方法**:
    1.  **线性探测 (Linear Probing)**: 依次探测 `index+1`, `index+2`, ...。实现简单，但易产生**聚集 (Clustering)** 现象，即连续的槽位被占据，降低性能。
    2.  **二次探测 (Quadratic Probing)**: 依次探测 `index+1²`, `index+2²`, ...。可缓解主聚集。
    3.  **双重哈希 (Double Hashing)**: 使用第二个哈希函数计算探测的步长。`index = (hash1(key) + i * hash2(key)) % capacity`。能有效避免各类聚集，是性能较好的探测方法。

*   **开放寻址法总结**:
    *   **优点**: 无额外数据结构开销，空间利用率高，数据连续存储对 CPU 缓存友好。
    *   **缺点**: 实现相对复杂，删除操作需要懒删除机制，负载因子必须严格小于1，对哈希函数的均匀性要求更高。

## 4. 关键组件三：负载因子与扩容机制

*   **负载因子 (Load Factor)**:
    *   **定义**: `负载因子 = 已存元素数量 / 桶数组总容量`。
    *   **作用**: 衡量哈希表的填充程度，是决定是否需要扩容的关键指标。Java `HashMap` 默认为 `0.75`。

*   **扩容 (Rehashing)**:
    *   **触发条件**: 当负载因子超过设定的阈值时。
    *   **目的**: 降低负载因子，减少哈希冲突，维持 O(1) 的平均性能。
    *   **过程 (时间复杂度 O(N))**:
        1.  创建一个容量通常为原来2倍的新桶数组。
        2.  遍历**旧桶数组**中的**每一个元素**。
        3.  **重新计算**每个元素在新容量下的哈希索引 (`key % new_capacity`)。
        4.  将元素放入新桶数组的对应位置。
        5.  用新桶数组替换旧桶数组。
    *   **注意**: 扩容是一个高成本操作，因为它需要重新处理所有现有元素。

## 5. 两种方案对比总结

| 特性 | 链式地址法 (Separate Chaining) | 开放寻址法 (Open Addressing) |
| :--- | :--- | :--- |
| **空间使用** | 存在额外指针/节点开销 | 空间利用率高，无额外开销 |
| **负载因子** | 可大于 1 | 必须小于 1 |
| **删除操作** | 简单，直接移除节点 | 复杂，需要 `TOMBSTONE` 标记 |
| **缓存效率** | 较低（内存不连续） | 较高（内存连续） |
| **主要问题** | 链表过长导致性能退化 | 元素聚集导致性能退化 |
| **常见场景** | 通用哈希表实现 (如 Java `HashMap`) | 对内存占用敏感的特定场景 |

---


## 6. 完整代码实现

### 实现 1：HashMapChaining.java (链式地址法)

```java
import java.util.ArrayList;
import java.util.List;

// 辅助类：键值对
class Pair {
    public int key;
    public String val;

    public Pair(int key, String val) {
        this.key = key;
        this.val = val;
    }
}

public class HashMapChaining {
    /*
    实现哈希表，链式地址
    实现构造，hashFunc,loadFactor,get,put,remove,extend,print方法。
     */
    int size;
    int capacity;
    double lodaThres;
    int extendRatio;
    List<List<Pair>> buckets;

    public HashMapChaining() {
        size = 0;
        capacity = 4;
        lodaThres = 2.0 / 3.0;
        extendRatio = 2;
        buckets = new ArrayList<>(capacity);
        for (int i = 0; i < capacity; i++) {
            buckets.add(new ArrayList<>());
        }
    }

    int hashFunc(int key) {
        return key % capacity;
    }

    double loadFactor() {
        return (double) size / capacity;
    }

    String get(int key) {
        int index = hashFunc(key);
        List<Pair> bucket = buckets.get(index);
        for (Pair pair : bucket) {
            if (pair.key == key) {
                return pair.val;
            }
        }
        return null;
    }

    void put(int key, String val) {
        if (loadFactor() > lodaThres) {
            extend();
        }
        int index = hashFunc(key);
        List<Pair> bucket = buckets.get(index);
        for (Pair pair : bucket) {
            if (pair.key == key) {
                pair.val = val;
                return;
            }
        }
        Pair pair = new Pair(key, val);
        bucket.add(pair);
        size++;
    }

    void remove(int key) {
        int index = hashFunc((key));
        List<Pair> bucket = buckets.get(index);
        for (Pair pair : bucket) {
            if (pair.key == key) {
                bucket.remove(pair);
                size--;
                break;
            }
        }
    }

    void extend() {
        List<List<Pair>> bucketsTemp = buckets;
        capacity *= extendRatio;
        buckets = new ArrayList<>(capacity);
        for (int i = 0; i < capacity; i++) {
            buckets.add(new ArrayList<>());
        }
        size = 0; // 重置size，因为put操作会重新增加它
        for (List<Pair> bucket : bucketsTemp) {
            for (Pair pair : bucket) {
                put(pair.key, pair.val);
            }
        }
    }

    void print() {
        for (List<Pair> bucket : buckets) {
            List<String> res = new ArrayList<>();
            for (Pair pair : bucket) {
                res.add(pair.key + "->" + pair.val);
            }
            System.out.println(res);
        }
    }
}
```

### 实现 2：HashMapOpenAddressing.java (开放寻址法)

```java
// Pair 类复用上面的定义

public class HashMapOpenAddressing {
    /*
    包含懒删除的开放寻址（线性探测）的哈希表。
    实现构造，hashFunc ,loadFactor,findBucket,get,put,remove,extend,print
     */
    private int size;
    private int capacity = 4;
    private final double loadThres = 2.0 / 3.0;
    private final int extendRatio = 2;
    private Pair[] buckets;
    private final Pair TOMBSTONE = new Pair(-1, "-1"); // 墓碑标记

    public HashMapOpenAddressing() {
        size = 0;
        buckets = new Pair[capacity];
    }

    private int hashFunc(int key) {
        return key % capacity;
    }

    private double loadFactor() {
        return (double) size / capacity;
    }

    private int findBucket(int key) {
        int index = hashFunc(key);
        int firstTombstone = -1;
        // 循环探测
        while (buckets[index] != null) {
            // 如果找到匹配的key，直接返回
            if (buckets[index].key == key) {
                // 如果之前遇到了墓碑，做交换优化，让元素更靠近初始位置
                if (firstTombstone != -1) {
                    buckets[firstTombstone] = buckets[index];
                    buckets[index] = TOMBSTONE;
                    return firstTombstone;
                }
                return index; // 直接返回当前位置
            }
            // 记录遇到的第一个墓碑
            if (firstTombstone == -1 && buckets[index] == TOMBSTONE) {
                firstTombstone = index;
            }
            // 线性探测，移动到下一个位置
            index = (index + 1) % capacity;
        }
        // 循环结束，表示未找到key。
        // 如果曾遇到墓碑，返回第一个墓碑的位置（用于插入）；否则返回null的位置。
        return firstTombstone == -1 ? index : firstTombstone;
    }

    public String get(int key) {
        int index = findBucket(key);
        // 如果找到的位置不为null且不是墓碑，说明找到了
        if (buckets[index] != null && buckets[index] != TOMBSTONE) {
            return buckets[index].val;
        }
        return null;
    }

    public void put(int key, String val) {
        if (loadFactor() > loadThres) {
            extend();
        }
        int index = findBucket(key);
        // 如果该位置已有元素（不是null或墓碑），说明是更新操作
        if (buckets[index] != null && buckets[index] != TOMBSTONE) {
            buckets[index].val = val;
            return;
        }
        // 否则是插入新元素
        buckets[index] = new Pair(key, val);
        size++;
    }

    public void remove(int key) {
        int index = findBucket(key);
        // 确保该位置有元素再删除
        if (buckets[index] != null && buckets[index] != TOMBSTONE) {
            buckets[index] = TOMBSTONE;
            size--;
        }
    }

    private void extend() {
        Pair[] bucketsTemp = buckets;
        capacity *= extendRatio;
        buckets = new Pair[capacity];
        size = 0; // 重置size，因为put会重新计算
        // 遍历旧数组，将非null且非墓碑的元素重新插入
        for (Pair pair : bucketsTemp) {
            if (pair != null && pair != TOMBSTONE) {
                put(pair.key, pair.val);
            }
        }
    }

    public void print() {
        for (Pair pair : buckets) {
            if (pair == null) {
                System.out.println("null");
            } else if (pair == TOMBSTONE) {
                System.out.println("TOMBSTONE");
            } else {
                System.out.println(pair.key + "->" + pair.val);
            }
        }
    }
}
```