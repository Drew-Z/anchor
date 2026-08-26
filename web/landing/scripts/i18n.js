const STORAGE_KEY = 'anchor.locale';
const SUPPORTED_LOCALES = new Set(['zh', 'en']);

const translations = {
  en: {
    'meta.title': 'Anchor Learning - Traceable AI Learning',
    'meta.description': 'Turn documentation and code into source-grounded learning exercises with citations, local-first storage, and guided review.',
    'a11y.skip': 'Skip to content',
    'a11y.primaryNav': 'Primary navigation',
    'a11y.language': 'Language',
    'a11y.openMenu': 'Open menu',
    'a11y.closeMenu': 'Close menu',
    'a11y.verificationLayers': 'Verification layers',
    'a11y.productStatus': 'Current product status',
    'nav.product': 'Android app',
    'nav.workflow': 'Workflow',
    'nav.architecture': 'Architecture',
    'nav.demo': 'Demo',
    'nav.source': 'Source',
    'hero.eyebrow': 'Android Private Alpha',
    'hero.lead': 'Turn technical documentation and code into source-grounded practice, Agent tutoring, and interview preparation. Every explanation stays connected to the evidence that supports it.',
    'hero.note': 'The browser demo is a static product sample. It uses bundled data and makes no AI requests.',
    'status.alpha': 'Android Private Alpha',
    'status.local': 'Local-first SQLite',
    'status.grounded': 'Source-grounded',
    'status.open': 'Open source',
    'actions.tryDemo': 'Try the demo',
    'actions.launchDemo': 'Launch demo',
    'actions.viewSource': 'View source',
    'actions.copyInstall': 'Copy install command',
    'actions.copied': 'Install command copied',
    'actions.copyFailed': 'Copy failed - select the command',
    'native.eyebrow': 'The native product',
    'native.title': 'A source-bound workflow on Android',
    'native.intro': 'The Private Alpha connects imported technical sources to a local learning Agent, evidence-aware interview practice, and on-device data controls.',
    'native.sourceTitle': 'Start from inspectable evidence',
    'native.sourceBody': 'The Agent sets a learning target from imported documentation or code and previews the exact source chunk before the session begins.',
    'native.sourceAlt': 'Anchor Learning Android Agent session showing a learning target and source evidence preview',
    'native.interviewTitle': 'Practice in interview mode',
    'native.interviewBody': 'Interview questions stay tied to project evidence and a defined learning target, with room to explain tradeoffs in your own words.',
    'native.interviewAlt': 'Anchor Learning Android interview mode showing a source-bound technical question',
    'native.privacyTitle': 'Keep data under local control',
    'native.privacyBody': 'Learning data and product events stay on device. Backups can be exported and restored, while credentials and model configuration remain excluded.',
    'native.privacyAlt': 'Anchor Learning Android local data and privacy controls with backup and restore actions',
    'native.disclosure': 'Captured on a physical Android device from the current Private Alpha. No public APK is being offered on this page.',
    'workflow.eyebrow': 'From source to review',
    'workflow.title': 'A learning loop you can inspect',
    'workflow.intro': 'Anchor keeps ingestion, generation, verification, and review as separate steps so weak evidence can stop before it becomes study material.',
    'workflow.importTitle': 'Import',
    'workflow.importBody': 'Bring in Markdown, technical notes, or code while preserving headings and structural boundaries.',
    'workflow.generateTitle': 'Generate',
    'workflow.generateBody': 'Extract concepts and create varied exercises from bounded source chunks.',
    'workflow.verifyTitle': 'Verify',
    'workflow.verifyBody': 'Check that cited chunks exist and that answers are supported before review.',
    'workflow.reviewTitle': 'Learn',
    'workflow.reviewBody': 'Practice with source excerpts, guided hints, and spaced follow-up.',
    'architecture.eyebrow': 'Grounding by construction',
    'architecture.title': 'Three checks between a source and a question',
    'architecture.intro': 'The system treats generated content as a proposal. Structure, citation, and answer support are checked independently before the material is considered ready.',
    'architecture.chunkTitle': 'Semantic chunking',
    'architecture.chunkBody': 'Split at meaningful document or code boundaries and retain a stable locator.',
    'architecture.citationTitle': 'Citation verification',
    'architecture.citationBody': 'Reject references to missing chunks and keep the cited excerpt visible.',
    'architecture.answerTitle': 'Answer validation',
    'architecture.answerBody': 'Confirm that the proposed answer follows from the cited material; send uncertainty to review.',
    'demo.eyebrow': 'Browser demo',
    'demo.title': 'Finish a complete source-traced quiz',
    'demo.body': 'Choose Flutter, Git, or JavaScript. Submit an answer, inspect the supporting excerpt, ask for a scripted tutor hint, and keep your progress in this browser.',
    'demo.pointOne': 'Three bundled datasets and twelve exercises',
    'demo.pointTwo': 'Single choice, multiple choice, and true/false',
    'demo.pointThree': 'No account, upload, backend, analytics, or AI call',
    'demo.previewAlt': 'Anchor Learning browser demo showing a quiz and source citation',
    'demo.caption': 'The demo is a guided product sample, not the full Flutter application.',
    'audience.eyebrow': 'Designed for technical learning',
    'audience.title': 'Use your own sources as the curriculum',
    'audience.developerTitle': 'Developers',
    'audience.developerBody': 'Convert framework documentation and code into deliberate practice.',
    'audience.onboardingTitle': 'Engineering teams',
    'audience.onboardingBody': 'Turn architecture notes into an inspectable onboarding path.',
    'audience.interviewTitle': 'Interview preparation',
    'audience.interviewBody': 'Practice from system-design notes and implementation decisions instead of generic prompts.',
    'final.eyebrow': 'Start with evidence',
    'final.title': 'See how traceable practice feels',
    'footer.tagline': 'Traceable, local-first learning for developers.',
    'footer.architecture': 'Architecture',
    'app.metaTitle': 'Interactive Demo - Anchor Learning',
    'app.metaDescription': 'Try the Anchor Learning source-traced quiz demo with bundled datasets.',
    'app.back': 'Product site',
    'app.datasets': 'Datasets',
    'app.chooseDataset': 'Choose a dataset',
    'app.chooseDatasetBody': 'Each sample contains four exercises and the exact source passages used to explain them.',
    'app.questions': 'questions',
    'app.localOnly': 'Bundled data only',
    'app.localOnlyBody': 'This guided demo runs entirely in your browser. It does not upload files or call an AI provider.',
    'app.question': 'Question',
    'app.of': 'of',
    'app.score': 'Score',
    'app.selectOne': 'Choose one answer.',
    'app.selectMany': 'Choose every answer that applies.',
    'app.trueFalse': 'Decide whether the statement is true or false.',
    'app.submit': 'Check answer',
    'app.previous': 'Previous',
    'app.next': 'Next',
    'app.finish': 'Finish dataset',
    'app.reset': 'Reset progress',
    'app.progress': 'Answered questions',
    'app.correct': 'Supported by the source',
    'app.incorrect': 'Review the source and try the next question',
    'app.explanation': 'Explanation',
    'app.sourceEvidence': 'Source evidence',
    'app.tutor': 'Ask scripted tutor',
    'app.tutorLabel': 'Scripted tutor demo',
    'app.tutorDisclosure': 'These hints are bundled with the demo. No live AI is running.',
    'app.tutorPanel': 'Scripted tutor hints',
    'app.completed': 'Dataset complete',
    'app.completedBody': 'You finished this sample with source evidence available for every answer.',
    'app.reviewAgain': 'Review from the start',
    'app.chooseAnother': 'Choose another dataset',
    'app.progressRestored': 'Your local progress was restored.',
    'app.progressReset': 'Local demo progress was reset.',
    'app.true': 'True',
    'app.false': 'False',
    'app.menu': 'Open datasets',
    'app.closeMenu': 'Close datasets',
  },
  zh: {
    'meta.title': 'Anchor Learning 锚学 - 来源可溯源的 AI 学习系统',
    'meta.description': '将技术文档和代码转化为带来源引用的学习练习，以本地优先存储、引用校验和引导式复习保证内容可追溯。',
    'a11y.skip': '跳到主要内容',
    'a11y.primaryNav': '主导航',
    'a11y.language': '语言',
    'a11y.openMenu': '打开菜单',
    'a11y.closeMenu': '关闭菜单',
    'a11y.verificationLayers': '验证层级',
    'a11y.productStatus': '当前产品状态',
    'nav.product': 'Android 应用',
    'nav.workflow': '工作流程',
    'nav.architecture': '架构',
    'nav.demo': '演示',
    'nav.source': '源码',
    'hero.eyebrow': 'Android Private Alpha',
    'hero.lead': '把技术文档和代码转化为来源约束的练习、Agent 辅导和面试准备，让每段解释都能回到真正支持它的证据。',
    'hero.note': '浏览器演示是静态产品样例，只使用内置数据，不会发起 AI 请求。',
    'status.alpha': 'Android Private Alpha',
    'status.local': '本地优先 SQLite',
    'status.grounded': '来源约束',
    'status.open': '开放源码',
    'actions.tryDemo': '尝试演示',
    'actions.launchDemo': '进入演示',
    'actions.viewSource': '查看源码',
    'actions.copyInstall': '复制安装命令',
    'actions.copied': '安装命令已复制',
    'actions.copyFailed': '复制失败，请手动选择命令',
    'native.eyebrow': '原生产品',
    'native.title': 'Android 上的来源约束学习流程',
    'native.intro': 'Private Alpha 把导入的技术资料连接到本地学习 Agent、带证据的面试练习，以及可由用户控制的本机数据。',
    'native.sourceTitle': '从可检查的证据开始',
    'native.sourceBody': 'Agent 从导入的文档或代码确定学习目标，并在会话开始前展示对应的准确来源片段。',
    'native.sourceAlt': 'Anchor Learning Android Agent 会话，显示学习目标和来源证据预览',
    'native.interviewTitle': '进入面试官模式练习',
    'native.interviewBody': '面试问题与项目证据和明确的学习目标绑定，学习者需要用自己的话说明事实、取舍和边界。',
    'native.interviewAlt': 'Anchor Learning Android 面试官模式，显示一道有来源依据的技术问题',
    'native.privacyTitle': '把数据控制留在本机',
    'native.privacyBody': '学习数据和产品事件保存在设备上，可导出和恢复备份；模型凭证与模型配置不会进入备份。',
    'native.privacyAlt': 'Anchor Learning Android 本地数据与隐私页面，显示备份和恢复操作',
    'native.disclosure': '画面来自当前 Private Alpha 的真实 Android 设备；本页面不提供公开 APK。',
    'workflow.eyebrow': '从原文到复习',
    'workflow.title': '每一步都能检查的学习闭环',
    'workflow.intro': 'Anchor 将导入、生成、验证和学习拆成独立阶段，让证据不足的内容在进入题库前就停止。',
    'workflow.importTitle': '导入',
    'workflow.importBody': '导入 Markdown、技术笔记或代码，同时保留标题和代码结构边界。',
    'workflow.generateTitle': '生成',
    'workflow.generateBody': '从有界的来源片段提取概念，并生成不同类型的练习。',
    'workflow.verifyTitle': '验证',
    'workflow.verifyBody': '检查引用片段真实存在，并确认答案得到原文支持。',
    'workflow.reviewTitle': '学习',
    'workflow.reviewBody': '结合原文摘录、引导提示和间隔复习完成练习。',
    'architecture.eyebrow': '从架构上约束生成',
    'architecture.title': '一道题进入学习环节前的三层检查',
    'architecture.intro': '系统把生成内容视为待验证的提案，分别检查结构、引用和答案依据，通过后才作为学习材料。',
    'architecture.chunkTitle': '语义切分',
    'architecture.chunkBody': '在文档或代码的语义边界切分，并保留稳定的来源定位。',
    'architecture.citationTitle': '引用校验',
    'architecture.citationBody': '拒绝不存在的片段引用，并始终向学习者展示原文。',
    'architecture.answerTitle': '答案核验',
    'architecture.answerBody': '确认答案可以由引用内容推出，不确定内容进入人工复核。',
    'demo.eyebrow': '浏览器演示',
    'demo.title': '完成一轮带来源引用的真实答题流程',
    'demo.body': '选择 Flutter、Git 或 JavaScript，提交答案、查看支持原文、获取预置导师提示，并在当前浏览器保存进度。',
    'demo.pointOne': '三套内置数据，共十二道练习',
    'demo.pointTwo': '覆盖单选、多选和判断题',
    'demo.pointThree': '无需账号、上传、后端、分析或 AI 调用',
    'demo.previewAlt': 'Anchor Learning 浏览器演示，显示答题和来源引用',
    'demo.caption': '这是引导式产品样例，不是完整 Flutter 应用。',
    'audience.eyebrow': '为技术学习而设计',
    'audience.title': '让自己的资料成为课程',
    'audience.developerTitle': '开发者',
    'audience.developerBody': '把框架文档和代码转化为有针对性的练习。',
    'audience.onboardingTitle': '工程团队',
    'audience.onboardingBody': '把架构说明转化为可检查、可追溯的入职学习路径。',
    'audience.interviewTitle': '面试准备',
    'audience.interviewBody': '从系统设计笔记和真实实现决策中练习，而不是依赖泛化问题。',
    'final.eyebrow': '从证据开始',
    'final.title': '体验来源可溯源的练习方式',
    'footer.tagline': '面向开发者的可溯源、本地优先学习工具。',
    'footer.architecture': '架构文档',
    'app.metaTitle': '交互演示 - Anchor Learning 锚学',
    'app.metaDescription': '使用内置数据体验 Anchor Learning 带来源引用的答题流程。',
    'app.back': '返回产品站',
    'app.datasets': '数据集',
    'app.chooseDataset': '选择一个数据集',
    'app.chooseDatasetBody': '每套样例包含四道练习，以及用于解释答案的准确来源片段。',
    'app.questions': '道题',
    'app.localOnly': '仅使用内置数据',
    'app.localOnlyBody': '这个引导式演示完全在浏览器中运行，不上传文件，也不调用 AI 服务。',
    'app.question': '第',
    'app.of': '题，共',
    'app.score': '得分',
    'app.selectOne': '请选择一个答案。',
    'app.selectMany': '请选择所有符合条件的答案。',
    'app.trueFalse': '请判断这句话是否正确。',
    'app.submit': '检查答案',
    'app.previous': '上一题',
    'app.next': '下一题',
    'app.finish': '完成数据集',
    'app.reset': '重置进度',
    'app.progress': '已答题目',
    'app.correct': '答案得到来源支持',
    'app.incorrect': '请结合原文理解，再继续下一题',
    'app.explanation': '答案解释',
    'app.sourceEvidence': '来源证据',
    'app.tutor': '询问预置导师',
    'app.tutorLabel': '预置导师演示',
    'app.tutorDisclosure': '这些提示随演示内置，没有运行实时 AI。',
    'app.tutorPanel': '预置导师提示',
    'app.completed': '数据集已完成',
    'app.completedBody': '你已完成这套样例，每道题的答案都能查看来源证据。',
    'app.reviewAgain': '从头复习',
    'app.chooseAnother': '选择其他数据集',
    'app.progressRestored': '已恢复本地学习进度。',
    'app.progressReset': '已重置本地演示进度。',
    'app.true': '正确',
    'app.false': '错误',
    'app.menu': '打开数据集',
    'app.closeMenu': '关闭数据集',
  },
};

let activeLocale = 'en';

export function normalizeLocale(value) {
  if (SUPPORTED_LOCALES.has(value)) return value;
  return String(value ?? '').toLowerCase().startsWith('zh') ? 'zh' : 'en';
}

export function getStoredLocale(storage = globalThis.localStorage) {
  try {
    return normalizeLocale(storage?.getItem(STORAGE_KEY) || globalThis.navigator?.language);
  } catch {
    return normalizeLocale(globalThis.navigator?.language);
  }
}

export function getLocale() {
  return activeLocale;
}

export function translate(key, locale = activeLocale) {
  return translations[normalizeLocale(locale)]?.[key] ?? translations.en[key] ?? key;
}

export function applyLocale(locale, root = document) {
  activeLocale = normalizeLocale(locale);
  root.documentElement.lang = activeLocale === 'zh' ? 'zh-CN' : 'en';
  root.title = translate(root.body?.dataset.surface === 'app' ? 'app.metaTitle' : 'meta.title');

  const description = root.querySelector('meta[name="description"]');
  if (description) description.content = translate(root.body?.dataset.surface === 'app' ? 'app.metaDescription' : 'meta.description');

  root.querySelectorAll('[data-i18n]').forEach((element) => {
    element.textContent = translate(element.dataset.i18n);
  });
  root.querySelectorAll('[data-i18n-aria-label]').forEach((element) => {
    element.setAttribute('aria-label', translate(element.dataset.i18nAriaLabel));
  });
  root.querySelectorAll('[data-i18n-alt]').forEach((element) => {
    element.setAttribute('alt', translate(element.dataset.i18nAlt));
  });
  root.querySelectorAll('[data-locale]').forEach((button) => {
    button.setAttribute('aria-pressed', String(button.dataset.locale === activeLocale));
  });
}

export function setLocale(locale, { persist = true, root = document } = {}) {
  const normalized = normalizeLocale(locale);
  if (persist) {
    try {
      globalThis.localStorage?.setItem(STORAGE_KEY, normalized);
    } catch {
      // The page remains usable when storage is unavailable.
    }
  }
  applyLocale(normalized, root);
  globalThis.dispatchEvent?.(new CustomEvent('anchor:localechange', { detail: { locale: normalized } }));
  return normalized;
}

export function initializeLocale(root = document) {
  return setLocale(getStoredLocale(), { persist: false, root });
}

export { STORAGE_KEY, translations };
