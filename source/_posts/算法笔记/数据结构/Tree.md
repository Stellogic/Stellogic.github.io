---
title: Tree
date: 2025-09-15 09:19:35
categories:
  - 数据结构
tags:
  - 数据结构
  - 学习笔记
---

# 二叉树
## 遍历
### 层序遍历（广度优先，bfs）
广度优先，和队列的“先进先出”类似。因此考虑使用队列

<!-- more -->


```java
import javax.swing.tree.TreeNode;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

List<Integer> levelOrder(TreeNode root) {
    //初始化一个队列,作为遍历过程中的临时储存。
    Queue<TreeNode> queue = new LinkedList<>();
    queue.add(root);
    //初始化一个列表储存结果
    List<Integer> result = new ArrayList<>();
    while (!queue.isEmpty())
    {
        TreeNode node = queue.poll();//出队
        result.add(node.val);
        if(node.left != null){
            queue.offer(node.left);
        }
        if(node.right != null)
        {
            queue.offer(node.right);
        }
    }
    return result;
}
```
时间复杂度：O(N).要访问所有节点<br>
空间复杂度：O(N).队列和result占用空间
### 深度优先（前序，中序，后序）
前序：当前节点->左子树->右子树<br>
中序：左子树->当前节点->右子树<br>
后序：左子树->右子树->当前节点

```java
import javax.swing.tree.TreeNode;
import java.util.LinkedList;
import java.util.List;

List<Integer> list = new LinkedList<>();

void preOrder(TreeNode cur) {
    if (cur == null) {
        return;
    }
    list.add(cur.val);
    preOrder(cur.left);
    preOrder(cur.right);

}

void inOrder(TreeNode cur){
    if(cur == null)
    {
        return;
    }
    inOrder(cur.left);
    list.add(cur.val);
    inOrder(cur.right);
}

void postOrder(TreeNode cur){
    if(cur == null)
    {
        return;
    }
    postOrder(cur.left);
    postOrder(cur.right);
    list.add(cur.val);
}
```
时间复杂度：都是O(N)，因为要遍历所有节点<br>
空间复杂度: O(N)。list储存结果是O（N）；栈帧应该是O(logN),因为每次要按深度递到叶节点后再归，理想状态平衡的话应当是O（logN），如果退化成链表就是O(N)

## 数组表示

```java
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;

class ArrayBinaryTree {
    private List<Integer> tree;

    public ArrayBinaryTree(List<Integer> arr) {
        tree = new ArrayList<>(arr);
    }
    public int size(){
        return tree.size();
    }
    public Integer val(int i ){
        if(i<0 || i>= size())
        {
            return null;
        }
        return tree.get(i);
    }
    public Integer left(int i)
    {
        return 2 * i + 1;
    } 
    public Integer right(int i)
    {
        return 2*i+2;
    }
    public Integer parent(int i){
        return (i - 1) / 2;
    }
    public List<Integer> levelOrder(){
        List<Integer> res = new ArrayList<>();
        for(int i =0;i < size();i++)
        {
            if(val(i) != null)
            {
                res.add(val(i));
            }
        }
        return res;
    }
    private void dfs(Integer i, String order, List<Integer> res) {
        if (i >= size() || val(i) == null) { // 索引越界或节点为空
            return;
        }
        if ("pre".equals(order)) {
            res.add(val(i));
            dfs(left(i), order, res);
            dfs(right(i), order, res);
        } else if ("in".equals(order)) {
            dfs(left(i), order, res);
            res.add(val(i));
            dfs(right(i), order, res);
        } else if ("post".equals(order)) {
            dfs(left(i), order, res);
            dfs(right(i), order, res);
            res.add(val(i));
        }
    }
}
```

## 二叉搜索树
左子树<根节点<右子树，任意子树也满足
### 查找节点

```java
import javax.swing.tree.TreeNode;

TreeNode search(int num){
    TreeNode cur = root;
    while (cur != null)
    {
        if(cur.val < num)
        {
            cur = cur.right;
        } else if (cur.val > num) {
            cur = cur.left;
        }
        else{
            break;
        }
    }
    return cur;
}
```
类似二分查找，时间复杂度是O(logN)(在二叉树平衡时）, 空间复杂度O(1)

### 插入节点
一般直接插在合适的末端，作为新的叶节点，这样更方便
先查找再插入
```java
import javax.swing.tree.TreeNode;

void insert(int num) {
    if (root == null) {
        root = new TreeNode(num);
        return;
    }
    TreeNode cur = root,pre = null;
    while (cur != null)
    {
        if(cur.val == num )
        {
            return;
        }
        pre = cur;
        if(cur.val < num)
        {
            cur = cur.right;
        }
        else{
            cur = cur.left;
        }
    }
    TreeNode node = new TreeNode(num);
    if(pre.val < num)
    {
        pre.right = node;
    }
    else {
        pre.left = node;
    }
}
```
时间复杂度平衡时也是O（logN).
### 删除节点
需分情况，要删的节点的度是0，1，2
其中度为二时为了保证满足二叉搜索树。需要用一个节点替换被删除的节点，可以是右子树最小节点或者左子树最大节点。这里我们使用右子树最小节点（也就是中序遍历的下一个节点，左子树->当前节点->右子树）
```java
import javax.swing.tree.TreeNode;
TreeNode root;
void remove(int num) {
    if (root == null) {
        return;
    }
    TreeNode cur = root,pre = null;
    //查找
    while(cur != null)
    {
        if(cur.val == num)
        {
            break;
        }
        pre = cur;
        if(cur.val < num)
        {
            cur = cur.right;
        }
        else {
            cur = cur.left;
        }
    }
    if(cur == null)
    {
        return;
    }
    if(cur.left == null || cur.right ==null)
    {
        TreeNode child = (cur.left != null ? cur.left : cur.right);
        if(cur != root)
        {
            if(pre.left == cur)
            {
                pre.left =child;
            }
            else{
                pre.right = child;
            }
        }
        else{
            root = child;
        }
    }
    //度为二
    else {
        TreeNode temp = cur.right;
        TreeNode tempParent = cur;
        //查找右子树的最小节点
        while (temp.left != null)
        {
            tempParent = temp;
            temp = temp.left;
        }
        cur.val = temp.val;
        //删除后继节点
        if(tempParent.left == temp)
        {
            tempParent.left = temp.right;
        }
        else{
            tempParent.right = temp.right;
        }
    }
}
```
时间复杂度: 查找O(logn),获取中序遍历后继节点O(logn)，最终是O（logn)<br>
空间复杂度：O（1）
<br>
**因此平衡的二叉搜索树的增删查都是O(logN)**