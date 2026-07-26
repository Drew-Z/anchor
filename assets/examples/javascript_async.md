# JavaScript 异步编程指南

> 理解 Promise、async/await 和异步模式

## 异步编程基础

### 为什么需要异步?

JavaScript 是单线程的,如果执行耗时操作(网络请求、文件读取)时阻塞,页面会卡死。

同步代码的问题:
```javascript
// 假设 fetchData 是同步的
const data = fetchData();  // 阻塞 3 秒
console.log(data);
console.log('done');  // 必须等 3 秒后才执行
```

异步代码的优势:
```javascript
// 异步执行
fetchData().then(data => {
  console.log(data);
});
console.log('done');  // 立即执行,不等待
```

### 回调函数(Callback)

早期的异步模式:

```javascript
function fetchData(callback) {
  setTimeout(() => {
    callback('data');
  }, 1000);
}

fetchData((data) => {
  console.log(data);  // 1 秒后输出
});
```

回调地狱问题:
```javascript
fetchUser((user) => {
  fetchOrders(user.id, (orders) => {
    fetchOrderDetails(orders[0].id, (details) => {
      console.log(details);  // 嵌套 3 层
    });
  });
});
```

## Promise

### Promise 基础

Promise 表示一个异步操作的最终结果,有三种状态:
- **pending**: 进行中
- **fulfilled**: 成功
- **rejected**: 失败

创建 Promise:
```javascript
const promise = new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve('success');  // 成功时调用
    // reject('error');  // 失败时调用
  }, 1000);
});
```

使用 Promise:
```javascript
promise
  .then(result => {
    console.log(result);  // 'success'
  })
  .catch(error => {
    console.error(error);
  });
```

### Promise 链式调用

```javascript
fetchUser()
  .then(user => {
    return fetchOrders(user.id);  // 返回新 Promise
  })
  .then(orders => {
    return fetchOrderDetails(orders[0].id);
  })
  .then(details => {
    console.log(details);
  })
  .catch(error => {
    console.error('任何一步失败都会到这里', error);
  });
```

### Promise 静态方法

#### Promise.all - 并发执行

等待所有 Promise 完成:
```javascript
Promise.all([
  fetch('/api/user'),
  fetch('/api/posts'),
  fetch('/api/comments')
])
  .then(([user, posts, comments]) => {
    console.log('全部完成', user, posts, comments);
  })
  .catch(error => {
    console.error('任何一个失败就会到这里', error);
  });
```

注意: 一个失败,整体失败。

#### Promise.allSettled - 等待所有完成

不管成功失败,都等待所有完成:
```javascript
Promise.allSettled([
  fetch('/api/user'),
  fetch('/api/posts'),
  fetch('/api/comments')
])
  .then(results => {
    results.forEach(result => {
      if (result.status === 'fulfilled') {
        console.log('成功', result.value);
      } else {
        console.log('失败', result.reason);
      }
    });
  });
```

#### Promise.race - 竞速

返回最快完成的那个:
```javascript
Promise.race([
  fetch('/api/primary'),
  fetch('/api/backup')
])
  .then(result => {
    console.log('最快的结果', result);
  });
```

常用于超时控制:
```javascript
function timeout(ms) {
  return new Promise((_, reject) => {
    setTimeout(() => reject(new Error('timeout')), ms);
  });
}

Promise.race([
  fetch('/api/data'),
  timeout(5000)
])
  .then(data => console.log(data))
  .catch(error => console.error('5秒超时', error));
```

## async/await

### 基础语法

async 函数返回 Promise:
```javascript
async function fetchData() {
  return 'data';  // 自动包装为 Promise.resolve('data')
}

fetchData().then(data => console.log(data));
```

await 等待 Promise 完成:
```javascript
async function loadUser() {
  const response = await fetch('/api/user');
  const user = await response.json();
  return user;
}
```

### 错误处理

使用 try/catch:
```javascript
async function loadUser() {
  try {
    const response = await fetch('/api/user');
    const user = await response.json();
    return user;
  } catch (error) {
    console.error('加载用户失败', error);
    throw error;  // 重新抛出
  }
}
```

不使用 try/catch:
```javascript
async function loadUser() {
  const response = await fetch('/api/user');
  const user = await response.json();
  return user;
}

loadUser()
  .then(user => console.log(user))
  .catch(error => console.error(error));
```

### 并发控制

错误示例(串行执行):
```javascript
async function loadAll() {
  const user = await fetch('/api/user');      // 等 1 秒
  const posts = await fetch('/api/posts');    // 再等 1 秒
  const comments = await fetch('/api/comments');  // 再等 1 秒
  return { user, posts, comments };  // 总共 3 秒
}
```

正确示例(并发执行):
```javascript
async function loadAll() {
  const [user, posts, comments] = await Promise.all([
    fetch('/api/user'),
    fetch('/api/posts'),
    fetch('/api/comments')
  ]);
  return { user, posts, comments };  // 总共 1 秒
}
```

### 循环中使用 await

串行执行:
```javascript
async function processItems(items) {
  for (const item of items) {
    await processItem(item);  // 逐个处理
  }
}
```

并发执行:
```javascript
async function processItems(items) {
  await Promise.all(items.map(item => processItem(item)));
}
```

## 常见陷阱

### 1. 忘记 await

错误:
```javascript
async function loadUser() {
  const user = fetch('/api/user');  // 忘记 await
  console.log(user);  // Promise 对象,不是数据
}
```

正确:
```javascript
async function loadUser() {
  const user = await fetch('/api/user');
  console.log(user);  // 实际数据
}
```

### 2. 在非 async 函数中使用 await

错误:
```javascript
function loadUser() {
  const user = await fetch('/api/user');  // SyntaxError
}
```

正确:
```javascript
async function loadUser() {
  const user = await fetch('/api/user');
}
```

顶层 await(现代浏览器支持):
```javascript
// 模块顶层
const user = await fetch('/api/user');
```

### 3. Promise 构造函数中使用 async

错误:
```javascript
new Promise(async (resolve, reject) => {
  const data = await fetchData();
  resolve(data);
});
```

这是反模式,直接用 async 函数:
```javascript
async function fetchData() {
  const data = await someAsyncOperation();
  return data;  // 自动包装为 Promise
}
```

### 4. 忘记 return await

有时需要显式 return await:
```javascript
async function loadUser() {
  try {
    return await fetch('/api/user');  // 需要 await
  } catch (error) {
    console.error(error);
    return null;
  }
}
```

如果不加 await,错误不会被 catch 捕获:
```javascript
async function loadUser() {
  try {
    return fetch('/api/user');  // 错误逃逸
  } catch (error) {
    console.error('捕获不到');  // 不会执行
  }
}
```

### 5. 并发数量过多

错误(1000 个并发请求):
```javascript
async function loadAll(ids) {
  return Promise.all(ids.map(id => fetch(`/api/item/${id}`)));
}

loadAll(Array.from({length: 1000}, (_, i) => i));  // 浏览器崩溃
```

正确(分批处理):
```javascript
async function loadAll(ids, batchSize = 10) {
  const results = [];
  for (let i = 0; i < ids.length; i += batchSize) {
    const batch = ids.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(id => fetch(`/api/item/${id}`))
    );
    results.push(...batchResults);
  }
  return results;
}
```

## 实战示例

### 重试机制

```javascript
async function fetchWithRetry(url, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await fetch(url);
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

### 超时控制

```javascript
function timeout(ms) {
  return new Promise((_, reject) => 
    setTimeout(() => reject(new Error('timeout')), ms)
  );
}

async function fetchWithTimeout(url, ms = 5000) {
  return Promise.race([
    fetch(url),
    timeout(ms)
  ]);
}
```

### 并发限制

```javascript
class AsyncQueue {
  constructor(concurrency = 3) {
    this.concurrency = concurrency;
    this.running = 0;
    this.queue = [];
  }

  async run(fn) {
    while (this.running >= this.concurrency) {
      await new Promise(resolve => this.queue.push(resolve));
    }
    this.running++;
    try {
      return await fn();
    } finally {
      this.running--;
      const resolve = this.queue.shift();
      if (resolve) resolve();
    }
  }
}

// 使用
const queue = new AsyncQueue(3);
const tasks = ids.map(id => () => fetch(`/api/item/${id}`));
const results = await Promise.all(tasks.map(task => queue.run(task)));
```

---

**知识点数量**: 约 10 个  
**难度**: 中级  
**适合**: 前端开发者进阶
