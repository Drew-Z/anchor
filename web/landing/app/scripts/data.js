export const DATA_VERSION = 1;

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
    'The browser shell mirrors the app layout. It runs on bundled data with no account, upload, or AI request.',
    '浏览器外壳复刻应用结构，只使用内置数据，不需要账号，也不会上传文件或发起 AI 请求。',
  ),
  backToDecks: localized('All datasets', '全部数据集'),

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
    continueTitle: localized('Continue where you stopped', '继续上次的练习'),
    continueAction: localized('Continue', '继续'),
    startTitle: localized('Pick a dataset', '选择一套数据集'),
    startBody: localized(
      'Each dataset mixes single choice, multiple choice, and true/false questions, and every answer opens its source passage.',
      '每套数据集包含单选、多选和判断题，每个答案都可以展开对应的原文。',
    ),
    startAction: localized('Open decks', '打开题库'),
    importTitle: localized('Add content', '添加内容'),
    importBody: localized(
      'The Android app builds questions from files, pasted text, or shared content. See what import covers before it reaches this shell.',
      'Android 应用可以从文件、粘贴的文本或分享的内容生成题目。可以先了解导入涵盖的范围。',
    ),
    importAction: localized('How import works', '导入方式说明'),
    planTitle: localized('Review plan', '复习计划'),
    planBody: localized(
      'Built from the progress stored in this browser. Nothing is scheduled on a server.',
      '根据保存在此浏览器中的进度生成，不依赖任何服务端排程。',
    ),
    planRemaining: localized('{n} left', '还剩 {n} 题'),
    planDone: localized('Complete', '已完成'),
  },

  decks: {
    eyebrow: localized('Decks', '题库'),
    note: localized(
      'These datasets are bundled with the demo. Generating new questions from your own material happens in the Android app.',
      '这些数据集随演示内置。基于你自己的资料生成新题目在 Android 应用中完成。',
    ),
  },

  agent: {
    eyebrow: localized('Agent', 'Agent'),
    title: localized('Guided help that shows its sources', '会展示来源的引导式辅导'),
    body: localized(
      'In the Android Private Alpha the Agent sets a learning target, explains concepts from imported material, and runs interview practice. The browser shell carries the scripted part of that experience.',
      '在 Android Private Alpha 中，Agent 会设定学习目标、基于导入资料讲解概念，并进行面试练习。浏览器外壳只承载其中的预置部分。',
    ),
    tutorTitle: localized('Scripted tutor hints', '预置导师提示'),
    tutorBody: localized(
      'Answer a question in the decks, then open the tutor panel to read hints that ship with the demo. No model is called.',
      '在题库中作答后展开导师面板，即可阅读随演示内置的提示，不会调用任何模型。',
    ),
    tutorAction: localized('Practice and open a hint', '去练习并查看提示'),
    nativeTitle: localized('Runs on Android only', '仅在 Android 上运行'),
    nativeBody: localized(
      'These capabilities need a configured model and on-device storage, so the static browser demo does not include them.',
      '这些能力需要已配置的模型和设备本地存储，静态浏览器演示不包含它们。',
    ),
    nativeTutor: localized('Live tutor conversation about an imported concept', '围绕导入概念的实时导师对话'),
    nativeInterview: localized('Interview mode with evidence-bound follow-up questions', '带证据约束追问的面试官模式'),
    nativeTarget: localized('Learning targets for interview prep, project study, or open exploration', '面试准备、项目学习、自由探索等学习目标'),
    nativeReview: localized('Session history and interview review records', '会话历史与面试复盘记录'),
  },

  library: {
    eyebrow: localized('Library', '知识库'),
    title: localized('Every source passage in this demo', '演示中的全部来源片段'),
    body: localized(
      '{n} excerpts back the {q} bundled questions. Each one is the passage the demo quotes when it explains an answer.',
      '{n} 段摘录支撑内置的 {q} 道题目，每段都是演示解释答案时引用的原文。',
    ),
    openDataset: localized('Practice this dataset', '练习这套数据集'),
    questionLabel: localized('Explains', '用于解释'),
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
    accountTitle: localized('No account involved', '不涉及账号'),
    accountBody: localized(
      'There is no sign-in, no profile sync, and no server holding your answers.',
      '这里没有登录、没有资料同步，也没有服务端保存你的答案。',
    ),
    languageTitle: localized('Language', '语言'),
    languageBody: localized(
      'Switch between English and 中文 with the toggle in the header. The choice is remembered locally.',
      '使用页眉的切换按钮在 English 与中文之间切换，选择会保存在本地。',
    ),
    resetTitle: localized('Reset local progress', '重置本地进度'),
    resetBody: localized(
      'Clears answers and scores for all bundled datasets in this browser.',
      '清除此浏览器中所有内置数据集的答案与得分。',
    ),
    nativeTitle: localized('Part of the Android app', '属于 Android 应用'),
    nativeStreak: localized('Streaks, badges, and achievement history', '连续学习、成就徽章与历史记录'),
    nativeSettings: localized('Model configuration and app settings', '模型配置与应用设置'),
    nativeBackup: localized('Local backup export and restore', '本地备份导出与恢复'),
  },

  sources: {
    eyebrow: localized('Import', '导入'),
    title: localized('Bringing in your own material', '导入你自己的资料'),
    body: localized(
      'The browser demo has no file picker and no upload. It only reads the three datasets bundled with this page.',
      '浏览器演示没有文件选择器，也不会上传任何内容，只读取本页内置的三套数据集。',
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
