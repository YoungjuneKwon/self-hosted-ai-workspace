# self-hosted-ai-workspace

[![CI](https://github.com/YoungjuneKwon/self-hosted-ai-workspace/actions/workflows/ci.yml/badge.svg)](https://github.com/YoungjuneKwon/self-hosted-ai-workspace/actions/workflows/ci.yml)
[![license](https://img.shields.io/github/license/YoungjuneKwon/self-hosted-ai-workspace.svg)](../../LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Engine-2496ED.svg?logo=docker&logoColor=white)](https://docs.docker.com/engine/)
[![Debian](https://img.shields.io/badge/Debian-12-A81D33.svg?logo=debian&logoColor=white)](https://www.debian.org/)
[![Node](https://img.shields.io/badge/Node-22-5FA04E.svg?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-included-D97757.svg)](https://docs.claude.com/ko/docs/claude-code)
[![ValetFS](https://img.shields.io/badge/ValetFS-v0.3.0-0A7E8C.svg)](https://github.com/WinM2M/valet-fs)
[![docs](https://img.shields.io/badge/docs-English-blue.svg)](../../README.md)

**AI 코딩 에이전트용 작업 컨테이너를 설정하는 스크립트입니다.
키는 폰에 남고, 맥락은 내 디스크에 남습니다.**

English: [../../README.md](../../README.md)

## 왜 필요한가

클라우드 작업환경은 바로 사용할 수 있고, 사용할 때마다 초기 상태로 시작합니다. 가끔 쓴다면
이런 방식이 적합합니다. 매일 쓰면 세션마다 같은 도구와 파일을 준비하고 권한을 다시 설정해야
합니다. 자격 증명, 작업 맥락, 사용 한계도 서비스 제공자가 관리합니다.

호텔과 집의 차이에 가깝습니다. 대부분의 사용자에게는 클라우드 작업환경이 적합합니다. 이
저장소는 작업환경을 직접 관리해야 하는 경우를 위한 것입니다.

**전제하는 독자:** Claude Code 같은 코딩 에이전트를 이미 쓰고 있고 그 한계에 부딪혀 본
사람입니다. AI 코딩 에이전트 입문서가 아니며, 아직 쓸지 말지 정하는 단계라면 설정 비용이
아깝습니다.

## 차이가 실제로 무엇인가

아래 비교는 2026년 10월 기준입니다. 서비스 기능은 바뀔 수 있으므로, 필요한 기능의 현재 지원
여부는 직접 확인해 주세요.

| | 오픈AI 클라우드 | 앤트로픽 클라우드 | 이 작업환경 |
|---|:---:|:---:|:---:|
| 내가 통제하는 하드웨어에서 실행 | X | X | O |
| 세션이 끝나도 맥락이 남는다 | △ | △ | O |
| 데스크톱·브라우저 제어 | △ | △ | O |
| 자격 증명과 권한 | X | △ | O |
| 작업 중에 UI 를 만들어 붙인다 | X | △ | O |
| **24/7 사실상 무정지로 돈다** | **O** | **O** | **X** |
| 데이터가 둔 자리에 남는다 | X | X | O |
| 비용을 예측할 수 있다 | △ | △ | O |

`O` 직접 지원 · `△` 부분적이거나 제약이 있음 · `X` 불가

굵게 표시한 항목에서는 클라우드가 유리합니다. 집에 있는 컴퓨터의 전원이 꺼지거나 네트워크가
끊겨도, 노트북 덮개를 닫아도 호스팅 에이전트는 계속 실행됩니다. 호스트를 계속 켜 두고 cron
과 재시작 정책을 설정해도 이 차이를 완전히 없앨 수는 없습니다. 반드시 실행돼야 하는 예약
작업에는 클라우드를 사용하는 편이 좋습니다. 이 작업환경과 클라우드를 함께 사용할 수도
있습니다.

각 항목의 근거: [why-this-exists.md](why-this-exists.md)

## 무엇이 들어 있나

재시작해도 홈 디렉터리가 남는 데비안 컨테이너입니다.

- Node 22, Python 3.11, git, gh, ripgrep, jq
- Claude Code. 필요하면 opencode 와 Codex CLI 도 함께 설치합니다.
- [ValetFS](https://github.com/WinM2M/valet-fs). 비밀값을 컨테이너에 저장하지 않고
  명령 하나에만 전달합니다. 설치할 때 공개된 SHA-256 을 확인합니다. 이 검사로 확인할 수
  있는 범위는 아래 「체크섬에 대해」에서 설명합니다.
- `ssh`, `rsync`, `tmux`, `wget`, `openssl`. 실제 작업은 대부분 컨테이너 밖의 무언가에
  닿고, 리스너는 띄운 셸보다 오래 살아야 하기 때문입니다. `cloudflared` 는
  `--with-cloudflared` 를 줄 때 설치합니다.
- `workspace/` 는 호스트에서 바인드 마운트됩니다. 코드는 호스트에 남으므로 컨테이너를
  삭제해도 됩니다.

## 빠른 시작

**권장 경로는 Docker Engine 입니다.** 리눅스에서는 Docker Engine 을 설치하고,
윈도우에서는 WSL2 배포판 안에 Docker Engine 을 설치한 뒤 그 안에서 스크립트를
실행합니다. 여기 적힌 모든 것을 **이 구성에서 검증했습니다** — Debian 12, Docker
Engine 29.5, x86_64.

**Docker Desktop 은 검증하지 않았습니다.** 동작할 것으로 보고 여기 어떤 것도 Engine
에만 의존하지 않지만, 실제로 돌려 보지 않았으니 미확인으로 보시면 됩니다. 또한 컨테이너와
윈도우 호스트 사이에 자체 프록시가 하나 더 있어 공개한 포트의 동작이 Engine 의 직접
바인딩과 다릅니다. 이 때문에 시간을 쓴 적이 있다면 WSL2 안에 Engine 을 올리는 쪽이 그
계층을 아예 피합니다.

```sh
git clone https://github.com/YoungjuneKwon/self-hosted-ai-workspace
cd self-hosted-ai-workspace
./bootstrap.sh
```

스크립트는 필요한 도구를 확인한 뒤 도커 이미지, 홈 디렉터리용 named volume, 컨테이너를
만듭니다. 도커 외부에 만드는 것은 스크립트를 실행한 디렉터리의 `workspace/` 뿐입니다.

```sh
./bootstrap.sh --help         # 전체 옵션
./bootstrap.sh --no-valetfs   # 금고 없이
./bootstrap.sh --grant-vault  # 아래 허가 질문에 미리 답하고 시작
./bootstrap.sh --port 5173    # 포트를 공개합니다. 여러 번 쓸 수 있습니다
./bootstrap.sh --shell        # 이미 만든 작업환경에 셸로 들어가기
./bootstrap.sh -- claude --version   # 셸 대신 명령 하나만 실행합니다
```

지정하지 않으면 포트를 하나도 공개하지 않습니다. 컨테이너 안에서 돌리는 개발 서버에
접속하려면 포트마다 `--port` 를 한 번씩 지정합니다.

컨테이너 안에서 `claude` 를 실행해 로그인하면 로그인 세션이 볼륨에 저장됩니다.

## ValetFS 가 무엇인가

이 저장소 곳곳에 [ValetFS](https://github.com/WinM2M/valet-fs) 가 나오므로, 다시
나오기 전에 한 문단으로 밝혀 둡니다.

에이전트가 도는 기계가 아니라 **폰에 API 키를 보관하는 작은 오픈소스 도구**입니다.
컨테이너의 데몬이 폰이 허용하는 동안에만 키를 메모리로 받고, `valetfs exec` 가 값을 자식
프로세스에 넘기므로 에이전트는 그 값을 읽지 않습니다. 이름이 곧 설명입니다 — 발레파킹처럼
운전은 남이 하되 열쇠는 내게 돌아옵니다.

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
```

위 비교표의 「자격 증명과 권한」 줄 때문에 들어 있습니다. 키를 읽은 에이전트는 그 사본을
전사본에 남기고, 그 사본은 폐기할 수 없습니다. **선택 사항입니다** — `--no-valetfs` 를
주면 빼고도 나머지는 그대로 동작합니다. MIT 라이선스에 무료이고, 제가 만들었습니다. 이
작업환경이 이 도구를 집어 드는 이유이기도 합니다.

저장소: <https://github.com/WinM2M/valet-fs> ·
문서: <https://winm2m.github.io/valet-fs/> ·
자세한 내용은 [secrets.md](secrets.md)

## 부트스트랩이 묻는 것

컨테이너를 시작하기 전에 스크립트가 에이전트의 `valetfs exec` 실행을 매번 승인 없이
허용할지 묻습니다. 이때 허용되는 명령도 표시합니다. `exec`·`ls`·`status` 가 포함되며
`cat` 은 제외됩니다.

에이전트의 금고 상시 접근을 허용할지는 운영자가 결정해야 하므로, 스크립트가 임의로 설정하지
않고 묻습니다. 운영자가 답하면 스크립트가 설정을 바로 적용합니다. 나중에 명령을 따로 입력할
필요는 없습니다.

자동화 스크립트에서 실행할 때는 `--grant-vault` 나 `--no-grant-vault` 를 사용합니다.
비대화형 실행에서는 기본적으로 접근을 허용하지 않습니다. 나중에 답을 바꾸려면 컨테이너
안에서 `valetfs setup-claude` 를 실행하거나 `~/.claude/settings.json` 을 수정합니다.

에이전트가 비밀값을 읽지 않고도 명령에 전달하는 방식과 이 방식의 보안상 한계는
[secrets.md](secrets.md) 에서 설명합니다.

## 바깥과 연결하기

깃헙, Claude Code 로그인, Claude 리모트 컨트롤, MCP 커넥터, 공개 URL 은 각각 한 단계씩
필요하고, 설정은 홈 볼륨에 남으므로 한 번만 하면 됩니다. 컨테이너로 통과하지 않는 것까지
[connect.md](connect.md) 에 정리했습니다.

## 체크섬에 대해

설치기는 SHA-256 을 바이너리와 **같은 깃헙 릴리스**에서 받아 옵니다. 이 검사로 다운로드가
중간에 끊기거나 파일이 손상됐는지는 확인할 수 있지만, 파일의 출처는 확인할 수 없습니다.
바이너리를 바꿀 권한이 있으면 체크섬 파일도 바꿀 수 있기 때문입니다.

ValetFS 릴리스에는 cosign(keyless) 서명이 있으며, 출처를 확인하려면 이 서명을 검증해야
합니다. 이미지 크기를 줄이기 위해 cosign 은 포함하지 않았습니다. 서명 검증이 필요하시면
빌드 전에 아래 명령을 직접 실행해 주세요.

```sh
cosign verify-blob \
  --certificate SHA256SUMS.pem \
  --signature   SHA256SUMS.sig \
  --certificate-identity-regexp 'https://github.com/WinM2M/valet-fs/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SHA256SUMS
```

## 이것이 아닌 것

- **클라우드 대체재가 아닙니다.** 예약 작업의 지속 실행 여부는 위 표의 굵게 표시한 항목을
  참고해 주세요.
- **GPU 장비가 아닙니다.** 호스팅 모델을 호출하는 에이전트용 작업환경입니다. 로컬 추론
  환경은 구성하지 않습니다.
- **작업환경 전체를 구성하지는 않습니다.** 에이전트가 제어하는 브라우저, 터널, 호스트별
  설정은 다른 환경으로 그대로 옮길 수 없어 구성 대상에서 제외했습니다.
- **독립적인 감사를 받지 않았습니다.** 제3자 보안 검토는 없었습니다. 실행 전에
  `docker/Dockerfile` 과 `bootstrap.sh` 를 읽어 보시기 바랍니다.
- **Docker Desktop 에서 시험하지 않았습니다.** 여기 있는 것은 전부 Docker Engine 에서
  돌렸습니다. Docker Desktop 도 동작할 것으로 보고 쓰지 말라는 뜻은 아니지만, 확인되지
  않았습니다. 써 보셨다면 결과를 이슈로 남겨 주시면 고맙겠습니다.

ValetFS 는 이 저장소와 같은 저자가 공개했습니다.

## 라이선스

MIT. [LICENSE](../../LICENSE)
