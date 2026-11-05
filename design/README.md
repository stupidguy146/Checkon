# Design System — Checkon (เช็คก่อน)

ระบบดีไซน์รวมศูนย์สำหรับแอป โดยมี **แหล่งความจริงเดียว (single source of truth)** คือ design tokens
ที่ใช้ตรงกันทั้งในโค้ด Flutter และใน Figma

## โครงสร้าง

```
design/
├─ figma-tokens-2.json    # current logo-inspired tokens (Tokens Studio format) → import เข้า Figma
└─ README.md              # ไฟล์นี้

frontend/lib/
├─ theme/
│  ├─ app_tokens.dart     # tokens ฝั่งโค้ด (สี, spacing, radius, shadow, type)
│  └─ app_theme.dart      # ThemeData light/dark สร้างจาก tokens
└─ widgets/
   ├─ app_widgets.dart   # components ใช้ซ้ำ (AppCard, GradientHeader, StatTile, AppPill, ...)
   ├─ app_snackbar.dart  # snackbar แบ่งสีตามผล (success/error/info)
   ├─ confirm_dialog.dart# modal ยืนยันกลาง (รองรับโหมด danger สำหรับลบข้อมูล)
   ├─ password_strength_meter.dart # แถบวัดความแข็งแรง + checklist เงื่อนไขรหัสผ่าน
   └─ pin_pad.dart       # แป้น PIN 6 หลัก (ใช้ตอนตั้ง/ปลดล็อก)
```

The app bundles the Anuphan variable font under `frontend/assets/fonts/anuphan/`.
Its SIL Open Font License is included alongside the font as `OFL.txt`.

ค่าใน `app_tokens.dart` (Dart) และ `figma-tokens-2.json` (Figma) **ตรงกัน** —
ถ้าแก้สี/ระยะห่าง ให้แก้ทั้งสองที่เพื่อให้ดีไซน์กับโค้ดไม่หลุดกัน

---

## วิธีนำ tokens เข้า Figma (ด้วยปลั๊กอิน Tokens Studio)

> หมายเหตุ: ผมสร้างไฟล์ `.fig` โดยตรงไม่ได้ (เป็นฟอร์แมตปิดของ Figma)
> วิธีมาตรฐานของวงการคือใช้ปลั๊กอินฟรี **Tokens Studio for Figma** นำ JSON เข้าไปสร้างเป็น Figma variables/styles

1. เปิดไฟล์ Figma → เมนู **Plugins → Tokens Studio for Figma** (ติดตั้งจาก Figma Community ถ้ายังไม่มี)
2. ในปลั๊กอิน เลือก **Tools → Load from file / Import**
3. เลือกไฟล์ `design/figma-tokens-2.json`
4. กด **Import** — จะได้ token sets: `global`, `light`, `dark`
5. กด **Create styles / Create variables** ในปลั๊กอินเพื่อแปลง tokens เป็น Figma Color Styles,
   Text Styles และ Effect Styles ที่ลาก-วางใช้ในดีไซน์ได้ทันที

### ทางเลือก: sync ผ่าน Git
Tokens Studio ตั้งค่า sync กับ repo โดยตรงได้ (Settings → Sync → GitHub/GitLab)
ชี้ไปที่ `design/figma-tokens-2.json` แล้วแก้ที่เดียว อัปเดตได้ทั้งโค้ดและ Figma

---

## Design tokens

### สี (Color)
| กลุ่ม | ใช้ทำอะไร |
|------|-----------|
| `brand.50–900` | สีฟ้าท้องฟ้าเป็นสีหลัก — primary = `brand.600` `#246FC4` |
| `secondary.tennisGreen` | พื้นปุ่ม action ใน light mode และจุดเน้นขนาดเล็ก |
| `secondary.green` | พื้นปุ่ม action ใน dark mode และสถานะสำเร็จ |
| `secondary.tennisGreenSurface` / `secondary.mint` | พื้นผิวเขียวโทนอ่อน |
| `accent.400–600` | สีเน้น (amber) — ใช้กับหน้าแจ้งเตือน/เงิน |
| `semantic.*` | success / warning / danger / info |
| `neutral.0–900` | สีเทา/พื้นหลัง/ตัวอักษร |
| `dark.*` | พื้นผิวสำหรับ dark mode |

### Spacing (4pt scale)
`xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48`

### Radius
`sm 8 · md 12 · lg 16 · xl 20 · xxl 28 · pill 999`

### Typography
`displayLarge 34 · headlineMedium 26 · titleLarge 20 · titleMedium 16 · bodyLarge 15 · bodyMedium 13.5 · label 12.5 · caption 11.5`

### Shadow
`sm` (การ์ด) · `md` (ลอยปานกลาง) · `lg` (modal/overlay)

---

## Components ที่ใช้ซ้ำได้ (Flutter)

| Component | หน้าที่ |
|-----------|---------|
| `AppCard` | การ์ดพื้นฐาน เงานุ่ม มุมโค้ง กดได้ |
| `GradientHeader` | hero header แบบ gradient พร้อมแถวสถิติ |
| `StatTile` | กล่องสถิติ (วางบน gradient หรือพื้นขาว) |
| `AppPill` | ป้ายสถานะ/แท็กทรงแคปซูล |
| `SectionHeader` | หัวข้อ section + ปุ่ม action |
| `EmptyState` | สถานะว่างพร้อมไอคอนวงกลม |
| `ErrorView` | มุมมอง error + ปุ่มลองใหม่ |
| `LoadingView` | ตัวโหลดกึ่งกลาง |

### ตัวอย่างการใช้
```dart
GradientHeader(
  subtitle: 'รายการซื้อของเข้าห้อง',
  title: 'สรุปทุกเดือน',
  stats: [
    StatTile(onGradient: true, label: 'ยอดรวม', value: '฿12,000'),
  ],
);

AppCard(
  onTap: () {},
  child: Text('เนื้อหา'),
);

AppPill(text: 'อีก 3 วัน', color: AppColors.warning);
```

---

## เกี่ยวกับ "Lokalise"
Lokalise เป็นเครื่องมือ **แปลภาษา (i18n/l10n)** ไม่ใช่เครื่องมือดีไซน์
ถ้าต้องการรองรับหลายภาษาในแอป แนะนำตั้ง Flutter localization (`flutter_localizations` + ไฟล์ `.arb`)
แล้วค่อย sync ไฟล์ `.arb` กับ Lokalise — แจ้งได้ถ้าต้องการให้ช่วยตั้งส่วนนี้
