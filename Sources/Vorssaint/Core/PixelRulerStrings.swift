// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Localized strings for the pixel ruler: hover-to-measure edge distances,
/// styled after PixelSnap.
struct PixelRulerFeatureStrings {
    let pageTitle: String
    let hubDescription: String
    let panelCaption: String
    let enableShortcutToggle: String
    let toleranceTitle: String
    let toleranceZero: String
    let toleranceLow: String
    let toleranceMedium: String
    let toleranceHigh: String
    let toleranceCaption: String
    let unitTitle: String
    let unitPixels: String
    let unitPoints: String
    let keysCaption: String
    let streamFailedHUD: String
}

extension FeatureStrings {
    static func pixelRuler(_ language: AppLanguage) -> PixelRulerFeatureStrings {
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

extension PixelRulerFeatureStrings {
    static let enUS = PixelRulerFeatureStrings(
        pageTitle: "Pixel Ruler",
        hubDescription: "Hover to measure live pixel distances to nearby edges",
        panelCaption: "Measure distances between edges on screen",
        enableShortcutToggle: "Enable shortcut",
        toleranceTitle: "Edge sensitivity",
        toleranceZero: "Zero",
        toleranceLow: "Low",
        toleranceMedium: "Medium",
        toleranceHigh: "High",
        toleranceCaption: "How much contrast counts as an edge. Lower catches more edges; higher ignores subtle shadows and gradients.",
        unitTitle: "Units",
        unitPixels: "Pixels",
        unitPoints: "Points",
        keysCaption: "While measuring: Esc to stop, +/- to adjust sensitivity, Tab to cycle presets, U to switch units.",
        streamFailedHUD: "Pixel Ruler couldn't start")

    static let ptBR = PixelRulerFeatureStrings(
        pageTitle: "Régua de Pixels",
        hubDescription: "Passe o cursor para medir distâncias em pixels até bordas próximas",
        panelCaption: "Meça distâncias entre bordas na tela",
        enableShortcutToggle: "Ativar atalho",
        toleranceTitle: "Sensibilidade de borda",
        toleranceZero: "Zero",
        toleranceLow: "Baixa",
        toleranceMedium: "Média",
        toleranceHigh: "Alta",
        toleranceCaption: "Quanto contraste conta como uma borda. Mais baixa detecta mais bordas; mais alta ignora sombras e gradientes sutis.",
        unitTitle: "Unidades",
        unitPixels: "Pixels",
        unitPoints: "Pontos",
        keysCaption: "Durante a medição: Esc para parar, +/- para ajustar a sensibilidade, Tab para alternar predefinições, U para trocar unidades.",
        streamFailedHUD: "Não foi possível iniciar a Régua de Pixels")

    static let tr = PixelRulerFeatureStrings(
        pageTitle: "Piksel Cetveli",
        hubDescription: "Yakındaki kenarlara olan canlı piksel mesafelerini ölçmek için üzerine gelin",
        panelCaption: "Ekrandaki kenarlar arasındaki mesafeleri ölçün",
        enableShortcutToggle: "Kısayolu etkinleştir",
        toleranceTitle: "Kenar hassasiyeti",
        toleranceZero: "Sıfır",
        toleranceLow: "Düşük",
        toleranceMedium: "Orta",
        toleranceHigh: "Yüksek",
        toleranceCaption: "Ne kadar kontrastın kenar sayılacağı. Düşük değer daha çok kenar yakalar; yüksek değer hafif gölgeleri ve geçişleri yok sayar.",
        unitTitle: "Birimler",
        unitPixels: "Piksel",
        unitPoints: "Nokta",
        keysCaption: "Ölçüm sırasında: durdurmak için Esc, hassasiyeti ayarlamak için +/-, ön ayarlar arasında geçiş için Tab, birim değiştirmek için U.",
        streamFailedHUD: "Piksel Cetveli başlatılamadı")

    static let ru = PixelRulerFeatureStrings(
        pageTitle: "Пиксельная линейка",
        hubDescription: "Наведите курсор, чтобы измерить расстояние в пикселях до ближайших краёв",
        panelCaption: "Измеряйте расстояния между краями на экране",
        enableShortcutToggle: "Включить сочетание клавиш",
        toleranceTitle: "Чувствительность к краям",
        toleranceZero: "Ноль",
        toleranceLow: "Низкая",
        toleranceMedium: "Средняя",
        toleranceHigh: "Высокая",
        toleranceCaption: "Какой контраст считается краем: меньшее значение выявляет больше краёв, а большее игнорирует лёгкие тени и градиенты.",
        unitTitle: "Единицы",
        unitPixels: "Пиксели",
        unitPoints: "Пункты",
        keysCaption: "Во время измерения: Esc останавливает, +/- изменяет чувствительность, Tab переключает пресеты, U меняет единицы.",
        streamFailedHUD: "Не удалось запустить пиксельную линейку")

    static let es = PixelRulerFeatureStrings(
        pageTitle: "Regla de Píxeles",
        hubDescription: "Pasa el cursor para medir distancias en píxeles hasta los bordes cercanos",
        panelCaption: "Mide distancias entre bordes en la pantalla",
        enableShortcutToggle: "Activar atajo",
        toleranceTitle: "Sensibilidad de bordes",
        toleranceZero: "Cero",
        toleranceLow: "Baja",
        toleranceMedium: "Media",
        toleranceHigh: "Alta",
        toleranceCaption: "Cuánto contraste cuenta como borde. Baja detecta más bordes; alta ignora sombras y degradados sutiles.",
        unitTitle: "Unidades",
        unitPixels: "Píxeles",
        unitPoints: "Puntos",
        keysCaption: "Mientras mides: Esc para detener, +/- para ajustar la sensibilidad, Tab para cambiar de preajuste, U para cambiar de unidad.",
        streamFailedHUD: "No se pudo iniciar la Regla de Píxeles")

    static let de = PixelRulerFeatureStrings(
        pageTitle: "Pixel-Lineal",
        hubDescription: "Bewege den Zeiger, um Pixelabstände zu nahen Kanten live zu messen",
        panelCaption: "Miss Abstände zwischen Kanten auf dem Bildschirm",
        enableShortcutToggle: "Tastenkombination aktivieren",
        toleranceTitle: "Kantenempfindlichkeit",
        toleranceZero: "Null",
        toleranceLow: "Niedrig",
        toleranceMedium: "Mittel",
        toleranceHigh: "Hoch",
        toleranceCaption: "Wie viel Kontrast als Kante zählt. Niedriger erkennt mehr Kanten; höher ignoriert leichte Schatten und Verläufe.",
        unitTitle: "Einheiten",
        unitPixels: "Pixel",
        unitPoints: "Punkte",
        keysCaption: "Während der Messung: Esc zum Beenden, +/- zum Anpassen der Empfindlichkeit, Tab zum Wechseln der Voreinstellungen, U zum Wechseln der Einheit.",
        streamFailedHUD: "Pixel-Lineal konnte nicht gestartet werden")

    static let fr = PixelRulerFeatureStrings(
        pageTitle: "Règle de Pixels",
        hubDescription: "Survolez pour mesurer en direct les distances en pixels jusqu'aux bords proches",
        panelCaption: "Mesurez les distances entre les bords à l'écran",
        enableShortcutToggle: "Activer le raccourci",
        toleranceTitle: "Sensibilité des bords",
        toleranceZero: "Zéro",
        toleranceLow: "Faible",
        toleranceMedium: "Moyenne",
        toleranceHigh: "Élevée",
        toleranceCaption: "Le contraste nécessaire pour compter comme un bord. Plus faible détecte plus de bords ; plus élevée ignore les ombres et dégradés subtils.",
        unitTitle: "Unités",
        unitPixels: "Pixels",
        unitPoints: "Points",
        keysCaption: "Pendant la mesure : Échap pour arrêter, +/- pour ajuster la sensibilité, Tab pour changer de préréglage, U pour changer d'unité.",
        streamFailedHUD: "Impossible de démarrer la Règle de Pixels")

    static let it = PixelRulerFeatureStrings(
        pageTitle: "Righello Pixel",
        hubDescription: "Passa il cursore per misurare in tempo reale le distanze in pixel dai bordi vicini",
        panelCaption: "Misura le distanze tra i bordi sullo schermo",
        enableShortcutToggle: "Attiva scorciatoia",
        toleranceTitle: "Sensibilità dei bordi",
        toleranceZero: "Zero",
        toleranceLow: "Bassa",
        toleranceMedium: "Media",
        toleranceHigh: "Alta",
        toleranceCaption: "Quanto contrasto conta come bordo. Più bassa rileva più bordi; più alta ignora ombre e sfumature sottili.",
        unitTitle: "Unità",
        unitPixels: "Pixel",
        unitPoints: "Punti",
        keysCaption: "Durante la misurazione: Esc per interrompere, +/- per regolare la sensibilità, Tab per cambiare preset, U per cambiare unità.",
        streamFailedHUD: "Impossibile avviare il Righello Pixel")

    static let ja = PixelRulerFeatureStrings(
        pageTitle: "ピクセル定規",
        hubDescription: "カーソルを合わせると、近くの端までのピクセル距離をリアルタイムで測定します",
        panelCaption: "画面上の端と端の距離を測定します",
        enableShortcutToggle: "ショートカットを有効にする",
        toleranceTitle: "エッジ検出の感度",
        toleranceZero: "ゼロ",
        toleranceLow: "低",
        toleranceMedium: "中",
        toleranceHigh: "高",
        toleranceCaption: "どの程度のコントラストをエッジとみなすか。低いほど多くのエッジを検出し、高いほど微妙な影やグラデーションを無視します。",
        unitTitle: "単位",
        unitPixels: "ピクセル",
        unitPoints: "ポイント",
        keysCaption: "測定中: Escで停止、+/-で感度を調整、Tabでプリセットを切り替え、Uで単位を切り替え。",
        streamFailedHUD: "ピクセル定規を開始できませんでした")

    static let ko = PixelRulerFeatureStrings(
        pageTitle: "픽셀 자",
        hubDescription: "커서를 올리면 가까운 가장자리까지의 픽셀 거리를 실시간으로 측정합니다",
        panelCaption: "화면의 가장자리 간 거리를 측정합니다",
        enableShortcutToggle: "단축키 사용",
        toleranceTitle: "가장자리 감도",
        toleranceZero: "없음",
        toleranceLow: "낮음",
        toleranceMedium: "보통",
        toleranceHigh: "높음",
        toleranceCaption: "가장자리로 인식할 대비 정도입니다. 낮으면 더 많은 가장자리를 감지하고, 높으면 미세한 그림자와 그러데이션을 무시합니다.",
        unitTitle: "단위",
        unitPixels: "픽셀",
        unitPoints: "포인트",
        keysCaption: "측정 중: Esc로 중지, +/-로 감도 조정, Tab으로 프리셋 전환, U로 단위 전환.",
        streamFailedHUD: "픽셀 자를 시작할 수 없습니다")

    static let zhHans = PixelRulerFeatureStrings(
        pageTitle: "像素尺",
        hubDescription: "悬停即可实时测量到附近边缘的像素距离",
        panelCaption: "测量屏幕上边缘之间的距离",
        enableShortcutToggle: "启用快捷键",
        toleranceTitle: "边缘灵敏度",
        toleranceZero: "零",
        toleranceLow: "低",
        toleranceMedium: "中",
        toleranceHigh: "高",
        toleranceCaption: "多大的对比度才算作边缘。越低检测到的边缘越多；越高则会忽略细微的阴影和渐变。",
        unitTitle: "单位",
        unitPixels: "像素",
        unitPoints: "点",
        keysCaption: "测量时：按 Esc 停止，按 +/- 调整灵敏度，按 Tab 切换预设，按 U 切换单位。",
        streamFailedHUD: "无法启动像素尺")

    static let zhTW = PixelRulerFeatureStrings(
        pageTitle: "像素尺",
        hubDescription: "將游標移到附近邊緣即可即時測量像素距離",
        panelCaption: "測量畫面上邊緣之間的距離",
        enableShortcutToggle: "啟用快速鍵",
        toleranceTitle: "邊緣靈敏度",
        toleranceZero: "零",
        toleranceLow: "低",
        toleranceMedium: "中",
        toleranceHigh: "高",
        toleranceCaption: "多少對比度才算是邊緣。越低偵測到的邊緣越多；越高則會忽略細微的陰影與漸層。",
        unitTitle: "單位",
        unitPixels: "像素",
        unitPoints: "點",
        keysCaption: "測量時：按 Esc 停止，按 +/- 調整靈敏度，按 Tab 切換預設，按 U 切換單位。",
        streamFailedHUD: "無法啟動像素尺")

    static let zhHK = PixelRulerFeatureStrings(
        pageTitle: "像素尺",
        hubDescription: "將游標移到附近邊緣就可以即時量度像素距離",
        panelCaption: "量度畫面上邊緣之間嘅距離",
        enableShortcutToggle: "啟用快速鍵",
        toleranceTitle: "邊緣靈敏度",
        toleranceZero: "零",
        toleranceLow: "低",
        toleranceMedium: "中",
        toleranceHigh: "高",
        toleranceCaption: "幾多對比先算邊緣。越低偵測到嘅邊緣越多；越高就會忽略細微嘅陰影同漸層。",
        unitTitle: "單位",
        unitPixels: "像素",
        unitPoints: "點",
        keysCaption: "量度緊嘅時候：撳 Esc 停止，撳 +/- 調整靈敏度，撳 Tab 切換預設，撳 U 切換單位。",
        streamFailedHUD: "無法啟動像素尺")
}
