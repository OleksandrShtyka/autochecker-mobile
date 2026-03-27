import '../services/locale_service.dart';

/// t('key') — повертає переклад для поточної мови
String t(String key) {
  final lang = LocaleService.instance.langCode.value;
  return _s[lang]?[key] ?? _s['en']![key] ?? key;
}

const _s = <String, Map<String, String>>{
  // ─────────────────────────────────────────────────── English
  'en': {
    // Bottom nav
    'tab_dashboard':    'Dashboard',
    'tab_supplements':  'Supplements',
    'tab_sessions':     'Sessions',
    'tab_settings':     'Settings',

    // Dashboard
    'fitness_profile':    'FITNESS PROFILE',
    'gym_cost_label':     'Monthly gym cost (\$)',
    'fitness_goal_label': 'Fitness goal',
    'badge_label':        'Badge / level',
    'save_profile':       'Save profile',
    'saved':              'Saved ✓',
    'sessions_month':     'sessions\nthis month',
    'gym_cost':           'gym\ncost',
    'cost_per_session':   'cost per\nsession',
    'goal_general':       'General Fitness',
    'goal_strength':      'Strength',
    'goal_hypertrophy':   'Hypertrophy',
    'goal_endurance':     'Endurance',

    // AI panel
    'helper_ai':          'Helper AI',
    'ai_hint':            'Ask me anything…',
    'ai_empty_sub':       'Ask anything about AutoChecker\nor your fitness data.',
    'ai_context_loaded':  'I can see your fitness data ✓',

    // Settings sections
    'section_profile':    'PROFILE',
    'section_security':   'SECURITY',
    'section_ai':         'AI WORKOUT ANALYSIS',
    'section_account':    'ACCOUNT',
    'section_language':   'LANGUAGE',

    // Settings items
    'pin_lock':           'PIN Lock',
    'pin_lock_sub':       'Require PIN to open the app',
    'change_pin':         'Change PIN',
    'biometric':          'Fingerprint / Face ID',
    'biometric_sub':      'Use biometrics instead of PIN',
    'ai_auto_analyse':    'Auto-analyse workouts',
    'ai_auto_sub':        'AI checks your sessions and sends improvement tips',
    'frequency':          'Frequency',
    'analyse_now':        'Analyse now',
    'analyse_now_sub':    'Run AI analysis immediately',
    'sign_out':           'Sign out',
    'upload_photo':       'Upload photo',
    'change_photo':       'Change photo',
    'remove':             'Remove',
    'version':            'AutoChecker Mobile v2.0',

    // Frequency options
    'freq_manual':   'Manual only',
    'freq_daily':    'Every day',
    'freq_2days':    'Every 2 days',
    'freq_3days':    'Every 3 days',
    'freq_weekly':   'Weekly',

    // Dialogs
    'cancel':             'Cancel',
    'confirm':            'Confirm',
    'disable_pin_title':  'Disable PIN?',
    'disable_pin_body':   'App lock will be removed.',
    'remove_photo_title': 'Remove photo?',
    'remove_photo_body':  'Your avatar will be deleted.',
    'sign_out_title':     'Sign out?',
    'sign_out_body':      'You will need to log in again.',

    // Language labels
    'lang_en': 'English',
    'lang_uk': 'Українська',

    // AI analysis snackbar
    'analysis_done': 'Analysis done — check your notifications',

    // Login
    'login_title':    'Sign in to AutoChecker',
    'email':          'Email',
    'password':       'Password',
    'sign_in':        'Sign in',
    'no_account':     "Don't have an account? Sign up",
    'login_error':    'Login failed. Check your credentials.',

    // Register
    'register_title': 'Create account',
    'full_name':      'Full name',
    'confirm_pass':   'Confirm password',
    'create_account': 'Create account',
    'have_account':   'Already have an account? Sign in',
    'pass_too_short': 'Password must be at least 12 characters',
    'pass_mismatch':  'Passwords do not match',

    // Supplements
    'supplements':        'Supplements',
    'add_supplement':     'Add supplement',
    'name':               'Name',
    'dose':               'Dose (e.g. 5g)',
    'time':               'Time (e.g. morning)',
    'no_supplements':     'No supplements yet',
    'no_supps_sub':       'Tap + to add your first supplement',

    // Workout program tab
    'tab_program':           'Program',
    'program_title':         'Workout Program',
    'program_empty_title':   'No program yet',
    'program_empty_sub':     'Write your own or generate one with AI',
    'program_edit':          'Edit manually',
    'program_save':          'Save program',
    'program_saved':         'Saved ✓',
    'program_hint':          'Write your weekly training program here…',
    'program_generate':      'Generate with AI',
    'program_generate_sub':  'Describe yourself — AI writes the perfect plan',
    'ai_gen_title':          'AI Workout Generator',
    'ai_gen_age':            'Age',
    'ai_gen_weight':         'Weight (kg)',
    'ai_gen_goal':           'Goal',
    'ai_gen_level':          'Fitness level',
    'ai_gen_days':           'Days per week',
    'ai_gen_equipment':      'Available equipment',
    'ai_gen_notes':          'Additional info (injuries, preferences…)',
    'ai_gen_btn':            'Generate program',
    'ai_gen_generating':     'Generating…',
    'ai_gen_goal_muscle':    'Build muscle',
    'ai_gen_goal_fat':       'Burn fat',
    'ai_gen_goal_strength':  'Get stronger',
    'ai_gen_goal_endurance': 'Improve endurance',
    'ai_gen_goal_general':   'General fitness',
    'ai_gen_level_beg':      'Beginner',
    'ai_gen_level_int':      'Intermediate',
    'ai_gen_level_adv':      'Advanced',
    'ai_gen_equip_gym':      'Full gym',
    'ai_gen_equip_home':     'Home (dumbbells)',
    'ai_gen_equip_body':     'Bodyweight only',
    'ai_gen_equip_barbell':  'Barbell + rack',
    'ai_gen_lang':           'Program language',
    'ai_gen_lang_en':        'English',
    'ai_gen_lang_uk':        'Ukrainian',

    // Sessions
    'sessions':           'Sessions',
    'add_session':        'Log session',
    'workout_type':       'Workout type',
    'duration_min':       'Duration (min)',
    'volume_kg':          'Volume (kg)',
    'exercises':          'Exercises',
    'no_sessions':        'No sessions yet',
    'no_sessions_sub':    'Tap + to log your first session',
    'delete':             'Delete',
  },

  // ─────────────────────────────────────────────────── Ukrainian
  'uk': {
    // Bottom nav
    'tab_dashboard':    'Дашборд',
    'tab_supplements':  'Добавки',
    'tab_sessions':     'Тренування',
    'tab_settings':     'Налаштування',

    // Dashboard
    'fitness_profile':    'ФІТНЕС ПРОФІЛЬ',
    'gym_cost_label':     'Місячна вартість залу (\$)',
    'fitness_goal_label': 'Мета тренувань',
    'badge_label':        'Значок / рівень',
    'save_profile':       'Зберегти профіль',
    'saved':              'Збережено ✓',
    'sessions_month':     'сесій\nцього місяця',
    'gym_cost':           'вартість\nзалу',
    'cost_per_session':   'вартість\nсесії',
    'goal_general':       'Загальна форма',
    'goal_strength':      'Сила',
    'goal_hypertrophy':   'Гіпертрофія',
    'goal_endurance':     'Витривалість',

    // AI panel
    'helper_ai':          'Помічник AI',
    'ai_hint':            'Запитайте що завгодно…',
    'ai_empty_sub':       'Запитайте про AutoChecker\nабо ваші фітнес-дані.',
    'ai_context_loaded':  'Я бачу ваші дані тренувань ✓',

    // Settings sections
    'section_profile':    'ПРОФІЛЬ',
    'section_security':   'БЕЗПЕКА',
    'section_ai':         'AI АНАЛІЗ ТРЕНУВАНЬ',
    'section_account':    'АКАУНТ',
    'section_language':   'МОВА',

    // Settings items
    'pin_lock':           'PIN замок',
    'pin_lock_sub':       'Потрібен PIN для відкриття додатку',
    'change_pin':         'Змінити PIN',
    'biometric':          'Відбиток / Face ID',
    'biometric_sub':      'Використовувати біометрію замість PIN',
    'ai_auto_analyse':    'Авто-аналіз тренувань',
    'ai_auto_sub':        'AI перевіряє сесії та надсилає поради',
    'frequency':          'Частота',
    'analyse_now':        'Аналізувати зараз',
    'analyse_now_sub':    'Запустити AI аналіз одразу',
    'sign_out':           'Вийти',
    'upload_photo':       'Завантажити фото',
    'change_photo':       'Змінити фото',
    'remove':             'Видалити',
    'version':            'AutoChecker Mobile v2.0',

    // Frequency options
    'freq_manual':   'Лише вручну',
    'freq_daily':    'Щодня',
    'freq_2days':    'Кожні 2 дні',
    'freq_3days':    'Кожні 3 дні',
    'freq_weekly':   'Щотижня',

    // Dialogs
    'cancel':             'Скасувати',
    'confirm':            'Підтвердити',
    'disable_pin_title':  'Вимкнути PIN?',
    'disable_pin_body':   'Замок додатку буде знятий.',
    'remove_photo_title': 'Видалити фото?',
    'remove_photo_body':  'Ваш аватар буде видалено.',
    'sign_out_title':     'Вийти?',
    'sign_out_body':      'Вам потрібно буде увійти знову.',

    // Language labels
    'lang_en': 'English',
    'lang_uk': 'Українська',

    // AI analysis snackbar
    'analysis_done': 'Аналіз готовий — перевірте сповіщення',

    // Login
    'login_title':    'Увійти в AutoChecker',
    'email':          'Електронна пошта',
    'password':       'Пароль',
    'sign_in':        'Увійти',
    'no_account':     'Немає акаунту? Зареєструватися',
    'login_error':    'Помилка входу. Перевірте дані.',

    // Register
    'register_title': 'Створити акаунт',
    'full_name':      'Повне ім\'я',
    'confirm_pass':   'Підтвердити пароль',
    'create_account': 'Створити акаунт',
    'have_account':   'Вже є акаунт? Увійти',
    'pass_too_short': 'Пароль має бути щонайменше 12 символів',
    'pass_mismatch':  'Паролі не збігаються',

    // Supplements
    'supplements':        'Добавки',
    'add_supplement':     'Додати добавку',
    'name':               'Назва',
    'dose':               'Доза (напр. 5г)',
    'time':               'Час (напр. ранок)',
    'no_supplements':     'Добавок ще немає',
    'no_supps_sub':       'Натисніть + щоб додати першу добавку',

    // Workout program tab
    'tab_program':           'Програма',
    'program_title':         'Програма тренувань',
    'program_empty_title':   'Програми ще немає',
    'program_empty_sub':     'Напишіть свою або згенеруйте за допомогою ШІ',
    'program_edit':          'Редагувати вручну',
    'program_save':          'Зберегти програму',
    'program_saved':         'Збережено ✓',
    'program_hint':          'Напишіть тут свою тижневу програму тренувань…',
    'program_generate':      'Генерація ШІ',
    'program_generate_sub':  'Опишіть себе — ШІ напише ідеальний план',
    'ai_gen_title':          'Генератор тренувань ШІ',
    'ai_gen_age':            'Вік',
    'ai_gen_weight':         'Вага (кг)',
    'ai_gen_goal':           'Мета',
    'ai_gen_level':          'Рівень підготовки',
    'ai_gen_days':           'Днів на тиждень',
    'ai_gen_equipment':      'Доступне обладнання',
    'ai_gen_notes':          'Додаткова інфо (травми, побажання…)',
    'ai_gen_btn':            'Згенерувати програму',
    'ai_gen_generating':     'Генерую…',
    'ai_gen_goal_muscle':    'Набір маси',
    'ai_gen_goal_fat':       'Спалення жиру',
    'ai_gen_goal_strength':  'Збільшення сили',
    'ai_gen_goal_endurance': 'Витривалість',
    'ai_gen_goal_general':   'Загальна форма',
    'ai_gen_level_beg':      'Початківець',
    'ai_gen_level_int':      'Середній',
    'ai_gen_level_adv':      'Досвідчений',
    'ai_gen_equip_gym':      'Повноцінний зал',
    'ai_gen_equip_home':     'Вдома (гантелі)',
    'ai_gen_equip_body':     'Лише власна вага',
    'ai_gen_equip_barbell':  'Штанга + стійка',
    'ai_gen_lang':           'Мова програми',
    'ai_gen_lang_en':        'Англійська',
    'ai_gen_lang_uk':        'Українська',

    // Sessions
    'sessions':           'Тренування',
    'add_session':        'Записати тренування',
    'workout_type':       'Тип тренування',
    'duration_min':       'Тривалість (хв)',
    'volume_kg':          'Об\'єм (кг)',
    'exercises':          'Вправи',
    'no_sessions':        'Тренувань ще немає',
    'no_sessions_sub':    'Натисніть + щоб записати перше тренування',
    'delete':             'Видалити',
  },
};
