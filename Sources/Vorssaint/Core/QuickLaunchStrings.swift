// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct QuickLaunchStrings {
    let sectionTitle: String
    let enableToggle: String
    let enableCaption: String
    let modifierLabel: String
    let modifierRightCommand: String
    let modifierLeftCommand: String
    let modifierRightOption: String
    let modifierLeftOption: String
    let modifierRightControl: String
    let modifierLeftControl: String
    let prioritiesTitle: String
    let prioritiesCaption: String
    let addButton: String
    let removeButton: String
    let addLetterButton: String
    let removeLetterButton: String
}

extension FeatureStrings {
    static func quickLaunch(_ language: AppLanguage) -> QuickLaunchStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension QuickLaunchStrings {
    static let enUS = QuickLaunchStrings(
        sectionTitle: "Quick Launch",
        enableToggle: "Enable Quick Launch",
        enableCaption: "Hold the modifier below and tap a letter to bring the matching running app forward. Tap the same letter again while still holding to cycle to the next match. Nothing is ever launched — only apps already running. While held, this key stops acting as an ordinary modifier — other shortcuts on it, like copy or paste, are blocked so they never also fire in the app you're leaving.",
        modifierLabel: "Modifier",
        modifierRightCommand: "Right ⌘",
        modifierLeftCommand: "Left ⌘",
        modifierRightOption: "Right ⌥",
        modifierLeftOption: "Left ⌥",
        modifierRightControl: "Right ⌃",
        modifierLeftControl: "Left ⌃",
        prioritiesTitle: "Letter priorities",
        prioritiesCaption: "Choose which app a letter reaches first, and add apps that don't start with that letter. Apps left unranked follow by how recently they were used.",
        addButton: "Add an app…",
        removeButton: "Remove",
        addLetterButton: "Add letter…",
        removeLetterButton: "Remove letter"
    )

    static let ptBR = QuickLaunchStrings(
        sectionTitle: "Início Rápido",
        enableToggle: "Ativar Início Rápido",
        enableCaption: "Mantenha pressionado o modificador abaixo e toque em uma letra para trazer o app correspondente que já está aberto. Toque na mesma letra novamente, ainda segurando, para passar para a próxima correspondência. Nada é aberto — só apps já em execução. Enquanto pressionado, essa tecla deixa de funcionar como um modificador comum — outros atalhos nela, como copiar ou colar, ficam bloqueados para nunca serem acionados também no app que você está deixando.",
        modifierLabel: "Modificador",
        modifierRightCommand: "⌘ direita",
        modifierLeftCommand: "⌘ esquerda",
        modifierRightOption: "⌥ direita",
        modifierLeftOption: "⌥ esquerda",
        modifierRightControl: "⌃ direita",
        modifierLeftControl: "⌃ esquerda",
        prioritiesTitle: "Prioridades por letra",
        prioritiesCaption: "Escolha qual app cada letra alcança primeiro, e adicione apps que não começam com essa letra. Apps sem prioridade seguem pelo uso mais recente.",
        addButton: "Adicionar app…",
        removeButton: "Remover",
        addLetterButton: "Adicionar letra…",
        removeLetterButton: "Remover letra"
    )

    static let tr = QuickLaunchStrings(
        sectionTitle: "Hızlı Başlatma",
        enableToggle: "Hızlı Başlatmayı Etkinleştir",
        enableCaption: "Aşağıdaki değiştiriciyi basılı tutup bir harfe basarak o harfle eşleşen açık uygulamayı öne getirin. Basılı tutarken aynı harfe tekrar basmak sıradaki eşleşmeye geçer. Hiçbir şey başlatılmaz — yalnızca zaten çalışan uygulamalar. Basılı tutulduğunda bu tuş sıradan bir değiştirici gibi davranmaz — kopyalama veya yapıştırma gibi diğer kısayolları engellenir, böylece bıraktığınız uygulamada da tetiklenmez.",
        modifierLabel: "Değiştirici",
        modifierRightCommand: "Sağ ⌘",
        modifierLeftCommand: "Sol ⌘",
        modifierRightOption: "Sağ ⌥",
        modifierLeftOption: "Sol ⌥",
        modifierRightControl: "Sağ ⌃",
        modifierLeftControl: "Sol ⌃",
        prioritiesTitle: "Harfe göre öncelikler",
        prioritiesCaption: "Bir harfin önce hangi uygulamaya ulaşacağını seçin ve o harfle başlamayan uygulamalar da ekleyin. Sıralanmamış uygulamalar en son kullanıma göre sıralanır.",
        addButton: "Uygulama ekle…",
        removeButton: "Kaldır",
        addLetterButton: "Harf ekle…",
        removeLetterButton: "Harfi kaldır"
    )

    static let ru = QuickLaunchStrings(
        sectionTitle: "Быстрый запуск",
        enableToggle: "Включить быстрый запуск",
        enableCaption: "Удерживайте модификатор ниже и нажмите букву, чтобы вывести на передний план соответствующее запущенное приложение. Повторное нажатие той же буквы при удержании переключает на следующее совпадение. Ничего не запускается — только уже открытые приложения. Пока клавиша удерживается, она перестаёт работать как обычный модификатор — другие сочетания на ней, например копирование или вставка, блокируются, чтобы не сработать и в покидаемом приложении.",
        modifierLabel: "Модификатор",
        modifierRightCommand: "Правый ⌘",
        modifierLeftCommand: "Левый ⌘",
        modifierRightOption: "Правый ⌥",
        modifierLeftOption: "Левый ⌥",
        modifierRightControl: "Правый ⌃",
        modifierLeftControl: "Левый ⌃",
        prioritiesTitle: "Приоритеты по буквам",
        prioritiesCaption: "Выберите, какое приложение буква открывает первым, и добавьте приложения, названия которых не начинаются с этой буквы. Неотсортированные приложения идут по недавнему использованию.",
        addButton: "Добавить приложение…",
        removeButton: "Удалить",
        addLetterButton: "Добавить букву…",
        removeLetterButton: "Удалить букву"
    )

    static let es = QuickLaunchStrings(
        sectionTitle: "Inicio Rápido",
        enableToggle: "Activar Inicio Rápido",
        enableCaption: "Mantén pulsado el modificador de abajo y toca una letra para traer al frente la app abierta que coincida. Toca la misma letra otra vez sin soltar para pasar a la siguiente coincidencia. Nunca se abre nada — solo apps que ya están abiertas. Mientras se mantiene pulsada, esta tecla deja de actuar como modificador normal — otros atajos con ella, como copiar o pegar, quedan bloqueados para que nunca se disparen también en la app que dejas atrás.",
        modifierLabel: "Modificador",
        modifierRightCommand: "⌘ derecha",
        modifierLeftCommand: "⌘ izquierda",
        modifierRightOption: "⌥ derecha",
        modifierLeftOption: "⌥ izquierda",
        modifierRightControl: "⌃ derecha",
        modifierLeftControl: "⌃ izquierda",
        prioritiesTitle: "Prioridades por letra",
        prioritiesCaption: "Elige a qué app llega primero cada letra, y añade apps que no empiecen por esa letra. Las apps sin prioridad siguen el uso más reciente.",
        addButton: "Añadir app…",
        removeButton: "Quitar",
        addLetterButton: "Añadir letra…",
        removeLetterButton: "Quitar letra"
    )

    static let de = QuickLaunchStrings(
        sectionTitle: "Schnellstart",
        enableToggle: "Schnellstart aktivieren",
        enableCaption: "Halte die untenstehende Modifikatortaste gedrückt und tippe einen Buchstaben, um die passende laufende App nach vorn zu holen. Denselben Buchstaben bei gehaltener Taste erneut tippen wechselt zum nächsten Treffer. Es wird nie etwas gestartet — nur bereits laufende Apps. Solange sie gehalten wird, verhält sich diese Taste nicht mehr wie ein gewöhnlicher Modifikator — andere Tastenkombinationen damit, etwa Kopieren oder Einfügen, werden blockiert, damit sie nicht auch in der verlassenen App ausgelöst werden.",
        modifierLabel: "Modifikator",
        modifierRightCommand: "Rechte ⌘",
        modifierLeftCommand: "Linke ⌘",
        modifierRightOption: "Rechte ⌥",
        modifierLeftOption: "Linke ⌥",
        modifierRightControl: "Rechte ⌃",
        modifierLeftControl: "Linke ⌃",
        prioritiesTitle: "Prioritäten pro Buchstabe",
        prioritiesCaption: "Lege fest, welche App ein Buchstabe zuerst erreicht, und füge Apps hinzu, die nicht mit diesem Buchstaben beginnen. Nicht eingestufte Apps folgen nach letzter Nutzung.",
        addButton: "App hinzufügen…",
        removeButton: "Entfernen",
        addLetterButton: "Buchstabe hinzufügen…",
        removeLetterButton: "Buchstabe entfernen"
    )

    static let fr = QuickLaunchStrings(
        sectionTitle: "Lancement Rapide",
        enableToggle: "Activer le Lancement Rapide",
        enableCaption: "Maintenez le modificateur ci-dessous et appuyez sur une lettre pour ramener au premier plan l'app ouverte correspondante. Appuyer à nouveau sur la même lettre en la maintenant passe à la correspondance suivante. Rien n'est jamais lancé — uniquement des apps déjà ouvertes. Tant qu'elle est maintenue, cette touche cesse d'agir comme un modificateur ordinaire — les autres raccourcis qui l'utilisent, comme copier ou coller, sont bloqués pour ne jamais se déclencher aussi dans l'app que vous quittez.",
        modifierLabel: "Modificateur",
        modifierRightCommand: "⌘ droite",
        modifierLeftCommand: "⌘ gauche",
        modifierRightOption: "⌥ droite",
        modifierLeftOption: "⌥ gauche",
        modifierRightControl: "⌃ droite",
        modifierLeftControl: "⌃ gauche",
        prioritiesTitle: "Priorités par lettre",
        prioritiesCaption: "Choisissez quelle app une lettre atteint en premier, et ajoutez des apps qui ne commencent pas par cette lettre. Les apps non classées suivent l'utilisation la plus récente.",
        addButton: "Ajouter une app…",
        removeButton: "Retirer",
        addLetterButton: "Ajouter une lettre…",
        removeLetterButton: "Retirer la lettre"
    )

    static let it = QuickLaunchStrings(
        sectionTitle: "Avvio Rapido",
        enableToggle: "Attiva Avvio Rapido",
        enableCaption: "Tieni premuto il modificatore qui sotto e premi una lettera per portare in primo piano l'app aperta corrispondente. Premere di nuovo la stessa lettera mentre è tenuto premuto passa alla corrispondenza successiva. Non viene mai aperto nulla — solo app già in esecuzione. Finché è tenuto premuto, questo tasto smette di comportarsi come un normale modificatore — le altre scorciatoie che lo usano, come copia o incolla, vengono bloccate così da non attivarsi anche nell'app che stai lasciando.",
        modifierLabel: "Modificatore",
        modifierRightCommand: "⌘ destro",
        modifierLeftCommand: "⌘ sinistro",
        modifierRightOption: "⌥ destro",
        modifierLeftOption: "⌥ sinistro",
        modifierRightControl: "⌃ destro",
        modifierLeftControl: "⌃ sinistro",
        prioritiesTitle: "Priorità per lettera",
        prioritiesCaption: "Scegli quale app una lettera raggiunge per prima e aggiungi app che non iniziano con quella lettera. Le app senza priorità seguono l'uso più recente.",
        addButton: "Aggiungi app…",
        removeButton: "Rimuovi",
        addLetterButton: "Aggiungi lettera…",
        removeLetterButton: "Rimuovi lettera"
    )

    static let ja = QuickLaunchStrings(
        sectionTitle: "クイック起動",
        enableToggle: "クイック起動を有効にする",
        enableCaption: "下の修飾キーを押したまま文字キーを押すと、一致する起動中のAppが前面に来ます。押したまま同じ文字をもう一度押すと次の候補に切り替わります。何も新しく起動しません — すでに起動しているAppのみが対象です。押している間、このキーは通常の修飾キーとして機能しなくなります — コピーや貼り付けなど他のショートカットはブロックされ、離れるAppで誤って実行されることはありません。",
        modifierLabel: "修飾キー",
        modifierRightCommand: "右⌘",
        modifierLeftCommand: "左⌘",
        modifierRightOption: "右⌥",
        modifierLeftOption: "左⌥",
        modifierRightControl: "右⌃",
        modifierLeftControl: "左⌃",
        prioritiesTitle: "文字ごとの優先順位",
        prioritiesCaption: "文字が最初にどのAppに到達するかを選び、その文字で始まらないAppも追加できます。順位のないAppは最近使った順になります。",
        addButton: "Appを追加…",
        removeButton: "削除",
        addLetterButton: "文字を追加…",
        removeLetterButton: "文字を削除"
    )

    static let ko = QuickLaunchStrings(
        sectionTitle: "빠른 실행",
        enableToggle: "빠른 실행 사용",
        enableCaption: "아래 보조 키를 누른 채로 글자를 누르면 일치하는 실행 중인 앱이 앞으로 옵니다. 누른 채로 같은 글자를 다시 누르면 다음 일치 항목으로 이동합니다. 아무것도 새로 실행되지 않습니다 — 이미 실행 중인 앱만 해당됩니다. 누르고 있는 동안 이 키는 일반 보조 키처럼 동작하지 않습니다 — 복사나 붙여넣기 같은 다른 단축키는 차단되어 떠나는 앱에서도 실행되지 않습니다.",
        modifierLabel: "보조 키",
        modifierRightCommand: "오른쪽 ⌘",
        modifierLeftCommand: "왼쪽 ⌘",
        modifierRightOption: "오른쪽 ⌥",
        modifierLeftOption: "왼쪽 ⌥",
        modifierRightControl: "오른쪽 ⌃",
        modifierLeftControl: "왼쪽 ⌃",
        prioritiesTitle: "글자별 우선순위",
        prioritiesCaption: "각 글자가 먼저 도달할 앱을 선택하고, 그 글자로 시작하지 않는 앱도 추가할 수 있습니다. 순위가 없는 앱은 최근 사용 순서를 따릅니다.",
        addButton: "앱 추가…",
        removeButton: "제거",
        addLetterButton: "글자 추가…",
        removeLetterButton: "글자 제거"
    )

    static let zhHans = QuickLaunchStrings(
        sectionTitle: "快速启动",
        enableToggle: "启用快速启动",
        enableCaption: "按住下方的修饰键并点按一个字母，即可将匹配的运行中 App 调到前台。按住不放时再次点按同一字母可切换到下一个匹配项。不会启动任何新 App — 仅涉及已在运行的 App。按住期间，该键不再作为普通修饰键使用 — 复制、粘贴等其他快捷键会被阻止，不会在你离开的 App 中意外触发。",
        modifierLabel: "修饰键",
        modifierRightCommand: "右 ⌘",
        modifierLeftCommand: "左 ⌘",
        modifierRightOption: "右 ⌥",
        modifierLeftOption: "左 ⌥",
        modifierRightControl: "右 ⌃",
        modifierLeftControl: "左 ⌃",
        prioritiesTitle: "按字母设置优先级",
        prioritiesCaption: "选择某个字母最先到达哪个 App，也可以添加名称不以该字母开头的 App。未设置优先级的 App 按最近使用顺序排列。",
        addButton: "添加 App…",
        removeButton: "移除",
        addLetterButton: "添加字母…",
        removeLetterButton: "移除字母"
    )

    static let zhTW = QuickLaunchStrings(
        sectionTitle: "快速啟動",
        enableToggle: "啟用快速啟動",
        enableCaption: "按住下方的修飾鍵並點按一個字母，即可將相符的執行中 App 調到最前面。按住不放時再次點按同一字母可切換到下一個相符項目。不會啟動任何新 App — 僅涉及已在執行的 App。按住期間，該鍵不再作為一般修飾鍵使用 — 複製、貼上等其他快捷鍵會被阻擋，不會在你離開的 App 中意外觸發。",
        modifierLabel: "修飾鍵",
        modifierRightCommand: "右 ⌘",
        modifierLeftCommand: "左 ⌘",
        modifierRightOption: "右 ⌥",
        modifierLeftOption: "左 ⌥",
        modifierRightControl: "右 ⌃",
        modifierLeftControl: "左 ⌃",
        prioritiesTitle: "依字母設定優先順序",
        prioritiesCaption: "選擇某個字母最先開啟哪個 App，也可以加入名稱不以該字母開頭的 App。沒有設定優先順序的 App 依最近使用順序排列。",
        addButton: "加入 App…",
        removeButton: "移除",
        addLetterButton: "加入字母…",
        removeLetterButton: "移除字母"
    )

    static let zhHK = QuickLaunchStrings(
        sectionTitle: "快速啟動",
        enableToggle: "啟用快速啟動",
        enableCaption: "按住下方的修飾鍵並點按一個字母，即可將相符的執行中 App 調到最前面。按住不放時再次點按同一字母可切換到下一個相符項目。不會啟動任何新 App — 僅涉及已在執行的 App。按住期間，該鍵不再作為一般修飾鍵使用 — 複製、貼上等其他快捷鍵會被阻擋，不會在你離開的 App 中意外觸發。",
        modifierLabel: "修飾鍵",
        modifierRightCommand: "右 ⌘",
        modifierLeftCommand: "左 ⌘",
        modifierRightOption: "右 ⌥",
        modifierLeftOption: "左 ⌥",
        modifierRightControl: "右 ⌃",
        modifierLeftControl: "左 ⌃",
        prioritiesTitle: "依字母設定優先順序",
        prioritiesCaption: "選擇某個字母最先開啟哪個 App，也可以加入名稱不以該字母開頭的 App。沒有設定優先順序的 App 依最近使用順序排列。",
        addButton: "加入 App…",
        removeButton: "移除",
        addLetterButton: "加入字母…",
        removeLetterButton: "移除字母"
    )
}
