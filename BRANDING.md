# remotectl 브랜딩 패치 계획

이 fork는 RustDesk 1.4.6를 기반으로 한다. AGPL-3.0 하에 운영.

## 패치 대상 (실제 hbbs 배포 후 적용)

| 파일 | 변경 사항 | 의존 |
|------|-----------|------|
| `libs/hbb_common/src/config.rs` | `RENDEZVOUS_SERVERS` → `["relay.remotectl.io"]` | hbbs 도메인 확정 |
| `libs/hbb_common/src/config.rs` | `RS_PUB_KEY` → 우리 hbbs의 `id_ed25519.pub` 내용 | hbbs 첫 실행 후 키 추출 |
| `Cargo.toml` | `name = "remotectl"`, `default-run = "remotectl"`, `description` | 브랜드명 확정 |
| `flutter/pubspec.yaml` | `name: remotectl` | 동일 |
| `flutter/lib/common.dart` | 앱 표시명 `'remotectl'` | 동일 |
| `res/icon.ico` + `flutter/assets/logo.png` | 자체 로고 (1024×1024 PNG 원본 + ICO) | 디자인 |
| `flutter/lib/desktop/widgets/menu_bar.dart` 등 | "RustDesk" 문자열 → "remotectl" | grep -r 일괄 치환 |

## 적용 순서

1. **VPS에 hbbs 띄우고 `Key:` 추출** — 이 키 없이 코드 패치하면 의미 없음.
2. 위 표의 패치를 한 PR로 묶어 적용.
3. `.github/workflows/flutter-build.yml`의 Windows job만 활성화하고 나머지는 일단 비활성화 (빌드 시간 절약).
4. 첫 빌드 → artifact 다운로드 → 자체 hbbs로 호스트 등록 테스트.

## 라이선스

이 fork는 AGPL-3.0을 유지한다. 우리가 추가한 변경 사항(브랜딩, 페어링 UI)도 AGPL이 적용된다. SaaS로 서비스 제공 시 사용자가 요청하면 fork 소스를 제공할 의무가 있다.

상용 라이선스로 전환하려면 RustDesk 측과 별도 협의 필요.

## upstream 동기화

```bash
git remote add upstream https://github.com/rustdesk/rustdesk
git fetch upstream
git merge upstream/master   # 또는 cherry-pick
```

`customize/remotectl` 브랜치에서 패치를 유지하고 `master`는 upstream 추적용으로 보관하는 패턴 권장.
