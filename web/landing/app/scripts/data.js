export const DATA_VERSION = 1;

/** Storage schema for browser-local imported sources. Bumped independently of `DATA_VERSION`. */
export const LIBRARY_VERSION = 1;

/**
 * Conservative ceilings for browser-local import.
 *
 * `localStorage` is a small, synchronous, per-origin store, so the demo keeps structured excerpts
 * rather than whole documents. The caps below bound one record to roughly 20 KB of JSON.
 */
export const LOCAL_IMPORT_LIMITS = {
  extensions: ['.md', '.markdown', '.txt'],
  maxBytes: 131_072,
  maxSections: 40,
  maxExcerptChars: 480,
  maxSources: 12,
};

/** Storage schema for the browser-local guided Agent session. Bumped independently of the keys above. */
export const AGENT_SESSION_VERSION = 1;

/**
 * Bounds for one stored guided session.
 *
 * A reflection is the only learner-authored text this surface keeps, so it is capped for the same
 * reason imported excerpts are: `localStorage` is small, synchronous, and shared across the origin.
 */
export const AGENT_SESSION_LIMITS = {
  maxReflectionChars: 600,
};

/**
 * Envelope written by the Profile backup export.
 *
 * `format` is checked before `version` so a JSON file from somewhere else is rejected as the wrong
 * kind of document rather than as an incompatible Anchor backup. `version` covers the envelope only;
 * each section still carries the schema version of the key it came from.
 */
export const BACKUP_FORMAT = 'anchor.demo.backup';
export const BACKUP_VERSION = 1;

/**
 * Ceilings for a restore candidate. A backup holds the three demo keys, and their own caps bound it
 * to well under 300 KB, so 1 MB rejects a hostile or unrelated file before it is parsed while leaving
 * a wide margin for a legitimate export.
 */
export const BACKUP_LIMITS = {
  maxBytes: 1_048_576,
  extensions: ['.json'],
};

/** Sections a backup may carry, in the order the review panel lists them. */
export const BACKUP_SECTIONS = ['progress', 'library', 'agent'];

/** Themes the app can apply. `system` is not a value: the resolved choice is always one of these. */
export const THEMES = ['light', 'dark'];

/** Storage schema for the persisted theme choice. Bumped independently of the data keys. */
export const THEME_VERSION = 1;

const localized = (en, zh) => ({ en, zh });

export const DATASETS = [
  {
    id: 'flutter',
    mark: 'FL',
    title: localized('Flutter lifecycle', 'Flutter 生命周期'),
    summary: localized(
      'Widget identity, State lifecycle, mounted checks, and immutable configuration.',
      '理解 Widget 身份、State 生命周期、mounted 检查与不可变配置。',
    ),
    questions: [
      {
        id: 'flutter-state-owner',
        type: 'single',
        prompt: localized(
          'Which object keeps mutable data across rebuilds for a StatefulWidget?',
          'StatefulWidget 重建时，哪个对象会保留可变数据？',
        ),
        options: [
          { id: 'widget', label: localized('The StatefulWidget instance', 'StatefulWidget 实例') },
          { id: 'state', label: localized('The associated State object', '与之关联的 State 对象') },
          { id: 'element', label: localized('A new BuildContext value', '新的 BuildContext 值') },
          { id: 'theme', label: localized('The nearest ThemeData object', '最近的 ThemeData 对象') },
        ],
        correct: ['state'],
        explanation: localized(
          'StatefulWidget is immutable configuration. Flutter creates a separate State object whose lifetime can span many widget instances at the same location.',
          'StatefulWidget 是不可变配置。Flutter 会创建独立的 State 对象；只要位置和身份保持匹配，它可以跨越多次 Widget 实例重建。',
        ),
        citations: [
          {
            locator: 'flutter/widgets.md#statefulwidget',
            excerpt: localized(
              'StatefulWidget instances themselves are immutable and store their mutable state either in separate State objects or in subscribed objects.',
              'StatefulWidget 实例本身不可变；可变状态保存在独立的 State 对象或其订阅对象中。',
            ),
          },
        ],
        tutorHints: [
          localized('Separate configuration from data that changes over time.', '先区分“配置”与“随时间变化的数据”。'),
          localized('Ask which object receives setState and survives a normal rebuild.', '想一想 setState 属于谁，以及普通重建后谁仍然存在。'),
        ],
      },
      {
        id: 'flutter-init-order',
        type: 'single',
        prompt: localized(
          'When should one-time State initialization that does not depend on inherited widgets normally run?',
          '不依赖 InheritedWidget 的一次性 State 初始化通常应放在哪里？',
        ),
        options: [
          { id: 'constructor', label: localized('Inside every build method call', '每次 build 调用中') },
          { id: 'initState', label: localized('Inside initState, before calling super.initState', '在 initState 中，并在 super.initState 前') },
          { id: 'initStateAfter', label: localized('Inside initState, after calling super.initState', '在 initState 中，并在 super.initState 后') },
          { id: 'dispose', label: localized('Inside dispose', '在 dispose 中') },
        ],
        correct: ['initStateAfter'],
        explanation: localized(
          'initState is called once for a State object. The conventional contract is to call super.initState first, then perform local initialization.',
          '一个 State 对象只会调用一次 initState。通常先调用 super.initState，再执行本地初始化。',
        ),
        citations: [
          {
            locator: 'flutter/state-lifecycle.md#initState',
            excerpt: localized(
              'The framework calls initState exactly once for each State object. Implementations should start by calling super.initState().',
              '框架会为每个 State 对象调用一次 initState；实现应首先调用 super.initState()。',
            ),
          },
        ],
        tutorHints: [
          localized('Look for the lifecycle method with a once-per-State guarantee.', '寻找对每个 State 只执行一次的生命周期方法。'),
          localized('Inherited dependencies are handled later in didChangeDependencies.', '依赖 InheritedWidget 的初始化通常要等到 didChangeDependencies。'),
        ],
      },
      {
        id: 'flutter-async-safety',
        type: 'multiple',
        prompt: localized(
          'Which actions help make an asynchronous State update safe after an await?',
          'await 之后要安全更新 State，哪些做法是正确的？',
        ),
        options: [
          { id: 'mounted', label: localized('Check mounted before calling setState', '调用 setState 前检查 mounted') },
          { id: 'cancel', label: localized('Cancel owned subscriptions or operations in dispose', '在 dispose 中取消自己持有的订阅或任务') },
          { id: 'force', label: localized('Call setState even after dispose to keep data current', '即使已 dispose 也调用 setState 保持数据最新') },
          { id: 'context', label: localized('Assume BuildContext remains valid across every await', '假设 BuildContext 在所有 await 后都有效') },
        ],
        correct: ['mounted', 'cancel'],
        explanation: localized(
          'A State object can be disposed while work is suspended. Checking mounted and cancelling owned work prevent updates from targeting a dead lifecycle.',
          '异步任务挂起期间 State 可能已被销毁。检查 mounted，并在 dispose 中取消自己持有的任务，可以避免更新已经结束的生命周期。',
        ),
        citations: [
          {
            locator: 'flutter/state-lifecycle.md#mounted',
            excerpt: localized(
              'It is an error to call setState unless mounted is true. Resources retained by a State object should be released in dispose.',
              '只有 mounted 为 true 时才能调用 setState；State 持有的资源应在 dispose 中释放。',
            ),
          },
        ],
        tutorHints: [
          localized('An await creates time for navigation or disposal to happen.', 'await 留出了页面跳转或销毁发生的时间。'),
          localized('Think about both preventing future callbacks and guarding the callback that already resumed.', '既要阻止未来回调，也要保护已经恢复执行的回调。'),
        ],
      },
      {
        id: 'flutter-widget-immutable',
        type: 'boolean',
        prompt: localized(
          'A StatefulWidget should mutate its own fields when the user changes a setting.',
          '当用户修改设置时，StatefulWidget 应直接修改自身字段。',
        ),
        options: [
          { id: 'true', label: localized('True', '正确') },
          { id: 'false', label: localized('False', '错误') },
        ],
        correct: ['false'],
        explanation: localized(
          'Widgets are immutable descriptions. Mutable values belong in State or another state holder; a parent can provide new configuration through a new widget instance.',
          'Widget 是不可变的界面描述。可变值应放在 State 或其他状态容器中；父组件通过新的 Widget 实例传入新配置。',
        ),
        citations: [
          {
            locator: 'flutter/widgets.md#immutability',
            excerpt: localized(
              'Widgets describe configuration and are immutable. When configuration changes, the framework receives a new widget instance.',
              'Widget 描述配置并保持不可变；配置变化时，框架会收到新的 Widget 实例。',
            ),
          },
        ],
        tutorHints: [
          localized('Treat a widget like a value object that describes desired UI.', '把 Widget 看成描述目标界面的值对象。'),
          localized('The word Stateful refers to the paired State object, not mutable widget fields.', 'Stateful 指的是配套的 State 对象，而不是 Widget 字段可变。'),
        ],
      },
    ],
  },
  {
    id: 'git',
    mark: 'GT',
    title: localized('Git collaboration', 'Git 协作'),
    summary: localized(
      'Commits, the staging area, history repair, and safe collaboration choices.',
      '掌握提交、暂存区、历史修复与协作中的安全选择。',
    ),
    questions: [
      {
        id: 'git-commit-snapshot',
        type: 'single',
        prompt: localized('What does a Git commit primarily record?', 'Git commit 主要记录什么？'),
        options: [
          { id: 'diff', label: localized('Only a patch against the previous commit', '只记录相对上一个提交的补丁') },
          { id: 'snapshot', label: localized('A snapshot tree plus metadata and parent references', '文件树快照、元数据与父提交引用') },
          { id: 'working', label: localized('Every untracked file in the working directory', '工作目录中的所有未跟踪文件') },
          { id: 'branch', label: localized('A permanent copy of the branch name', '分支名称的永久副本') },
        ],
        correct: ['snapshot'],
        explanation: localized(
          'A commit points to a tree snapshot and records author/message metadata plus parent commit references. Diffs are derived by comparing snapshots.',
          '提交指向文件树快照，并记录作者、消息和父提交引用；diff 是比较两个快照后推导出来的。',
        ),
        citations: [
          {
            locator: 'git/data-model.md#commit-object',
            excerpt: localized(
              'A commit object references one tree, zero or more parents, and author/committer metadata. Differences are computed between trees.',
              'Commit 对象引用一个 tree、零个或多个父提交，以及作者和提交者元数据；差异通过比较 tree 得到。',
            ),
          },
        ],
        tutorHints: [
          localized('Git stores objects; patches are a view over those objects.', 'Git 存储对象，补丁只是观察这些对象的一种方式。'),
          localized('Consider how a merge commit can have more than one parent.', '想一想为什么合并提交可以拥有多个父提交。'),
        ],
      },
      {
        id: 'git-staging',
        type: 'multiple',
        prompt: localized('Which statements about the staging area are correct?', '关于暂存区，哪些说法正确？'),
        options: [
          { id: 'next', label: localized('It represents the proposed content of the next commit', '它表示下一次提交准备包含的内容') },
          { id: 'partial', label: localized('It can hold selected hunks instead of every working-tree change', '它可以只包含部分修改，而不是工作区全部变化') },
          { id: 'remote', label: localized('It automatically uploads changes to the remote', '它会自动把修改上传到远端') },
          { id: 'backup', label: localized('It is a durable off-machine backup', '它是持久的异机备份') },
        ],
        correct: ['next', 'partial'],
        explanation: localized(
          'The index lets you assemble the next snapshot independently of remaining working-tree changes. It is local and is not a remote backup.',
          '索引允许你独立组装下一次提交的快照，不必包含工作区所有变化。它是本地状态，不是远端备份。',
        ),
        citations: [
          {
            locator: 'git/workflow.md#the-index',
            excerpt: localized(
              'The index is the proposed next tree. Commands such as git add -p can update selected portions while other changes remain unstaged.',
              '索引是下一棵文件树的提案；git add -p 可以只更新选中片段，其他变化仍留在未暂存状态。',
            ),
          },
        ],
        tutorHints: [
          localized('Compare working tree, index, and HEAD as three separate states.', '把工作区、索引和 HEAD 看成三个独立状态。'),
          localized('Ask whether staging communicates with any server.', '判断暂存操作是否会与服务器通信。'),
        ],
      },
      {
        id: 'git-revert-shared',
        type: 'single',
        prompt: localized(
          'A bad commit is already on a shared main branch. What is the safest normal correction?',
          '错误提交已经进入共享 main 分支，通常最安全的修复方式是什么？',
        ),
        options: [
          { id: 'reset', label: localized('Force-push a reset main branch', '强制推送 reset 后的 main') },
          { id: 'delete', label: localized('Delete the repository and clone again', '删除仓库后重新克隆') },
          { id: 'revert', label: localized('Create a revert commit that records the inverse change', '创建 revert 提交记录反向修改') },
          { id: 'amend', label: localized('Amend the shared commit in place', '直接 amend 已共享的提交') },
        ],
        correct: ['revert'],
        explanation: localized(
          'Revert preserves published history and adds an auditable inverse change. Rewriting shared main can invalidate collaborators\' references.',
          'Revert 保留已发布历史，并新增可审计的反向修改；重写共享 main 会让协作者持有的引用失效。',
        ),
        citations: [
          {
            locator: 'git/collaboration.md#revert',
            excerpt: localized(
              'git revert creates a new commit that reverses selected changes without removing the original commit from shared history.',
              'git revert 会创建新提交来反转所选修改，而不会从共享历史中删除原提交。',
            ),
          },
        ],
        tutorHints: [
          localized('Prefer an additive repair when other clones already reference the history.', '其他克隆已引用这段历史时，应优先选择新增式修复。'),
          localized('Auditability matters on a protected shared branch.', '受保护的共享分支需要保留可审计记录。'),
        ],
      },
      {
        id: 'git-rebase-public',
        type: 'boolean',
        prompt: localized(
          'Rebasing a branch that other people already consume is always harmless because file contents stay the same.',
          '只要文件内容相同，对他人已经使用的分支执行 rebase 就一定没有影响。',
        ),
        options: [
          { id: 'true', label: localized('True', '正确') },
          { id: 'false', label: localized('False', '错误') },
        ],
        correct: ['false'],
        explanation: localized(
          'Rebase creates new commit objects with new identities. Even identical final files do not preserve the old commit graph referenced by collaborators.',
          'Rebase 会创建具有新身份的提交对象。即使最终文件相同，也不会保留协作者引用的旧提交图。',
        ),
        citations: [
          {
            locator: 'git/collaboration.md#published-history',
            excerpt: localized(
              'Rewriting published commits replaces object identities and requires collaborators to reconcile divergent histories.',
              '重写已发布提交会替换对象身份，并迫使协作者处理分叉历史。',
            ),
          },
        ],
        tutorHints: [
          localized('Commit identity includes parent references, not just file content.', '提交身份还包含父引用，不只是文件内容。'),
          localized('Separate rebasing a private feature branch from rewriting a shared branch.', '区分重放私有特性分支与重写共享分支。'),
        ],
      },
    ],
  },
  {
    id: 'javascript',
    mark: 'JS',
    title: localized('JavaScript runtime', 'JavaScript 运行时'),
    summary: localized(
      'Tasks, promises, bindings, and lifecycle-safe event handling in the browser.',
      '理解浏览器中的任务、Promise、绑定与生命周期安全的事件处理。',
    ),
    questions: [
      {
        id: 'js-microtask-order',
        type: 'single',
        prompt: localized(
          'After the current call stack finishes, which queued callback normally runs first?',
          '当前调用栈结束后，哪个已排队回调通常最先运行？',
        ),
        options: [
          { id: 'timeout', label: localized('A setTimeout(..., 0) callback', 'setTimeout(..., 0) 回调') },
          { id: 'promise', label: localized('A resolved Promise.then callback', '已解决 Promise 的 then 回调') },
          { id: 'click', label: localized('A future user click handler', '未来的用户点击处理器') },
          { id: 'idle', label: localized('An idle callback regardless of deadlines', '不考虑期限的 idle 回调') },
        ],
        correct: ['promise'],
        explanation: localized(
          'Promise reactions use the microtask queue. The runtime drains microtasks after the stack before selecting the next task such as a timer.',
          'Promise 回调进入微任务队列。运行时会在调用栈结束后先清空微任务，再选择计时器等下一个任务。',
        ),
        citations: [
          {
            locator: 'javascript/event-loop.md#microtasks',
            excerpt: localized(
              'After a task completes and the JavaScript stack is empty, the event loop performs a microtask checkpoint before the next task.',
              '一个任务完成且 JavaScript 调用栈清空后，事件循环会在下一个任务前执行微任务检查点。',
            ),
          },
        ],
        tutorHints: [
          localized('Distinguish the task queue from the microtask queue.', '先区分任务队列与微任务队列。'),
          localized('Promise reactions and timers use different scheduling layers.', 'Promise 回调与计时器属于不同调度层。'),
        ],
      },
      {
        id: 'js-const-binding',
        type: 'boolean',
        prompt: localized(
          'Declaring an object with const makes every property of that object immutable.',
          '使用 const 声明对象后，对象的所有属性都会不可变。',
        ),
        options: [
          { id: 'true', label: localized('True', '正确') },
          { id: 'false', label: localized('False', '错误') },
        ],
        correct: ['false'],
        explanation: localized(
          'const prevents rebinding the variable. It does not freeze the referenced object; Object.freeze or an immutable data discipline is separate.',
          'const 阻止变量重新绑定，但不会冻结引用的对象；Object.freeze 或不可变数据约定是另一层机制。',
        ),
        citations: [
          {
            locator: 'javascript/language.md#const',
            excerpt: localized(
              'A const declaration creates a binding that cannot be reassigned. If the value is an object, its properties may still change.',
              'const 声明创建不可重新赋值的绑定；如果值是对象，其属性仍可能变化。',
            ),
          },
        ],
        tutorHints: [
          localized('Separate the variable binding from the object it references.', '区分变量绑定与它引用的对象。'),
          localized('Ask what operation const rejects: assignment or property mutation.', '判断 const 拒绝的是重新赋值还是属性修改。'),
        ],
      },
      {
        id: 'js-promise-all',
        type: 'multiple',
        prompt: localized('Which statements describe Promise.all correctly?', '哪些说法正确描述了 Promise.all？'),
        options: [
          { id: 'ordered', label: localized('Fulfilled results preserve input order', '成功结果保持输入顺序') },
          { id: 'reject', label: localized('The returned promise rejects when one input rejects', '任一输入拒绝时，返回的 Promise 会拒绝') },
          { id: 'cancel', label: localized('It automatically cancels every other operation', '它会自动取消其他所有操作') },
          { id: 'serial', label: localized('It starts promises strictly one after another', '它会严格按顺序逐个启动 Promise') },
        ],
        correct: ['ordered', 'reject'],
        explanation: localized(
          'Promise.all aggregates already-created inputs, preserves their positional result order, and rejects on the first observed rejection. Cancellation requires a separate mechanism.',
          'Promise.all 聚合已经创建的输入，按输入位置保持结果顺序，并在观察到拒绝时拒绝；取消任务需要独立机制。',
        ),
        citations: [
          {
            locator: 'javascript/promises.md#promise-all',
            excerpt: localized(
              'Promise.all fulfills with an array ordered like the iterable, or rejects when any input rejects. It does not define cancellation of the remaining work.',
              'Promise.all 成功时返回与输入迭代顺序一致的数组；任一输入拒绝时返回拒绝。它不负责取消剩余任务。',
            ),
          },
        ],
        tutorHints: [
          localized('Aggregation is not the same as scheduling or cancellation.', '聚合不等于调度或取消。'),
          localized('Completion timing and result-array order are different questions.', '完成时间顺序与结果数组顺序不是同一件事。'),
        ],
      },
      {
        id: 'js-listener-cleanup',
        type: 'multiple',
        prompt: localized(
          'Which practices make a removable DOM event listener reliable?',
          '哪些做法能让 DOM 事件监听器可靠地移除？',
        ),
        options: [
          { id: 'reference', label: localized('Keep the same function reference used during registration', '保留注册监听器时使用的同一个函数引用') },
          { id: 'options', label: localized('Match the capture setting when removing it', '移除时匹配 capture 设置') },
          { id: 'anonymous', label: localized('Pass a new anonymous function to removeEventListener', '向 removeEventListener 传入新的匿名函数') },
          { id: 'reload', label: localized('Reload the page whenever cleanup is needed', '需要清理时重新加载页面') },
        ],
        correct: ['reference', 'options'],
        explanation: localized(
          'Removal matches listener identity and capture mode. A new function expression is a different object and cannot remove the original callback.',
          '移除监听器需要匹配函数身份与捕获模式。新的函数表达式是不同对象，无法移除原回调。',
        ),
        citations: [
          {
            locator: 'javascript/dom-events.md#listener-identity',
            excerpt: localized(
              'removeEventListener identifies a listener by event type, callback reference, and capture value. A newly created callback does not match.',
              'removeEventListener 通过事件类型、回调引用和 capture 值识别监听器；新建回调无法匹配。',
            ),
          },
        ],
        tutorHints: [
          localized('Functions are objects with identity, not interchangeable source text.', '函数是有身份的对象，不是相同源码就能互换。'),
          localized('Check the capture flag as well as the callback.', '除了回调，还要检查 capture 标志。'),
        ],
      },
    ],
  },
];

/**
 * Copy for the app shell surfaces.
 *
 * These strings live here instead of `landing/scripts/i18n.js` because the shell is specific to
 * the `/app/` surface. Existing landing keys are still resolved with `translate()` so the demo
 * keeps a single bilingual vocabulary.
 */
export const SHELL_TEXT = {
  navAria: localized('App sections', '应用分区'),
  navLearn: localized('Learn', '学习'),
  navDecks: localized('Decks', '题库'),
  navAgent: localized('Agent', 'Agent'),
  navLibrary: localized('Library', '知识库'),
  navProfile: localized('Profile', '我的'),
  navImport: localized('Import', '导入'),
  badgeLocal: localized('Local demo', '本地演示'),
  badgeAndroid: localized('Android app', 'Android 应用'),
  browserScope: localized(
    'The browser shell mirrors the app layout. It runs on bundled data and files you import locally, with no account, upload, or AI request.',
    '浏览器外壳复刻应用结构，只使用内置数据和你在本地导入的文件，不需要账号，也不会上传文件或发起 AI 请求。',
  ),
  backToDecks: localized('All datasets', '全部数据集'),

  /**
   * Sidebar privacy note. The shell renders this instead of the landing page's `app.localOnly`
   * strings because local import means "bundled data only" is no longer an accurate claim.
   */
  privacy: {
    title: localized('Stays in this browser', '只保留在此浏览器'),
    body: localized(
      'Bundled datasets and any file you import are read and stored locally. Nothing is uploaded and no AI provider is called.',
      '内置数据集和你导入的文件都在本地读取和保存，不会上传，也不会调用任何 AI 服务。',
    ),
  },

  home: {
    eyebrow: localized('Learn', '学习'),
    title: localized('Practice from bundled sources', '从内置来源开始练习'),
    body: localized(
      'Anchor Learning turns technical material into exercises that stay attached to their evidence. This browser shell ships fixed datasets so you can walk the whole loop without an account.',
      'Anchor Learning 把技术资料转化为始终附带证据的练习。这个浏览器外壳内置固定数据集，无需账号即可走完整个流程。',
    ),
    statAnswered: localized('Answered', '已答题'),
    statCorrect: localized('Supported', '得到支持'),
    statStarted: localized('Datasets started', '已开始数据集'),
    statCompletion: localized('Questions covered', '题目覆盖率'),

    /**
     * Today block. The count is answers submitted in this browser since local midnight, so the copy
     * names both limits: it is one browser, and it is one day. No streak is implied or stored, and
     * nothing here is scheduled — a goal is a target for today, not a queue somebody else built.
     */
    todayTitle: localized('Today', '今天'),
    todayBody: localized(
      'Answers you submitted in this browser today. The count resets at midnight on this device and is never uploaded.',
      '今天在此浏览器中提交的答题数。计数在本机午夜重置，且不会上传。',
    ),
    todayGoal: localized('{done} of {goal} answered today', '今天已答 {done} / {goal} 题'),
    todayCount: localized('{done} answered today', '今天已答 {done} 题'),
    todayMet: localized('Daily goal reached', '已达成今日目标'),
    todayRemaining: localized('{n} to go', '还差 {n} 题'),
    todayExhausted: localized(
      'Every bundled question has been answered. Import your own material to keep going.',
      '内置题目已全部作答。导入你自己的资料即可继续。',
    ),
    todayEmpty: localized('Nothing answered yet today', '今天还没有答题'),

    /** Focus card: one deterministic target, picked from stored progress rather than a review queue. */
    focusEyebrow: localized('Next up', '接下来'),
    continueTitle: localized('Continue where you stopped', '继续上次的练习'),
    focusStartTitle: localized('Start your first deck', '开始第一个题包'),
    focusReviewTitle: localized('Review a completed deck', '复习已完成的题包'),
    focusRemaining: localized('{n} of {total} questions left', '还剩 {n} / {total} 题'),
    focusComplete: localized('All {total} questions answered', '{total} 道题已全部作答'),
    continueAction: localized('Continue', '继续'),
    actionsTitle: localized('Where to go next', '接下来去哪里'),
    startTitle: localized('Pick a dataset', '选择一套数据集'),
    startBody: localized(
      'Each dataset mixes single choice, multiple choice, and true/false questions, and every answer opens its source passage.',
      '每套数据集包含单选、多选和判断题，每个答案都可以展开对应的原文。',
    ),
    startAction: localized('Open decks', '打开题库'),
    agentTitle: localized('Walk a guided session', '走一遍引导流程'),
    agentBody: localized(
      'A scripted walkthrough of how the agent works, with preset prompts and no model call. Your notes stay in this browser.',
      '以预设提示脚本化地展示代理的工作方式，不会调用任何模型。你的笔记只保存在此浏览器中。',
    ),
    agentAction: localized('Open the agent', '打开代理'),
    libraryTitle: localized('Check the sources', '查看来源'),
    libraryBody: localized(
      'Every bundled passage and imported file, searchable by literal text. This is where an answer’s evidence comes from.',
      '所有内置原文和导入文件，可按字面文本搜索。答案的证据就来自这里。',
    ),
    libraryAction: localized('Open the library', '打开来源库'),
    importTitle: localized('Add content', '添加内容'),
    importBody: localized(
      'Read a Markdown or text file into this browser to see how Anchor splits it into sections. The Android app takes the same file further and builds questions from it.',
      '可以把 Markdown 或纯文本文件读入当前浏览器，看看 Anchor 如何把它切分成小节。Android 应用会在此基础上继续生成题目。',
    ),
    importAction: localized('Import a file', '导入文件'),
    /**
     * The plan lists every bundled deck in its bundled order and reports what this browser has
     * answered. It is deliberately not called a review plan: nothing here is due, scheduled, or
     * ordered by an algorithm.
     */
    planTitle: localized('Learning plan', '学习计划'),
    planBody: localized(
      'Every bundled deck, in order, with the progress stored in this browser. Nothing is scheduled on a server.',
      '按顺序列出全部内置题包，并显示保存在此浏览器中的进度。不依赖任何服务端排程。',
    ),
    planProgress: localized('{done}/{total} answered', '已答 {done}/{total}'),
    planRemaining: localized('{n} left', '还剩 {n} 题'),
    planDone: localized('Complete', '已完成'),
    planSummary: localized('{done} of {total} decks complete', '已完成 {done} / {total} 个题包'),
  },

  decks: {
    eyebrow: localized('Decks', '题库'),
    note: localized(
      'These datasets are bundled with the demo. Generating new questions from your own material happens in the Android app.',
      '这些数据集随演示内置。基于你自己的资料生成新题目在 Android 应用中完成。',
    ),

    /**
     * Deck search copy. Like the library, it stays mechanical: the surface matches the deck name as
     * literal text, so it says so rather than implying a ranked or semantic result.
     */
    searchLabel: localized('Find a deck', '查找题包'),
    searchPlaceholder: localized('Deck name', '题包名称'),
    searchHint: localized(
      'Matches the deck name shown here, up to {max} characters. Enter opens the first deck, Escape clears.',
      '按当前显示的题包名称匹配，最多 {max} 个字符。按 Enter 打开第一个题包，按 Esc 清空。',
    ),
    searchClear: localized('Clear search', '清空搜索'),
    searchRegion: localized('Search decks', '搜索题包'),
    statusIdle: localized('Decks: {n}. Verified questions: {q}.', '题包：{n} 个。已核验题目：{q} 道。'),
    statusResults: localized('Decks matching “{query}”: {n} of {total}.', '匹配“{query}”的题包：{n} / {total} 个。'),
    emptyNoResults: localized(
      'No deck name matched “{query}”. Clear the search to see all {total}, or add your own material.',
      '没有题包名称匹配“{query}”。清空搜索可查看全部 {total} 个，也可以添加你自己的资料。',
    ),
    announceCleared: localized('Deck search cleared. Showing all {total} decks.', '已清空题包搜索，显示全部 {total} 个题包。'),

    /** Per-card status. Counts are bundled data plus this browser's progress, never a server. */
    cardVerified: localized('{verified} verified / {total} total', '{verified} 已核验 / {total} 总题'),
    cardAnswered: localized('{answered}/{total} answered', '已答 {answered}/{total}'),
    cardProgress: localized('{percent}% answered', '已答 {percent}%'),
    cardNotStarted: localized('Not started', '尚未开始'),
    actionStart: localized('Start studying', '开始学习'),
    actionContinue: localized('Continue studying', '继续学习'),
    actionReview: localized('Review again', '再次复习'),
    actionPending: localized('Awaiting verification', '待核验'),
    importAction: localized('Add content', '添加内容'),
  },

  agent: {
    eyebrow: localized('Agent', 'Agent'),
    title: localized('Guided help that shows its sources', '会展示来源的引导式辅导'),
    body: localized(
      'In the Android Private Alpha the Agent picks a learning goal, explains concepts from imported material, and runs interview practice. The browser shell runs the scripted walkthrough of that loop.',
      '在 Android Private Alpha 中，Agent 会选择学习目标、基于导入资料讲解概念，并进行面试练习。浏览器外壳运行其中预置的引导流程。',
    ),

    /** Start panel: choosing a bundled dataset and opening a scripted session. */
    modeTitle: localized('Guided walkthrough', '引导式流程'),
    modeBody: localized(
      'Work through one bundled dataset turn by turn. Every prompt, source passage, and hint below is fixed text that ships with this demo, so the same dataset always produces the same session.',
      '按顺序走完一套内置数据集。下面每个提示、原文片段和导师提示都是随演示内置的固定文本，因此同一套数据集每次都会得到相同的流程。',
    ),
    modeScripted: localized('Scripted, no model call', '预置内容，不调用模型'),
    pickLegend: localized('Dataset for this session', '本次流程使用的数据集'),
    pickHint: localized('{n} turns', '{n} 轮'),
    startAction: localized('Start guided session', '开始引导式流程'),
    startBlocked: localized('Select a dataset to start.', '请先选择一套数据集。'),

    /** Active session: progress, turn content, reflection, hints. */
    sessionTitle: localized('Guided session', '引导式流程'),
    turnCounter: localized('Turn {n} of {total}', '第 {n} 轮 / 共 {total} 轮'),
    turnFocus: localized('Focus', '本轮重点'),
    turnPrompt: localized('Question from the dataset', '来自数据集的问题'),
    sourceTitle: localized('Source passage', '原文片段'),
    hintAction: localized('Reveal a hint', '展开一条提示'),
    hintTitle: localized('Tutor hints', '导师提示'),
    hintAllShown: localized('All hints shown', '提示已全部展开'),
    reflectionLabel: localized('Your reflection', '你的思考'),
    reflectionHelp: localized(
      'Write what you would say out loud. It stays in this browser and is never uploaded.',
      '写下你会怎么说出来。内容只保留在此浏览器，不会上传。',
    ),
    reflectionRequired: localized('Write a reflection to continue.', '写下思考后即可继续。'),
    reflectionCount: localized('{n}/{max} characters', '{n}/{max} 字符'),
    nextAction: localized('Next turn', '下一轮'),
    finishAction: localized('Finish session', '完成流程'),
    storedNote: localized(
      'This session is stored in this browser only. Reloading the page resumes it.',
      '流程仅保存在此浏览器中，刷新页面后会继续。',
    ),

    /** Completion: recap plus links back into the deck and the library. */
    doneTitle: localized('Session complete', '流程已完成'),
    doneBody: localized(
      'You wrote a reflection for all {n} turns of {dataset}. Compare each one with the passage the dataset cites.',
      '你已为《{dataset}》的全部 {n} 轮写下思考。可以逐条对照数据集引用的原文。',
    ),
    recapTitle: localized('Your notes and the source', '你的笔记与原文'),
    recapMine: localized('Your reflection', '你的思考'),
    recapSource: localized('What the dataset says', '数据集的说明'),
    deckAction: localized('Practice this dataset', '练习这套数据集'),
    libraryAction: localized('Open the source library', '打开来源库'),
    restartAction: localized('Start another session', '开始新的流程'),

    /** Scoped reset. Separate from the quiz reset so neither control clears the other's data. */
    clearAction: localized('Clear this session', '清除此流程'),
    clearTitle: localized('Clear the guided session?', '确认清除引导式流程？'),
    clearBody: localized(
      'This removes the stored turns and reflections for this session only. Quiz progress and imported sources stay.',
      '仅会删除此流程已保存的轮次与思考，答题进度和已导入的来源不受影响。',
    ),
    clearConfirm: localized('Clear session', '清除流程'),
    clearCancel: localized('Keep session', '保留流程'),

    /** Live-region announcements. */
    announceStarted: localized('Guided session started on {dataset}. Turn 1 of {total}.', '已开始《{dataset}》的引导式流程，第 1 轮 / 共 {total} 轮。'),
    announceTurn: localized('Turn {n} of {total}.', '第 {n} 轮 / 共 {total} 轮。'),
    announceHint: localized('Hint {n} of {total} shown. Scripted text, no live AI.', '已展开第 {n} / {total} 条提示。内容为预置文本，未运行实时 AI。'),
    announceDone: localized('Session complete. {n} reflections saved in this browser.', '流程已完成，{n} 条思考已保存在此浏览器。'),
    announceCleared: localized('Guided session cleared. Quiz progress kept.', '引导式流程已清除，答题进度保留。'),

    /** Android-only boundary. */
    nativeTitle: localized('Runs on Android only', '仅在 Android 上运行'),
    nativeBody: localized(
      'These capabilities need a configured model and on-device storage, so the static browser demo does not include them. The walkthrough above replays fixed text instead.',
      '这些能力需要已配置的模型和设备本地存储，静态浏览器演示不包含它们。上面的引导流程只是回放固定文本。',
    ),
    nativeTutor: localized('Live tutor conversation about an imported concept', '围绕导入概念的实时导师对话'),
    nativeQa: localized('Knowledge base question and answer over your own material', '基于你自己资料的知识库问答'),
    nativeSocratic: localized('Socratic follow-up questions generated from your answers', '根据你的回答生成的苏格拉底式追问'),
    nativeInterview: localized('Project interview mode with evidence-bound follow-up questions', '带证据约束追问的项目面试官模式'),
    nativeTarget: localized('Learning goals for interview prep, project study, or programming foundations', '面试准备、讲清项目细节、编程基础等学习目标'),
    nativeReview: localized('Session history and interview review records', '会话历史与面试复盘记录'),
  },

  library: {
    eyebrow: localized('Library', '知识库'),
    title: localized('Sources behind this demo', '演示背后的来源'),
    body: localized(
      '{n} excerpts back the {q} bundled questions. Each one is the passage the demo quotes when it explains an answer. Files you import in this browser are listed separately.',
      '{n} 段摘录支撑内置的 {q} 道题目，每段都是演示解释答案时引用的原文。你在此浏览器中导入的文件会单独列出。',
    ),
    openDataset: localized('Practice this dataset', '练习这套数据集'),
    questionLabel: localized('Explains', '用于解释'),
    bundledTitle: localized('Bundled with this demo', '随演示内置'),
    bundledBody: localized(
      'Verified excerpts that back the demo questions. They ship with the page and cannot be edited or removed.',
      '支撑演示题目的已校验摘录。它们随页面内置，无法编辑或删除。',
    ),

    /**
     * Search copy stays deliberately mechanical. The surface matches literal text, so it says which field
     * matched and never claims a result is relevant, related, or best.
     */
    search: {
      title: localized('Search this library', '搜索本知识库'),
      body: localized(
        'Matches text in the bundled excerpts and in files you imported into this browser. Substring matching runs on this page: no ranking model, no embedding, and no request leaves the browser.',
        '在内置摘录和你导入到此浏览器的文件中匹配文本。子串匹配就在本页完成：没有排序模型，没有向量化，也不会有任何请求离开浏览器。',
      ),
      label: localized('Search text', '搜索文本'),
      placeholder: localized('Word or phrase', '词或短语'),
      hint: localized(
        'Up to {max} characters, and every term has to appear in the same record. Enter jumps to the first result, Escape clears.',
        '最多 {max} 个字符，且每个词都必须出现在同一条记录中。按 Enter 跳到第一条结果，按 Esc 清空。',
      ),
      clear: localized('Clear search', '清空搜索'),
      kindLegend: localized('Source kind', '来源类型'),
      kindAll: localized('All', '全部'),
      kindBundled: localized('Bundled', '内置'),
      kindImported: localized('Imported', '导入'),
      scopeLabel: localized('Limit to one source', '限定单个来源'),
      scopeAll: localized('Every source', '全部来源'),
      scopeBundledGroup: localized('Bundled datasets', '内置数据集'),
      scopeImportedGroup: localized('Imported files', '导入的文件'),
      statusIdle: localized(
        'Ready to search. Bundled excerpts: {n}. Imported sections: {m}.',
        '可以开始搜索。内置摘录：{n} 段。导入小节：{m} 个。',
      ),
      statusResults: localized('Matches: {n}.', '匹配：{n} 条。'),
      statusTruncated: localized('Matches: {total}. Showing the first {n}.', '匹配：{total} 条，显示前 {n} 条。'),
      emptyIdle: localized(
        'Type a word or phrase above to search source names, section headings, locators, question prompts, and excerpt text.',
        '在上方输入词或短语，可搜索来源名称、小节标题、定位、题目内容和摘录正文。',
      ),
      emptyNoResults: localized(
        'Nothing matched “{query}”. Try one word, or widen the source kind.',
        '没有内容匹配“{query}”。可以只用一个词，或放宽来源类型。',
      ),
      emptyNoImported: localized(
        'No imported files yet, so this filter has nothing to search. Import a Markdown or text file, or switch back to All for the bundled excerpts.',
        '还没有导入文件，此筛选没有可搜索的内容。可以导入一个 Markdown 或文本文件，或切回“全部”以搜索内置摘录。',
      ),
      reasonLabel: localized('Matched in', '匹配位置'),
      reasonName: localized('source name', '来源名称'),
      reasonHeading: localized('section heading', '小节标题'),
      reasonLocator: localized('locator', '定位'),
      reasonPrompt: localized('question prompt', '题目内容'),
      reasonExcerpt: localized('excerpt text', '摘录正文'),
      badgeBundled: localized('Bundled evidence', '内置证据'),
      badgeImported: localized('Imported text', '导入文本'),
      noteBundled: localized(
        'Checked excerpt behind a bundled question.',
        '支撑内置题目的已校验摘录。',
      ),
      noteImported: localized(
        'Text from a file in this browser. Not a verified claim.',
        '来自此浏览器中某个文件的文本，不是经过核实的结论。',
      ),
      headingLabel: localized('Section', '小节'),
      openBundled: localized('Practice this dataset', '练习这套数据集'),
      openImported: localized('Show in imported sources', '在导入来源中查看'),
      announceCleared: localized('Search cleared.', '已清空搜索。'),
      announceOpened: localized('Showing {name} in the imported sources list.', '已在导入来源列表中显示 {name}。'),
    },
  },

  profile: {
    eyebrow: localized('Profile', '我的'),
    title: localized('Your local demo state', '你的本地演示状态'),
    body: localized(
      'Everything on this page comes from this browser. Clearing site data removes it.',
      '本页所有内容都来自当前浏览器，清除站点数据即会一并删除。',
    ),
    storageTitle: localized('Stored in this browser', '保存在此浏览器'),
    storageBody: localized(
      'Answers and the current question index are kept in localStorage so a reload resumes the same place.',
      '答案和当前题号保存在 localStorage 中，重新加载后会回到同一位置。',
    ),
    inventoryTitle: localized('What this browser is holding', '此浏览器保存了哪些数据'),
    inventoryBody: localized(
      'Every key Anchor writes on this origin, with its measured size. Nothing else on this page is read, and nothing leaves the browser.',
      '这里列出 Anchor 在此来源写入的每个键及其实测大小。本页不会读取其他数据，也不会把任何内容发送出去。',
    ),
    inventoryEmpty: localized('Not written yet', '尚未写入'),
    inventoryProgress: localized('Quiz progress', '答题进度'),
    inventoryLibrary: localized('Imported sources', '导入的资料'),
    inventoryAgent: localized('Guided Agent session', '引导式 Agent 会话'),
    inventoryTheme: localized('Theme preference', '主题偏好'),
    inventoryLocale: localized('Language preference', '语言偏好'),
    inventoryTotal: localized('{size} across {keys} stored keys.', '共 {keys} 个已存储的键，合计 {size}。'),
    inventoryAnswers: localized('{count} submitted answers', '{count} 个已提交答案'),
    inventorySources: localized('{count} sources, {sections} sections', '{count} 个来源，{sections} 个小节'),
    inventoryReflections: localized('{count} reflections written', '已写下 {count} 条回顾'),
    accountTitle: localized('No account involved', '不涉及账号'),
    accountBody: localized(
      'There is no sign-in, no profile sync, and no server holding your answers.',
      '这里没有登录、没有资料同步，也没有服务端保存你的答案。',
    ),
    themeTitle: localized('Appearance', '外观'),
    themeBody: localized(
      'Choose a light or dark theme. The choice is stored in this browser and applied on the next visit; before you choose, Anchor follows your system setting.',
      '可以选择浅色或深色主题。选择会保存在此浏览器并在下次访问时应用；在你做出选择前，Anchor 会跟随系统设置。',
    ),
    themeLabel: localized('Theme', '主题'),
    themeLight: localized('Light', '浅色'),
    themeDark: localized('Dark', '深色'),
    themeAnnounceLight: localized('Light theme applied.', '已应用浅色主题。'),
    themeAnnounceDark: localized('Dark theme applied.', '已应用深色主题。'),
    languageTitle: localized('Language', '语言'),
    languageBody: localized(
      'Switch between English and 中文 with the toggle in the header. The choice is remembered locally.',
      '使用页眉的切换按钮在 English 与中文之间切换，选择会保存在本地。',
    ),
    backupTitle: localized('Backup this browser', '备份此浏览器'),
    backupBody: localized(
      'Export a JSON file holding your quiz progress, imported sources, and guided session. The file is written by your browser to your own download folder — it is never uploaded, and it contains no keys, tokens, or account details.',
      '可以导出一个 JSON 文件，包含你的答题进度、导入的资料与引导式会话。该文件由浏览器写入你自己的下载目录，不会被上传，也不包含任何密钥、令牌或账号信息。',
    ),
    backupExport: localized('Export backup', '导出备份'),
    backupExportEmpty: localized(
      'Nothing is stored yet, so an export would be empty. Answer a question or import a file first.',
      '目前尚无数据，导出会是空的。请先答一道题或导入一个文件。',
    ),
    backupExported: localized('Backup exported as {name}.', '备份已导出为 {name}。'),
    backupExportFailed: localized(
      'This browser blocked the download. Check its download settings and try again.',
      '浏览器阻止了此次下载。请检查下载设置后重试。',
    ),
    restoreTitle: localized('Restore from a backup file', '从备份文件恢复'),
    restoreBody: localized(
      'Choose a backup you exported earlier. Anchor checks it and shows you what it contains; nothing is replaced until you confirm.',
      '选择你此前导出的备份文件。Anchor 会先校验并展示其中的内容，在你确认之前不会替换任何数据。',
    ),
    restorePick: localized('Choose backup file', '选择备份文件'),
    restoreReviewTitle: localized('Review before replacing', '替换前请先确认'),
    restoreReviewLead: localized(
      'Checked in this browser. Confirm to replace the local state below, or cancel to keep what you have now.',
      '已在此浏览器中完成校验。确认后将替换下列本地数据，取消则保留当前内容。',
    ),
    restoreFile: localized('File', '文件'),
    restoreSize: localized('Size', '大小'),
    restoreSchema: localized('Schema version', '架构版本'),
    restoreExportedAt: localized('Exported', '导出时间'),
    restoreExportedUnknown: localized('Not recorded', '未记录'),
    restoreIncludes: localized('Included in this backup', '此备份包含的内容'),
    restoreSectionProgress: localized('Quiz progress — {count} submitted answers', '答题进度 — {count} 个已提交答案'),
    restoreSectionLibrary: localized('Imported sources — {count} sources, {sections} sections', '导入的资料 — {count} 个来源，{sections} 个小节'),
    restoreSectionAgent: localized('Guided Agent session — {count} reflections', '引导式 Agent 会话 — {count} 条回顾'),
    restoreDropped: localized(
      'Anchor could not read these sections and will clear them instead of restoring them: {sections}.',
      'Anchor 无法读取以下部分，将清除而不是恢复它们：{sections}。',
    ),
    restoreWarning: localized(
      'Replacing overwrites the quiz progress, imported sources, and guided session already in this browser. This cannot be undone.',
      '替换会覆盖此浏览器中现有的答题进度、导入资料与引导式会话，且无法撤销。',
    ),
    restoreConfirm: localized('Replace local data', '替换本地数据'),
    restoreCancel: localized('Cancel', '取消'),
    restoreReady: localized('Backup {name} checked. Review it, then confirm to replace local data.', '备份 {name} 已校验。请查看后确认替换本地数据。'),
    restoreDone: localized('Local data replaced from {name}.', '已从 {name} 替换本地数据。'),
    restoreCancelled: localized('Restore cancelled. Nothing was changed.', '已取消恢复，未更改任何内容。'),
    restoreErrorType: localized('Choose a .json backup file exported from this demo.', '请选择由本演示导出的 .json 备份文件。'),
    restoreErrorEmpty: localized('That file is empty.', '该文件是空的。'),
    restoreErrorSize: localized('That file is {size}. A backup has to stay under {kb} KB.', '该文件为 {size}，备份必须小于 {kb} KB。'),
    restoreErrorJson: localized('That file is not valid JSON.', '该文件不是有效的 JSON。'),
    restoreErrorFormat: localized('That JSON file is not an Anchor backup.', '该 JSON 文件不是 Anchor 备份。'),
    restoreErrorVersion: localized('That backup was written by a different version of this demo and cannot be restored.', '该备份由本演示的其他版本写入，无法恢复。'),
    restoreErrorShape: localized('That backup has no sections this build can restore.', '该备份不包含此版本可恢复的内容。'),
    restoreErrorRead: localized('This browser could not read that file.', '浏览器无法读取该文件。'),
    controlsTitle: localized('Delete local data', '删除本地数据'),
    controlsBody: localized(
      'Each action is scoped and confirmed separately, so clearing one thing never takes the others with it.',
      '每项操作都有独立范围并单独确认，清除其中一项不会影响其他内容。',
    ),
    resetTitle: localized('Reset quiz progress', '重置答题进度'),
    resetBody: localized(
      'Clears answers and scores for all bundled datasets. Imported sources and the guided session are kept.',
      '清除所有内置数据集的答案与得分。导入的资料与引导式会话会保留。',
    ),
    resetConfirm: localized('Reset quiz progress in this browser? Imported sources and the guided session stay.', '要重置此浏览器中的答题进度吗？导入的资料与引导式会话将保留。'),
    resetAction: localized('Reset progress', '重置进度'),
    resetDone: localized('Local demo progress was reset.', '本地演示进度已重置。'),
    agentResetTitle: localized('Clear the guided Agent session', '清除引导式 Agent 会话'),
    agentResetBody: localized(
      'Deletes the scripted session and the reflections you wrote in it. Quiz progress and imported sources are kept.',
      '删除脚本化会话以及你在其中写下的回顾。答题进度与导入的资料会保留。',
    ),
    agentResetConfirm: localized('Delete the guided session and its reflections? Quiz progress and imported sources stay.', '要删除引导式会话及其回顾吗？答题进度与导入的资料将保留。'),
    agentResetAction: localized('Clear session', '清除会话'),
    agentResetDone: localized('Guided Agent session cleared.', '引导式 Agent 会话已清除。'),
    libraryResetTitle: localized('Delete imported sources', '删除导入的资料'),
    libraryResetBody: localized(
      'Removes every file you read into this browser. Quiz progress and the guided session are kept.',
      '移除你读入此浏览器的所有文件。答题进度与引导式会话会保留。',
    ),
    libraryResetConfirm: localized('Delete all imported sources from this browser? Quiz progress and the guided session stay.', '要从此浏览器删除所有导入的资料吗？答题进度与引导式会话将保留。'),
    libraryResetAction: localized('Delete sources', '删除资料'),
    libraryResetDone: localized('Imported sources deleted.', '导入的资料已删除。'),
    clearAllTitle: localized('Clear all Anchor data in this browser', '清除此浏览器中的全部 Anchor 数据'),
    clearAllBody: localized(
      'Removes every key listed above — progress, imported sources, the guided session, and your theme and language choices. Only Anchor keys are touched; other sites and other data on this origin are left alone.',
      '移除上方列出的所有键：进度、导入的资料、引导式会话，以及你的主题与语言选择。仅涉及 Anchor 的键，不会影响其他网站或此来源的其他数据。',
    ),
    clearAllConfirm: localized('Delete every Anchor key in this browser, including your theme and language choices? This cannot be undone.', '要删除此浏览器中所有 Anchor 的键（含主题与语言选择）吗？此操作无法撤销。'),
    clearAllAction: localized('Clear all local data', '清除全部本地数据'),
    clearAllDone: localized('All Anchor data in this browser was cleared.', '此浏览器中的全部 Anchor 数据已清除。'),
    keepAction: localized('Keep it', '保留'),
    nativeTitle: localized('Part of the Android app', '属于 Android 应用'),
    nativeStreak: localized('Streaks, badges, and achievement history', '连续学习、成就徽章与历史记录'),
    nativeSettings: localized('Model configuration and app settings', '模型配置与应用设置'),
    nativeBackup: localized(
      'Backup and restore of the full learning database, including schedules and generated questions',
      '完整学习数据库的备份与恢复，包含复习计划与生成的题目',
    ),
  },

  sources: {
    eyebrow: localized('Import', '导入'),
    title: localized('Bringing in your own material', '导入你自己的资料'),
    body: localized(
      'Read a Markdown or text file into this browser to inspect how Anchor splits it into sections. The file is never uploaded, and question generation stays in the Android app.',
      '可以把 Markdown 或纯文本文件读入当前浏览器，查看 Anchor 如何把它切分成小节。文件不会被上传，题目生成仍然只在 Android 应用中进行。',
    ),
    nativeTitle: localized('How import works in the Android app', 'Android 应用中的导入方式'),
    nativeBody: localized(
      'Pick a file, paste text, or share content into the app. Import keeps document headings and code structure so citations can point back to a stable location.',
      '可以选择文件、粘贴文本，或把内容分享到应用中。导入会保留文档标题与代码结构，让引用能指向稳定位置。',
    ),
    loopTitle: localized('What happens after import', '导入之后会发生什么'),
    productAction: localized('See the Android workflow', '查看 Android 工作流'),
    demoAction: localized('Use the bundled datasets', '使用内置数据集'),
  },

  importer: {
    pickTitle: localized('Read a file in this browser', '在此浏览器中读取文件'),
    pickBody: localized(
      'Choose a Markdown or plain-text file, or drop one here. It is parsed by this page and kept in this browser only.',
      '选择 Markdown 或纯文本文件，也可以直接拖放到这里。文件由本页解析，并且只保存在当前浏览器中。',
    ),
    pickAction: localized('Choose a file', '选择文件'),
    dropHint: localized('Drop a file here', '把文件拖放到这里'),
    limits: localized(
      'Accepted: .md, .markdown, .txt. Up to {kb} KB per file, {sources} sources kept in this browser.',
      '支持 .md、.markdown、.txt，单个文件最大 {kb} KB，此浏览器最多保存 {sources} 个来源。',
    ),
    reviewTitle: localized('Review before saving', '保存前先检查'),
    reviewBody: localized(
      'Nothing is stored yet. Check the sections below, then confirm to keep this source in the browser library.',
      '目前还没有保存任何内容。请检查下面的小节，确认后才会把这个来源加入浏览器知识库。',
    ),
    reviewSections: localized('{n} sections', '{n} 个小节'),
    metaFile: localized('File', '文件'),
    metaSize: localized('Size', '大小'),
    metaSections: localized('Sections', '小节'),
    reviewTruncated: localized(
      'Only the first {n} sections are kept, and long passages are shortened for browser storage.',
      '只保留前 {n} 个小节，过长的段落会为浏览器存储而截断。',
    ),
    confirmAction: localized('Save to browser library', '保存到浏览器知识库'),
    cancelAction: localized('Discard', '放弃'),
    noAiTitle: localized('No questions are generated here', '这里不会生成题目'),
    noAiBody: localized(
      'This browser leaf only reads and splits the file. AI concept extraction, question generation, and citation verification run in the Android app, so no exercises are created from your file here.',
      '浏览器端只负责读取和切分文件。AI 概念提取、题目生成与引用校验都在 Android 应用中完成，因此这里不会用你的文件生成任何练习。',
    ),
    savedTitle: localized('Saved in this browser', '已保存到此浏览器'),
    savedBody: localized(
      '{name} is in your browser library with {n} sections.',
      '{name} 已加入浏览器知识库，包含 {n} 个小节。',
    ),
    savedAction: localized('Open the library', '打开知识库'),
    announceSaved: localized(
      '{name} was saved to the browser library with {n} sections.',
      '已把 {name} 保存到浏览器知识库，包含 {n} 个小节。',
    ),
    announceReview: localized(
      '{name} is ready to review. Confirm to save it in this browser.',
      '{name} 已准备好检查，确认后会保存在此浏览器中。',
    ),
    errorType: localized(
      'That file type is not supported. Choose a .md, .markdown, or .txt file.',
      '不支持这种文件类型，请选择 .md、.markdown 或 .txt 文件。',
    ),
    errorSize: localized(
      'That file is {size} and the limit is {kb} KB. Choose a smaller file or split it.',
      '该文件为 {size}，上限是 {kb} KB。请选择更小的文件或先拆分。',
    ),
    errorEmpty: localized(
      'That file has no readable text, so there is nothing to inspect.',
      '该文件没有可读文本，没有内容可以检查。',
    ),
    errorBinary: localized(
      'That file does not look like text. Choose a Markdown or plain-text file.',
      '该文件看起来不是文本，请选择 Markdown 或纯文本文件。',
    ),
    errorRead: localized(
      'That file could not be read in this browser. Try another file.',
      '此浏览器无法读取该文件，请换一个文件。',
    ),
    errorFull: localized(
      'The browser library already holds {sources} sources. Remove one before importing another.',
      '浏览器知识库已保存 {sources} 个来源，请先删除一个再导入。',
    ),
    errorStorage: localized(
      'This browser refused to store the source, usually because site storage is full or blocked.',
      '此浏览器拒绝保存该来源，通常是站点存储已满或被禁用。',
    ),
  },

  localLibrary: {
    title: localized('Imported in this browser', '在此浏览器中导入'),
    body: localized(
      'Files you read into this page. They stay in localStorage on this device and are never uploaded.',
      '你读入本页的文件会保存在此设备的 localStorage 中，不会上传。',
    ),
    empty: localized(
      'No imported sources yet. Reading a file adds it here without leaving the browser.',
      '还没有导入的来源。读取一个文件即可添加到这里，全程不离开浏览器。',
    ),
    emptyAction: localized('Import a file', '导入文件'),
    sectionsLabel: localized('{n} sections', '{n} 个小节'),
    importedAt: localized('Imported {when}', '导入于 {when}'),
    expandAction: localized('Show sections', '展开小节'),
    collapseAction: localized('Hide sections', '收起小节'),
    removeAction: localized('Remove', '删除'),
    removeConfirmTitle: localized('Remove {name}?', '删除 {name}？'),
    removeConfirmBody: localized(
      'This deletes the stored sections for this source only. Bundled datasets and quiz progress are untouched.',
      '这只会删除该来源保存的小节，内置数据集与答题进度不受影响。',
    ),
    removeConfirmAction: localized('Delete this source', '确认删除'),
    removeCancelAction: localized('Keep it', '保留'),
    announceRemoved: localized('{name} was removed from the browser library.', '已从浏览器知识库中删除 {name}。'),
    resetTitle: localized('Clear imported sources', '清空导入的来源'),
    resetBody: localized(
      'Removes every imported source from this browser. Quiz progress uses separate storage and is not affected.',
      '删除此浏览器中的全部导入来源。答题进度使用独立存储，不受影响。',
    ),
    resetAction: localized('Clear all imported sources', '清空全部导入来源'),
    resetConfirmAction: localized('Delete all {n} sources', '删除全部 {n} 个来源'),
    announceReset: localized('All imported sources were removed from this browser.', '已删除此浏览器中的全部导入来源。'),
    noAi: localized(
      'Imported sections are shown exactly as they appear in the file. No summary, question, or citation is generated from them in the browser.',
      '导入的小节按文件原文展示，浏览器不会基于它们生成摘要、题目或引用。',
    ),
    kindHeading: localized('Heading section', '标题小节'),
    kindPreamble: localized('Before the first heading', '首个标题之前'),
    kindDocument: localized('Whole document', '整篇文档'),
  },
};

export function formatCount(template, values) {
  return Object.entries(values).reduce(
    (text, [key, value]) => text.replaceAll(`{${key}}`, String(value)),
    String(template ?? ''),
  );
}

/**
 * Flattens bundled citations into a per-dataset source index for the Library surface.
 * Excerpts stay grouped by dataset and keep the question they explain.
 */
export function collectSources(datasets = DATASETS) {
  return datasets.map((dataset) => ({
    id: dataset.id,
    mark: dataset.mark,
    title: dataset.title,
    excerpts: dataset.questions.flatMap((question) =>
      question.citations.map((citation) => ({
        locator: citation.locator,
        excerpt: citation.excerpt,
        questionId: question.id,
        prompt: question.prompt,
      })),
    ),
  }));
}

export function countSources(datasets = DATASETS) {
  return collectSources(datasets).reduce((total, group) => total + group.excerpts.length, 0);
}

export function countQuestions(datasets = DATASETS) {
  return datasets.reduce((total, dataset) => total + dataset.questions.length, 0);
}

export function textFor(value, locale) {
  return value?.[locale] ?? value?.en ?? '';
}

export function getDataset(datasetId) {
  return DATASETS.find((dataset) => dataset.id === datasetId) ?? null;
}

function collapseWhitespace(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim();
}

/** Shortens a passage for browser storage, preferring a word boundary when the text has one. */
export function truncateExcerpt(value, maxChars = LOCAL_IMPORT_LIMITS.maxExcerptChars) {
  const text = collapseWhitespace(value);
  if (text.length <= maxChars) return { text, truncated: false };
  const slice = text.slice(0, maxChars);
  const boundary = slice.lastIndexOf(' ');
  const kept = boundary > maxChars * 0.6 ? slice.slice(0, boundary) : slice;
  return { text: `${kept.trimEnd()}…`, truncated: true };
}

/** Stable, filesystem-free anchor for a heading. Keeps CJK letters so locators stay readable. */
export function slugifyHeading(value) {
  return collapseWhitespace(value)
    .toLowerCase()
    .replace(/[^\p{Letter}\p{Number}]+/gu, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48);
}

/**
 * Splits Markdown or plain text into deterministic, inspectable sections.
 *
 * Headings outside fenced code blocks start a new section. Text before the first heading becomes a
 * `preamble` section, and a document with no headings at all yields a single `document` section, so
 * every accepted file has something to review. Nothing is invented: each excerpt is file text.
 */
export function extractSections(text, limits = LOCAL_IMPORT_LIMITS) {
  const lines = String(text ?? '').replace(/\r\n?/g, '\n').split('\n');
  const raw = [];
  let current = null;
  let fence = null;

  const begin = (heading, level, line) => {
    current = { heading, level, line, body: [] };
    raw.push(current);
  };

  lines.forEach((line, index) => {
    const fenceMatch = line.match(/^ {0,3}(`{3,}|~{3,})/);
    if (fenceMatch) {
      const marker = fenceMatch[1][0];
      if (fence === null) fence = marker;
      else if (fence === marker) fence = null;
    } else if (fence === null) {
      const heading = line.match(/^(#{1,6})\s+(.*\S)\s*$/);
      if (heading) {
        begin(heading[2].replace(/\s+#+$/, '').trim(), heading[1].length, index + 1);
        return;
      }
    }
    if (!current) begin(null, 0, index + 1);
    current.body.push(line);
  });

  const hasHeading = raw.some((entry) => entry.heading !== null);
  const sections = [];
  let truncated = false;

  for (const entry of raw) {
    const body = entry.body.join('\n');
    if (entry.heading === null && !collapseWhitespace(body)) continue;
    if (sections.length >= limits.maxSections) {
      truncated = true;
      break;
    }
    const excerpt = truncateExcerpt(body, limits.maxExcerptChars);
    if (excerpt.truncated) truncated = true;
    sections.push({
      heading: entry.heading,
      level: entry.level,
      line: entry.line,
      kind: entry.heading !== null ? 'heading' : hasHeading ? 'preamble' : 'document',
      excerpt: excerpt.text,
    });
  }

  return { sections, truncated };
}

/** Honest, pre-read validation from File metadata alone: extension, emptiness, size, and capacity. */
export function validateImportCandidate(file, { limits = LOCAL_IMPORT_LIMITS, sourceCount = 0 } = {}) {
  const name = String(file?.name ?? '').trim();
  const lower = name.toLowerCase();
  if (!name || !limits.extensions.some((extension) => lower.endsWith(extension))) return { ok: false, reason: 'type' };
  const size = Number(file?.size);
  if (!Number.isFinite(size) || size <= 0) return { ok: false, reason: 'empty' };
  if (size > limits.maxBytes) return { ok: false, reason: 'size' };
  if (sourceCount >= limits.maxSources) return { ok: false, reason: 'full' };
  return { ok: true, reason: null };
}

/** Rejects files that carry a text extension but decode as binary. */
export function looksBinary(text) {
  const sample = String(text ?? '').slice(0, 4096);
  if (sample.includes('\u0000')) return true;
  const suspicious = (sample.match(/[\u0001-\u0008\u000e-\u001f\ufffd]/g) ?? []).length;
  return suspicious > Math.max(4, sample.length * 0.02);
}

function localSourceId(name, importedAt) {
  const base = slugifyHeading(String(name ?? '').replace(/\.[^.]+$/, '')) || 'source';
  return `${base}-${Math.round(Number(importedAt) || 0).toString(36)}`;
}

/** Builds the versioned record persisted for one imported file. */
export function createLocalSource(
  { name, size, text, importedAt = Date.now(), existingIds = [] },
  limits = LOCAL_IMPORT_LIMITS,
) {
  const { sections, truncated } = extractSections(text, limits);
  const taken = new Set(existingIds);
  const base = localSourceId(name, importedAt);
  let id = base;
  for (let suffix = 2; taken.has(id); suffix += 1) id = `${base}-${suffix}`;
  return {
    id,
    name: String(name ?? '').trim(),
    bytes: Math.max(0, Math.round(Number(size) || 0)),
    importedAt: Math.round(Number(importedAt) || 0),
    sectionCount: sections.length,
    truncated,
    sections,
  };
}

export function createEmptyLibrary() {
  return { version: LIBRARY_VERSION, sources: [] };
}

/**
 * Accepts only records this build understands. Stale versions, wrong shapes, duplicate ids, and
 * over-long excerpts are dropped instead of thrown, so damaged storage degrades to an empty library.
 */
export function normalizeLocalLibrary(candidate, limits = LOCAL_IMPORT_LIMITS) {
  if (!candidate || typeof candidate !== 'object' || Array.isArray(candidate)) return createEmptyLibrary();
  if (candidate.version !== LIBRARY_VERSION || !Array.isArray(candidate.sources)) return createEmptyLibrary();

  const library = createEmptyLibrary();
  const seen = new Set();

  for (const source of candidate.sources) {
    if (library.sources.length >= limits.maxSources) break;
    if (!source || typeof source !== 'object') continue;
    const id = typeof source.id === 'string' ? source.id.trim() : '';
    const name = typeof source.name === 'string' ? source.name.trim() : '';
    if (!id || !name || seen.has(id)) continue;

    const sections = [];
    for (const section of (Array.isArray(source.sections) ? source.sections : []).slice(0, limits.maxSections)) {
      if (!section || typeof section !== 'object') continue;
      const heading = typeof section.heading === 'string' && section.heading.trim()
        ? collapseWhitespace(section.heading)
        : null;
      const excerpt = typeof section.excerpt === 'string'
        ? truncateExcerpt(section.excerpt, limits.maxExcerptChars).text
        : '';
      if (!heading && !excerpt) continue;
      sections.push({
        heading,
        level: Number.isInteger(section.level) ? Math.min(Math.max(section.level, 0), 6) : 0,
        line: Number.isInteger(section.line) && section.line > 0 ? section.line : 1,
        kind: ['heading', 'preamble', 'document'].includes(section.kind)
          ? section.kind
          : heading ? 'heading' : 'document',
        excerpt,
      });
    }
    if (!sections.length) continue;

    seen.add(id);
    library.sources.push({
      id,
      name,
      bytes: Number.isFinite(Number(source.bytes)) && Number(source.bytes) > 0 ? Math.round(Number(source.bytes)) : 0,
      importedAt: Number.isFinite(Number(source.importedAt)) && Number(source.importedAt) > 0
        ? Math.round(Number(source.importedAt))
        : 0,
      sectionCount: sections.length,
      truncated: source.truncated === true,
      sections,
    });
  }

  return library;
}

/**
 * Derives the fixed turn script for one guided Agent session.
 *
 * Every field is a reference into the bundled dataset: the question prompt, its first citation, its
 * tutor hints, and its explanation. Nothing here is generated, so a dataset always yields the same
 * turns in the same order and the surface can say so honestly.
 */
export function buildAgentScript(dataset) {
  if (!dataset || !Array.isArray(dataset.questions)) return [];
  return dataset.questions.map((question, index) => ({
    index,
    questionId: question.id,
    prompt: question.prompt,
    focus: question.citations[0]?.locator ?? '',
    citation: question.citations[0] ?? null,
    hints: question.tutorHints ?? [],
    explanation: question.explanation,
  }));
}

export function createAgentSession(datasetId) {
  return {
    version: AGENT_SESSION_VERSION,
    datasetId,
    turnIndex: 0,
    completed: false,
    reflections: {},
    hints: {},
    startedAt: 0,
  };
}

/** Trims a reflection to the stored ceiling without collapsing the spacing the learner typed. */
export function clampReflection(value, limits = AGENT_SESSION_LIMITS) {
  return String(value ?? '').slice(0, limits.maxReflectionChars);
}

/**
 * Accepts only a session this build can replay. A stale version, an unknown dataset, or a shape that
 * no longer matches returns `null` so the surface falls back to its start panel instead of throwing.
 *
 * Question ids that have disappeared from the dataset are dropped, `turnIndex` is clamped to the turn
 * after the last answered one, and `completed` requires a reflection on every turn — so a tampered or
 * partially written record resumes at a position the learner could actually have reached.
 */
export function normalizeAgentSession(candidate, resolveDataset = getDataset, limits = AGENT_SESSION_LIMITS) {
  if (!candidate || typeof candidate !== 'object' || Array.isArray(candidate)) return null;
  if (candidate.version !== AGENT_SESSION_VERSION) return null;
  const dataset = resolveDataset(candidate.datasetId);
  if (!dataset) return null;

  const script = buildAgentScript(dataset);
  if (!script.length) return null;

  const session = createAgentSession(dataset.id);
  session.startedAt = Number.isFinite(Number(candidate.startedAt)) && Number(candidate.startedAt) > 0
    ? Math.round(Number(candidate.startedAt))
    : 0;

  for (const turn of script) {
    const reflection = candidate.reflections?.[turn.questionId];
    if (typeof reflection === 'string' && reflection.trim()) {
      session.reflections[turn.questionId] = clampReflection(reflection, limits);
    }
    const revealed = candidate.hints?.[turn.questionId];
    if (Number.isInteger(revealed) && revealed > 0) {
      session.hints[turn.questionId] = Math.min(revealed, turn.hints.length);
    }
  }

  const answered = script.filter((turn) => session.reflections[turn.questionId]).length;
  const ceiling = Math.min(answered, script.length - 1);
  session.turnIndex = Number.isInteger(candidate.turnIndex)
    ? Math.min(Math.max(candidate.turnIndex, 0), ceiling)
    : ceiling;
  session.completed = candidate.completed === true && answered === script.length;
  return session;
}

/** Number of turns the learner has actually written a reflection for. */
export function agentReflectionCount(session, script) {
  if (!session || !Array.isArray(script)) return 0;
  return script.filter((turn) => Boolean(session.reflections?.[turn.questionId])).length;
}

/**
 * Progress as a decile bucket. The Content-Security-Policy blocks inline styles, so the width has to
 * come from a class rather than a computed `style` attribute.
 */
export function agentProgressFill(done, total) {
  if (!Number.isFinite(total) || total <= 0) return 0;
  const ratio = Math.min(Math.max(Number(done) || 0, 0), total) / total;
  return Math.round(ratio * 10) * 10;
}

/** Locator shown next to an imported excerpt. Derived from the file name, never from a model. */
export function sectionLocator(source, section) {
  const base = String(source?.name ?? '').trim() || 'source';
  const anchor = section?.heading ? slugifyHeading(section.heading) : '';
  return anchor ? `${base}#${anchor}` : `${base}:L${section?.line ?? 1}`;
}

/*
 * Library search.
 *
 * The index is a plain array rebuilt from the records already on the surface: bundled citations and
 * imported file sections. Matching is literal substring matching over folded text, so every hit can be
 * explained by naming the field it landed in. There is no embedding, no scoring model, and no request.
 */

export const LIBRARY_SEARCH_LIMITS = {
  maxQueryChars: 80,
  maxTerms: 8,
  maxResults: 30,
};

export const LIBRARY_SEARCH_KINDS = ['all', 'bundled', 'imported'];

/**
 * Field order is the whole ranking rule: a hit on what a record *is* outranks a hit somewhere in its
 * body text. Ties fall back to the earliest match offset, then to index order, so results are stable.
 */
export const LIBRARY_SEARCH_FIELDS = ['name', 'heading', 'locator', 'prompt', 'excerpt'];

/**
 * Folds text for comparison. NFKC so full-width and half-width forms match, lowercase for
 * case-insensitive Latin, and collapsed whitespace so a line break in a file cannot hide a phrase.
 * Chinese has no case and no word spacing, so one fold serves both languages without a locale branch.
 */
export function foldSearchText(value) {
  return collapseWhitespace(value).normalize('NFKC').toLowerCase();
}

/** Caps and collapses a query for the address bar and for matching. The field keeps what was typed. */
export function clampLibraryQuery(value, limits = LIBRARY_SEARCH_LIMITS) {
  return collapseWhitespace(value).slice(0, limits.maxQueryChars);
}

/**
 * Splits a query into the terms a record has to contain. Whitespace separates Latin words; a run of
 * Chinese stays whole, because splitting it per character would match almost everything.
 */
export function librarySearchTerms(query, limits = LIBRARY_SEARCH_LIMITS) {
  const folded = clampLibraryQuery(foldSearchText(query), limits);
  const terms = [];
  for (const term of folded.split(' ')) {
    if (!term || terms.includes(term)) continue;
    terms.push(term);
    if (terms.length >= limits.maxTerms) break;
  }
  return terms;
}

function searchField(field, value) {
  const text = collapseWhitespace(value);
  return text ? { field, text, folded: foldSearchText(text) } : null;
}

/**
 * One flat record per searchable passage. `kind` keeps bundled evidence and imported file text apart all
 * the way to the renderer, so the surface never has to guess which one it is holding.
 */
export function buildLibraryIndex({ datasets = DATASETS, library = null, locale = 'en' } = {}) {
  const records = [];

  collectSources(datasets).forEach((group) => {
    const scopeName = textFor(group.title, locale);
    group.excerpts.forEach((entry, index) => {
      const prompt = textFor(entry.prompt, locale);
      const excerpt = textFor(entry.excerpt, locale);
      records.push({
        id: `bundled:${group.id}:${entry.questionId}:${index}`,
        kind: 'bundled',
        scope: `bundled:${group.id}`,
        scopeId: group.id,
        scopeName,
        mark: group.mark,
        locator: entry.locator,
        detail: prompt,
        text: excerpt,
        sectionIndex: null,
        fields: [
          searchField('name', scopeName),
          searchField('locator', entry.locator),
          searchField('prompt', prompt),
          searchField('excerpt', excerpt),
        ].filter(Boolean),
      });
    });
  });

  // Defensive rather than trusting: this index is built straight from browser storage on every render.
  const sources = Array.isArray(library?.sources) ? library.sources : [];
  sources.forEach((source) => {
    const sections = Array.isArray(source?.sections) ? source.sections : [];
    const name = collapseWhitespace(source?.name);
    sections.forEach((section, sectionIndex) => {
      const locator = sectionLocator(source, section ?? {});
      const heading = collapseWhitespace(section?.heading);
      const excerpt = collapseWhitespace(section?.excerpt);
      records.push({
        id: `imported:${source?.id ?? sectionIndex}:${sectionIndex}`,
        kind: 'imported',
        scope: `imported:${source?.id ?? ''}`,
        scopeId: String(source?.id ?? ''),
        scopeName: name,
        mark: '',
        locator,
        detail: heading,
        text: excerpt,
        sectionIndex,
        fields: [
          searchField('name', name),
          searchField('heading', heading),
          searchField('locator', locator),
          searchField('excerpt', excerpt),
        ].filter(Boolean),
      });
    });
  });

  return records;
}

/** Options for the scope filter, in the order the surface lists them. */
export function librarySearchScopes({ datasets = DATASETS, library = null, locale = 'en' } = {}) {
  const sources = Array.isArray(library?.sources) ? library.sources : [];
  return [
    ...collectSources(datasets).map((group) => ({
      value: `bundled:${group.id}`,
      kind: 'bundled',
      label: textFor(group.title, locale),
    })),
    ...sources.map((source) => ({
      value: `imported:${source?.id ?? ''}`,
      kind: 'imported',
      label: collapseWhitespace(source?.name),
    })),
  ];
}

/**
 * Normalizes search state against the scopes that actually exist. A shared link naming a source this
 * browser never imported, or one the kind filter excludes, falls back to every source instead of
 * pinning the surface to a filter with nothing behind it.
 */
export function resolveLibrarySearch(state, scopes = []) {
  const kind = LIBRARY_SEARCH_KINDS.includes(state?.kind) ? state.kind : 'all';
  const requested = collapseWhitespace(state?.scope);
  const match = (Array.isArray(scopes) ? scopes : []).find((entry) => entry?.value === requested);
  return {
    query: clampLibraryQuery(state?.query),
    kind,
    scope: match && (kind === 'all' || match.kind === kind) ? requested : '',
  };
}

/**
 * Every term has to appear somewhere in the same record, which is what makes a two-word query narrow
 * rather than noisy. `reasons` lists the fields that were hit, ordered by field priority, so the
 * surface can state why a record is on screen.
 */
export function searchLibrary(index, query, { kind = 'all', scope = '', limits = LIBRARY_SEARCH_LIMITS } = {}) {
  const terms = librarySearchTerms(query, limits);
  if (!terms.length) return { terms, matches: [], total: 0, truncated: false };

  const hits = [];
  (Array.isArray(index) ? index : []).forEach((record, order) => {
    if (kind !== 'all' && record.kind !== kind) return;
    if (scope && record.scope !== scope) return;

    const reasons = [];
    for (const term of terms) {
      let found = false;
      for (const field of record.fields) {
        if (field.folded.indexOf(term) < 0) continue;
        found = true;
        if (!reasons.includes(field.field)) reasons.push(field.field);
      }
      if (!found) return;
    }

    reasons.sort((a, b) => LIBRARY_SEARCH_FIELDS.indexOf(a) - LIBRARY_SEARCH_FIELDS.indexOf(b));
    const primary = reasons[0];
    const folded = record.fields.find((field) => field.field === primary).folded;
    const offset = Math.min(
      ...terms.map((term) => {
        const at = folded.indexOf(term);
        return at < 0 ? Number.MAX_SAFE_INTEGER : at;
      }),
    );
    hits.push({ record, reasons, primary, rank: LIBRARY_SEARCH_FIELDS.indexOf(primary), offset, order });
  });

  hits.sort((a, b) => a.rank - b.rank || a.offset - b.offset || a.order - b.order);
  return {
    terms,
    total: hits.length,
    truncated: hits.length > limits.maxResults,
    matches: hits.slice(0, limits.maxResults),
  };
}

/**
 * Splits display text into plain and matched runs so the caller can escape every piece and wrap only
 * the matches. Offsets come from the folded copy, so they only line up while folding preserves length;
 * when a rare NFKC or lowercase expansion changes it, the text is returned unmarked rather than marked
 * in the wrong place.
 */
export function highlightSegments(text, terms) {
  const display = collapseWhitespace(text);
  if (!display) return [];
  const list = (Array.isArray(terms) ? terms : []).filter((term) => term);
  const folded = foldSearchText(display);
  if (!list.length || folded.length !== display.length) return [{ text: display, match: false }];

  const marked = new Array(display.length).fill(false);
  for (const term of list) {
    for (let at = folded.indexOf(term); at >= 0; at = folded.indexOf(term, at + 1)) {
      for (let i = at; i < at + term.length; i += 1) marked[i] = true;
    }
  }

  const segments = [];
  let start = 0;
  for (let i = 1; i <= display.length; i += 1) {
    if (i === display.length || marked[i] !== marked[start]) {
      segments.push({ text: display.slice(start, i), match: marked[start] });
      start = i;
    }
  }
  return segments;
}

/*
 * Deck library.
 *
 * The deck surface is a filter over the datasets already on this page. Matching is literal substring
 * matching on the deck name in the language on screen, which is what the Android deck list does, so a
 * result can always be explained by pointing at the title. Every count below is derived from bundled
 * data or from progress stored in this browser: nothing is fetched, ranked, or inferred.
 */

export const DECK_SEARCH_LIMITS = {
  maxQueryChars: 60,
  maxTerms: 6,
};

/** Caps and collapses a deck query. The field keeps what was typed; this is what matching sees. */
export function clampDeckQuery(value, limits = DECK_SEARCH_LIMITS) {
  return clampLibraryQuery(value, limits);
}

/** Same term rules as the library: whitespace splits Latin words, a run of Chinese stays whole. */
export function deckSearchTerms(query, limits = DECK_SEARCH_LIMITS) {
  return librarySearchTerms(query, limits);
}

/**
 * Questions that carry at least one source citation. The Android deck list gates study on its verified
 * question count, so the browser demo derives the same number from bundled data rather than restating
 * the deck size under a second name.
 */
export function verifiedQuestionCount(dataset) {
  const questions = Array.isArray(dataset?.questions) ? dataset.questions : [];
  return questions.filter((question) => Array.isArray(question?.citations) && question.citations.length > 0).length;
}

/**
 * Progress as a decile bucket, for the same reason the agent bar uses one: the deployed CSP blocks
 * inline styles, so a width has to arrive as a class.
 */
export function deckProgressFill(done, total) {
  return agentProgressFill(done, total);
}

/**
 * Everything one deck card shows, resolved in a single pass so the badge, the bar, and the action can
 * never disagree. `answered` and `correct` come from browser-local progress; `total` and `verified` come
 * from bundled data. `action` is a state, not a label: the renderer maps it to text in the active locale.
 */
export function deckCardModel(dataset, { answered = 0, correct = 0, completed = false } = {}) {
  const total = Array.isArray(dataset?.questions) ? dataset.questions.length : 0;
  const verified = verifiedQuestionCount(dataset);
  const seen = Math.min(Math.max(Number(answered) || 0, 0), total);
  const done = completed === true || (total > 0 && seen >= total);
  const percent = total > 0 ? Math.round((seen / total) * 100) : 0;

  // No verified question means nothing to practice, so the card says so instead of offering a start
  // that would open an empty deck. Bundled datasets always have one; an edited dataset might not.
  const action = verified === 0 ? 'pending' : done ? 'review' : seen > 0 ? 'continue' : 'start';
  return {
    id: dataset?.id ?? '',
    mark: dataset?.mark ?? '',
    total,
    verified,
    answered: seen,
    correct: Math.min(Math.max(Number(correct) || 0, 0), total),
    completed: done,
    percent,
    fill: deckProgressFill(seen, total),
    tier: percent >= 100 ? 'complete' : percent >= 50 ? 'progress' : 'start',
    action,
    startable: verified > 0,
  };
}

/**
 * How many answers count as a day's work here. One bundled deck is four questions, so the target is one
 * deck's worth: reachable in a sitting, and honest about the size of the bundled set. It is a fixed
 * local target, not a plan handed down by a scheduler.
 */
export const DAILY_GOAL_QUESTIONS = 4;

/**
 * The device's calendar day as `YYYY-MM-DD`. Local, not UTC: a learner's "today" is the one on their
 * own clock, and this value is only ever compared against another reading from the same device. Returns
 * an empty string for an unusable timestamp, which every caller treats as "no day recorded".
 */
export function localDayStamp(timestamp = Date.now()) {
  const value = Number(timestamp);
  if (!Number.isFinite(value) || value <= 0) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

/**
 * Today's target, derived from progress this browser already holds. The goal is capped by the questions
 * still unanswered, so it can never ask for more than the bundled set can supply: once everything is
 * answered the goal is `exhausted` and the surface points at import instead of showing an impossible bar.
 */
export function dailyGoalModel({ answeredToday = 0, remainingQuestions = 0, target = DAILY_GOAL_QUESTIONS } = {}) {
  const done = Math.max(Math.round(Number(answeredToday) || 0), 0);
  const remaining = Math.max(Math.round(Number(remainingQuestions) || 0), 0);
  const wanted = Math.max(Math.round(Number(target) || 0), 0);

  // Answers already logged today are work that happened, so they always count toward the goal even when
  // they used up the last unanswered question and `remaining` has since dropped to zero.
  const goal = Math.max(Math.min(wanted, done + remaining), done > 0 ? Math.min(done, wanted) : 0);
  const exhausted = remaining === 0;
  const met = goal > 0 && done >= goal;
  return {
    done,
    goal,
    remaining: Math.max(goal - done, 0),
    met,
    exhausted,
    percent: goal > 0 ? Math.min(Math.round((done / goal) * 100), 100) : 0,
    fill: agentProgressFill(Math.min(done, goal), goal),
  };
}

/**
 * Everything Home shows, resolved in one pass from bundled data plus browser-local progress: the four
 * summary numbers, today's goal, one deterministic focus deck, and a plan row for every bundled deck.
 *
 * `focus` is chosen by stored state, never by a schedule: the deck this browser last opened if it still
 * has questions left, else the first unfinished deck in bundled order, else the first startable deck to
 * review. It resolves to `null` only when no deck has a verified question to practice.
 */
export function homeDashboardModel({ datasets = DATASETS, progressFor = () => ({}), answeredToday = 0, activeDatasetId = null } = {}) {
  const list = Array.isArray(datasets) ? datasets : [];
  const rows = list.map((dataset) => {
    const card = deckCardModel(dataset, progressFor(dataset) ?? {});
    return { dataset, ...card, remaining: Math.max(card.total - card.answered, 0) };
  });

  const summary = rows.reduce((totals, row) => ({
    total: totals.total + row.total,
    answered: totals.answered + row.answered,
    correct: totals.correct + row.correct,
    started: totals.started + (row.answered > 0 || row.completed ? 1 : 0),
    decksComplete: totals.decksComplete + (row.completed ? 1 : 0),
  }), { total: 0, answered: 0, correct: 0, started: 0, decksComplete: 0 });
  summary.decks = rows.length;
  summary.remaining = Math.max(summary.total - summary.answered, 0);
  summary.percent = summary.total > 0 ? Math.round((summary.answered / summary.total) * 100) : 0;

  const unfinished = rows.filter((row) => row.startable && !row.completed);
  const focus = unfinished.find((row) => row.id === activeDatasetId)
    ?? unfinished[0]
    ?? rows.find((row) => row.startable)
    ?? null;

  return {
    summary,
    rows,
    focus,
    daily: dailyGoalModel({ answeredToday, remainingQuestions: summary.remaining }),
  };
}

/**
 * Filters datasets by name in one locale. Returns the datasets themselves in bundled order, plus the
 * terms that matched, so the caller can highlight exactly what it searched on. An empty query is not a
 * search: every deck comes back and `terms` is empty, which is how the surface tells idle from no-match.
 */
export function searchDecks(query, { datasets = DATASETS, locale = 'en', limits = DECK_SEARCH_LIMITS } = {}) {
  const list = Array.isArray(datasets) ? datasets : [];
  const terms = deckSearchTerms(query, limits);
  if (!terms.length) return { terms, matches: [...list], total: list.length };

  const matches = list.filter((dataset) => {
    const folded = foldSearchText(textFor(dataset?.title, locale));
    return terms.every((term) => folded.includes(term));
  });
  return { terms, matches, total: list.length };
}

export function formatBytes(bytes) {
  const value = Number(bytes);
  if (!Number.isFinite(value) || value <= 0) return '0 KB';
  if (value < 1024) return `${Math.round(value)} B`;
  const kb = value / 1024;
  if (kb < 1024) return `${kb >= 10 ? Math.round(kb) : kb.toFixed(1)} KB`;
  return `${(kb / 1024).toFixed(1)} MB`;
}

/** UTC, so the same record reads identically in every timezone and in test assertions. */
export function formatImportedAt(timestamp) {
  const value = Number(timestamp);
  if (!Number.isFinite(value) || value <= 0) return '';
  const iso = new Date(value).toISOString();
  return `${iso.slice(0, 10)} ${iso.slice(11, 16)} UTC`;
}

/** UTF-8 byte length, so a size check matches what the browser actually stored or read. */
export function byteLength(value) {
  const text = String(value ?? '');
  if (typeof TextEncoder === 'function') return new TextEncoder().encode(text).length;
  return text.length;
}

/**
 * The only theme values this build applies. Anything else — a stale name, a tampered key, `system` —
 * returns `null` so the caller falls back to the platform hint instead of writing an unknown class.
 */
export function normalizeTheme(candidate) {
  if (typeof candidate === 'string' && THEMES.includes(candidate)) return candidate;
  if (candidate && typeof candidate === 'object' && !Array.isArray(candidate)) {
    if (candidate.version !== THEME_VERSION) return null;
    return typeof candidate.theme === 'string' && THEMES.includes(candidate.theme) ? candidate.theme : null;
  }
  return null;
}

/** Record written to the theme key. Versioned so a later palette change can reject this shape. */
export function createThemeRecord(theme) {
  return { version: THEME_VERSION, theme: normalizeTheme(theme) ?? 'light' };
}

/**
 * `prefers-color-scheme` is an initial fallback only. Once the learner has chosen, the stored value
 * wins even if the platform later disagrees — otherwise a system change would silently override them.
 */
export function resolveTheme(stored, prefersDark = false) {
  return normalizeTheme(stored) ?? (prefersDark ? 'dark' : 'light');
}

/* Backup: assembling an export, and validating a candidate before anything is replaced. */

/** Keys each section may contribute. Anything else in a tampered record is dropped, not copied. */
const BACKUP_SECTION_KEYS = {
  progress: ['version', 'activeDatasetId', 'datasets'],
  library: ['version', 'sources'],
  agent: ['version', 'datasetId', 'turnIndex', 'completed', 'reflections', 'hints', 'startedAt'],
};

function pickKeys(source, keys) {
  if (!source || typeof source !== 'object' || Array.isArray(source)) return null;
  const picked = {};
  for (const key of keys) {
    if (Object.hasOwn(source, key)) picked[key] = source[key];
  }
  return picked;
}

/** Answers the learner has actually submitted, plus the sections and reflections a backup carries. */
export function backupCounts(sections = {}) {
  let answers = 0;
  const datasets = sections.progress?.datasets;
  if (datasets && typeof datasets === 'object') {
    for (const entry of Object.values(datasets)) {
      const submitted = entry?.submitted;
      if (!submitted || typeof submitted !== 'object') continue;
      answers += Object.values(submitted).filter((value) => value === true).length;
    }
  }

  const sources = Array.isArray(sections.library?.sources) ? sections.library.sources : [];
  const reflections = sections.agent?.reflections;
  return {
    answers,
    sources: sources.length,
    sections: sources.reduce((total, source) => total + (Array.isArray(source?.sections) ? source.sections.length : 0), 0),
    reflections: reflections && typeof reflections === 'object'
      ? Object.values(reflections).filter((value) => typeof value === 'string' && value.trim()).length
      : 0,
    agentDatasetId: typeof sections.agent?.datasetId === 'string' ? sections.agent.datasetId : null,
  };
}

/**
 * Builds the export envelope from already-normalized state.
 *
 * Only the three demo keys are copied, field by field through `BACKUP_SECTION_KEYS`, so no unrelated
 * `localStorage` entry, credential, or stray property can reach the file even if a caller passes a
 * tampered record. An absent section is omitted rather than written as `null`.
 */
export function createBackup({ progress = null, library = null, agent = null, exportedAt = 0 } = {}) {
  const backup = { format: BACKUP_FORMAT, version: BACKUP_VERSION };
  const stamp = Number(exportedAt);
  if (Number.isFinite(stamp) && stamp > 0) backup.exportedAt = Math.round(stamp);

  const picked = {
    progress: pickKeys(progress, BACKUP_SECTION_KEYS.progress),
    library: pickKeys(library, BACKUP_SECTION_KEYS.library),
    agent: pickKeys(agent, BACKUP_SECTION_KEYS.agent),
  };
  for (const section of BACKUP_SECTIONS) {
    if (picked[section]) backup[section] = picked[section];
  }
  return backup;
}

/** `anchor-demo-backup-YYYY-MM-DD.json`, UTC so the name matches the stamp inside the file. */
export function backupFileName(exportedAt = 0) {
  const value = Number(exportedAt);
  if (!Number.isFinite(value) || value <= 0) return 'anchor-demo-backup.json';
  return `anchor-demo-backup-${new Date(value).toISOString().slice(0, 10)}.json`;
}

/** Cheap pre-read rejection: a candidate too large to be one of our exports never reaches JSON.parse. */
export function validateBackupCandidate(file, { limits = BACKUP_LIMITS } = {}) {
  const name = String(file?.name ?? '');
  const size = Number(file?.size);
  if (!limits.extensions.some((extension) => name.toLowerCase().endsWith(extension))) {
    return { ok: false, reason: 'type', name };
  }
  if (!Number.isFinite(size) || size <= 0) return { ok: false, reason: 'empty', name };
  if (size > limits.maxBytes) return { ok: false, reason: 'size', name, bytes: size };
  return { ok: true, name, bytes: size };
}

/**
 * Parses and validates backup text into a restore draft. Never throws and never touches storage: the
 * caller decides whether to apply `draft.sections`, so a rejected or cancelled file leaves state alone.
 *
 * Each section is normalized with the same function that guards its live key, so an incompatible inner
 * version or a hostile payload degrades to that key's empty value instead of being trusted. Sections
 * the file declared but which normalized to nothing are reported in `dropped` for the review panel.
 */
export function readBackup(text, {
  limits = BACKUP_LIMITS,
  normalizeProgress: normalizeProgressSection,
  normalizeLibrary = normalizeLocalLibrary,
  normalizeAgent = normalizeAgentSession,
  name = '',
} = {}) {
  const bytes = byteLength(text);
  if (!bytes) return { ok: false, reason: 'empty', name };
  if (bytes > limits.maxBytes) return { ok: false, reason: 'size', name, bytes };

  let parsed;
  try {
    parsed = JSON.parse(String(text));
  } catch {
    return { ok: false, reason: 'json', name, bytes };
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    return { ok: false, reason: 'format', name, bytes };
  }
  if (parsed.format !== BACKUP_FORMAT) return { ok: false, reason: 'format', name, bytes };
  if (parsed.version !== BACKUP_VERSION) {
    return { ok: false, reason: 'version', name, bytes, version: parsed.version ?? null };
  }

  const declared = BACKUP_SECTIONS.filter((section) => {
    const value = parsed[section];
    return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
  });
  if (!declared.length) return { ok: false, reason: 'shape', name, bytes };

  const sections = {};
  const dropped = [];
  if (declared.includes('progress')) {
    const progress = typeof normalizeProgressSection === 'function'
      ? normalizeProgressSection(parsed.progress)
      : null;
    if (progress) sections.progress = progress;
    else dropped.push('progress');
  }
  if (declared.includes('library')) {
    const library = normalizeLibrary(parsed.library);
    sections.library = library;
    if (!library.sources.length) dropped.push('library');
  }
  if (declared.includes('agent')) {
    const agent = normalizeAgent(parsed.agent);
    if (agent) sections.agent = agent;
    else dropped.push('agent');
  }

  const exportedAt = Number(parsed.exportedAt);
  return {
    ok: true,
    name,
    bytes,
    version: BACKUP_VERSION,
    exportedAt: Number.isFinite(exportedAt) && exportedAt > 0 ? Math.round(exportedAt) : 0,
    declared,
    dropped,
    sections,
    counts: backupCounts(sections),
  };
}

export function validateDatasets(datasets = DATASETS) {
  const errors = [];
  const datasetIds = new Set();
  const questionIds = new Set();

  if (datasets.length !== 3) errors.push('expected-three-datasets');
  for (const dataset of datasets) {
    if (!dataset.id || datasetIds.has(dataset.id)) errors.push(`invalid-dataset-id:${dataset.id}`);
    datasetIds.add(dataset.id);
    if (dataset.questions.length < 4) errors.push(`insufficient-questions:${dataset.id}`);
    for (const question of dataset.questions) {
      if (questionIds.has(question.id)) errors.push(`duplicate-question:${question.id}`);
      questionIds.add(question.id);
      if (!['single', 'multiple', 'boolean'].includes(question.type)) errors.push(`invalid-type:${question.id}`);
      const optionIds = new Set(question.options.map((option) => option.id));
      if (!question.correct.length || question.correct.some((id) => !optionIds.has(id))) errors.push(`invalid-correct-answer:${question.id}`);
      if (!question.citations.length) errors.push(`missing-citation:${question.id}`);
      if (!question.tutorHints.length) errors.push(`missing-tutor-hint:${question.id}`);
      for (const locale of ['en', 'zh']) {
        if (!textFor(question.prompt, locale) || !textFor(question.explanation, locale)) errors.push(`missing-locale:${question.id}:${locale}`);
      }
    }
  }
  return errors;
}
